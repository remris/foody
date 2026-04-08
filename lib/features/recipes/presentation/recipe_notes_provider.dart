import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider für persönliche Kochnotizen pro Rezept (lokal gespeichert).
class RecipeNotesNotifier extends Notifier<Map<String, String>> {
  static const _prefix = 'recipe_note_';

  @override
  Map<String, String> build() {
    _loadAll();
    return {};
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final map = <String, String>{};
    for (final key in keys) {
      final id = key.replaceFirst(_prefix, '');
      final note = prefs.getString(key);
      if (note != null && note.isNotEmpty) map[id] = note;
    }
    state = map;
  }

  Future<void> setNote(String recipeId, String note) async {
    final prefs = await SharedPreferences.getInstance();
    if (note.trim().isEmpty) {
      await prefs.remove('$_prefix$recipeId');
      final updated = Map<String, String>.from(state);
      updated.remove(recipeId);
      state = updated;
    } else {
      await prefs.setString('$_prefix$recipeId', note);
      state = {...state, recipeId: note};
    }
  }

  String getNote(String recipeId) => state[recipeId] ?? '';
}

final recipeNotesProvider =
    NotifierProvider<RecipeNotesNotifier, Map<String, String>>(
  RecipeNotesNotifier.new,
);

