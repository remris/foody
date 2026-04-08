import 'package:kokomi/core/constants/app_constants.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/features/recipes/domain/saved_recipe_repository.dart';
import 'package:kokomi/models/recipe.dart';

class SavedRecipeRepositoryImpl implements SavedRecipeRepository {
  final _client = SupabaseService.client;

  @override
  Future<List<FoodRecipe>> getSavedRecipes(String userId) async {
    final data = await _client
        .from(AppConstants.tableSavedRecipes)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) {
      final json = Map<String, dynamic>.from(e['recipe_json'] as Map<String, dynamic>);
      // source und DB-Row-ID aus der DB-Zeile übernehmen (überschreibt ggf. alten JSON-Wert)
      final dbSource = e['source'] as String?;
      // 'manual' ist ein Legacy-Wert → normalisieren zu 'own'
      json['source'] = (dbSource == 'manual') ? 'own' : (dbSource ?? 'ai');
      json['savedRecipeId'] = e['id']?.toString();
      return FoodRecipe.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveRecipe(String userId, FoodRecipe recipe, {String source = 'ai'}) async {
    await _client.from(AppConstants.tableSavedRecipes).insert({
      'user_id': userId,
      'title': recipe.title,
      'recipe_json': recipe.copyWith(source: source).toJson(),
      'source': source,
      // Denormalisierte Felder für Index-Nutzung
      'cooking_time_minutes': recipe.cookingTimeMinutes,
      'difficulty': recipe.difficulty,
      'calories': recipe.nutrition?.calories,
      'tags': _extractTags(recipe),
    });
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await _client
        .from(AppConstants.tableSavedRecipes)
        .delete()
        .eq('id', id);
  }

  @override
  Future<bool> isRecipeSaved(String userId, String title) async {
    final data = await _client
        .from(AppConstants.tableSavedRecipes)
        .select('id')
        .eq('user_id', userId)
        .eq('title', title)
        .maybeSingle();
    return data != null;
  }

  /// Extrahiert Tags aus einem Rezept für schnelle Filter.
  List<String> _extractTags(FoodRecipe recipe) {
    final tags = <String>[];
    // Difficulty
    tags.add(recipe.difficulty.toLowerCase());
    // Zeit-Klassen
    if (recipe.cookingTimeMinutes <= 20) tags.add('schnell');
    if (recipe.cookingTimeMinutes <= 45) tags.add('mittel');
    if (recipe.cookingTimeMinutes > 45) tags.add('aufwändig');
    // Kalorien-Klassen
    final cal = recipe.nutrition?.calories ?? 0;
    if (cal > 0 && cal < 400) tags.add('kalorienarm');
    if (cal >= 400 && cal < 700) tags.add('ausgewogen');
    if (cal >= 700) tags.add('kalorienreich');
    // Protein-Klassen
    final protein = recipe.nutrition?.protein ?? 0;
    if (protein >= 30) tags.add('high-protein');
    return tags;
  }
}
