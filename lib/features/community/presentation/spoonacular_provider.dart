import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/core/services/spoonacular_service.dart';
import 'package:kokomi/models/recipe.dart';

final spoonacularServiceProvider = Provider<SpoonacularService>((ref) {
  return SpoonacularService();
});

// ─── State ────────────────────────────────────────────────────────────────

class SpoonacularState {
  final List<FoodRecipe> recipes;
  final bool isLoading;
  final String? error;
  final String? activeQuery;
  final String? activeDiet;

  const SpoonacularState({
    this.recipes = const [],
    this.isLoading = false,
    this.error,
    this.activeQuery,
    this.activeDiet,
  });

  SpoonacularState copyWith({
    List<FoodRecipe>? recipes,
    bool? isLoading,
    String? error,
    String? activeQuery,
    String? activeDiet,
  }) =>
      SpoonacularState(
        recipes: recipes ?? this.recipes,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        activeQuery: activeQuery ?? this.activeQuery,
        activeDiet: activeDiet ?? this.activeDiet,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────

class SpoonacularNotifier extends AutoDisposeNotifier<SpoonacularState> {
  @override
  SpoonacularState build() => const SpoonacularState();

  /// Zufällige deutsche Rezepte beim ersten Laden
  Future<void> loadRandom({List<String> tags = const []}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final recipes = await ref
          .read(spoonacularServiceProvider)
          .getRandomRecipes(number: 10, tags: tags);
      state = state.copyWith(recipes: recipes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Nach Suchbegriff suchen
  Future<void> search({
    required String query,
    String? diet,
    String? mealType,
    int? maxReadyTime,
  }) async {
    if (query.trim().isEmpty) {
      loadRandom();
      return;
    }
    state = state.copyWith(isLoading: true, error: null, activeQuery: query);
    try {
      final recipes = await ref.read(spoonacularServiceProvider).searchRecipes(
            query: query,
            diet: diet,
            mealType: mealType,
            maxReadyTime: maxReadyTime,
          );
      state = state.copyWith(
          recipes: recipes, isLoading: false, activeDiet: diet);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Nach Zutaten suchen
  Future<void> findByIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final recipes = await ref
          .read(spoonacularServiceProvider)
          .findByIngredients(ingredients);
      state = state.copyWith(recipes: recipes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final spoonacularProvider =
    AutoDisposeNotifierProvider<SpoonacularNotifier, SpoonacularState>(
  SpoonacularNotifier.new,
);

