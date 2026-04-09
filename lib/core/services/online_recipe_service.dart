import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:groq_sdk/groq_sdk.dart';
import 'package:kokomu/models/recipe.dart';

/// Service für Online-Rezeptsuche über TheMealDB API (kostenlos).
/// Übersetzt Ergebnisse automatisch ins Deutsche via Groq.
class OnlineRecipeService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://www.themealdb.com/api/json/v1/1',
  ));

  // Übersetzungstabelle: Deutsch → Englisch für Suchanfragen
  static const _deToEn = <String, String>{
    'hähnchen': 'chicken',
    'hühnchen': 'chicken',
    'huhn': 'chicken',
    'rindfleisch': 'beef',
    'rind': 'beef',
    'schweinefleisch': 'pork',
    'schwein': 'pork',
    'lamm': 'lamb',
    'lachs': 'salmon',
    'thunfisch': 'tuna',
    'garnelen': 'shrimp',
    'nudeln': 'pasta',
    'spaghetti': 'spaghetti',
    'reis': 'rice',
    'kartoffeln': 'potatoes',
    'kartoffel': 'potato',
    'tomate': 'tomato',
    'tomaten': 'tomatoes',
    'zwiebel': 'onion',
    'zwiebeln': 'onions',
    'knoblauch': 'garlic',
    'pilze': 'mushrooms',
    'pilz': 'mushroom',
    'käse': 'cheese',
    'eier': 'eggs',
    'ei': 'egg',
    'kuchen': 'cake',
    'suppe': 'soup',
    'salat': 'salad',
    'pizza': 'pizza',
    'curry': 'curry',
    'steak': 'steak',
    'burger': 'burger',
    'sandwich': 'sandwich',
    'schokolade': 'chocolate',
    'dessert': 'dessert',
    'frühstück': 'breakfast',
    'vegetarisch': 'vegetarian',
    'vegan': 'vegan',
    'fisch': 'fish',
    'meeresfrüchte': 'seafood',
  };

  // Übersetzung einer deutschen Suchanfrage ins Englische
  static String _translateQuery(String query) {
    final lower = query.toLowerCase().trim();
    // Exaktes Matching
    if (_deToEn.containsKey(lower)) return _deToEn[lower]!;
    // Teilstring-Matching
    for (final entry in _deToEn.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return query; // Original zurückgeben falls keine Übersetzung
  }

  /// Rezepte nach Zutat suchen.
  Future<List<FoodRecipe>> searchByIngredient(String ingredient) async {
    final translated = _translateQuery(ingredient);
    final response = await _dio.get('/filter.php', queryParameters: {
      'i': translated,
    });

    final meals = response.data['meals'] as List<dynamic>?;
    if (meals == null) return [];

    // Details für jedes Rezept laden (parallel, max 5)
    final futures = meals.take(5).map((meal) async {
      return lookupMeal(meal['idMeal'] as String);
    });

    final results = await Future.wait(futures);
    return results.whereType<FoodRecipe>().toList();
  }

  /// Rezepte nach Name suchen.
  Future<List<FoodRecipe>> searchByName(String query) async {
    final translated = _translateQuery(query);
    final response = await _dio.get('/search.php', queryParameters: {
      's': translated,
    });

    final meals = response.data['meals'] as List<dynamic>?;
    if (meals == null) return [];

    return meals.take(10).map((meal) => _mealToRecipe(meal)).toList();
  }

  /// Einzelnes Rezept nach ID laden.
  Future<FoodRecipe?> lookupMeal(String id) async {
    final response = await _dio.get('/lookup.php', queryParameters: {
      'i': id,
    });

    final meals = response.data['meals'] as List<dynamic>?;
    if (meals == null || meals.isEmpty) return null;

    return _mealToRecipe(meals.first);
  }

  /// Zufällige Rezepte laden.
  Future<List<FoodRecipe>> getRandomRecipes({int count = 5}) async {
    final futures = List.generate(count, (_) async {
      final response = await _dio.get('/random.php');
      final meals = response.data['meals'] as List<dynamic>?;
      if (meals == null || meals.isEmpty) return null;
      return _mealToRecipe(meals.first);
    });

    final results = await Future.wait(futures);
    return results.whereType<FoodRecipe>().toList();
  }

  /// Nach Kategorie suchen (z.B. "Chicken", "Beef", "Vegetarian").
  Future<List<FoodRecipe>> searchByCategory(String category) async {
    final response = await _dio.get('/filter.php', queryParameters: {
      'c': category,
    });

    final meals = response.data['meals'] as List<dynamic>?;
    if (meals == null) return [];

    final futures = meals.take(5).map((meal) async {
      return lookupMeal(meal['idMeal'] as String);
    });

    final results = await Future.wait(futures);
    return results.whereType<FoodRecipe>().toList();
  }

  // Übersetzungen für Kategorien
  static const _categoryTranslations = <String, String>{
    'Beef': 'Rind',
    'Chicken': 'Hähnchen',
    'Dessert': 'Dessert',
    'Lamb': 'Lamm',
    'Miscellaneous': 'Sonstiges',
    'Pasta': 'Nudeln',
    'Pork': 'Schwein',
    'Seafood': 'Meeresfrüchte',
    'Side': 'Beilage',
    'Starter': 'Vorspeise',
    'Vegan': 'Vegan',
    'Vegetarian': 'Vegetarisch',
    'Breakfast': 'Frühstück',
    'Goat': 'Ziege',
  };

  // Übersetzungen für Herkunftsländer
  static const _areaTranslations = <String, String>{
    'American': 'Amerikanisch',
    'British': 'Britisch',
    'Canadian': 'Kanadisch',
    'Chinese': 'Chinesisch',
    'Croatian': 'Kroatisch',
    'Dutch': 'Niederländisch',
    'Egyptian': 'Ägyptisch',
    'Filipino': 'Philippinisch',
    'French': 'Französisch',
    'Greek': 'Griechisch',
    'Indian': 'Indisch',
    'Irish': 'Irisch',
    'Italian': 'Italienisch',
    'Jamaican': 'Jamaikanisch',
    'Japanese': 'Japanisch',
    'Kenyan': 'Kenianisch',
    'Malaysian': 'Malaysisch',
    'Mexican': 'Mexikanisch',
    'Moroccan': 'Marokkanisch',
    'Polish': 'Polnisch',
    'Portuguese': 'Portugiesisch',
    'Russian': 'Russisch',
    'Spanish': 'Spanisch',
    'Thai': 'Thailändisch',
    'Tunisian': 'Tunesisch',
    'Turkish': 'Türkisch',
    'Unknown': 'Unbekannt',
    'Vietnamese': 'Vietnamesisch',
  };

  static String _translateCategory(String? cat) {
    if (cat == null || cat.isEmpty) return '';
    return _categoryTranslations[cat] ?? cat;
  }

  static String _translateArea(String? area) {
    if (area == null || area.isEmpty) return '';
    return _areaTranslations[area] ?? area;
  }

  // Einfache Übersetzung der Zubereitungsanleitung
  // Wichtige englische Kochbegriffe → Deutsch
  static const _cookingTerms = <String, String>{
    'Preheat': 'Vorheizen',
    'preheat': 'Vorheizen',
    'Add': 'Hinzufügen',
    'add': 'hinzufügen',
    'Mix': 'Mischen',
    'mix': 'mischen',
    'Stir': 'Rühren',
    'stir': 'rühren',
    'Cook': 'Kochen',
    'cook': 'kochen',
    'Bake': 'Backen',
    'bake': 'backen',
    'Fry': 'Braten',
    'fry': 'braten',
    'Boil': 'Aufkochen',
    'boil': 'aufkochen',
    'Simmer': 'Köcheln lassen',
    'simmer': 'köcheln lassen',
    'Serve': 'Servieren',
    'serve': 'servieren',
    'minutes': 'Minuten',
    'minute': 'Minute',
    'hours': 'Stunden',
    'hour': 'Stunde',
    'oven': 'Ofen',
    'pan': 'Pfanne',
    'pot': 'Topf',
    'bowl': 'Schüssel',
    'heat': 'Hitze',
    'medium heat': 'mittlerer Hitze',
    'high heat': 'hoher Hitze',
    'low heat': 'niedriger Hitze',
    'salt and pepper': 'Salz und Pfeffer',
    'tablespoon': 'Esslöffel',
    'teaspoon': 'Teelöffel',
    'cup': 'Tasse',
    'cups': 'Tassen',
    'Remove': 'Entfernen',
    'remove': 'entfernen',
    'Place': 'Legen',
    'place': 'legen',
    'Heat': 'Erhitzen',
    'Cut': 'Schneiden',
    'cut': 'schneiden',
    'Chop': 'Hacken',
    'chop': 'hacken',
    'Slice': 'In Scheiben schneiden',
    'slice': 'in Scheiben schneiden',
    'Drain': 'Abgießen',
    'drain': 'abgießen',
    'Season': 'Würzen',
    'season': 'würzen',
    'Cover': 'Abdecken',
    'cover': 'abdecken',
    'Combine': 'Kombinieren',
    'combine': 'kombinieren',
    'Pour': 'Gießen',
    'pour': 'gießen',
    'Bring': 'Bringen',
    'bring': 'bringen',
    'Transfer': 'Umfüllen',
    'transfer': 'umfüllen',
  };

  static String _translateInstructions(String text) {
    if (text.isEmpty) return text;
    var result = text;
    for (final entry in _cookingTerms.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// TheMealDB Meal JSON → FoodRecipe konvertieren.
  FoodRecipe _mealToRecipe(Map<String, dynamic> meal) {
    // Zutaten extrahieren (bis zu 20 Zutaten in TheMealDB)
    final ingredients = <RecipeIngredient>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'] as String?;
      final measure = meal['strMeasure$i'] as String?;
      if (ingredient != null && ingredient.trim().isNotEmpty) {
        ingredients.add(RecipeIngredient(
          name: ingredient.trim(),
          amount: _translateMeasure(measure?.trim() ?? ''),
        ));
      }
    }

    // Schritte aufteilen (TheMealDB hat Instructions als Fließtext)
    final instructionsRaw = meal['strInstructions'] as String? ?? '';
    final translatedInstructions = _translateInstructions(instructionsRaw);
    final steps = translatedInstructions
        .split(RegExp(r'[\r\n]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    // Schwierigkeit schätzen anhand Zutatenzahl
    String difficulty;
    if (ingredients.length <= 5) {
      difficulty = 'Einfach';
    } else if (ingredients.length <= 10) {
      difficulty = 'Mittel';
    } else {
      difficulty = 'Fortgeschritten';
    }

    final category = _translateCategory(meal['strCategory'] as String?);
    final area = _translateArea(meal['strArea'] as String?);
    final descParts = [category, area].where((s) => s.isNotEmpty).toList();

    return FoodRecipe(
      id: meal['idMeal'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: meal['strMeal'] as String? ?? 'Unbekanntes Rezept',
      description: descParts.join(' · '),
      cookingTimeMinutes: _estimateCookingTime(ingredients.length),
      difficulty: difficulty,
      servings: 4,
      ingredients: ingredients,
      steps: steps,
    );
  }

  // Maßeinheiten übersetzen
  static const _measureTranslations = <String, String>{
    'tbs': 'EL',
    'tsp': 'TL',
    'tbsp': 'EL',
    'tablespoon': 'Esslöffel',
    'tablespoons': 'Esslöffel',
    'teaspoon': 'Teelöffel',
    'teaspoons': 'Teelöffel',
    'cup': 'Tasse',
    'cups': 'Tassen',
    'oz': 'oz',
    'lb': 'lb',
    'lbs': 'lb',
    'pound': 'Pfund',
    'pounds': 'Pfund',
    'clove': 'Zehe',
    'cloves': 'Zehen',
    'pinch': 'Prise',
    'handful': 'Handvoll',
    'to taste': 'nach Geschmack',
    'as needed': 'nach Bedarf',
    'large': 'groß',
    'small': 'klein',
    'medium': 'mittel',
    'chopped': 'gehackt',
    'sliced': 'in Scheiben',
    'diced': 'gewürfelt',
    'minced': 'fein gehackt',
    'grated': 'gerieben',
  };

  static String _translateMeasure(String measure) {
    if (measure.isEmpty) return measure;
    var result = measure;
    for (final entry in _measureTranslations.entries) {
      result = result.replaceAll(
        RegExp(r'\b' + entry.key + r'\b', caseSensitive: false),
        entry.value,
      );
    }
    return result;
  }

  int _estimateCookingTime(int ingredientCount) {
    if (ingredientCount <= 5) return 20;
    if (ingredientCount <= 8) return 30;
    if (ingredientCount <= 12) return 45;
    return 60;
  }

  /// Vollständiges Rezept via Groq ins Deutsche übersetzen.
  /// Fällt auf die einfache Wort-Ersetzung zurück wenn Groq nicht verfügbar.
  Future<FoodRecipe> translateRecipe(FoodRecipe recipe) async {
    try {
      final key = dotenv.env['GROQ_API_KEY'] ?? '';
      if (key.isEmpty) return recipe;

      final groq = Groq(key);
      final chat = groq.startNewChat('llama3-8b-8192');

      final ingredientsList = recipe.ingredients
          .map((i) => '${i.amount} ${i.name}')
          .join('\n');
      final stepsList = recipe.steps
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value}')
          .join('\n');

      final prompt = '''
Übersetze das folgende Rezept ins Deutsche. Behalte die Struktur bei.
Antworte NUR im folgenden Format (kein Markdown, keine Erklärung):

TITEL: [Deutscher Titel]
BESCHREIBUNG: [Kurze deutsche Beschreibung]
ZUTATEN:
[Menge] [Zutat auf Deutsch]
...
SCHRITTE:
1. [Schritt auf Deutsch]
2. [Schritt auf Deutsch]
...

Originalrezept:
Titel: ${recipe.title}
Beschreibung: ${recipe.description}
Zutaten:
$ingredientsList
Schritte:
$stepsList
''';

      final (response, _) = await chat.sendMessage(prompt);
      final text = response.choices.first.message;

      return _parseTranslatedRecipe(text, recipe);
    } catch (_) {
      return recipe; // Fallback: Original zurückgeben
    }
  }

  /// Geparste Groq-Antwort in ein FoodRecipe umwandeln.
  FoodRecipe _parseTranslatedRecipe(String text, FoodRecipe original) {
    String? title;
    String? description;
    final ingredients = <RecipeIngredient>[];
    final steps = <String>[];

    var section = '';
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('TITEL:')) {
        title = trimmed.replaceFirst('TITEL:', '').trim();
      } else if (trimmed.startsWith('BESCHREIBUNG:')) {
        description = trimmed.replaceFirst('BESCHREIBUNG:', '').trim();
      } else if (trimmed == 'ZUTATEN:') {
        section = 'ingredients';
      } else if (trimmed == 'SCHRITTE:') {
        section = 'steps';
      } else if (section == 'ingredients') {
        // Format: "200g Mehl" oder "2 EL Olivenöl"
        final match = RegExp(r'^([\d.,/½¼¾⅓⅔]+\s*\S*)\s+(.+)$').firstMatch(trimmed);
        if (match != null) {
          ingredients.add(RecipeIngredient(
            name: match.group(2)!.trim(),
            amount: match.group(1)!.trim(),
          ));
        } else {
          ingredients.add(RecipeIngredient(name: trimmed, amount: ''));
        }
      } else if (section == 'steps') {
        // Nummerierung entfernen
        final step = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        if (step.isNotEmpty) steps.add(step);
      }
    }

    return FoodRecipe(
      id: original.id,
      title: title ?? original.title,
      description: description ?? original.description,
      cookingTimeMinutes: original.cookingTimeMinutes,
      difficulty: original.difficulty,
      servings: original.servings,
      ingredients: ingredients.isNotEmpty ? ingredients : original.ingredients,
      steps: steps.isNotEmpty ? steps : original.steps,
      nutrition: original.nutrition,
    );
  }
}

