import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rezept-Kategorie-Optionen.
enum RecipeMealType {
  breakfast('Frühstück', '🌅'),
  lunch('Mittagessen', '☀️'),
  dinner('Abendessen', '🌙'),
  snack('Snack', '🍎'),
  dessert('Dessert', '🍰');

  final String label;
  final String emoji;
  const RecipeMealType(this.label, this.emoji);

  String get display => '$emoji $label';

  static RecipeMealType? fromName(String? name) {
    if (name == null) return null;
    try {
      return RecipeMealType.values.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }
}

/// Provider für Rezept-Kategorien (lokal gespeichert).
class RecipeCategoryNotifier extends Notifier<Map<String, RecipeMealType>> {
  static const _prefix = 'recipe_category_';

  @override
  Map<String, RecipeMealType> build() {
    _loadAll();
    return {};
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final map = <String, RecipeMealType>{};
    for (final key in keys) {
      final id = key.replaceFirst(_prefix, '');
      final type = RecipeMealType.fromName(prefs.getString(key));
      if (type != null) map[id] = type;
    }
    state = map;
  }

  Future<void> setCategory(String recipeId, RecipeMealType? type) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == null) {
      await prefs.remove('$_prefix$recipeId');
      final updated = Map<String, RecipeMealType>.from(state);
      updated.remove(recipeId);
      state = updated;
    } else {
      await prefs.setString('$_prefix$recipeId', type.name);
      state = {...state, recipeId: type};
    }
  }

  RecipeMealType? getCategory(String recipeId) => state[recipeId];
}

final recipeCategoryProvider =
    NotifierProvider<RecipeCategoryNotifier, Map<String, RecipeMealType>>(
  RecipeCategoryNotifier.new,
);

/// Provider für Kategorie-Filter im gespeicherten Rezept-Tab.
final recipeCategoryFilterProvider =
    StateProvider<RecipeMealType?>((ref) => null);

