import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kokomi/core/constants/app_constants.dart';

class OpenAiService {
  // Dio-Instanz ohne festen Auth-Header – Key wird per Request gelesen
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.openAiBaseUrl,
    headers: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

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

  OpenAiService();

  /// Rezepte generieren basierend auf vorhandenen Zutaten.
  Future<String> generateRecipes(List<String> ingredients) async {
    final prompt = '''
Du bist ein Koch-Assistent. Schlage 3 Rezepte vor, die mit folgenden Zutaten gekocht werden können.
Antworte NUR im folgenden JSON-Format ohne Markdown-Codeblöcke:
$_jsonFormat

Die Nährwerte (nutrition) sind pro Portion geschätzt.

Vorhandene Zutaten: ${ingredients.join(', ')}
''';

    return _sendPrompt(prompt);
  }

  /// Rezepte generieren basierend auf einem Freitext-Prompt.
  Future<String> generateRecipesFromPrompt(String userPrompt) async {
    final prompt = '''
Du bist ein Koch-Assistent. Der Benutzer möchte folgendes: "$userPrompt"
Schlage 3 passende Rezepte vor.
Antworte NUR im folgenden JSON-Format ohne Markdown-Codeblöcke:
$_jsonFormat

Die Nährwerte (nutrition) sind pro Portion geschätzt.
''';

    return _sendPrompt(prompt);
  }

  /// Rezepte generieren basierend auf ausgewählten Zutaten + optionalem Wunsch.
  Future<String> generateRecipesFromSelection(
    List<String> selectedIngredients, {
    String? additionalPrompt,
  }) async {
    final extra = additionalPrompt != null && additionalPrompt.isNotEmpty
        ? '\nZusätzlicher Wunsch: $additionalPrompt'
        : '';

    final prompt = '''
Du bist ein Koch-Assistent. Schlage 3 Rezepte vor, die hauptsächlich diese ausgewählten Zutaten verwenden.
Antworte NUR im folgenden JSON-Format ohne Markdown-Codeblöcke:
$_jsonFormat

Die Nährwerte (nutrition) sind pro Portion geschätzt.

Ausgewählte Zutaten: ${selectedIngredients.join(', ')}$extra
''';

    return _sendPrompt(prompt);
  }

  Future<String> _sendPrompt(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty || apiKey == 'null') {
      throw Exception(
        'OpenAI API-Key nicht konfiguriert.\n'
        'Bitte OPENAI_API_KEY in der .env-Datei eintragen.',
      );
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
        data: {
          'model': AppConstants.openAiModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        },
      );

      final content =
          response.data['choices'][0]['message']['content'] as String;
      return content;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? '';

      if (status == 401) {
        // Exakte Fehlermeldung von OpenAI auslesen
        final message = (e.response?.data is Map)
            ? (e.response?.data['error']?['message'] as String? ?? body)
            : body;
        throw Exception('OpenAI 401: $message');
      } else if (status == 429) {
        throw Exception(
          'OpenAI Rate-Limit erreicht (429).\n'
          'Bitte kurz warten und erneut versuchen.',
        );
      } else if (status == 402) {
        throw Exception(
          'OpenAI Guthaben aufgebraucht (402).\n'
          'Bitte unter platform.openai.com Guthaben aufladen.',
        );
      }
      throw Exception('OpenAI Fehler ($status): ${e.message}\n$body');
    }
  }
}

