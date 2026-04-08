import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeRatingNotifier extends Notifier<Map<String, int>> {
  static const _prefix = 'recipe_rating_';

  @override
  Map<String, int> build() {
    _loadAll();
    return {};
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final map = <String, int>{};
    for (final key in keys) {
      final id = key.replaceFirst(_prefix, '');
      map[id] = prefs.getInt(key) ?? 0;
    }
    state = map;
  }

  Future<void> setRating(String recipeId, int rating) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$recipeId', rating);
    state = {...state, recipeId: rating};
  }

  int getRating(String recipeId) => state[recipeId] ?? 0;
}

final recipeRatingProvider =
    NotifierProvider<RecipeRatingNotifier, Map<String, int>>(
  RecipeRatingNotifier.new,
);

