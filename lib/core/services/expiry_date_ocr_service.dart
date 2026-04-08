import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Service zum Erkennen von Mindesthaltbarkeitsdaten per Kamera (OCR).
class ExpiryDateOcrService {
  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  static final _picker = ImagePicker();

  /// Öffnet die Kamera, führt OCR durch und gibt das erkannte Datum zurück.
  /// Gibt null zurück wenn kein Datum erkannt wurde oder der User abbricht.
  static Future<DateTime?> scanExpiryDate() async {
    // Kamera-Foto aufnehmen
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (photo == null) return null;

    return _extractDateFromImage(File(photo.path));
  }

  /// Aus einer Datei ein Datum extrahieren (auch für Tests nutzbar).
  static Future<DateTime?> _extractDateFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);
    final fullText = recognizedText.text;

    return _parseDate(fullText);
  }

  /// Versucht ein Datum aus dem erkannten Text zu parsen.
  /// Unterstützte Formate:
  /// - DD.MM.YYYY, DD/MM/YYYY, DD-MM-YYYY
  /// - MM/YYYY, MM.YYYY
  /// - YYYY-MM-DD (ISO)
  /// - "MHD ...", "BBD ...", "best before ...", "exp ...", "use by ..."
  static DateTime? _parseDate(String text) {
    // Text normalisieren
    final normalized = text.replaceAll('\n', ' ').toUpperCase();

    // Pattern 1: DD.MM.YYYY oder DD/MM/YYYY oder DD-MM-YYYY
    final ddmmyyyy = RegExp(
      r'\b(\d{1,2})[.\/\-](\d{1,2})[.\/\-](\d{4})\b',
    );
    final match1 = ddmmyyyy.firstMatch(normalized);
    if (match1 != null) {
      final day = int.tryParse(match1.group(1)!);
      final month = int.tryParse(match1.group(2)!);
      final year = int.tryParse(match1.group(3)!);
      if (day != null && month != null && year != null &&
          day >= 1 && day <= 31 && month >= 1 && month <= 12 &&
          year >= DateTime.now().year) {
        return DateTime(year, month, day);
      }
    }

    // Pattern 2: YYYY-MM-DD (ISO)
    final iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
    final match2 = iso.firstMatch(normalized);
    if (match2 != null) {
      final year = int.tryParse(match2.group(1)!);
      final month = int.tryParse(match2.group(2)!);
      final day = int.tryParse(match2.group(3)!);
      if (year != null && month != null && day != null &&
          year >= DateTime.now().year) {
        return DateTime(year, month, day);
      }
    }

    // Pattern 3: MM/YYYY oder MM.YYYY (nur Monat/Jahr)
    final mmyyyy = RegExp(r'\b(\d{1,2})[.\/](\d{4})\b');
    final match3 = mmyyyy.firstMatch(normalized);
    if (match3 != null) {
      final month = int.tryParse(match3.group(1)!);
      final year = int.tryParse(match3.group(2)!);
      if (month != null && year != null &&
          month >= 1 && month <= 12 &&
          year >= DateTime.now().year) {
        // Ende des Monats als Ablaufdatum
        final lastDay = DateTime(year, month + 1, 0).day;
        return DateTime(year, month, lastDay);
      }
    }

    // Pattern 4: DD.MM.YY (zweistellige Jahreszahl)
    final ddmmyy = RegExp(r'\b(\d{1,2})[.\/\-](\d{1,2})[.\/\-](\d{2})\b');
    final match4 = ddmmyy.firstMatch(normalized);
    if (match4 != null) {
      final day = int.tryParse(match4.group(1)!);
      final month = int.tryParse(match4.group(2)!);
      final yearShort = int.tryParse(match4.group(3)!);
      if (day != null && month != null && yearShort != null &&
          day >= 1 && day <= 31 && month >= 1 && month <= 12) {
        final year = 2000 + yearShort;
        if (year >= DateTime.now().year) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  /// Schließt den Recognizer frei.
  static void dispose() => _recognizer.close();
}

