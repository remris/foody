import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/community/data/community_local_repository.dart';
import 'package:kokomu/features/profile/presentation/profile_provider.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/models/community.dart';

// ── Repository Provider ──────────────────────────────────────────────────────
final communityLocalRepoProvider = Provider<CommunityLocalRepository>(
  (_) => CommunityLocalRepository(),
);

// ── Meine Communities ────────────────────────────────────────────────────────
final myCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  return ref.read(communityLocalRepoProvider).getMyCommunities(userId);
});

// ── PLZ-Suche ────────────────────────────────────────────────────────────────
final communityPlzSearchProvider =
    FutureProvider.family<List<Community>, String>((ref, plz) async {
  if (plz.trim().isEmpty) return [];
  return ref.read(communityLocalRepoProvider).searchByPlz(plz.trim());
});

// ── Posts einer Community ────────────────────────────────────────────────────
final communityPostsProvider =
    FutureProvider.family<List<CommunityPost>, String>((ref, communityId) async {
  return ref.read(communityLocalRepoProvider).getPosts(communityId);
});

// ── Shares einer Community ───────────────────────────────────────────────────
final communitySharesProvider =
    FutureProvider.family<List<CommunityShare>, String>((ref, communityId) async {
  return ref.read(communityLocalRepoProvider).getShares(communityId);
});

// ── Mitglieder einer Community ───────────────────────────────────────────────
final communityMembersProvider =
    FutureProvider.family<List<CommunityMember>, String>((ref, communityId) async {
  return ref.read(communityLocalRepoProvider).getMembers(communityId);
});

// ── Share Requests (Abholungsanfragen für ein Angebot) ───────────────────────
final shareRequestsProvider =
    FutureProvider.family<List<CommunityShareRequest>, String>((ref, shareId) async {
  return ref.read(communityLocalRepoProvider).getShareRequests(shareId);
});

// ── Help Requests (Suchanfragen) ─────────────────────────────────────────────
final helpRequestsProvider =
    FutureProvider.family<List<CommunityHelpRequest>, String>((ref, communityId) async {
  return ref.read(communityLocalRepoProvider).getHelpRequests(communityId);
});

// ── Help Offers für eine Anfrage ─────────────────────────────────────────────
final helpOffersProvider =
    FutureProvider.family<List<CommunityHelpOffer>, String>((ref, requestId) async {
  return ref.read(communityLocalRepoProvider).getHelpOffers(requestId);
});

// ── Messages für einen Kontext ───────────────────────────────────────────────
class _MsgParams {
  final String type;
  final String id;
  const _MsgParams(this.type, this.id);
  @override
  bool operator ==(Object other) =>
      other is _MsgParams && other.type == type && other.id == id;
  @override
  int get hashCode => Object.hash(type, id);
}

final communityMessagesProvider =
    FutureProvider.family<List<CommunityMessage>, _MsgParams>((ref, p) async {
  return ref.read(communityLocalRepoProvider).getMessages(
        contextType: p.type,
        contextId: p.id,
      );
});

/// Hilfsfunktion um Provider für Messages zu bauen
_MsgParams msgParams(String type, String id) => _MsgParams(type, id);

// ── Community-Aktionen Notifier ──────────────────────────────────────────────
class CommunityActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  CommunityLocalRepository get _repo =>
      ref.read(communityLocalRepoProvider);

  String get _userId => ref.read(currentUserProvider)?.id ?? '';
  String get _displayName {
    // 1. Spitzname (householdNickname) – für Community & Haushalt
    final profile = ref.read(ownProfileProvider).valueOrNull;
    if (profile != null && (profile.householdNickname?.isNotEmpty == true)) {
      return profile.householdNickname!;
    }
    // 2. Anzeigename (displayName)
    if (profile != null && profile.displayName.isNotEmpty) {
      return profile.displayName;
    }
    // 3. Fallback: Auth-Metadata
    final meta = ref.read(currentUserProvider)?.userMetadata?['display_name'] as String?;
    if (meta != null && meta.isNotEmpty) return meta;
    // 4. Fallback: Email-Prefix
    return ref.read(currentUserProvider)?.email?.split('@').first ?? 'Du';
  }

  /// Community erstellen – nur mit Pro.
  Future<Community?> createCommunity({
    required String name,
    String? description,
    String? plz,
    String? city,
  }) async {
    if (_userId.isEmpty) return null;

    final isPro = ref.read(isProProvider);
    if (!isPro) {
      throw Exception('pro_required');
    }

    state = const AsyncLoading();
    try {
      final community = await _repo.createCommunity(
        adminId: _userId,
        name: name,
        description: description,
        plz: plz,
        city: city,
      );
      ref.invalidate(myCommunitiesProvider);
      state = const AsyncData(null);
      return community;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Beitrittsanfrage per Code oder nach PLZ-Suche.
  Future<String?> requestToJoin(Community community, String displayName) async {
    if (_userId.isEmpty) return 'Nicht angemeldet';

    if (community.isFull) {
      return 'Community ist voll (max. ${community.maxMembers} Mitglieder)';
    }

    await _repo.sendJoinRequest(
      communityId: community.id,
      userId: _userId,
      displayName: displayName,
    );
    ref.invalidate(myCommunitiesProvider);
    return null;
  }

  /// Admin: Beitritt annehmen.
  Future<void> acceptMember(String memberId, String communityId) async {
    await _repo.acceptMember(memberId);
    ref.invalidate(communityMembersProvider(communityId));
  }

  /// Admin: Beitritt ablehnen.
  Future<void> rejectMember(String memberId, String communityId) async {
    await _repo.rejectMember(memberId);
    ref.invalidate(communityMembersProvider(communityId));
  }

  /// Admin: Mitglied entfernen.
  Future<void> removeMember(String memberId, String communityId) async {
    await _repo.removeMember(memberId);
    ref.invalidate(communityMembersProvider(communityId));
  }

  /// Community verlassen.
  Future<void> leaveCommunity(String communityId) async {
    if (_userId.isEmpty) return;
    await _repo.leaveCommunity(communityId, _userId);
    ref.invalidate(myCommunitiesProvider);
  }

  /// Admin: Community löschen.
  Future<void> deleteCommunity(String communityId) async {
    await _repo.deleteCommunity(communityId);
    ref.invalidate(myCommunitiesProvider);
  }

  /// Admin: Einladungscode neu generieren.
  Future<String> regenerateCode(String communityId) async {
    final code = await _repo.regenerateInviteCode(communityId);
    ref.invalidate(myCommunitiesProvider);
    return code;
  }

  // ── Posts ──────────────────────────────────────────────────────────────────

  Future<void> createPost({
    required String communityId,
    required String content,
    String? recipeId,
    String? recipeTitle,
    String? mealPlanId,
    String? mealPlanTitle,
  }) async {
    if (_userId.isEmpty) return;
    await _repo.createPost(
      communityId: communityId,
      userId: _userId,
      content: content,
      authorName: _displayName,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      mealPlanId: mealPlanId,
      mealPlanTitle: mealPlanTitle,
    );
    ref.invalidate(communityPostsProvider(communityId));
  }

  Future<void> deletePost(String postId, String communityId) async {
    await _repo.deletePost(postId);
    ref.invalidate(communityPostsProvider(communityId));
  }

  // ── Shares ─────────────────────────────────────────────────────────────────

  Future<void> offerShare({
    required String communityId,
    required String itemName,
    String? quantity,
    String? note,
    String offeredByName = '',
  }) async {
    if (_userId.isEmpty) return;
    final name = offeredByName.isNotEmpty ? offeredByName : _displayName;
    await _repo.offerShare(
      communityId: communityId,
      offeredBy: _userId,
      offeredByName: name,
      itemName: itemName,
      quantity: quantity,
      note: note,
    );
    ref.invalidate(communitySharesProvider(communityId));
  }

  /// Abholen anfragen (für fremde Angebote).
  Future<void> requestPickup({
    required String shareId,
    required String communityId,
    String? message,
  }) async {
    if (_userId.isEmpty) return;
    await _repo.requestPickup(
      shareId: shareId,
      communityId: communityId,
      userId: _userId,
      displayName: _displayName,
      message: message,
    );
    ref.invalidate(shareRequestsProvider(shareId));
  }

  /// Anfrage bestätigen (Angebots-Ersteller).
  Future<void> acceptShareRequest({
    required String requestId,
    required String shareId,
    required String communityId,
  }) async {
    await _repo.acceptShareRequest(requestId);
    ref.invalidate(shareRequestsProvider(shareId));
    ref.invalidate(communitySharesProvider(communityId));
  }

  /// Anfrage ablehnen.
  Future<void> rejectShareRequest({
    required String requestId,
    required String shareId,
  }) async {
    await _repo.rejectShareRequest(requestId);
    ref.invalidate(shareRequestsProvider(shareId));
  }

  /// Anfrage zurückziehen.
  Future<void> deleteShareRequest({
    required String requestId,
    required String shareId,
  }) async {
    await _repo.deleteShareRequest(requestId);
    ref.invalidate(shareRequestsProvider(shareId));
  }

  /// Angebot als abgeholt markieren und löschen.
  Future<void> markSharePickedUp({
    required String shareId,
    required String communityId,
  }) async {
    await _repo.deleteShare(shareId);
    ref.invalidate(communitySharesProvider(communityId));
  }

  /// Claim → Eintrag verschwindet sofort (alter Flow, bleibt für Rückwärtskompatibilität).
  Future<void> claimShare({
    required String shareId,
    required String communityId,
    String claimedByName = '',
  }) async {
    if (_userId.isEmpty) return;
    await _repo.claimShare(
      shareId: shareId,
      claimedBy: _userId,
      claimedByName: claimedByName.isNotEmpty ? claimedByName : _displayName,
    );
    ref.invalidate(communitySharesProvider(communityId));
  }

  Future<void> deleteShare(String shareId, String communityId) async {
    await _repo.deleteShare(shareId);
    ref.invalidate(communitySharesProvider(communityId));
  }

  // ── Help Requests (Suchanfragen) ───────────────────────────────────────────

  Future<void> createHelpRequest({
    required String communityId,
    required String itemName,
    String? quantity,
    String? note,
  }) async {
    if (_userId.isEmpty) return;
    await _repo.createHelpRequest(
      communityId: communityId,
      userId: _userId,
      displayName: _displayName,
      itemName: itemName,
      quantity: quantity,
      note: note,
    );
    ref.invalidate(helpRequestsProvider(communityId));
  }

  Future<void> closeHelpRequest(String requestId, String communityId) async {
    await _repo.closeHelpRequest(requestId);
    ref.invalidate(helpRequestsProvider(communityId));
  }

  Future<void> deleteHelpRequest(String requestId, String communityId) async {
    await _repo.deleteHelpRequest(requestId);
    ref.invalidate(helpRequestsProvider(communityId));
  }

  // ── Help Offers (Aushelfen) ────────────────────────────────────────────────

  Future<void> offerHelp({
    required String requestId,
    required String communityId,
    String? message,
  }) async {
    if (_userId.isEmpty) return;
    await _repo.offerHelp(
      requestId: requestId,
      communityId: communityId,
      userId: _userId,
      displayName: _displayName,
      message: message,
    );
    ref.invalidate(helpOffersProvider(requestId));
  }

  Future<void> acceptHelpOffer({
    required String offerId,
    required String requestId,
  }) async {
    await _repo.acceptHelpOffer(offerId);
    ref.invalidate(helpOffersProvider(requestId));
  }

  Future<void> deleteHelpOffer({
    required String offerId,
    required String requestId,
  }) async {
    await _repo.deleteHelpOffer(offerId);
    ref.invalidate(helpOffersProvider(requestId));
  }

  // ── Messages (Mini-Chat) ───────────────────────────────────────────────────

  Future<void> sendMessage({
    required String contextType,
    required String contextId,
    required String communityId,
    required String recipientId,
    required String text,
  }) async {
    if (_userId.isEmpty) return;
    await _repo.sendMessage(
      contextType: contextType,
      contextId: contextId,
      communityId: communityId,
      senderId: _userId,
      senderName: _displayName,
      recipientId: recipientId,
      text: text,
    );
    ref.invalidate(communityMessagesProvider(msgParams(contextType, contextId)));
  }

  Future<void> markMessagesRead({
    required String contextType,
    required String contextId,
  }) async {
    if (_userId.isEmpty) return;
    await _repo.markMessagesRead(
      contextType: contextType,
      contextId: contextId,
      userId: _userId,
    );
    ref.invalidate(communityMessagesProvider(msgParams(contextType, contextId)));
  }
}

final communityActionsProvider =
    AsyncNotifierProvider<CommunityActionsNotifier, void>(
  CommunityActionsNotifier.new,
);

