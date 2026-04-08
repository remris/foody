import 'dart:math';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/models/household.dart';

class HouseholdRepository {
  final _client = SupabaseService.client;

  /// Haushalt des Users laden (der erste dem er angehört).
  Future<Household?> getHousehold(String userId) async {
    final memberData = await _client
        .from('household_members')
        .select('household_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (memberData == null) return null;

    final householdData = await _client
        .from('households')
        .select()
        .eq('id', memberData['household_id'] as String)
        .single();

    return Household.fromJson(householdData);
  }

  /// Alle Mitglieder eines Haushalts laden.
  Future<List<HouseholdMember>> getMembers(String householdId) async {
    final data = await _client
        .from('household_members')
        .select()
        .eq('household_id', householdId)
        .order('joined_at', ascending: true);
    return (data as List).map((e) => HouseholdMember.fromJson(e)).toList();
  }

  /// Neuen Haushalt erstellen.
  Future<Household> createHousehold(String name, String userId) async {
    final inviteCode = _generateInviteCode();

    final data = await _client
        .from('households')
        .insert({
          'name': name,
          'created_by': userId,
          'invite_code': inviteCode,
        })
        .select()
        .single();

    final household = Household.fromJson(data);

    // Ersteller als Admin hinzufügen
    await _client.from('household_members').insert({
      'household_id': household.id,
      'user_id': userId,
      'role': 'admin',
    });

    return household;
  }

  /// Per Einladungscode den Haushalt SUCHEN (ohne beizutreten).
  /// Nutzt security-definer Funktion → kein RLS-Problem für Nicht-Mitglieder.
  Future<Household?> findByInviteCode(String code) async {
    final data = await _client
        .rpc('get_household_by_invite_code', params: {'code': code.trim().toUpperCase()})
        .maybeSingle();
    if (data == null) return null;
    return Household.fromJson(data as Map<String, dynamic>);
  }

  /// Per Einladungscode beitreten (nur noch intern, nach Admin-Genehmigung).
  Future<Household?> joinByInviteCode(String code, String userId) async {
    // Haushalt über security-definer Funktion finden (umgeht RLS)
    final household = await findByInviteCode(code);
    if (household == null) return null;

    // Prüfen ob User bereits Mitglied ist
    final existing = await _client
        .from('household_members')
        .select('id')
        .eq('household_id', household.id)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) return household;

    await _client.from('household_members').insert({
      'household_id': household.id,
      'user_id': userId,
      'role': 'member',
    });

    return household;
  }

  // ── Join Requests ────────────────────────────────────────────────────────

  /// Beitrittsanfrage stellen.
  Future<void> sendJoinRequest({
    required String householdId,
    required String userId,
    required String displayName,
  }) async {
    // Prüfen ob bereits eine Anfrage existiert
    final existing = await _client
        .from('household_join_requests')
        .select('id, status')
        .eq('household_id', householdId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Bereits vorhanden → auf pending zurücksetzen (z.B. nach Ablehnung)
      await _client
          .from('household_join_requests')
          .update({'status': 'pending', 'display_name': displayName})
          .eq('id', existing['id'] as String);
    } else {
      // Neu anlegen
      await _client.from('household_join_requests').insert({
        'household_id': householdId,
        'user_id': userId,
        'display_name': displayName,
        'status': 'pending',
      });
    }
  }

  /// Offene Anfragen für einen Haushalt laden (nur für Admins).
  Future<List<HouseholdJoinRequest>> getPendingRequests(String householdId) async {
    final data = await _client
        .from('household_join_requests')
        .select()
        .eq('household_id', householdId)
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return (data as List).map((e) => HouseholdJoinRequest.fromJson(e)).toList();
  }

  /// Eigene Anfrage-Status prüfen.
  Future<String?> getMyRequestStatus(String householdId, String userId) async {
    final data = await _client
        .from('household_join_requests')
        .select('status')
        .eq('household_id', householdId)
        .eq('user_id', userId)
        .maybeSingle();
    return data?['status'] as String?;
  }

  /// Anfrage annehmen → Mitglied hinzufügen (via security-definer Funktion).
  Future<void> acceptRequest(HouseholdJoinRequest request) async {
    await _client.rpc('accept_join_request', params: {'request_id': request.id});
  }

  /// Anfrage ablehnen.
  Future<void> rejectRequest(String requestId) async {
    await _client
        .from('household_join_requests')
        .update({'status': 'rejected'})
        .eq('id', requestId);
  }

  /// Anzahl der Mitglieder eines Haushalts.
  Future<int> getMemberCount(String householdId) async {
    final data = await _client
        .from('household_members')
        .select('id')
        .eq('household_id', householdId);
    return (data as List).length;
  }

  /// Haushalt verlassen.
  Future<void> leaveHousehold(String householdId, String userId) async {
    await _client
        .from('household_members')
        .delete()
        .eq('household_id', householdId)
        .eq('user_id', userId);

    // Wenn keine Mitglieder mehr → Haushalt löschen
    final remaining = await _client
        .from('household_members')
        .select('id')
        .eq('household_id', householdId);

    if ((remaining as List).isEmpty) {
      await _client.from('households').delete().eq('id', householdId);
    }
  }

  /// Mitglied entfernen (nur für Admins).
  Future<void> removeMember(String memberId) async {
    await _client.from('household_members').delete().eq('id', memberId);
  }

  /// Haushalt komplett auflösen (alle Mitglieder + Haushalt löschen).
  Future<void> dissolveHousehold(String householdId) async {
    await _client
        .from('household_members')
        .delete()
        .eq('household_id', householdId);
    await _client.from('households').delete().eq('id', householdId);
  }

  /// Einladungscode neu generieren.
  Future<String> regenerateInviteCode(String householdId) async {
    final code = _generateInviteCode();
    await _client
        .from('households')
        .update({'invite_code': code}).eq('id', householdId);
    return code;
  }

  /// Admin: Haushalt-Feature-Einstellungen aktualisieren.
  Future<void> updateSettings(
    String householdId, {
    bool? sharedInventory,
    bool? sharedShoppingList,
    bool? sharedMealPlan,
  }) async {
    final updates = <String, dynamic>{};
    if (sharedInventory != null) updates['shared_inventory'] = sharedInventory;
    if (sharedShoppingList != null) updates['shared_shopping_list'] = sharedShoppingList;
    if (sharedMealPlan != null) updates['shared_meal_plan'] = sharedMealPlan;
    if (updates.isEmpty) return;
    await _client.from('households').update(updates).eq('id', householdId);
  }

  /// 6-stelligen Einladungscode generieren.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

