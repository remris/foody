import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kokomu/models/recipe.dart';
import 'package:kokomu/features/meal_plan/presentation/meal_plan_provider.dart';

/// Service zum Generieren und Teilen von PDFs für Rezepte und Wochenpläne.
class PdfExportService {
  // ─── Rezept als PDF ───────────────────────────────────────────────────────

  /// Generiert ein PDF für ein einzelnes Rezept.
  static Future<Uint8List> generateRecipePdf(FoodRecipe recipe,
      {int servings = 0}) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final displayServings = servings > 0 ? servings : recipe.servings;

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              recipe.title,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 22,
                color: PdfColor.fromHex('#4CAF50'),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'kokomu – Dein digitales Kochbuch',
              style: pw.TextStyle(
                  fontSize: 10, color: PdfColor.fromHex('#888888')),
            ),
            pw.Divider(color: PdfColor.fromHex('#E0E0E0')),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          // Meta-Infos
          pw.Wrap(
            spacing: 16,
            children: [
              _metaChip('⏱', '${recipe.cookingTimeMinutes} Min.', font),
              _metaChip('👥', '$displayServings Portionen', font),
              _metaChip('📊', recipe.difficulty, font),
            ],
          ),
          pw.SizedBox(height: 10),

          // Beschreibung
          if (recipe.description.isNotEmpty) ...[
            pw.Text(recipe.description,
                style: pw.TextStyle(
                    fontSize: 11, color: PdfColor.fromHex('#555555'))),
            pw.SizedBox(height: 16),
          ],

          // Nährwerte
          if (recipe.nutrition != null) ...[
            pw.Text('Nährwerte pro Portion',
                style: pw.TextStyle(font: fontBold, fontSize: 14)),
            pw.SizedBox(height: 6),
            _nutritionRow(recipe.nutrition!, font, fontBold),
            pw.SizedBox(height: 16),
          ],

          // Zutaten
          pw.Text('Zutaten',
              style: pw.TextStyle(font: fontBold, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: recipe.ingredients.map((ing) {
              return pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Text(ing.name,
                      style: pw.TextStyle(font: font, fontSize: 11)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Text(ing.amount,
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          color: PdfColor.fromHex('#4CAF50'))),
                ),
              ]);
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          // Zubereitung
          pw.Text('Zubereitung',
              style: pw.TextStyle(font: fontBold, fontSize: 16)),
          pw.SizedBox(height: 8),
          ...recipe.steps.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#4CAF50'),
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${e.key + 1}',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: PdfColors.white),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(e.value,
                          style: pw.TextStyle(font: font, fontSize: 11)),
                    ),
                  ],
                ),
              )),

          // Footer
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColor.fromHex('#E0E0E0')),
          pw.Text(
            'Erstellt mit kokomu · ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
            style: pw.TextStyle(
                fontSize: 9, color: PdfColor.fromHex('#AAAAAA')),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ─── Wochenplan als PDF ────────────────────────────────────────────────────

  /// Generiert ein PDF für einen ganzen Wochenplan.
  static Future<Uint8List> generateMealPlanPdf(
      List<MealPlanEntry> entries) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    const days = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
        'Freitag', 'Samstag', 'Sonntag'];

    // Einträge nach Tag gruppieren
    final byDay = <int, List<MealPlanEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(e.dayIndex, () => []).add(e);
    }

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Wochenplan',
                style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 22,
                    color: PdfColor.fromHex('#4CAF50'))),
            pw.Text(
              'kokomu – ${_weekDateRange()}',
              style: pw.TextStyle(
                  fontSize: 10, color: PdfColor.fromHex('#888888')),
            ),
            pw.Divider(color: PdfColor.fromHex('#E0E0E0')),
          ],
        ),
        build: (ctx) => List.generate(7, (dayIndex) {
          final dayEntries = byDay[dayIndex] ?? [];
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E8F5E9'),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(days[dayIndex],
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 13,
                          color: PdfColor.fromHex('#2E7D32'))),
                ),
                pw.SizedBox(height: 6),
                if (dayEntries.isEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 10),
                    child: pw.Text('Keine Mahlzeiten geplant',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColor.fromHex('#AAAAAA'))),
                  )
                else
                  ...dayEntries.map((entry) => pw.Padding(
                        padding: const pw.EdgeInsets.only(
                            left: 10, bottom: 4),
                        child: pw.Row(children: [
                          pw.Container(
                            width: 70,
                            child: pw.Text(
                              '${entry.slot.emoji} ${entry.slot.label}',
                              style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColor.fromHex('#555555')),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Text(entry.recipe.title,
                                style: pw.TextStyle(
                                    font: font, fontSize: 11)),
                          ),
                          pw.Text(
                            '${entry.recipe.cookingTimeMinutes} Min.',
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 9,
                                color: PdfColor.fromHex('#888888')),
                          ),
                        ]),
                      )),
              ],
            ),
          );
        }),
      ),
    );

    return doc.save();
  }

  // ─── Teilen / Drucken ─────────────────────────────────────────────────────

  /// PDF in der System-Druckvorschau anzeigen (auch Teilen möglich).
  static Future<void> sharePdf(Uint8List bytes, String fileName) async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// PDF direkt drucken.
  static Future<void> printPdf(Uint8List bytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: title,
    );
  }

  // ─── Hilfsmethoden ────────────────────────────────────────────────────────

  static pw.Widget _metaChip(String emoji, String label, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text('$emoji  $label',
          style: pw.TextStyle(font: font, fontSize: 10)),
    );
  }

  static pw.Widget _nutritionRow(
      NutritionInfo n, pw.Font font, pw.Font bold) {
    final items = [
      ('🔥', '${n.calories} kcal', 'Kalorien'),
      ('🥩', '${n.protein.toStringAsFixed(1)}g', 'Eiweiß'),
      ('🌾', '${n.carbs.toStringAsFixed(1)}g', 'Kohlenhydrate'),
      ('🧈', '${n.fat.toStringAsFixed(1)}g', 'Fett'),
    ];
    return pw.Wrap(
      spacing: 12,
      children: items.map((item) {
        return pw.Column(
          children: [
            pw.Text('${item.$1} ${item.$2}',
                style: pw.TextStyle(font: bold, fontSize: 11)),
            pw.Text(item.$3,
                style: pw.TextStyle(
                    font: font,
                    fontSize: 9,
                    color: PdfColor.fromHex('#888888'))),
          ],
        );
      }).toList(),
    );
  }

  static String _weekDateRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return '${monday.day}.${monday.month}. – ${sunday.day}.${sunday.month}.${sunday.year}';
  }
}

