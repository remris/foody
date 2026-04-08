import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/features/recipes/data/recipe_repository_impl.dart';
import 'package:kokomi/features/recipes/domain/recipe_repository.dart';
import 'package:kokomi/features/recipes/presentation/recent_prompts_provider.dart';
import 'package:kokomi/features/settings/presentation/ai_usage_provider.dart';
import 'package:kokomi/features/settings/presentation/allergen_provider.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/models/recipe.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl();
});

/// Zutaten die fast jeder zuhause hat – werden beim KI-Prompt ignoriert
/// damit die KI sich auf die "echten" Hauptzutaten konzentriert.
const _pantryStaples = {
  // Gewürze & Kräuter
  'salz', 'pfeffer', 'zucker', 'mehl', 'backpulver', 'natron',
  'zimt', 'paprikapulver', 'kurkuma', 'kreuzkümmel', 'oregano',
  'thymian', 'rosmarin', 'basilikum', 'petersilie', 'lorbeer',
  'muskat', 'vanille', 'nelken', 'kardamom', 'koriander',
  'chili', 'cayenne', 'curry', 'ingwer', 'knoblauchpulver',
  'zwiebelpulver', 'majoran', 'salbei', 'dill', 'schnittlauch',
  'gewürze', 'kräuter', 'würzmischung',
  // Öle & Essig
  'öl', 'olivenöl', 'sonnenblumenöl', 'rapsöl', 'butter',
  'margarine', 'essig', 'balsamico', 'weinessig',
  // Grundnahrungsmittel
  'wasser', 'sojasoße', 'worcester', 'senf', 'ketchup',
  'tomatenmark', 'brühe', 'gemüsebrühe', 'hühnerbrühe',
  // Backzutaten
  'hefe', 'speisestärke', 'gelatine',
};

/// Filtert Standard-Vorratszutaten heraus die die KI nicht braucht.
List<String> _filterStaples(List<String> ingredients) {
  return ingredients.where((name) {
    final lower = name.toLowerCase().trim();
    return !_pantryStaples.any((staple) => lower.contains(staple));
  }).toList();
}

class RecipeNotifier extends AsyncNotifier<List<FoodRecipe>> {
  // Wird true wenn User auf "Neu generieren" klickt → nächster Call forceRefresh
  bool _nextCallForceRefresh = false;

  @override
  Future<List<FoodRecipe>> build() async => [];

  /// Prüft ob der User noch generieren darf (Free-Limit) oder Pro ist.
  /// Gibt `null` zurück wenn OK, sonst eine Fehlermeldung.
  Future<String?> _checkFreeLimit() async {
    final isPro = ref.read(isProProvider);
    if (isPro) return null; // Pro: kein Limit
    final canGenerate = await ref.read(aiUsageProvider.notifier).canGenerate();
    if (canGenerate) return null;
    return 'KI-LIMIT_REACHED'; // spezieller Code → UI zeigt Paywall
  }

  /// Liest die konfigurierten Allergen-Labels – nur für Pro-User aktiv.
  List<String> _getAllergens() {
    final isPro = ref.read(isProProvider);
    if (!isPro) return const [];
    return ref.read(allergenFilterProvider).map((a) => a.label).toList();
  }

  Future<void> generateFromInventory() async {
    final limitError = await _checkFreeLimit();
    if (limitError != null) {
      state = AsyncError(limitError, StackTrace.current);
      return;
    }
    final items = ref.read(inventoryProvider).valueOrNull ?? [];
    if (items.isEmpty) {
      state = AsyncError(
        'Dein Vorrat ist leer. Füge zuerst Zutaten hinzu.',
        StackTrace.current,
      );
      return;
    }
    final allNames = items.map((e) => e.ingredientName).toList();
    final filtered = _filterStaples(allNames);
    final ingredientNames = filtered.isEmpty ? allNames : filtered;
    final force = _nextCallForceRefresh;
    _nextCallForceRefresh = false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recipeRepositoryProvider).getSuggestedRecipes(
            ingredientNames,
            forceRefresh: force,
            excludeAllergens: _getAllergens(),
          ),
    );
    if (state.hasValue) {
      await ref.read(aiUsageProvider.notifier).recordUsage();
    }
  }

  Future<void> generateFromPrompt(String prompt, {bool forceRefresh = false}) async {
    if (prompt.trim().isEmpty) {
      state = AsyncError('Bitte gib einen Wunsch ein.', StackTrace.current);
      return;
    }
    final limitError = await _checkFreeLimit();
    if (limitError != null) {
      state = AsyncError(limitError, StackTrace.current);
      return;
    }
    ref.read(recentPromptsProvider.notifier).addPrompt(prompt.trim());
    final force = forceRefresh || _nextCallForceRefresh;
    _nextCallForceRefresh = false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recipeRepositoryProvider).getRecipesFromPrompt(
            prompt,
            forceRefresh: force,
            excludeAllergens: _getAllergens(),
          ),
    );
    if (state.hasValue) {
      await ref.read(aiUsageProvider.notifier).recordUsage();
    }
  }

  Future<void> generateFromSelection(
    List<String> selectedIngredients, {
    String? additionalPrompt,
    bool forceRefresh = false,
  }) async {
    if (selectedIngredients.isEmpty) {
      state = AsyncError('Wähle mindestens eine Zutat aus.', StackTrace.current);
      return;
    }
    final limitError = await _checkFreeLimit();
    if (limitError != null) {
      state = AsyncError(limitError, StackTrace.current);
      return;
    }
    final filtered = _filterStaples(selectedIngredients);
    final toUse = filtered.isEmpty ? selectedIngredients : filtered;
    final force = forceRefresh || _nextCallForceRefresh;
    _nextCallForceRefresh = false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recipeRepositoryProvider).getRecipesFromSelection(
            toUse,
            additionalPrompt: additionalPrompt,
            forceRefresh: force,
            excludeAllergens: _getAllergens(),
          ),
    );
    if (state.hasValue) {
      await ref.read(aiUsageProvider.notifier).recordUsage();
    }
  }

  /// Löscht aktuelle Rezepte. Nächster Generate-Call erzwingt frische Ergebnisse.
  void clear() {
    _nextCallForceRefresh = true;
    state = const AsyncData([]);
  }
}

final recipeProvider =
    AsyncNotifierProvider<RecipeNotifier, List<FoodRecipe>>(RecipeNotifier.new);
