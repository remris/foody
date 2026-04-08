import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Ruft Groq direkt auf (kein Proxy nötig – Key liegt in .env, nicht im Store).
class GroqProxyService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Anti-Duplikat
  static final List<String> _recentTitles = [];
  static const int _maxRecentTitles = 30;

  static void rememberTitles(List<String> titles) {
    _recentTitles.addAll(titles);
    while (_recentTitles.length > _maxRecentTitles) {
      _recentTitles.removeAt(0);
    }
  }

  final _rng = Random();

  static final _cuisines = [
    'mediterran', 'asiatisch (Thai)', 'deutsch', 'mexikanisch', 'italienisch',
    'indisch', 'griechisch', 'arabisch/marokkanisch', 'französisch', 'japanisch',
    'koreanisch', 'türkisch', 'peruanisch', 'vietnamesisch', 'karibisch',
    'äthiopisch', 'spanisch', 'amerikanisch', 'osteuropäisch', 'skandinavisch',
  ];
  static final _styles = [
    'schnell & einfach (unter 20 Min)', 'kalorienarm', 'proteinreich', 'vegetarisch',
    'herzhaft', 'leicht und frisch', 'sättigend', 'kreativ & ungewöhnlich', 'klassisch',
    'exotisch', 'comfort food', 'festlich', 'one-pot', 'low carb', 'vegan',
    'Meal-Prep tauglich', 'glutenfrei', 'Budgetküche', 'Gourmet', 'Street Food',
  ];
  static final _techniques = [
    'Pfanne', 'Backofen', 'großer Topf', 'Grill', 'Wok', 'Dampfgarer',
    'roh/Salat', 'Schmortopf', 'Auflaufform', 'Suppe/Eintopf', 'Sandwich/Wrap',
    'Frittieren', 'Sous-Vide (vereinfacht)', 'Airfryer', 'Bowl',
  ];
  static final _mealTypes = [
    'Hauptgericht', 'Vorspeise', 'Dessert', 'Frühstück', 'Snack',
    'Beilage', 'Suppe', 'Salat', 'Fingerfood', 'Auflauf',
  ];

  static const String _jsonFormat = '''
{
  "recipes": [
    {
      "title": "Rezeptname",
      "description": "Kurze Beschreibung",
      "cookingTimeMinutes": 30,
      "difficulty": "Einfach",
      "servings": 2,
      "ingredients": [{"name": "Zutat", "amount": "200g"}],
      "steps": ["Schritt 1", "Schritt 2"],
      "nutrition": {
        "calories": 450,
        "protein": 25.0,
        "carbs": 50.0,
        "fat": 15.0,
        "fiber": 5.0
      }
    }
  ]
}''';

  String _varietyHint() {
    final s = List<String>.from(_styles)..shuffle(_rng);
    final t = List<String>.from(_techniques)..shuffle(_rng);
    final seed = _rng.nextInt(99999999);
    final ts = DateTime.now().microsecondsSinceEpoch;
    final avoid = _recentTitles.isNotEmpty
        ? '\nNICHT WIEDERHOLEN: ${_recentTitles.take(15).join(", ")}.'
        : '';
    return 'SEED:$seed-$ts | Stile: ${s[0]}, ${s[1]}, ${s[2]} | Techniken: ${t[0]}, ${t[1]}$avoid';
  }

  String _randomHint() {
    final c = List<String>.from(_cuisines)..shuffle(_rng);
    final s = List<String>.from(_styles)..shuffle(_rng);
    final t = List<String>.from(_techniques)..shuffle(_rng);
    final seed = _rng.nextInt(99999999);
    final ts = DateTime.now().microsecondsSinceEpoch;
    final avoid = _recentTitles.isNotEmpty
        ? '\nNICHT WIEDERHOLEN: ${_recentTitles.take(15).join(", ")}.'
        : '';
    return 'SEED:$seed-$ts\nKüche1:${c[0]} Stil:${s[0]} | Küche2:${c[1]} Stil:${s[1]} | Küche3:${c[2]} Technik:${t[0]}$avoid';
  }

  // ── Public API ─────────────────────────────────────────────────────────

  static String _allergenLine(List<String> allergens) {
    if (allergens.isEmpty) return '';
    return '\nWICHTIG – verwende KEINE Zutaten die folgende Allergene enthalten: '
        '${allergens.join(", ")}. Ersetze bei Bedarf durch allergenfreie Alternativen.\n';
  }

  Future<String> generateRecipes(
    List<String> ingredients, {
    List<String> excludeAllergens = const [],
  }) =>
      _send('Du bist Koch-Assistent. Generiere EXAKT 3 verschiedene Rezepte aus unterschiedlichen Küchen.\n'
          '${_randomHint()}\n'
          '${_allergenLine(excludeAllergens)}'
          'Zutaten als Grundlage: ${ingredients.join(", ")}\n'
          'Antworte NUR als JSON ohne Markdown:\n$_jsonFormat');

  Future<String> generateRecipesFromPrompt(
    String userPrompt, {
    List<String> excludeAllergens = const [],
  }) {
    final lowerPrompt = userPrompt.toLowerCase();
    final matchedCuisine = _cuisines.firstWhere(
      (c) => lowerPrompt.contains(c.toLowerCase().split(' ')[0]),
      orElse: () => '',
    );
    final hasSpecificCuisine = matchedCuisine.isNotEmpty;
    final hint = hasSpecificCuisine ? _varietyHint() : _randomHint();

    final instruction = hasSpecificCuisine
        ? 'Erstelle EXAKT 3 verschiedene $matchedCuisine Rezepte – unterschiedliche Gerichte, Techniken und Zutaten!'
        : 'Erstelle EXAKT 3 verschiedene Rezepte die zum Wunsch passen.';

    return _send(
        'Du bist Koch-Assistent. Wunsch: "$userPrompt"\n'
        '$hint\n'
        '${_allergenLine(excludeAllergens)}'
        '$instruction\n'
        'Antworte NUR als JSON ohne Markdown:\n$_jsonFormat');
  }

  Future<String> generateRecipesFromSelection(
    List<String> ingredients, {
    String? additionalPrompt,
    List<String> excludeAllergens = const [],
  }) {
    final lowerPrompt = (additionalPrompt ?? '').toLowerCase();
    final matchedCuisine = _cuisines.firstWhere(
      (c) => lowerPrompt.contains(c.toLowerCase().split(' ')[0]),
      orElse: () => '',
    );
    final hasSpecificCuisine = matchedCuisine.isNotEmpty;
    final hint = hasSpecificCuisine ? _varietyHint() : _randomHint();

    final wishLine = additionalPrompt != null
        ? (hasSpecificCuisine
            ? 'Erstelle EXAKT 3 verschiedene $matchedCuisine Rezepte mit diesen Zutaten!'
            : 'Wunsch: "$additionalPrompt" – EXAKT 3 Rezepte die dazu passen.')
        : 'Erstelle EXAKT 3 verschiedene Rezepte mit diesen Zutaten.';

    return _send(
        'Du bist Koch-Assistent.\n'
        '$hint\n'
        '$wishLine\n'
        'Hauptzutaten: ${ingredients.join(", ")}\n'
        '${_allergenLine(excludeAllergens)}'
        'Antworte NUR als JSON ohne Markdown:\n$_jsonFormat');
  }

  Future<String> generateMealPrepRecipes(List<String> ingredients) => _send(
      'Du bist Meal-Prep-Experte. EXAKT 3 Rezepte zum Vorkochen (3-5 Tage haltbar).\n'
      '${_randomHint()}\n'
      'Zutaten: ${ingredients.join(", ")}\n'
      'Antworte NUR als JSON ohne Markdown:\n$_jsonFormat');

  Future<String> generateMealPlan({
    int? calorieGoal,
    String? goal,
    List<String>? availableIngredients,
    List<String>? dietaryPreferences,
  }) =>
      _sendLarge(
        'Du bist Ernährungsexperte. Erstelle einen KOMPAKTEN 7-Tage-Mahlzeitenplan.\n'
        '${_randomHint()}\n'
        '${calorieGoal != null ? "Tagesziel: $calorieGoal kcal\n" : ""}'
        '${goal != null ? "Ziel: $goal\n" : ""}'
        '${dietaryPreferences != null && dietaryPreferences.isNotEmpty ? "Ernährungsform: ${dietaryPreferences.join(", ")}\n" : ""}'
        '${availableIngredients != null && availableIngredients.isNotEmpty ? "Bevorzugte Zutaten: ${availableIngredients.take(10).join(", ")}\n" : ""}'
        'WICHTIG: Antworte NUR mit reinem JSON, kein Markdown, keine Erklärungen.\n'
        'Format (KURZE Beschreibungen, max 3 Zutaten pro Rezept, max 2 Schritte):\n'
        '{"days":[{"dayIndex":0,"meals":['
        '{"slot":"breakfast","recipe":{"title":"","description":"","cookingTimeMinutes":10,"difficulty":"Einfach","servings":2,"ingredients":[{"name":"","amount":""}],"steps":[""],"nutrition":{"calories":300,"protein":15.0,"carbs":35.0,"fat":8.0,"fiber":3.0}}},'
        '{"slot":"lunch","recipe":{"title":"","description":"","cookingTimeMinutes":20,"difficulty":"Einfach","servings":2,"ingredients":[{"name":"","amount":""}],"steps":[""],"nutrition":{"calories":500,"protein":25.0,"carbs":50.0,"fat":15.0,"fiber":5.0}}},'
        '{"slot":"dinner","recipe":{"title":"","description":"","cookingTimeMinutes":25,"difficulty":"Mittel","servings":2,"ingredients":[{"name":"","amount":""}],"steps":[""],"nutrition":{"calories":600,"protein":30.0,"carbs":55.0,"fat":18.0,"fiber":6.0}}}'
        ']}]}\n'
        'Erstelle genau 7 Tage (dayIndex 0-6). Jeder Tag hat breakfast, lunch und dinner.',
      );

  // ── HTTP ───────────────────────────────────────────────────────────────
  Future<String> _send(String prompt) => _sendWithTokens(prompt, 4096);

  Future<String> _sendLarge(String prompt) => _sendWithTokens(prompt, 8192);

  Future<String> _sendWithTokens(String prompt, int maxTokens) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception('GROQ_API_KEY nicht in .env konfiguriert');

    final response = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 1.2,
        'max_tokens': maxTokens,
        'top_p': 0.9,
      }),
    ).timeout(const Duration(seconds: 60));

    final rawBody = response.body;

    if (response.statusCode == 429) {
      throw Exception('KI-LIMIT_REACHED');
    }

    if (response.statusCode != 200) {
      Map<String, dynamic> body;
      try {
        body = jsonDecode(rawBody) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Groq Fehler (${response.statusCode}): $rawBody');
      }
      final err = body['error']?.toString() ?? rawBody;
      throw Exception('Groq Fehler (${response.statusCode}): $err');
    }

    final body = jsonDecode(rawBody) as Map<String, dynamic>;
    final content =
        body['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('Leere Antwort von Groq');
    }

    return content;
  }
}
