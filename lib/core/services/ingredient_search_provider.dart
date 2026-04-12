import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/core/services/nutrition_service.dart';

/// Globaler NutritionService – Singleton über die gesamte App-Laufzeit.
final nutritionServiceProvider = Provider<NutritionService>((ref) {
  return NutritionService();
});

/// Prüft ob alle übergebenen Zutaten Nährwerte haben.
final allIngredientsHaveNutritionProvider =
    Provider.family<bool, List<String>>((ref, ingredientNames) {
  final service = ref.watch(nutritionServiceProvider);
  return service.allHaveNutrition(ingredientNames);
});

/// Gibt die Zutaten zurück die KEINE Nährwerte haben.
final missingNutritionProvider =
    Provider.family<List<String>, List<String>>((ref, ingredientNames) {
  final service = ref.watch(nutritionServiceProvider);
  return service.getMissingNutrition(ingredientNames);
});

