import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/recipes/data/saved_recipe_repository_impl.dart';
import 'package:kokomi/features/recipes/domain/saved_recipe_repository.dart';
import 'package:kokomi/models/recipe.dart';

final savedRecipeRepositoryProvider = Provider<SavedRecipeRepository>((ref) {
  return SavedRecipeRepositoryImpl();
});

class SavedRecipesNotifier extends AsyncNotifier<List<FoodRecipe>> {
  @override
  Future<List<FoodRecipe>> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return [];
    return ref.read(savedRecipeRepositoryProvider).getSavedRecipes(userId);
  }

  Future<void> saveRecipe(FoodRecipe recipe, {String source = 'ai'}) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await ref.read(savedRecipeRepositoryProvider).saveRecipe(userId, recipe, source: source);
    // Reload
    state = AsyncData(
        await ref.read(savedRecipeRepositoryProvider).getSavedRecipes(userId));
  }

  Future<void> deleteRecipe(String id) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await ref.read(savedRecipeRepositoryProvider).deleteRecipe(id);
    state = AsyncData(
        await ref.read(savedRecipeRepositoryProvider).getSavedRecipes(userId));
  }

  Future<bool> isRecipeSaved(String title) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;
    return ref
        .read(savedRecipeRepositoryProvider)
        .isRecipeSaved(userId, title);
  }
}

final savedRecipesProvider =
    AsyncNotifierProvider<SavedRecipesNotifier, List<FoodRecipe>>(
  SavedRecipesNotifier.new,
);
