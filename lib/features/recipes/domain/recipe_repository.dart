import 'package:kokomu/models/recipe.dart';

abstract class RecipeRepository {
  Future<List<FoodRecipe>> getSuggestedRecipes(
    List<String> ingredients, {
    bool forceRefresh = false,
    List<String> excludeAllergens = const [],
  });
  Future<List<FoodRecipe>> getRecipesFromPrompt(
    String prompt, {
    bool forceRefresh = false,
    List<String> excludeAllergens = const [],
  });
  Future<List<FoodRecipe>> getRecipesFromSelection(
    List<String> selectedIngredients, {
    String? additionalPrompt,
    bool forceRefresh = false,
    List<String> excludeAllergens = const [],
  });
}
