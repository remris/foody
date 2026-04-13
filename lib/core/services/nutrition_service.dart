import 'package:kokomu/core/data/ingredient_catalog.dart';
import 'package:kokomu/core/data/nutrient_data.dart';

/// Nährwert-Datensatz pro 100g.
class NutritionInfo {
  final double kcalPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;
  final NutritionSource source;

  const NutritionInfo({
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    required this.source,
  });

  /// Berechnet Nährwerte für eine bestimmte Menge in Gramm.
  ({double kcal, double protein, double fat, double carbs}) forGrams(double grams) {
    final factor = grams / 100.0;
    return (
      kcal: kcalPer100g * factor,
      protein: proteinPer100g * factor,
      fat: fatPer100g * factor,
      carbs: carbsPer100g * factor,
    );
  }

  @override
  String toString() =>
      'NutritionInfo(kcal: $kcalPer100g, protein: $proteinPer100g, fat: $fatPer100g, carbs: $carbsPer100g, source: $source)';
}

/// Woher die Nährwerte stammen.
enum NutritionSource {
  /// Gescannt über OpenFoodFacts (höchste Priorität)
  scanned,

  /// Aus dem hardcoded Ingredient-Katalog
  catalog,

  /// Manuell vom Nutzer eingegeben
  manual,

  /// Geschätzte Durchschnittswerte basierend auf der Kategorie
  estimated,

  /// Keine Nährwerte verfügbar
  unknown,
}

/// Nährwert für eine einzelne Rezept-Zutat.
class RecipeIngredientNutrition {
  final String ingredientName;
  final double amountGrams;
  final NutritionInfo? nutritionPer100g;
  final ({double kcal, double protein, double fat, double carbs})? totalNutrition;

  const RecipeIngredientNutrition({
    required this.ingredientName,
    required this.amountGrams,
    this.nutritionPer100g,
    this.totalNutrition,
  });

  bool get hasNutrition => nutritionPer100g != null;
}

/// Durchschnittliche Nährwerte pro Kategorie als letzter Fallback.
/// Diese werden nur verwendet wenn weder gescannte, manuelle noch
/// Katalog-Nährwerte vorhanden sind.
const Map<String, NutritionInfo> _categoryFallbackNutrition = {
  'Obst & Gemüse': NutritionInfo(kcalPer100g: 40, proteinPer100g: 1.5, fatPer100g: 0.3, carbsPer100g: 7.0, source: NutritionSource.estimated),
  'Fleisch & Fisch': NutritionInfo(kcalPer100g: 150, proteinPer100g: 20.0, fatPer100g: 7.0, carbsPer100g: 0, source: NutritionSource.estimated),
  'Milchprodukte': NutritionInfo(kcalPer100g: 200, proteinPer100g: 12.0, fatPer100g: 15.0, carbsPer100g: 4.0, source: NutritionSource.estimated),
  'Nudeln & Getreide': NutritionInfo(kcalPer100g: 355, proteinPer100g: 10.0, fatPer100g: 1.5, carbsPer100g: 73.0, source: NutritionSource.estimated),
  'Brot & Backwaren': NutritionInfo(kcalPer100g: 270, proteinPer100g: 8.5, fatPer100g: 3.0, carbsPer100g: 50.0, source: NutritionSource.estimated),
  'Backen': NutritionInfo(kcalPer100g: 360, proteinPer100g: 8.0, fatPer100g: 5.0, carbsPer100g: 70.0, source: NutritionSource.estimated),
  'Öle & Essig': NutritionInfo(kcalPer100g: 400, proteinPer100g: 0.5, fatPer100g: 45.0, carbsPer100g: 5.0, source: NutritionSource.estimated),
  'Konserven': NutritionInfo(kcalPer100g: 60, proteinPer100g: 3.0, fatPer100g: 0.5, carbsPer100g: 10.0, source: NutritionSource.estimated),
  'Gewürze & Soßen': NutritionInfo(kcalPer100g: 280, proteinPer100g: 10.0, fatPer100g: 10.0, carbsPer100g: 30.0, source: NutritionSource.estimated),
  'Nüsse & Samen': NutritionInfo(kcalPer100g: 580, proteinPer100g: 18.0, fatPer100g: 50.0, carbsPer100g: 12.0, source: NutritionSource.estimated),
  'Süßes & Aufstriche': NutritionInfo(kcalPer100g: 300, proteinPer100g: 1.0, fatPer100g: 5.0, carbsPer100g: 65.0, source: NutritionSource.estimated),
  'Getränke': NutritionInfo(kcalPer100g: 40, proteinPer100g: 0.2, fatPer100g: 0, carbsPer100g: 9.0, source: NutritionSource.estimated),
  'Frühstück': NutritionInfo(kcalPer100g: 380, proteinPer100g: 10.0, fatPer100g: 8.0, carbsPer100g: 62.0, source: NutritionSource.estimated),
  'Vorrat': NutritionInfo(kcalPer100g: 340, proteinPer100g: 20.0, fatPer100g: 2.0, carbsPer100g: 58.0, source: NutritionSource.estimated),
  'Asiatisch': NutritionInfo(kcalPer100g: 150, proteinPer100g: 4.0, fatPer100g: 3.0, carbsPer100g: 25.0, source: NutritionSource.estimated),
  'Mediterran': NutritionInfo(kcalPer100g: 180, proteinPer100g: 5.0, fatPer100g: 12.0, carbsPer100g: 12.0, source: NutritionSource.estimated),
  'Mexikanisch': NutritionInfo(kcalPer100g: 120, proteinPer100g: 4.0, fatPer100g: 4.0, carbsPer100g: 16.0, source: NutritionSource.estimated),
  'Fertigprodukte': NutritionInfo(kcalPer100g: 150, proteinPer100g: 6.0, fatPer100g: 6.0, carbsPer100g: 18.0, source: NutritionSource.estimated),
  'Wurst & Aufschnitt': NutritionInfo(kcalPer100g: 300, proteinPer100g: 16.0, fatPer100g: 25.0, carbsPer100g: 1.0, source: NutritionSource.estimated),
  'Tiefkühl': NutritionInfo(kcalPer100g: 100, proteinPer100g: 5.0, fatPer100g: 3.0, carbsPer100g: 12.0, source: NutritionSource.estimated),
  'Süßwaren & Snacks': NutritionInfo(kcalPer100g: 440, proteinPer100g: 5.0, fatPer100g: 18.0, carbsPer100g: 65.0, source: NutritionSource.estimated),
  'Pflanzliche Proteine': NutritionInfo(kcalPer100g: 180, proteinPer100g: 18.0, fatPer100g: 8.0, carbsPer100g: 8.0, source: NutritionSource.estimated),
  'Gesundheit': NutritionInfo(kcalPer100g: 250, proteinPer100g: 10.0, fatPer100g: 3.0, carbsPer100g: 40.0, source: NutritionSource.estimated),
  'Glutenfrei': NutritionInfo(kcalPer100g: 340, proteinPer100g: 6.0, fatPer100g: 3.0, carbsPer100g: 70.0, source: NutritionSource.estimated),
  'Fermentiert': NutritionInfo(kcalPer100g: 80, proteinPer100g: 5.0, fatPer100g: 2.0, carbsPer100g: 8.0, source: NutritionSource.estimated),
  'Alkohol': NutritionInfo(kcalPer100g: 85, proteinPer100g: 0.1, fatPer100g: 0, carbsPer100g: 3.0, source: NutritionSource.estimated),
  'Sport & Fitness': NutritionInfo(kcalPer100g: 350, proteinPer100g: 40.0, fatPer100g: 5.0, carbsPer100g: 30.0, source: NutritionSource.estimated),
};

/// Zentraler Service zum Auflösen von Nährwertdaten.
///
/// Priorität:
/// 1. Gescannte Daten (OpenFoodFacts via Inventar)
/// 2. Katalog-Daten (hardcoded im IngredientCatalog)
/// 3. Null (fehlend → UI zeigt Warnung)
class NutritionService {
  /// Cache für gescannte Nährwerte (z.B. aus OpenFoodFacts).
  /// Key = ingredient name (lowercase), Value = NutritionInfo
  final Map<String, NutritionInfo> _scannedNutrition = {};

  /// Cache für manuell eingegebene Nährwerte.
  final Map<String, NutritionInfo> _manualNutrition = {};

  /// Registriert Nährwerte aus einem gescannten Produkt (OpenFoodFacts).
  void registerScannedNutrition({
    required String ingredientName,
    required double kcalPer100g,
    required double proteinPer100g,
    required double fatPer100g,
    required double carbsPer100g,
  }) {
    _scannedNutrition[ingredientName.toLowerCase().trim()] = NutritionInfo(
      kcalPer100g: kcalPer100g,
      proteinPer100g: proteinPer100g,
      fatPer100g: fatPer100g,
      carbsPer100g: carbsPer100g,
      source: NutritionSource.scanned,
    );
  }

  /// Registriert manuell eingegebene Nährwerte.
  void registerManualNutrition({
    required String ingredientName,
    required double kcalPer100g,
    required double proteinPer100g,
    required double fatPer100g,
    required double carbsPer100g,
  }) {
    _manualNutrition[ingredientName.toLowerCase().trim()] = NutritionInfo(
      kcalPer100g: kcalPer100g,
      proteinPer100g: proteinPer100g,
      fatPer100g: fatPer100g,
      carbsPer100g: carbsPer100g,
      source: NutritionSource.manual,
    );
  }

  /// Holt Nährwerte für eine Zutat.
  /// Priorität: gescannt → manuell → Katalog (explizit) → Katalog (Kategorie-Fallback) → null
  NutritionInfo? getNutrition(String ingredientName) {
    final key = ingredientName.toLowerCase().trim();

    // 1. Gescannte Daten (höchste Priorität)
    if (_scannedNutrition.containsKey(key)) {
      return _scannedNutrition[key];
    }

    // 2. Manuell eingegebene Daten
    if (_manualNutrition.containsKey(key)) {
      return _manualNutrition[key];
    }

    // 3. Katalog-Fallback (Nährwerte aus nutrient_data.dart)
    final catalogEntry = IngredientCatalog.findByName(ingredientName);
    if (catalogEntry != null) {
      final catalogNutrients = getNutrientsForCatalogEntry(catalogEntry);
      if (catalogNutrients != null && catalogNutrients.hasData) {
        return NutritionInfo(
          kcalPer100g: catalogNutrients.kcalPer100g ?? 0,
          proteinPer100g: catalogNutrients.proteinPer100g ?? 0,
          fatPer100g: catalogNutrients.fatPer100g ?? 0,
          carbsPer100g: catalogNutrients.carbsPer100g ?? 0,
          source: NutritionSource.catalog,
        );
      }
    }

    // 4. Kategorie-Fallback (geschätzte Durchschnittswerte)
    if (catalogEntry != null) {
      final fallback = _categoryFallbackNutrition[catalogEntry.category];
      if (fallback != null) {
        return fallback;
      }
    }

    return null;
  }

  /// Berechnet die Gesamt-Nährwerte für eine Liste von Rezept-Zutaten.
  /// Gibt null zurück wenn EINE Zutat keine Nährwerte hat.
  ({
    double totalKcal,
    double totalProtein,
    double totalFat,
    double totalCarbs,
    List<RecipeIngredientNutrition> perIngredient,
    bool isComplete,
    List<String> missingIngredients,
  }) calculateRecipeNutrition(List<({String name, double amountGrams})> ingredients) {
    double totalKcal = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCarbs = 0;
    bool isComplete = true;
    final List<String> missing = [];
    final List<RecipeIngredientNutrition> perIngredient = [];

    for (final ingredient in ingredients) {
      final nutrition = getNutrition(ingredient.name);
      if (nutrition != null) {
        final totals = nutrition.forGrams(ingredient.amountGrams);
        totalKcal += totals.kcal;
        totalProtein += totals.protein;
        totalFat += totals.fat;
        totalCarbs += totals.carbs;
        perIngredient.add(RecipeIngredientNutrition(
          ingredientName: ingredient.name,
          amountGrams: ingredient.amountGrams,
          nutritionPer100g: nutrition,
          totalNutrition: totals,
        ));
      } else {
        isComplete = false;
        missing.add(ingredient.name);
        perIngredient.add(RecipeIngredientNutrition(
          ingredientName: ingredient.name,
          amountGrams: ingredient.amountGrams,
        ));
      }
    }

    return (
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalFat: totalFat,
      totalCarbs: totalCarbs,
      perIngredient: perIngredient,
      isComplete: isComplete,
      missingIngredients: missing,
    );
  }

  /// Gibt die Quelle der Nährwerte für eine Zutat zurück.
  NutritionSource getSource(String ingredientName) {
    return getNutrition(ingredientName)?.source ?? NutritionSource.unknown;
  }

  /// Prüft ob ALLE übergebenen Zutaten Nährwerte haben.
  bool allHaveNutrition(List<String> ingredientNames) {
    return ingredientNames.every((name) => getNutrition(name) != null);
  }

  /// Gibt die Namen der Zutaten zurück, die KEINE Nährwerte haben.
  List<String> getMissingNutrition(List<String> ingredientNames) {
    return ingredientNames.where((name) => getNutrition(name) == null).toList();
  }
}
