import 'dart:convert';
import 'dart:io';
import 'package:kokomi/core/services/groq_proxy_service.dart';
import 'package:kokomi/core/services/local_recipe_service.dart';
import 'package:kokomi/core/services/recipe_cache_service.dart';
import 'package:kokomi/features/recipes/domain/recipe_repository.dart';
import 'package:kokomi/models/recipe.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final _groqService = GroqProxyService();
  final _localService = LocalRecipeService();

  /// Nur Netzwerkfehler → Offline-Fallback
  bool _isNetworkError(Object e) =>
      e is SocketException ||
      e is HttpException ||
      e.toString().contains('SocketException') ||
      e.toString().contains('TimeoutException');

  @override
  Future<List<FoodRecipe>> getSuggestedRecipes(
    List<String> ingredients, {
    bool forceRefresh = false,
    List<String> excludeAllergens = const [],
  }) async {
    RecipeCacheService.trackQuery(ingredients);
    final key = RecipeCacheService.buildKey(ingredients);

    if (!forceRefresh) {
      final cached = await RecipeCacheService.get(key);
      if (cached != null) return cached;
    }

    try {
      final raw = await _groqService.generateRecipes(
        ingredients,
        excludeAllergens: excludeAllergens,
      );
      final recipes = _parseRecipes(raw);
      await RecipeCacheService.set(key, recipes);
      return recipes;
    } catch (e) {
      if (_isNetworkError(e)) return _localService.generateFromIngredients(ingredients);
      rethrow;
    }
  }

  @override
  Future<List<FoodRecipe>> getRecipesFromPrompt(
    String prompt, {
    bool forceRefresh = false,
    List<String> excludeAllergens = const [],
  }) async {
    final key = RecipeCacheService.buildPromptKey(prompt);

    if (!forceRefresh) {
      final cached = await RecipeCacheService.get(key);
      if (cached != null) return cached;
    }

    try {
      final raw = await _groqService.generateRecipesFromPrompt(
        prompt,
        excludeAllergens: excludeAllergens,
      );
      final recipes = _parseRecipes(raw);
      await RecipeCacheService.set(key, recipes);
      return recipes;
    } catch (e) {
      if (_isNetworkError(e)) return _localService.generateFromPrompt(prompt);
      rethrow;
    }
  }

  @override
  Future<List<FoodRecipe>> getRecipesFromSelection(
    List<String> selectedIngredients, {
    String? additionalPrompt,
    bool forceRefresh = false,
    List<String> excludeAllergens = const [],
  }) async {
    RecipeCacheService.trackQuery(selectedIngredients);
    final key = RecipeCacheService.buildKey(selectedIngredients,
        promptExtra: additionalPrompt);

    if (!forceRefresh) {
      final cached = await RecipeCacheService.get(key);
      if (cached != null) return cached;
    }

    try {
      final raw = await _groqService.generateRecipesFromSelection(
        selectedIngredients,
        additionalPrompt: additionalPrompt,
        excludeAllergens: excludeAllergens,
      );
      final recipes = _parseRecipes(raw);
      await RecipeCacheService.set(key, recipes);
      return recipes;
    } catch (e) {
      if (_isNetworkError(e)) return _localService.generateFromIngredients(selectedIngredients);
      rethrow;
    }
  }

  List<FoodRecipe> _parseRecipes(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final list = json['recipes'] as List<dynamic>;
    final recipes =
        list.map((e) => FoodRecipe.fromJson(e as Map<String, dynamic>)).toList();
    GroqProxyService.rememberTitles(recipes.map((r) => r.title).toList());
    return recipes;
  }
}
