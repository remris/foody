import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:groq_sdk/groq_sdk.dart';

/// KI-Service über Groq (kostenlos, kein Billing nötig).
/// Kostenloser API-Key: https://console.groq.com
class GroqService {
  static const _model = 'llama3-70b-8192';

  // Zufallsgenerator für Variabilität
  final _rng = Random();

  // ── Anti-Duplikat: zuletzt generierte Rezept-Titel merken ──────────────
  static final List<String> _recentTitles = [];
  static const int _maxRecentTitles = 30;

  /// Speichert generierte Rezept-Titel um Wiederholungen zu vermeiden.
  static void rememberTitles(List<String> titles) {
    _recentTitles.addAll(titles);
    while (_recentTitles.length > _maxRecentTitles) {
      _recentTitles.removeAt(0);
    }
  }

  // Verschiedene Küchen / Stile für Abwechslung
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

  GroqChat _chat() {
    final key = dotenv.env['GROQ_API_KEY'] ?? '';
    if (key.isEmpty) throw Exception('GROQ_API_KEY nicht gesetzt');
    return Groq(key).startNewChat(
      _model,
      settings: GroqChatSettings(
        temperature: 1.5,
        maxTokens: 4096,
        topP: 0.9,
      ),
    );
  }

  /// Zufällige Hinweise damit das Modell wirklich andere Rezepte wählt
  String _randomHint() {
    _cuisines.shuffle(_rng);
    _styles.shuffle(_rng);
    _techniques.shuffle(_rng);
    _mealTypes.shuffle(_rng);

    // Nimm 3 verschiedene Küchen damit die 3 Rezepte wirklich different sind
    final cuisine1 = _cuisines[0];
    final cuisine2 = _cuisines[1];
    final cuisine3 = _cuisines[2];
    final style = _styles.first;
    final technique = _techniques.first;
    final mealType = _mealTypes.first;
    final seed = _rng.nextInt(9999999);
    final ts = DateTime.now().microsecondsSinceEpoch;

    final avoidSection = _recentTitles.isNotEmpty
        ? '\n\nDU DARFST NICHT diese Rezepte wiederholen: ${_recentTitles.take(20).join(", ")}.'
        : '';

    return 'UNIQUE-SEED: $seed-$ts\n'
        'Erstelle EXAKT 3 Rezepte – jedes aus einer ANDEREN Küche:\n'
        '  Rezept 1: $cuisine1-Küche, Stil: $style\n'
        '  Rezept 2: $cuisine2-Küche, Technik: $technique\n'
        '  Rezept 3: $cuisine3-Küche, Typ: $mealType\n'
        'Wichtig: ALLE 3 müssen sich stark voneinander unterscheiden!\n'
        'Vermeide diese Klischée-Rezepte: Pasta Bolognese, Schnitzel, Rührei, '
        'Tomatensuppe, Spaghetti Carbonara, Pfannkuchen, Omelett, Avocado-Toast.'
        '$avoidSection';
  }

  Future<String> generateRecipes(List<String> ingredients) => _send('''
Du bist ein kreativer Koch-Assistent. Schlage 3 VERSCHIEDENE Rezepte vor, die mit folgenden Zutaten gekocht werden können.
${_randomHint()}
Antworte NUR im folgenden JSON-Format ohne Markdown-Codeblöcke:
$_jsonFormat

Vorhandene Zutaten: ${ingredients.join(', ')}
''');

  Future<String> generateRecipesFromPrompt(String userPrompt) => _send('''
Du bist ein kreativer Koch-Assistent. Der Benutzer möchte folgendes: "$userPrompt"
${_randomHint()}
Schlage 3 passende, ABWECHSLUNGSREICHE Rezepte vor.
Antworte NUR im folgenden JSON-Format ohne Markdown-Codeblöcke:
$_jsonFormat
''');

  Future<String> generateRecipesFromSelection(
    List<String> ingredients, {
    String? additionalPrompt,
  }) =>
      _send('''
Du bist ein kreativer Koch-Assistent. Schlage 3 KREATIVE und VERSCHIEDENE Rezepte vor, die hauptsächlich diese Zutaten verwenden.
${_randomHint()}
Antworte NUR im folgenden JSON-Format ohne Markdown-Codeblöcke:
$_jsonFormat

Zutaten: ${ingredients.join(', ')}${additionalPrompt != null ? '\nWunsch: $additionalPrompt' : ''}
''');

  Future<String> _send(String prompt) async {
    final chat = _chat();
    final (response, _) = await chat.sendMessage(prompt);
    return response.choices.first.message;
  }

  /// Generiert Meal-Prep Rezepte die sich gut vorkochen lassen.
  Future<String> generateMealPrepRecipes(List<String> ingredients) => _send('''
Du bist ein Meal-Prep-Experte. Schlage 3 Rezepte vor, die sich perfekt zum Vorkochen für die ganze Woche eignen.
${_randomHint()}
Die Rezepte sollten:
- Gut 3-5 Tage im Kühlschrank haltbar sein
- Sich einfach in Portionen aufteilen lassen
- Nahrhaft und sättigend sein

Antworte NUR im folgenden JSON-Format ohne Markdown-Codeblöcke:
$_jsonFormat

Vorhandene Zutaten: ${ingredients.join(', ')}
''');

  /// Generiert einen kompletten 7-Tage-Wochenplan basierend auf Ernährungsprofil.
  Future<String> generateMealPlan({
    int? calorieGoal,
    String? goal,
    List<String>? availableIngredients,
  }) => _send('''
Du bist ein Ernährungsexperte und kreativer Koch. Erstelle einen abwechslungsreichen 7-Tage-Mahlzeitenplan.
${_randomHint()}

${calorieGoal != null ? 'Tagesziel: ca. $calorieGoal kcal' : ''}
${goal != null ? 'Ziel: $goal' : ''}
${availableIngredients != null && availableIngredients.isNotEmpty ? 'Vorhandene Zutaten bevorzugen: ${availableIngredients.join(", ")}' : ''}

Antworte NUR im folgenden JSON-Format ohne Markdown-Codeblöcke:
{
  "days": [
    {
      "dayIndex": 0,
      "meals": [
        {
          "slot": "breakfast",
          "recipe": {
            "title": "Rezeptname",
            "description": "Kurze Beschreibung",
            "cookingTimeMinutes": 15,
            "difficulty": "Einfach",
            "servings": 2,
            "ingredients": [{"name": "Zutat", "amount": "200g"}],
            "steps": ["Schritt 1"],
            "nutrition": {"calories": 350, "protein": 20.0, "carbs": 40.0, "fat": 10.0, "fiber": 5.0}
          }
        },
        {"slot": "lunch", "recipe": {...}},
        {"slot": "dinner", "recipe": {...}}
      ]
    }
  ]
}

Erstelle genau 7 Tage (dayIndex 0-6, Mo-So), je 3 Mahlzeiten (breakfast, lunch, dinner).
Achte auf Abwechslung und ausgewogene Ernährung!
''');
}
