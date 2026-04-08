import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kokomi/models/recipe.dart';

/// Spoonacular API Service für deutsche Rezepte.
/// Kostenlos: 150 Punkte/Tag (ca. 1 Punkt pro Suchanfrage).
/// API-Key in .env: SPOONACULAR_API_KEY=dein_key
///
/// Ohne Key: gibt leere Liste zurück (graceful degradation).
class SpoonacularService {
  static const _baseUrl = 'https://api.spoonacular.com';

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  String? get _apiKey => dotenv.maybeGet('SPOONACULAR_API_KEY');
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  // ─── Rezepte suchen ───────────────────────────────────────────────────

  /// Rezepte nach Suchbegriff suchen (auf Deutsch).
  Future<List<FoodRecipe>> searchRecipes({
    required String query,
    int number = 10,
    String? diet,         // 'vegetarian', 'vegan', 'glutenFree'
    String? mealType,     // 'main course', 'breakfast', 'dessert'
    int? maxCalories,
    int? maxReadyTime,
  }) async {
    if (!isConfigured) return [];

    try {
      final params = <String, dynamic>{
        'apiKey': _apiKey,
        'query': query,
        'language': 'de',
        'number': number,
        'addRecipeInformation': true,
        'addRecipeNutrition': true,
        'fillIngredients': true,
        'instructionsRequired': true,
      };
      if (diet != null) params['diet'] = diet;
      if (mealType != null) params['type'] = mealType;
      if (maxCalories != null) params['maxCalories'] = maxCalories;
      if (maxReadyTime != null) params['maxReadyTime'] = maxReadyTime;

      final response = await _dio.get('/recipes/complexSearch',
          queryParameters: params);

      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .map((r) => _fromSpoonacularJson(r as Map<String, dynamic>))
          .whereType<FoodRecipe>()
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        // Tageslimit erreicht
        return [];
      }
      rethrow;
    }
  }

  /// Rezepte nach verfügbaren Zutaten suchen.
  Future<List<FoodRecipe>> findByIngredients(List<String> ingredients,
      {int number = 5}) async {
    if (!isConfigured || ingredients.isEmpty) return [];

    try {
      final response = await _dio.get('/recipes/findByIngredients',
          queryParameters: {
            'apiKey': _apiKey,
            'ingredients': ingredients.join(','),
            'number': number,
            'ranking': 1, // Maximiere genutzte Zutaten
            'ignorePantry': true,
          });

      final results = response.data as List<dynamic>? ?? [];
      // Detaildaten laden für jedes Rezept
      final futures = results.take(5).map((r) async {
        final id = r['id'] as int;
        return _getRecipeById(id);
      });
      final recipes = await Future.wait(futures);
      return recipes.whereType<FoodRecipe>().toList();
    } on DioException {
      return [];
    }
  }

  /// Zufällige Rezepte laden.
  Future<List<FoodRecipe>> getRandomRecipes({
    int number = 5,
    List<String> tags = const [],
  }) async {
    if (!isConfigured) return [];

    try {
      final params = <String, dynamic>{
        'apiKey': _apiKey,
        'number': number,
        'language': 'de',
      };
      if (tags.isNotEmpty) params['tags'] = tags.join(',');

      final response =
          await _dio.get('/recipes/random', queryParameters: params);
      final results =
          (response.data['recipes'] as List<dynamic>?) ?? [];
      return results
          .map((r) => _fromSpoonacularJson(r as Map<String, dynamic>))
          .whereType<FoodRecipe>()
          .toList();
    } on DioException {
      return [];
    }
  }

  /// Einzelnes Rezept per ID laden.
  Future<FoodRecipe?> _getRecipeById(int id) async {
    try {
      final response = await _dio.get(
        '/recipes/$id/information',
        queryParameters: {
          'apiKey': _apiKey,
          'includeNutrition': true,
        },
      );
      return _fromSpoonacularJson(
          response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  // ─── JSON-Parsing ──────────────────────────────────────────────────────

  FoodRecipe? _fromSpoonacularJson(Map<String, dynamic> json) {
    try {
      final title = json['title'] as String? ?? 'Unbekanntes Rezept';
      final readyInMinutes = json['readyInMinutes'] as int? ?? 30;
      final servings = json['servings'] as int? ?? 2;
      final summary = _stripHtml(
          (json['summary'] as String?) ?? '');

      // Schwierigkeit aus readyInMinutes ableiten
      final difficulty = readyInMinutes < 20
          ? 'Einfach'
          : readyInMinutes < 45
              ? 'Mittel'
              : 'Schwer';

      // Zutaten
      final extIngredients =
          (json['extendedIngredients'] as List<dynamic>?) ?? [];
      final ingredients = extIngredients.map((ing) {
        final amount = ing['amount'] as num? ?? 0;
        final unit = (ing['unit'] as String?) ?? '';
        final name = (ing['name'] as String?) ?? '';
        final amountStr = amount == amount.truncate()
            ? amount.toInt().toString()
            : amount.toStringAsFixed(1);
        return RecipeIngredient(
          name: name,
          amount: '$amountStr $unit'.trim(),
        );
      }).toList();

      // Schritte
      final analyzedInstructions =
          (json['analyzedInstructions'] as List<dynamic>?) ?? [];
      final List<String> steps = [];
      for (final instruction in analyzedInstructions) {
        final stepsRaw =
            (instruction['steps'] as List<dynamic>?) ?? [];
        for (final step in stepsRaw) {
          final stepText = (step['step'] as String?) ?? '';
          if (stepText.isNotEmpty) steps.add(stepText);
        }
      }

      // Falls keine strukturierten Schritte → aus instructions Text
      if (steps.isEmpty) {
        final instructions = _stripHtml(
            (json['instructions'] as String?) ?? '');
        if (instructions.isNotEmpty) {
          steps.addAll(instructions
              .split(RegExp(r'\.\s+'))
              .where((s) => s.trim().length > 10)
              .map((s) => '${s.trim()}.'));
        }
      }

      if (steps.isEmpty) steps.add('Zubereitung siehe Originalrezept.');

      // Nährwerte
      NutritionInfo? nutrition;
      final nutritionJson =
          json['nutrition'] as Map<String, dynamic>?;
      if (nutritionJson != null) {
        final nutrients =
            (nutritionJson['nutrients'] as List<dynamic>?) ?? [];
        double _get(String name) {
          final n = nutrients.firstWhere(
            (n) => (n['name'] as String?)?.toLowerCase() == name.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );
          return ((n as Map)['amount'] as num?)?.toDouble() ?? 0.0;
        }

        nutrition = NutritionInfo(
          calories: _get('Calories').toInt(),
          protein: _get('Protein'),
          carbs: _get('Carbohydrates'),
          fat: _get('Fat'),
          fiber: _get('Fiber'),
        );
      }

      return FoodRecipe(
        id: (json['id'] as int?)?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: summary.isNotEmpty
            ? (summary.length > 200
                ? '${summary.substring(0, 200)}...'
                : summary)
            : 'Rezept von Spoonacular',
        cookingTimeMinutes: readyInMinutes,
        difficulty: difficulty,
        servings: servings,
        ingredients: ingredients,
        steps: steps,
        nutrition: nutrition,
      );
    } catch (_) {
      return null;
    }
  }

  /// HTML-Tags aus Text entfernen.
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'")
        .trim();
  }
}

