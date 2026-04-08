import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Service zum Erkennen von Einkaufslisten aus Fotos (handgeschrieben oder gedruckt).
/// Nutzt ML Kit Text Recognition.
class ShoppingListOcrService {
  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  static final _picker = ImagePicker();

  /// Öffnet die Kamera oder Galerie, führt OCR durch und gibt erkannte Artikel zurück.
  static Future<List<String>> scanShoppingList({
    ImageSource source = ImageSource.camera,
  }) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (photo == null) return [];

    final inputImage = InputImage.fromFile(File(photo.path));
    final recognizedText = await _recognizer.processImage(inputImage);

    return _parseItems(recognizedText);
  }

  /// Parst den erkannten Text in einzelne Einkaufsartikel.
  static List<String> _parseItems(RecognizedText recognizedText) {
    final items = <String>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        // Bereinigung: typische Nicht-Artikel-Zeilen filtern
        final cleaned = _cleanLine(text);
        if (cleaned != null && cleaned.length >= 2) {
          items.add(cleaned);
        }
      }
    }

    return items;
  }

  /// Bereinigt eine OCR-Zeile und gibt null zurück wenn sie kein Artikel ist.
  static String? _cleanLine(String raw) {
    var line = raw.trim();

    // Zeilen die nur Zahlen/Sonderzeichen sind → ignorieren
    if (RegExp(r'^[\d\s\-\.\,\:\;\!\?\#\*\+\/]+$').hasMatch(line)) {
      return null;
    }

    // Überschriften wie "Einkaufsliste", "Shopping List" etc. ignorieren
    final lower = line.toLowerCase();
    const ignore = [
      'einkaufsliste', 'shopping list', 'einkauf', 'liste',
      'datum', 'date', 'summe', 'total', 'gesamt', 'mwst',
    ];
    if (ignore.any((w) => lower == w)) return null;

    // Führende Aufzählungszeichen entfernen: -, •, *, 1., 2. etc.
    line = line.replaceFirst(RegExp(r'^[\-\•\*\○\●\→\>\□\☐\☑\✓]\s*'), '');
    line = line.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');

    // Mengenangaben am Ende entfernen (z.B. "Milch 2L", "Butter 250g")
    // Wir behalten nur den Artikel-Namen
    line = line.replaceAll(RegExp(r'\s+\d+\s*(g|kg|ml|l|stk|stück|pck|pkg|pack)\s*$', caseSensitive: false), '');

    // Zu kurze Zeilen (< 2 Zeichen) ignorieren
    line = line.trim();
    if (line.length < 2) return null;

    // Ersten Buchstaben groß
    return line[0].toUpperCase() + line.substring(1);
  }

  static void dispose() => _recognizer.close();
}

