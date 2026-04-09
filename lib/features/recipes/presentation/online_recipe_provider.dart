import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/core/services/online_recipe_service.dart';
import 'package:kokomu/models/recipe.dart';

final onlineRecipeServiceProvider = Provider<OnlineRecipeService>((ref) {
  return OnlineRecipeService();
});

class OnlineRecipeNotifier extends AsyncNotifier<List<FoodRecipe>> {
  @override
  Future<List<FoodRecipe>> build() async => [];

  /// Rezepte übersetzen (parallel, max 5 gleichzeitig).
  Future<List<FoodRecipe>> _translateAll(List<FoodRecipe> recipes) async {
    final service = ref.read(onlineRecipeServiceProvider);
    try {
      final futures = recipes.map((r) => service.translateRecipe(r));
      return await Future.wait(futures);
    } catch (_) {
      return recipes; // Fallback auf Original
    }
  }

  /// Nach Rezeptname suchen.
  Future<void> searchByName(String query) async {
    if (query.trim().isEmpty) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results =
          await ref.read(onlineRecipeServiceProvider).searchByName(query);
      return _translateAll(results);
    });
  }

  /// Nach Zutat suchen.
  Future<void> searchByIngredient(String ingredient) async {
    if (ingredient.trim().isEmpty) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results = await ref
          .read(onlineRecipeServiceProvider)
          .searchByIngredient(ingredient);
      return _translateAll(results);
    });
  }

  /// Zufällige Rezepte laden.
  Future<void> loadRandom() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results =
          await ref.read(onlineRecipeServiceProvider).getRandomRecipes();
      return _translateAll(results);
    });
  }

  /// Nach Kategorie suchen.
  Future<void> searchByCategory(String category) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results = await ref
          .read(onlineRecipeServiceProvider)
          .searchByCategory(category);
      return _translateAll(results);
    });
  }

  void clear() {
    state = const AsyncData([]);
  }
}

final onlineRecipeProvider =
    AsyncNotifierProvider<OnlineRecipeNotifier, List<FoodRecipe>>(
  OnlineRecipeNotifier.new,
);

