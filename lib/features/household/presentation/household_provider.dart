import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/core/services/notification_service.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/household/data/household_repository.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/models/household.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Aktivitätslog-Eintrag
class ActivityLogEntry {
  final String id;
  final String householdId;
  final String userId;
  final String displayName;
  final String action;
  final String itemType;
  final String itemName;
  final DateTime createdAt;

  const ActivityLogEntry({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.displayName,
    required this.action,
    required this.itemType,
    required this.itemName,
    required this.createdAt,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) =>
      ActivityLogEntry(
        id: json['id'] as String,
        householdId: json['household_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String? ?? 'Unbekannt',
        action: json['action'] as String,
        itemType: json['item_type'] as String,
        itemName: json['item_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get actionLabel {
    switch (action) {
      case 'added':
        return 'hinzugefügt';
      case 'updated':
        return 'bearbeitet';
      case 'deleted':
        return 'entfernt';
      case 'checked':
        return 'abgehakt';
      case 'unchecked':
        return 'wieder offen';
      default:
        return action;
    }
  }

  String get typeLabel {
    return itemType == 'inventory' ? 'Vorrat' : 'Einkaufsliste';
  }

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tag${diff.inDays == 1 ? '' : 'en'}';
    return 'vor ${diff.inDays ~/ 7} Woche${diff.inDays ~/ 7 == 1 ? '' : 'n'}';
  }
}

/// Lädt die letzten 50 Aktivitäts-Einträge für den aktuellen Haushalt.
final householdActivityProvider =
    FutureProvider<List<ActivityLogEntry>>((ref) async {
  final household = ref.watch(householdProvider).valueOrNull;
  if (household == null) return [];
  try {
    final data = await Supabase.instance.client
        .from('household_activity_log')
        .select()
        .eq('household_id', household.id)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((e) => ActivityLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

/// Protokolliert eine Aktivität im Haushalt (fire-and-forget, kein Fehler wenn kein Haushalt).
/// Löst zusätzlich eine Push-Benachrichtigung aus (nur für Haushaltsmitglieder, nicht den Autor selbst).
Future<void> logHouseholdActivity({
  required String householdId,
  required String userId,
  required String displayName,
  required String action,
  required String itemType,
  required String itemName,
  bool sendNotification = true,
}) async {
  try {
    await Supabase.instance.client.from('household_activity_log').insert({
      'household_id': householdId,
      'user_id': userId,
      'display_name': displayName,
      'action': action,
      'item_type': itemType,
      'item_name': itemName,
    });

    // Push-Benachrichtigung für Haushalt-Änderungen
    if (sendNotification) {
      final actionLabel = switch (action) {
        'added' => 'hinzugefügt',
        'updated' => 'bearbeitet',
        'deleted' => 'entfernt',
        _ => action,
      };
      final typeEmoji = itemType == 'inventory' ? '🥕' : '🛒';
      await NotificationService.showHouseholdActivity(
        title: '$typeEmoji $displayName',
        body: '„$itemName" $actionLabel',
      );
    }
  } catch (_) {
    // Kein Fehler werfen – Aktivitätslog ist optional
  }
}

final householdRepoProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository();
});

/// Aktueller Haushalt des Users.
class HouseholdNotifier extends AsyncNotifier<Household?> {
  @override
  Future<Household?> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return null;
    return ref.read(householdRepoProvider).getHousehold(userId);
  }

  Future<void> createHousehold(String name) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(householdRepoProvider).createHousehold(name, userId),
    );
  }

  /// Beitrittsanfrage per Code stellen (kein direkter Beitritt mehr).
  /// Gibt null bei Erfolg zurück, sonst Fehlermeldung.
  Future<String?> requestToJoin(String code, String displayName) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return 'Nicht angemeldet';

    final repo = ref.read(householdRepoProvider);

    // Haushalt suchen (security-definer → kein RLS-Problem)
    final household = await repo.findByInviteCode(code);
    if (household == null) return 'Ungültiger Code';

    // Bereits Mitglied?
    final members = await repo.getMembers(household.id);
    if (members.any((m) => m.userId == userId)) {
      state = AsyncData(household);
      return null; // Bereits Mitglied → direkt setzen
    }

    // Bereits eine Anfrage gestellt?
    final existingStatus = await repo.getMyRequestStatus(household.id, userId);
    if (existingStatus == 'pending') {
      return 'Du hast bereits eine offene Anfrage für diesen Haushalt.';
    }
    if (existingStatus == 'rejected') {
      return 'Deine Anfrage wurde abgelehnt.';
    }

    // Anfrage senden
    await repo.sendJoinRequest(
      householdId: household.id,
      userId: userId,
      displayName: displayName,
    );

    return null; // Erfolg = Anfrage gesendet
  }

  Future<void> acceptJoinRequest(HouseholdJoinRequest request) async {
    final repo = ref.read(householdRepoProvider);
    await repo.acceptRequest(request);
    ref.invalidate(householdMembersProvider);
    // pendingJoinRequestsProvider wird vom Screen selbst refresht
  }

  Future<void> rejectJoinRequest(String requestId) async {
    final repo = ref.read(householdRepoProvider);
    await repo.rejectRequest(requestId);
    // pendingJoinRequestsProvider wird vom Screen selbst refresht
  }

  Future<void> leave() async {
    final userId = ref.read(currentUserProvider)?.id;
    final household = state.valueOrNull;
    if (userId == null || household == null) return;
    await ref.read(householdRepoProvider).leaveHousehold(household.id, userId);
    state = const AsyncData(null);
  }

  /// Admin: Mitglied rauswerfen (per member-Tabellen-ID).
  Future<void> removeMember(String memberId) async {
    await ref.read(householdRepoProvider).removeMember(memberId);
    ref.invalidate(householdMembersProvider);
  }

  /// Admin: Haushalt komplett auflösen.
  Future<void> dissolve() async {
    final household = state.valueOrNull;
    if (household == null) return;
    await ref.read(householdRepoProvider).dissolveHousehold(household.id);
    state = const AsyncData(null);
  }

  Future<String?> regenerateCode() async {
    final household = state.valueOrNull;
    if (household == null) return null;
    final code = await ref
        .read(householdRepoProvider)
        .regenerateInviteCode(household.id);
    state = AsyncData(household.copyWith(inviteCode: code));
    return code;
  }

  /// Admin: Feature-Toggle updaten und lokal sofort reflektieren.
  Future<void> updateSetting({
    bool? sharedInventory,
    bool? sharedShoppingList,
    bool? sharedMealPlan,
  }) async {
    final household = state.valueOrNull;
    if (household == null) return;
    await ref.read(householdRepoProvider).updateSettings(
          household.id,
          sharedInventory: sharedInventory,
          sharedShoppingList: sharedShoppingList,
          sharedMealPlan: sharedMealPlan,
        );
    state = AsyncData(household.copyWith(
      sharedInventory: sharedInventory ?? household.sharedInventory,
      sharedShoppingList: sharedShoppingList ?? household.sharedShoppingList,
      sharedMealPlan: sharedMealPlan ?? household.sharedMealPlan,
    ));
  }
}

final householdProvider =
    AsyncNotifierProvider<HouseholdNotifier, Household?>(
  HouseholdNotifier.new,
);

/// Mitglieder des aktuellen Haushalts.
final householdMembersProvider =
    FutureProvider<List<HouseholdMember>>((ref) async {
  final household = ref.watch(householdProvider).valueOrNull;
  if (household == null) return [];
  return ref.read(householdRepoProvider).getMembers(household.id);
});

/// Offene Beitrittsanfragen für einen Haushalt (family → kein circular dependency).
final pendingJoinRequestsProvider =
    FutureProvider.family<List<HouseholdJoinRequest>, String>((ref, householdId) async {
  return ref.read(householdRepoProvider).getPendingRequests(householdId);
});

/// Status der eigenen Beitrittsanfrage (wenn noch kein Mitglied).
/// Gibt 'pending', 'accepted', 'rejected' oder null zurück.
final myJoinRequestStatusProvider =
    FutureProvider.family<String?, String>((ref, householdId) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return ref.read(householdRepoProvider).getMyRequestStatus(householdId, userId);
});

