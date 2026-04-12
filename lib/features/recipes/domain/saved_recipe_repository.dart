import 'package:kokomu/models/recipe.dart';

abstract class SavedRecipeRepository {
  Future<List<FoodRecipe>> getSavedRecipes(String userId);
  Future<String?> saveRecipe(String userId, FoodRecipe recipe, {String source = 'ai'});
  Future<void> deleteRecipe(String id);
  Future<bool> isRecipeSaved(String userId, String title);
}


