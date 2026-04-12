import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/models/community.dart';

class CommunityLocalRepository {
  final _client = SupabaseService.client;

  // ── Communities ─────────────────────────────────────────────────────────────

  /// Alle Communities des Users (active + pending).
  Future<List<Community>> getMyCommunities(String userId) async {
    final memberData = await _client
        .from('community_members')
        .select('community_id, status')
        .eq('user_id', userId)
        .inFilter('status', ['active', 'pending']);

    if ((memberData as List).isEmpty) return [];

    final ids = memberData.map((e) => e['community_id'] as String).toList();
    final statusMap = {
      for (final e in memberData) e['community_id'] as String: e['status'] as String,
    };

    final communities = await _client
        .from('communities')
        .select()
        .inFilter('id', ids);

    return (communities as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['my_status'] = statusMap[map['id']];
      return Community.fromJson(map);
    }).toList();
  }

  /// Community per PLZ suchen.
  Future<List<Community>> searchByPlz(String plz) async {
    final data = await _client
        .from('communities')
        .select()
        .eq('plz', plz.trim())
        .eq('is_public', true)
        .limit(20);
    return (data as List).map((e) => Community.fromJson(e)).toList();
  }

  /// Community per Einladungscode finden (security-definer, kein RLS-Problem).
  Future<Community?> findByInviteCode(String code) async {
    final data = await _client
        .rpc('get_community_by_invite_code', params: {'code': code.trim().toUpperCase()})
        .maybeSingle();
    if (data == null) return null;
    return Community.fromJson(data as Map<String, dynamic>);
  }

  /// Neue Community erstellen (Pro-Gate wird im Provider geprüft).
  Future<Community> createCommunity({
    required String adminId,
    required String name,
    String? description,
    String? plz,
    String? city,
  }) async {
    final inviteCode = Community.generateInviteCode();
    final data = await _client
        .from('communities')
        .insert({
          'name': name,
          'description': description,
          'plz': plz,
          'city': city,
          'invite_code': inviteCode,
          'admin_id': adminId,
        })
        .select()
        .single();

    final community = Community.fromJson(data);

    // Admin direkt als aktives Mitglied hinzufügen
    await _client.from('community_members').insert({
      'community_id': community.id,
      'user_id': adminId,
      'status': 'active',
      'joined_at': DateTime.now().toIso8601String(),
    });

    return community;
  }

  /// Beitrittsanfrage stellen.
  Future<void> sendJoinRequest({
    required String communityId,
    required String userId,
    required String displayName,
  }) async {
    // Prüfen ob bereits vorhanden
    final existing = await _client
        .from('community_members')
        .select('id, status')
        .eq('community_id', communityId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      if (existing['status'] == 'rejected') {
        // Erneut versuchen → zurücksetzen auf pending
        await _client
            .from('community_members')
            .update({'status': 'pending', 'display_name': displayName})
            .eq('id', existing['id'] as String);
      }
      // pending oder active → nichts tun
      return;
    }

    await _client.from('community_members').insert({
      'community_id': communityId,
      'user_id': userId,
      'display_name': displayName,
      'status': 'pending',
    });
  }

  /// Eigenen Mitgliedsstatus abfragen.
  Future<String?> getMyStatus(String communityId, String userId) async {
    final data = await _client
        .from('community_members')
        .select('status')
        .eq('community_id', communityId)
        .eq('user_id', userId)
        .maybeSingle();
    return data?['status'] as String?;
  }

  // ── Mitglieder-Verwaltung (Admin) ───────────────────────────────────────────

  Future<List<CommunityMember>> getMembers(String communityId) async {
    final data = await _client
        .from('community_members')
        .select()
        .eq('community_id', communityId)
        .inFilter('status', ['active', 'pending'])
        .order('joined_at', ascending: true);
    return (data as List).map((e) => CommunityMember.fromJson(e)).toList();
  }

  Future<void> acceptMember(String memberId) async {
    await _client
        .from('community_members')
        .update({'status': 'active', 'joined_at': DateTime.now().toIso8601String()})
        .eq('id', memberId);
  }

  Future<void> rejectMember(String memberId) async {
    await _client
        .from('community_members')
        .update({'status': 'rejected'})
        .eq('id', memberId);
  }

  Future<void> removeMember(String memberId) async {
    await _client.from('community_members').delete().eq('id', memberId);
  }

  Future<void> leaveCommunity(String communityId, String userId) async {
    await _client
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', userId);
  }

  Future<void> deleteCommunity(String communityId) async {
    await _client.from('communities').delete().eq('id', communityId);
  }

  Future<String> regenerateInviteCode(String communityId) async {
    final code = Community.generateInviteCode();
    await _client
        .from('communities')
        .update({'invite_code': code})
        .eq('id', communityId);
    return code;
  }

  // ── Posts ────────────────────────────────────────────────────────────────────

  Future<List<CommunityPost>> getPosts(String communityId) async {
    final data = await _client
        .from('community_posts')
        .select()
        .eq('community_id', communityId)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => CommunityPost.fromJson(e)).toList();
  }

  Future<CommunityPost> createPost({
    required String communityId,
    required String userId,
    required String content,
    required String authorName,
    String? recipeId,
    String? recipeTitle,
    String? mealPlanId,
    String? mealPlanTitle,
  }) async {
    final data = await _client
        .from('community_posts')
        .insert({
          'community_id': communityId,
          'user_id': userId,
          'content': content,
          'author_name': authorName,
          'recipe_id': recipeId,
          'recipe_title': recipeTitle,
          'meal_plan_id': mealPlanId,
          'meal_plan_title': mealPlanTitle,
        })
        .select()
        .single();
    return CommunityPost.fromJson(data);
  }

  Future<void> deletePost(String postId) async {
    await _client.from('community_posts').delete().eq('id', postId);
  }

  // ── Shares (Reste / Vorrat) ──────────────────────────────────────────────────

  Future<List<CommunityShare>> getShares(String communityId) async {
    final data = await _client
        .from('community_shares')
        .select()
        .eq('community_id', communityId)
        .eq('status', 'available')
        .order('created_at', ascending: false);
    return (data as List).map((e) => CommunityShare.fromJson(e)).toList();
  }

  Future<CommunityShare> offerShare({
    required String communityId,
    required String offeredBy,
    required String offeredByName,
    required String itemName,
    String? quantity,
    String? note,
  }) async {
    final data = await _client
        .from('community_shares')
        .insert({
          'community_id': communityId,
          'offered_by': offeredBy,
          'offered_by_name': offeredByName,
          'item_name': itemName,
          'quantity': quantity,
          'note': note,
        })
        .select()
        .single();
    return CommunityShare.fromJson(data);
  }

  /// Claim: setzt status auf 'claimed' → Supabase-Trigger löscht den Eintrag sofort.
  Future<void> claimShare({
    required String shareId,
    required String claimedBy,
    required String claimedByName,
  }) async {
    await _client.from('community_shares').update({
      'status': 'claimed',
      'claimed_by': claimedBy,
      'claimed_by_name': claimedByName,
      'claimed_at': DateTime.now().toIso8601String(),
    }).eq('id', shareId);
  }

  Future<void> deleteShare(String shareId) async {
    await _client.from('community_shares').delete().eq('id', shareId);
  }

  // ── Share Requests (Abholungsanfragen) ──────────────────────────────────────

  /// Alle Anfragen für ein Angebot laden (sieht der Angebots-Ersteller).
  Future<List<CommunityShareRequest>> getShareRequests(String shareId) async {
    final data = await _client
        .from('community_share_requests')
        .select()
        .eq('share_id', shareId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => CommunityShareRequest.fromJson(e)).toList();
  }

  /// Anfrage stellen (nur einmal pro User pro Angebot).
  Future<CommunityShareRequest> requestPickup({
    required String shareId,
    required String communityId,
    required String userId,
    required String displayName,
    String? message,
  }) async {
    // Prüfen ob bereits vorhanden
    final existing = await _client
        .from('community_share_requests')
        .select('id, status')
        .eq('share_id', shareId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      return CommunityShareRequest.fromJson(existing as Map<String, dynamic>);
    }
    final data = await _client
        .from('community_share_requests')
        .insert({
          'share_id': shareId,
          'community_id': communityId,
          'user_id': userId,
          'display_name': displayName,
          'message': message,
        })
        .select()
        .single();
    return CommunityShareRequest.fromJson(data);
  }

  /// Anfrage bestätigen (Angebots-Ersteller).
  Future<void> acceptShareRequest(String requestId) async {
    await _client
        .from('community_share_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);
  }

  /// Anfrage ablehnen.
  Future<void> rejectShareRequest(String requestId) async {
    await _client
        .from('community_share_requests')
        .update({'status': 'rejected'})
        .eq('id', requestId);
  }

  /// Anfrage zurückziehen (Anfragesteller löscht seine eigene Anfrage).
  Future<void> deleteShareRequest(String requestId) async {
    await _client
        .from('community_share_requests')
        .delete()
        .eq('id', requestId);
  }

  /// Eigene Anfrage für ein Angebot abfragen.
  Future<CommunityShareRequest?> getMyShareRequest(
      String shareId, String userId) async {
    final data = await _client
        .from('community_share_requests')
        .select()
        .eq('share_id', shareId)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return CommunityShareRequest.fromJson(data as Map<String, dynamic>);
  }

  // ── Help Requests (Suchanfragen) ─────────────────────────────────────────────

  Future<List<CommunityHelpRequest>> getHelpRequests(String communityId) async {
    final data = await _client
        .from('community_help_requests')
        .select()
        .eq('community_id', communityId)
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return (data as List).map((e) => CommunityHelpRequest.fromJson(e)).toList();
  }

  Future<CommunityHelpRequest> createHelpRequest({
    required String communityId,
    required String userId,
    required String displayName,
    required String itemName,
    String? quantity,
    String? note,
  }) async {
    final data = await _client
        .from('community_help_requests')
        .insert({
          'community_id': communityId,
          'user_id': userId,
          'display_name': displayName,
          'item_name': itemName,
          'quantity': quantity,
          'note': note,
        })
        .select()
        .single();
    return CommunityHelpRequest.fromJson(data);
  }

  Future<void> closeHelpRequest(String requestId) async {
    await _client
        .from('community_help_requests')
        .update({'status': 'closed'})
        .eq('id', requestId);
  }

  Future<void> deleteHelpRequest(String requestId) async {
    await _client
        .from('community_help_requests')
        .delete()
        .eq('id', requestId);
  }

  // ── Help Offers (Aushelfen-Angebote) ─────────────────────────────────────────

  Future<List<CommunityHelpOffer>> getHelpOffers(String requestId) async {
    final data = await _client
        .from('community_help_offers')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => CommunityHelpOffer.fromJson(e)).toList();
  }

  Future<CommunityHelpOffer> offerHelp({
    required String requestId,
    required String communityId,
    required String userId,
    required String displayName,
    String? message,
  }) async {
    // Prüfen ob bereits vorhanden
    final existing = await _client
        .from('community_help_offers')
        .select('id, status')
        .eq('request_id', requestId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      return CommunityHelpOffer.fromJson(existing as Map<String, dynamic>);
    }
    final data = await _client
        .from('community_help_offers')
        .insert({
          'request_id': requestId,
          'community_id': communityId,
          'user_id': userId,
          'display_name': displayName,
          'message': message,
        })
        .select()
        .single();
    return CommunityHelpOffer.fromJson(data);
  }

  Future<void> acceptHelpOffer(String offerId) async {
    await _client
        .from('community_help_offers')
        .update({'status': 'accepted'})
        .eq('id', offerId);
  }

  Future<void> deleteHelpOffer(String offerId) async {
    await _client.from('community_help_offers').delete().eq('id', offerId);
  }

  // ── Messages (Mini-Chat) ─────────────────────────────────────────────────────

  Future<List<CommunityMessage>> getMessages({
    required String contextType,
    required String contextId,
  }) async {
    final data = await _client
        .from('community_messages')
        .select()
        .eq('context_type', contextType)
        .eq('context_id', contextId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => CommunityMessage.fromJson(e)).toList();
  }

  Future<CommunityMessage> sendMessage({
    required String contextType,
    required String contextId,
    required String communityId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required String text,
  }) async {
    final data = await _client
        .from('community_messages')
        .insert({
          'context_type': contextType,
          'context_id': contextId,
          'community_id': communityId,
          'sender_id': senderId,
          'sender_name': senderName,
          'recipient_id': recipientId,
          'text': text,
        })
        .select()
        .single();
    return CommunityMessage.fromJson(data);
  }

  Future<void> markMessagesRead({
    required String contextType,
    required String contextId,
    required String userId,
  }) async {
    await _client
        .from('community_messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('context_type', contextType)
        .eq('context_id', contextId)
        .eq('recipient_id', userId)
        .isFilter('read_at', null);
  }

  /// Anzahl ungelesener Nachrichten des Users in einer Community.
  Future<int> getUnreadMessageCount(String userId, String communityId) async {
    final data = await _client
        .from('community_messages')
        .select('id')
        .eq('community_id', communityId)
        .eq('recipient_id', userId)
        .isFilter('read_at', null);
    return (data as List).length;
  }
}

