import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:groq_sdk/groq_sdk.dart';
import 'package:image_picker/image_picker.dart';

/// Erkanntes Produkt beim Kühlschrank-Scan.
class FridgeScanItem {
  final String name;
  final String? category;
  final String? quantity;
  final String? unit;
  final bool isConfident;

  const FridgeScanItem({
    required this.name,
    this.category,
    this.quantity,
    this.unit,
    this.isConfident = true,
  });
}

/// Service für KI-gestützte Kühlschrank-/Vorratsfoto-Analyse.
/// Foto → ML Kit OCR → Groq KI → strukturierte Produktliste
class FridgeScanService {
  static final _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  static final _picker = ImagePicker();

  /// Öffnet Kamera oder Galerie, analysiert das Bild und gibt erkannte Produkte zurück.
  static Future<List<FridgeScanItem>> scanFridge({
    ImageSource source = ImageSource.camera,
  }) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (photo == null) return [];

    return analyzeImageFile(File(photo.path));
  }

  /// Analysiert eine vorhandene Bilddatei.
  static Future<List<FridgeScanItem>> analyzeImageFile(File imageFile) async {
    // Schritt 1: ML Kit OCR – erkennt Texte auf Verpackungen
    String ocrText = '';
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      ocrText = recognizedText.text;
    } catch (_) {
      // OCR kann bei unscharfen Bildern fehlschlagen → trotzdem KI-Analyse
    }

    // Schritt 2: Groq KI analysiert den OCR-Text und leitet Produkte ab
    return _analyzeWithGroq(ocrText, imageFile);
  }

  /// KI-Analyse via Groq – erkennt Produkte aus OCR-Text.
  static Future<List<FridgeScanItem>> _analyzeWithGroq(
    String ocrText,
    File imageFile,
  ) async {
    final key = dotenv.env['GROQ_API_KEY'] ?? '';
    if (key.isEmpty) return _localFallback(ocrText);

    try {
      final groq = Groq(key);
      final chat = groq.startNewChat('llama3-8b-8192');

      final prompt = '''
Du bist ein intelligenter Kühlschrank-Assistent. Analysiere den folgenden OCR-Text von einem Foto eines Kühlschranks oder Vorrats.

Deine Aufgabe:
1. Erkenne alle Lebensmittel und Produkte die im Text vorkommen oder logisch erschlossen werden können
2. Ignoriere Preise, Barcodes, Adressen, Datum, technische Angaben
3. Gruppiere ähnliche Produkte (z.B. "VOLLFETT JOGHURT" → "Joghurt")
4. Schätze Mengen wenn erkennbar

Antworte NUR in diesem JSON-Format (kein Markdown, kein anderer Text):
{
  "items": [
    {"name": "Milch", "category": "Milchprodukte", "quantity": "1", "unit": "L"},
    {"name": "Butter", "category": "Milchprodukte", "quantity": "250", "unit": "g"},
    {"name": "Karotte", "category": "Gemüse", "quantity": null, "unit": null}
  ]
}

Kategorien nutze aus dieser Liste: Obst, Gemüse, Milchprodukte, Fleisch & Fisch, Brot & Backwaren, Tiefkühlprodukte, Getränke, Konserven, Gewürze & Saucen, Snacks, Sonstiges

OCR-Text vom Foto:
${ocrText.isEmpty ? "(kein Text erkannt - bitte typische Kühlschrank-Produkte vorschlagen)" : ocrText}

${ocrText.isEmpty ? "Da kein Text erkannt wurde, schlage 5-8 typische Kühlschrank-Produkte als Beispiel vor." : "Erkenne alle Produkte aus dem Text."}
''';

      final (response, _) = await chat.sendMessage(prompt);
      final aiText = response.choices.first.message;

      return _parseGroqResponse(aiText);
    } catch (e) {
      // Fallback auf lokale OCR-Erkennung
      return _localFallback(ocrText);
    }
  }

  /// Parst die JSON-Antwort von Groq.
  static List<FridgeScanItem> _parseGroqResponse(String aiText) {
    try {
      // JSON aus Text extrahieren
      var json = aiText.trim();
      if (json.contains('```')) {
        final start = json.indexOf('{');
        final end = json.lastIndexOf('}');
        if (start >= 0 && end > start) {
          json = json.substring(start, end + 1);
        }
      }

      // Manuelle JSON-Verarbeitung ohne dart:convert Abhängigkeit
      final items = <FridgeScanItem>[];

      // Suche nach "name" Feldern im JSON
      final nameRegex = RegExp(r'"name"\s*:\s*"([^"]+)"');
      final categoryRegex = RegExp(r'"category"\s*:\s*"([^"]+)"');
      final quantityRegex = RegExp(r'"quantity"\s*:\s*(?:"([^"]+)"|null)');
      final unitRegex = RegExp(r'"unit"\s*:\s*(?:"([^"]+)"|null)');

      // Suche nach Item-Blöcken
      final itemBlockRegex = RegExp(r'\{[^{}]*"name"[^{}]*\}');
      final blocks = itemBlockRegex.allMatches(json);

      for (final block in blocks) {
        final blockStr = block.group(0) ?? '';
        final nameMatch = nameRegex.firstMatch(blockStr);
        if (nameMatch == null) continue;

        final name = nameMatch.group(1)?.trim() ?? '';
        if (name.isEmpty) continue;

        final categoryMatch = categoryRegex.firstMatch(blockStr);
        final quantityMatch = quantityRegex.firstMatch(blockStr);
        final unitMatch = unitRegex.firstMatch(blockStr);

        items.add(FridgeScanItem(
          name: name,
          category: categoryMatch?.group(1),
          quantity: quantityMatch?.group(1),
          unit: unitMatch?.group(1),
        ));
      }

      return items;
    } catch (_) {
      return [];
    }
  }

  /// Lokaler Fallback: extrahiert Produkte direkt aus OCR-Text ohne KI.
  static List<FridgeScanItem> _localFallback(String ocrText) {
    if (ocrText.isEmpty) return [];

    final items = <FridgeScanItem>[];
    final lines = ocrText.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length < 3) continue;

      // Zeilen die nur Zahlen/Preise sind überspringen
      if (RegExp(r'^[\d\s\.\,€\%\-\+\/\\]+$').hasMatch(trimmed)) continue;

      // Produktname bereinigen
      final cleaned = trimmed
          .replaceAll(RegExp(r'\b\d+[,\.]\d+\b'), '') // Preise entfernen
          .replaceAll(RegExp(r'\b\d+\s*(g|kg|ml|l|cl)\b', caseSensitive: false), '') // Mengen
          .trim();

      if (cleaned.length >= 3) {
        items.add(FridgeScanItem(
          name: cleaned[0].toUpperCase() + cleaned.substring(1),
          isConfident: false,
        ));
      }
    }

    return items.take(20).toList();
  }

  static void dispose() => _textRecognizer.close();
}

