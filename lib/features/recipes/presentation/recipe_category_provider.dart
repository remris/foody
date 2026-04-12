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
/// State: Map<recipeId, primäre RecipeMealType> (für Rückwärtskompatibilität)
/// Mehrfach-Kategorien werden unter _multiPrefix als CSV gespeichert.
class RecipeCategoryNotifier extends Notifier<Map<String, RecipeMealType>> {
  static const _prefix = 'recipe_category_';
  static const _multiPrefix = 'recipe_categories_multi_';

  // Interne Multi-Map – parallel zum State gepflegt
  final Map<String, Set<RecipeMealType>> _multiMap = {};

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
    // Multi-Keys laden
    final multiKeys = prefs.getKeys().where((k) => k.startsWith(_multiPrefix));
    for (final key in multiKeys) {
      final id = key.replaceFirst(_multiPrefix, '');
      final csv = prefs.getString(key) ?? '';
      final types = csv.split(',').map(RecipeMealType.fromName).whereType<RecipeMealType>().toSet();
      if (types.isNotEmpty) _multiMap[id] = types;
    }
    state = map;
  }

  Future<void> setCategory(String recipeId, RecipeMealType? type) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == null) {
      await prefs.remove('$_prefix$recipeId');
      await prefs.remove('$_multiPrefix$recipeId');
      final updated = Map<String, RecipeMealType>.from(state);
      updated.remove(recipeId);
      state = updated;
    } else {
      await prefs.setString('$_prefix$recipeId', type.name);
      state = {...state, recipeId: type};
    }
  }

  /// Mehrere Kategorien auf einmal setzen.
  Future<void> setCategories(String recipeId, List<RecipeMealType> types) async {
    if (types.isEmpty) {
      await setCategory(recipeId, null);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$recipeId', types.first.name);
    await prefs.setString('$_multiPrefix$recipeId', types.map((t) => t.name).join(','));
    _multiMap[recipeId] = types.toSet();
    state = {...state, recipeId: types.first};
  }

  /// Gibt alle Kategorien synchron zurück (inkl. Mehrfach aus _multiMap).
  Set<RecipeMealType> getCategories(String recipeId) {
    if (_multiMap.containsKey(recipeId)) return _multiMap[recipeId]!;
    final primary = state[recipeId];
    if (primary != null) return {primary};
    return {};
  }

  RecipeMealType? getCategory(String recipeId) => state[recipeId];

  /// Lädt Mehrfach-Kategorien aus SharedPreferences (async).
  Future<Set<RecipeMealType>> getCategoriesAsync(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final multi = prefs.getString('$_multiPrefix$recipeId');
    if (multi != null && multi.isNotEmpty) {
      return multi.split(',')
          .map(RecipeMealType.fromName)
          .whereType<RecipeMealType>()
          .toSet();
    }
    final single = RecipeMealType.fromName(prefs.getString('$_prefix$recipeId'));
    return single != null ? {single} : {};
  }
}

final recipeCategoryProvider =
    NotifierProvider<RecipeCategoryNotifier, Map<String, RecipeMealType>>(
  RecipeCategoryNotifier.new,
);

/// Provider für Kategorie-Filter im gespeicherten Rezept-Tab.
final recipeCategoryFilterProvider =
    StateProvider<RecipeMealType?>((ref) => null);
