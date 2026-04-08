import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:groq_sdk/groq_sdk.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';

/// Eine einzelne Chat-Nachricht.
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

/// State für den KI-Chat-Assistenten.
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) =>
      AiChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AiChatNotifier extends Notifier<AiChatState> {
  GroqChat? _chat;

  @override
  AiChatState build() => const AiChatState();

  GroqChat _getOrCreateChat(List<String> inventoryItems) {
    if (_chat != null) return _chat!;
    final key = dotenv.env['GROQ_API_KEY'] ?? '';
    if (key.isEmpty) throw Exception('GROQ_API_KEY nicht gesetzt');

    _chat = Groq(key).startNewChat(
      'llama3-70b-8192',
      settings: GroqChatSettings(
        temperature: 0.8,
        maxTokens: 1024,
      ),
    );
    return _chat!;
  }

  /// Baut den System-Kontext als ersten unsichtbaren Prompt
  String _buildSystemContext(List<String> inventoryItems) {
    final inventoryContext = inventoryItems.isEmpty
        ? 'Kein Vorrat vorhanden.'
        : 'Vorhandene Zutaten im Vorrat: ${inventoryItems.take(30).join(', ')}.';
    return 'Du bist ein freundlicher Küchen-Assistent für die App Kokomi. '
        'Du hilfst dem User beim Kochen, gibst Rezeptvorschläge und Küchentipps. '
        'Antworte immer auf Deutsch, kurz und hilfreich. '
        '$inventoryContext '
        'Wenn der User fragt was er kochen soll, schlage konkrete Gerichte vor. '
        'Jetzt antworte auf die Anfrage des Users:';
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    final inventoryItems = ref
        .read(inventoryProvider)
        .valueOrNull
        ?.map((e) => e.ingredientName)
        .toList() ?? [];

    // User-Nachricht hinzufügen
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          content: userText.trim(),
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: true,
      error: null,
    );

    try {
      final chat = _getOrCreateChat(inventoryItems);
      // Beim ersten User-Message den System-Kontext voranstellen
      final isFirstMessage = state.messages.length == 1; // nur User-Msg drin
      final messageToSend = isFirstMessage
          ? '${_buildSystemContext(inventoryItems)}\n\nUser: ${userText.trim()}'
          : userText.trim();
      final (response, _) = await chat.sendMessage(messageToSend);
      final reply = response.choices.first.message;

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            content: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler: $e',
        messages: [
          ...state.messages,
          ChatMessage(
            content: '❌ Fehler beim Senden: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      );
    }
  }

  void clearChat() {
    _chat = null;
    state = const AiChatState();
  }
}

final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);

