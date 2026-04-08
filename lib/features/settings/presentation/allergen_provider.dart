import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Allergene die der User in den Einstellungen konfiguriert.
/// Rezepte & Inventar-Items mit diesen Allergenen werden markiert.

// Vordefinierte Allergene gemäß EU-Verordnung
enum Allergen {
  gluten,
  crustaceans,
  eggs,
  fish,
  peanuts,
  soy,
  milk,
  nuts,
  celery,
  mustard,
  sesame,
  sulfites,
  lupin,
  molluscs,
}

extension AllergenExt on Allergen {
  String get label {
    switch (this) {
      case Allergen.gluten:
        return 'Gluten';
      case Allergen.crustaceans:
        return 'Krebstiere';
      case Allergen.eggs:
        return 'Eier';
      case Allergen.fish:
        return 'Fisch';
      case Allergen.peanuts:
        return 'Erdnüsse';
      case Allergen.soy:
        return 'Soja';
      case Allergen.milk:
        return 'Milch/Laktose';
      case Allergen.nuts:
        return 'Schalenfrüchte';
      case Allergen.celery:
        return 'Sellerie';
      case Allergen.mustard:
        return 'Senf';
      case Allergen.sesame:
        return 'Sesam';
      case Allergen.sulfites:
        return 'Sulfite';
      case Allergen.lupin:
        return 'Lupine';
      case Allergen.molluscs:
        return 'Weichtiere';
    }
  }

  String get emoji {
    switch (this) {
      case Allergen.gluten:
        return '🌾';
      case Allergen.crustaceans:
        return '🦐';
      case Allergen.eggs:
        return '🥚';
      case Allergen.fish:
        return '🐟';
      case Allergen.peanuts:
        return '🥜';
      case Allergen.soy:
        return '🫘';
      case Allergen.milk:
        return '🥛';
      case Allergen.nuts:
        return '🌰';
      case Allergen.celery:
        return '🥬';
      case Allergen.mustard:
        return '🟡';
      case Allergen.sesame:
        return '⚪';
      case Allergen.sulfites:
        return '🧪';
      case Allergen.lupin:
        return '🌸';
      case Allergen.molluscs:
        return '🐚';
    }
  }

  /// Schlüsselwörter die in Zutatennamen auf dieses Allergen hinweisen.
  List<String> get keywords {
    switch (this) {
      case Allergen.gluten:
        return [
          'weizen', 'roggen', 'gerste', 'hafer', 'dinkel', 'mehl',
          'nudel', 'pasta', 'brot', 'semmel', 'paniermehl', 'couscous',
          'bulgur', 'grieß', 'wheat', 'flour', 'bread', 'gluten',
        ];
      case Allergen.crustaceans:
        return ['garnele', 'shrimp', 'krebs', 'hummer', 'langust', 'crab'];
      case Allergen.eggs:
        return ['ei', 'eier', 'egg', 'eigelb', 'eiweiß', 'mayonnaise'];
      case Allergen.fish:
        return [
          'fisch', 'lachs', 'thunfisch', 'kabeljau', 'forelle', 'sardine',
          'sardelle', 'hering', 'makrele', 'fish', 'salmon', 'tuna', 'anchov',
        ];
      case Allergen.peanuts:
        return ['erdnuss', 'erdnüsse', 'peanut'];
      case Allergen.soy:
        return ['soja', 'tofu', 'edamame', 'soy', 'miso', 'tempeh'];
      case Allergen.milk:
        return [
          'milch', 'sahne', 'käse', 'butter', 'joghurt', 'quark', 'rahm',
          'molke', 'creme', 'mascarpone', 'mozzarella', 'parmesan', 'ricotta',
          'cream', 'cheese', 'milk', 'yogurt', 'laktose',
        ];
      case Allergen.nuts:
        return [
          'mandel', 'haselnuss', 'walnuss', 'cashew', 'pistazie', 'pecan',
          'macadamia', 'nuss', 'nüsse', 'nut', 'almond', 'walnut', 'hazelnut',
        ];
      case Allergen.celery:
        return ['sellerie', 'celery'];
      case Allergen.mustard:
        return ['senf', 'mustard'];
      case Allergen.sesame:
        return ['sesam', 'sesame'];
      case Allergen.sulfites:
        return ['sulfit', 'schwefel', 'sulfite', 'wein', 'wine'];
      case Allergen.lupin:
        return ['lupine', 'lupin'];
      case Allergen.molluscs:
        return ['muschel', 'tintenfisch', 'oktopus', 'calamari', 'austern'];
    }
  }
}

/// Provider für konfigurierte Allergene des Users.
class AllergenFilterNotifier extends Notifier<Set<Allergen>> {
  static const _key = 'allergen_filter';

  @override
  Set<Allergen> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return;
    try {
      final list = (jsonDecode(json) as List).cast<String>();
      state = list
          .map((name) => Allergen.values.firstWhere(
                (a) => a.name == name,
                orElse: () => Allergen.gluten,
              ))
          .toSet();
    } catch (_) {}
  }

  Future<void> toggle(Allergen allergen) async {
    final current = Set<Allergen>.from(state);
    if (current.contains(allergen)) {
      current.remove(allergen);
    } else {
      current.add(allergen);
    }
    state = current;
    await _save();
  }

  Future<void> setAll(Set<Allergen> allergens) async {
    state = allergens;
    await _save();
  }

  Future<void> clear() async {
    state = {};
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((a) => a.name).toList()),
    );
  }
}

final allergenFilterProvider =
    NotifierProvider<AllergenFilterNotifier, Set<Allergen>>(
  AllergenFilterNotifier.new,
);

/// Prüft ob ein Zutat-Name ein bestimmtes Allergen enthält.
bool ingredientContainsAllergen(String ingredientName, Allergen allergen) {
  final lower = ingredientName.toLowerCase();
  return allergen.keywords.any((kw) => lower.contains(kw));
}

/// Gibt alle Allergene zurück die in einem Zutatennamen erkannt werden.
Set<Allergen> detectAllergens(String ingredientName, Set<Allergen> filter) {
  final detected = <Allergen>{};
  for (final allergen in filter) {
    if (ingredientContainsAllergen(ingredientName, allergen)) {
      detected.add(allergen);
    }
  }
  return detected;
}

/// Prüft ob eine Liste von Zutaten Allergene aus dem Filter enthält.
Map<String, Set<Allergen>> checkRecipeAllergens(
  List<String> ingredientNames,
  Set<Allergen> filter,
) {
  final result = <String, Set<Allergen>>{};
  for (final name in ingredientNames) {
    final detected = detectAllergens(name, filter);
    if (detected.isNotEmpty) {
      result[name] = detected;
    }
  }
  return result;
}

