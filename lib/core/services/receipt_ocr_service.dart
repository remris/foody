import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:groq_sdk/groq_sdk.dart';

/// Ergebnis eines gescannten Kassenbons.
class ReceiptItem {
  final String name;
  final String? price;
  final String? quantity;

  const ReceiptItem({
    required this.name,
    this.price,
    this.quantity,
  });
}

/// Service für OCR-basiertes Kassenbon-Scannen.
/// Nutzt ML Kit für die Text-Erkennung und optional Groq für KI-Bereinigung.
class ReceiptOcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Bild analysieren und Positionen extrahieren.
  /// Versucht zuerst KI-Bereinigung, fällt auf lokalen Parser zurück.
  Future<List<ReceiptItem>> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final rawText = recognizedText.text;

    // Zuerst KI-basierte Bereinigung versuchen
    try {
      final aiResults = await _cleanWithAI(rawText);
      if (aiResults.isNotEmpty) return aiResults;
    } catch (_) {
      // Fallback auf lokalen Parser
    }

    return _parseReceiptText(rawText);
  }

  /// Raw-Text des Kassenbons zurückgeben.
  Future<String> getRawText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// KI-gestützte Bereinigung des OCR-Texts via Groq.
  Future<List<ReceiptItem>> _cleanWithAI(String rawText) async {
    final key = dotenv.env['GROQ_API_KEY'] ?? '';
    if (key.isEmpty) return [];

    final groq = Groq(key);
    final chat = groq.startNewChat('llama3-8b-8192');

    final prompt = '''
Du bist ein Kassenbon-Parser. Extrahiere NUR die Produktnamen aus dem folgenden OCR-Text eines Kassenbons.

Regeln:
- Nur echte Lebensmittel/Produkte zurückgeben
- Keine Preise, Summen, MwSt, Steuern, Kassennummern, Daten, Adressen
- Keine Filial-Infos, Danke-Texte, Barcodes
- Bereinige typische OCR-Fehler (z.B. "MILCH 3.5%" → "Milch 3,5%")
- Gib jeden Artikel in einer neuen Zeile zurück
- Format pro Zeile: Produktname|Menge|Preis (Menge und Preis optional, | als Trenner)
- Antworte NUR mit den Zeilen, kein anderer Text

OCR-Text:
$rawText
''';

    final (response, _) = await chat.sendMessage(prompt);
    final aiText = response.choices.first.message;

    final items = <ReceiptItem>[];
    for (final line in aiText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('-')) continue; // Markdown-Listen überspringen

      final parts = trimmed.split('|');
      final name = parts[0].trim();
      if (name.isEmpty || name.length < 2) continue;

      items.add(ReceiptItem(
        name: name,
        quantity: parts.length > 1 && parts[1].trim().isNotEmpty
            ? parts[1].trim()
            : null,
        price: parts.length > 2 && parts[2].trim().isNotEmpty
            ? parts[2].trim()
            : null,
      ));
    }

    return items;
  }

  /// Text parsen und Positionen extrahieren.
  List<ReceiptItem> _parseReceiptText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final items = <ReceiptItem>[];

    // Preismuster: 1,99 oder 1.99 oder 12,99 EUR
    final priceRegex = RegExp(r'(\d+[,\.]\d{2})\s*(EUR|€)?', caseSensitive: false);
    // Mengenangabe: 2x oder 2 Stk
    final qtyRegex = RegExp(r'^(\d+)\s*[xX×]\s*');

    // Zeilen die wir überspringen (Header/Footer/Summe)
    final skipPatterns = [
      RegExp(r'summe', caseSensitive: false),
      RegExp(r'gesamt', caseSensitive: false),
      RegExp(r'zwischen', caseSensitive: false),
      RegExp(r'total', caseSensitive: false),
      RegExp(r'mwst', caseSensitive: false),
      RegExp(r'mehrwert', caseSensitive: false),
      RegExp(r'ust', caseSensitive: false),
      RegExp(r'steuer', caseSensitive: false),
      RegExp(r'^\s*bar[\s:]', caseSensitive: false),
      RegExp(r'gegeben', caseSensitive: false),
      RegExp(r'karte', caseSensitive: false),
      RegExp(r'visa', caseSensitive: false),
      RegExp(r'mastercard', caseSensitive: false),
      RegExp(r'maestro', caseSensitive: false),
      RegExp(r'^\s*ec[\s\-]', caseSensitive: false),
      RegExp(r'rückgeld', caseSensitive: false),
      RegExp(r'wechselgeld', caseSensitive: false),
      RegExp(r'filiale', caseSensitive: false),
      RegExp(r'markt', caseSensitive: false),
      RegExp(r'datum', caseSensitive: false),
      RegExp(r'uhrzeit', caseSensitive: false),
      RegExp(r'kassierer', caseSensitive: false),
      RegExp(r'kasse\s*nr', caseSensitive: false),
      RegExp(r'bon\s*nr', caseSensitive: false),
      RegExp(r'beleg\s*nr', caseSensitive: false),
      RegExp(r'transakt', caseSensitive: false),
      RegExp(r'danke', caseSensitive: false),
      RegExp(r'vielen\s*dank', caseSensitive: false),
      RegExp(r'auf\s*wiedersehen', caseSensitive: false),
      RegExp(r'willkommen', caseSensitive: false),
      RegExp(r'tel\.?:', caseSensitive: false),
      RegExp(r'www\.', caseSensitive: false),
      RegExp(r'http', caseSensitive: false),
      RegExp(r'@', caseSensitive: false),
      RegExp(r'gmbh', caseSensitive: false),
      RegExp(r'^\d{2}[\./]\d{2}[\./]\d{2,4}'), // Datum
      RegExp(r'^\d{2}:\d{2}'), // Uhrzeit
      RegExp(r'^\s*\*+\s*$'), // Nur Sternchen
      RegExp(r'^\s*-+\s*$'), // Nur Striche
      RegExp(r'^\s*=+\s*$'), // Nur Gleichheitszeichen
      RegExp(r'pfand', caseSensitive: false),
    ];

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip-Zeilen
      if (skipPatterns.any((p) => p.hasMatch(trimmed))) continue;
      // Zu kurze Zeilen
      if (trimmed.length < 4) continue;
      // Nur-Zahlen-Zeilen (z.B. Barcodes, Nummern)
      if (RegExp(r'^\d+$').hasMatch(trimmed)) continue;
      // Zeilen die nur Sonderzeichen enthalten
      if (RegExp(r'^[^a-zA-ZäöüÄÖÜß]+$').hasMatch(trimmed)) continue;

      // Preis extrahieren
      final priceMatch = priceRegex.firstMatch(trimmed);
      String? price;
      String itemText = trimmed;

      if (priceMatch != null) {
        price = priceMatch.group(1)?.replaceAll(',', '.');
        itemText = trimmed
            .replaceFirst(priceMatch.group(0)!, '')
            .replaceAll(RegExp(r'\s*[A-B]\s*$'), '') // MwSt-Kennzeichen am Ende
            .replaceAll(RegExp(r'^\s*[A-B]\s+'), '') // MwSt-Kennzeichen am Anfang
            .trim();
      }

      // Menge extrahieren
      final qtyMatch = qtyRegex.firstMatch(itemText);
      String? quantity;
      if (qtyMatch != null) {
        quantity = qtyMatch.group(1);
        itemText = itemText.replaceFirst(qtyMatch.group(0)!, '').trim();
      }

      // Nur Items mit sinnvollem Namen (min. 3 Zeichen, mindestens 1 Buchstabe)
      final cleanedName = _cleanItemName(itemText);
      if (cleanedName.length >= 3 &&
          price != null &&
          RegExp(r'[a-zA-ZäöüÄÖÜß]').hasMatch(cleanedName)) {
        items.add(ReceiptItem(
          name: cleanedName,
          price: price,
          quantity: quantity,
        ));
      }
    }

    return items;
  }

  /// Artikelname bereinigen.
  String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[*#]+'), '')
        .trim();
  }

  void dispose() {
    _textRecognizer.close();
  }
}

