import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kokomu/core/services/notification_service.dart';
import 'package:kokomu/core/services/profanity_filter.dart';
import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/household/presentation/household_provider.dart';
import 'package:kokomu/features/profile/presentation/profile_provider.dart';
import 'package:kokomu/models/household.dart';

// ── Modell ────────────────────────────────────────────────────────────────

class HouseholdMessage {
  final String id;
  final String householdId;
  final String userId;
  final String senderName;
  final String content;
  final String? emoji;       // optionales Emoji z.B. 🛒 📌
  final bool isSystem;       // System-Nachrichten (z.B. "X hat den Haushalt verlassen")
  final DateTime createdAt;

  const HouseholdMessage({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.senderName,
    required this.content,
    this.emoji,
    this.isSystem = false,
    required this.createdAt,
  });

  factory HouseholdMessage.fromJson(Map<String, dynamic> json) =>
      HouseholdMessage(
        id: json['id'] as String,
        householdId: json['household_id'] as String,
        userId: json['user_id'] as String,
        senderName: json['sender_name'] as String? ?? 'Mitglied',
        content: json['content'] as String,
        emoji: json['emoji'] as String?,
        isSystem: json['is_system'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'household_id': householdId,
        'user_id': userId,
        'sender_name': senderName,
        'content': content,
        'emoji': emoji,
        'is_system': isSystem,
      };

  bool get isFromCurrentUser =>
      userId == SupabaseService.currentUserId;

  String get timeFormatted {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return '${createdAt.day}.${createdAt.month}.';
  }
}

// ── Quick-Message-Vorlagen ────────────────────────────────────────────────

const kQuickMessages = [
  ('🛒', 'Ich gehe einkaufen'),
  ('🥛', 'Bitte Milch kaufen'),
  ('🍞', 'Bitte Brot kaufen'),
  ('🥚', 'Wir brauchen Eier'),
  ('✅', 'Einkauf erledigt'),
  ('🍳', 'Ich koche heute'),
  ('🍕', 'Wir bestellen heute'),
  ('⚠️', 'Etwas läuft bald ab'),
];

// ── Provider ──────────────────────────────────────────────────────────────

class HouseholdChatNotifier
    extends AsyncNotifier<List<HouseholdMessage>> {
  RealtimeChannel? _channel;

  @override
  Future<List<HouseholdMessage>> build() async {
    final household = ref.watch(householdProvider).valueOrNull;
    if (household == null) return [];

    _subscribeRealtime(household.id);

    // Channel beim Dispose sauber abmelden
    ref.onDispose(() {
      if (_channel != null) {
        SupabaseService.client.removeChannel(_channel!);
        _channel = null;
      }
    });

    return _fetchMessages(household.id);
  }

  Future<List<HouseholdMessage>> _fetchMessages(String householdId) async {
    try {
      final data = await SupabaseService.client
          .from('household_messages')
          .select()
          .eq('household_id', householdId)
          .order('created_at', ascending: false)
          .limit(100);
      return (data as List)
          .map((e) => HouseholdMessage.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  void _subscribeRealtime(String householdId) {
    // Alten Channel sauber entfernen
    if (_channel != null) {
      SupabaseService.client.removeChannel(_channel!);
      _channel = null;
    }

    // Eindeutiger Channel-Name verhindert Duplikate
    _channel = SupabaseService.client
        .channel('household_chat_${householdId}_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'household_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'household_id',
            value: householdId,
          ),
          callback: (payload) async {
            final newMsg = HouseholdMessage.fromJson(
                payload.newRecord);
            final current = state.valueOrNull ?? [];

            // Bereits vorhanden (echte UUID)?
            if (current.any((m) => m.id == newMsg.id)) return;

            // Eigene optimistisch eingefügte Nachricht (temp-ID) ersetzen
            if (newMsg.isFromCurrentUser) {
              final withoutTemp = current
                  .where((m) => !(m.id.length <= 15 && m.content == newMsg.content))
                  .toList();
              state = AsyncData([newMsg, ...withoutTemp]);
              return;
            }

            state = AsyncData([newMsg, ...current]);

            // Push-Notification für fremde Nachricht
            if (!newMsg.isSystem) {
              await NotificationService.showHouseholdMessage(
                senderName: newMsg.senderName,
                message: newMsg.content,
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> sendMessage(String content, {String? emoji}) async {
    final household = ref.read(householdProvider).valueOrNull;
    final user = ref.read(currentUserProvider);
    if (household == null || user == null) return;

    // ── Profanity-Filter ──────────────────────────────────────────────────
    final filterError = ProfanityFilter.validate(content);
    if (filterError != null) {
      throw ProfanityException(filterError);
    }

    // Ermittle Display-Name aus Mitgliederliste
    final members = ref.read(householdMembersProvider).valueOrNull ?? [];
    final me = members.firstWhere(
      (m) => m.userId == user.id,
      orElse: () => HouseholdMember(
        id: '', householdId: household.id,
        userId: user.id, role: 'member',
        displayName: user.email?.split('@').first ?? 'Ich',
        joinedAt: DateTime.now(),
      ),
    );

    // Spitzname bevorzugen: household_members.display_name
    // → dann ownProfile.householdNickname → dann ownProfile.displayName → email
    final ownProfile = ref.read(ownProfileProvider).valueOrNull;
    final senderName = (me.displayName != null && me.displayName!.isNotEmpty)
        ? me.displayName!
        : (ownProfile?.householdNickname?.isNotEmpty == true)
            ? ownProfile!.householdNickname!
            : (ownProfile?.displayName.isNotEmpty == true)
                ? ownProfile!.displayName
                : user.email?.split('@').first ?? 'Ich';

    // temp-ID: kurze numerische Zeichenkette (max 15 Zeichen)
    final tempId = '${DateTime.now().millisecondsSinceEpoch % 100000}';

    final msg = HouseholdMessage(
      id: tempId,
      householdId: household.id,
      userId: user.id,
      senderName: senderName,
      content: content,
      emoji: emoji,
      createdAt: DateTime.now(),
    );

    // Optimistisches Update
    final current = state.valueOrNull ?? [];
    state = AsyncData([msg, ...current]);

    try {
      await SupabaseService.client
          .from('household_messages')
          .insert(msg.toJson());
      // Kurz warten – wenn Realtime innerhalb 800ms feuert, hat er schon ersetzt.
      // Danach laden wir neu als Fallback (Realtime ggf. nicht aktiviert).
      await Future.delayed(const Duration(milliseconds: 800));
      final fresh = await _fetchMessages(household.id);
      state = AsyncData(fresh);
    } catch (e, st) {
      // Rollback der optimistischen Nachricht
      state = AsyncData(current);
      // Detailliertes Logging damit der Fehler sichtbar wird
      // ignore: avoid_print
      print('[HouseholdChat] sendMessage Fehler: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await SupabaseService.client
          .from('household_messages')
          .delete()
          .eq('id', messageId);
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.where((m) => m.id != messageId).toList());
    } catch (_) {}
  }

  Future<void> refresh() async {
    final household = ref.read(householdProvider).valueOrNull;
    if (household == null) return;
    state = AsyncData(await _fetchMessages(household.id));
  }
}

final householdChatProvider =
    AsyncNotifierProvider<HouseholdChatNotifier, List<HouseholdMessage>>(
  HouseholdChatNotifier.new,
);

/// Wird geworfen wenn der Profanity-Filter anschlägt.
class ProfanityException implements Exception {
  final String message;
  const ProfanityException(this.message);
  @override
  String toString() => message;
}
