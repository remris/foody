import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kokomi/core/services/notification_service.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/household/presentation/household_provider.dart';
import 'package:kokomi/models/household.dart';

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
  StreamSubscription<dynamic>? _realtimeSub;

  @override
  Future<List<HouseholdMessage>> build() async {
    final household = ref.watch(householdProvider).valueOrNull;
    if (household == null) return [];

    _subscribeRealtime(household.id);
    ref.onDispose(() => _realtimeSub?.cancel());

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
    _realtimeSub?.cancel();
    SupabaseService.client
        .channel('household_chat_$householdId')
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
                payload.newRecord as Map<String, dynamic>);
            final current = state.valueOrNull ?? [];
            // Eigene Nachrichten nicht nochmal einfügen
            if (current.any((m) => m.id == newMsg.id)) return;
            state = AsyncData([newMsg, ...current]);

            // Push wenn Nachricht von anderem User
            if (!newMsg.isFromCurrentUser && !newMsg.isSystem) {
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

    // Ermittl Display-Name aus Mitgliederliste
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

    final msg = HouseholdMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // temp
      householdId: household.id,
      userId: user.id,
      senderName: me.displayName ?? user.email?.split('@').first ?? 'Ich',
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
    } catch (e) {
      // Rollback
      state = AsyncData(current);
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

