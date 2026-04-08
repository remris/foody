import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider für Lieblingsrezepte (Herzchen-Markierung).
class RecipeFavoritesNotifier extends Notifier<Set<String>> {
  static const _key = 'recipe_favorites';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  Future<void> toggleFavorite(String recipeId) async {
    final updated = Set<String>.from(state);
    if (updated.contains(recipeId)) {
      updated.remove(recipeId);
    } else {
      updated.add(recipeId);
    }
    state = updated;
    await _save();
  }

  bool isFavorite(String recipeId) => state.contains(recipeId);
}

final recipeFavoritesProvider =
    NotifierProvider<RecipeFavoritesNotifier, Set<String>>(
  RecipeFavoritesNotifier.new,
);

