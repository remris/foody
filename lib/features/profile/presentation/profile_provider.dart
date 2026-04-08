import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/profile/data/user_profile_repository.dart';
import 'package:kokomi/models/user_profile.dart';
import 'package:kokomi/models/community_recipe.dart';
import 'package:kokomi/models/community_meal_plan.dart';
import 'package:kokomi/models/feed_item.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (_) => UserProfileRepository(),
);

// ─── Profil eines Users laden (family) ───────────────────────────────────────

final userProfileProvider =
    FutureProvider.autoDispose.family<UserProfile, String>((ref, userId) async {
  return ref.read(userProfileRepositoryProvider).fetchProfile(userId);
});

// ─── Eigenes Profil (editable Notifier) ──────────────────────────────────────

class OwnProfileNotifier extends AutoDisposeAsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final repo = ref.read(userProfileRepositoryProvider);
    final userId = repo.currentUserId;
    if (userId == null) throw Exception('Nicht eingeloggt');
    return repo.fetchProfile(userId);
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    SocialLinks? socialLinks,
    String? avatarUrl,
  }) async {
    final repo = ref.read(userProfileRepositoryProvider);
    final userId = repo.currentUserId;
    if (userId == null) return;

    await repo.updateProfile(
      userId: userId,
      displayName: displayName,
      bio: bio,
      socialLinks: socialLinks,
      avatarUrl: avatarUrl,
    );

    // Cache invalidieren
    ref.invalidateSelf();
    ref.invalidate(userProfileProvider(userId));
  }
}

final ownProfileProvider =
    AutoDisposeAsyncNotifierProvider<OwnProfileNotifier, UserProfile>(
  OwnProfileNotifier.new,
);

// ─── Follow-State ─────────────────────────────────────────────────────────────

class FollowNotifier extends AutoDisposeFamilyNotifier<bool, String> {
  @override
  bool build(String followeeId) => false; // initial – wird vom Screen gesetzt

  void setInitial(bool value) => state = value;

  Future<void> toggle(String followeeId) async {
    final repo = ref.read(userProfileRepositoryProvider);
    final wasFollowing = state;
    state = !wasFollowing; // optimistic
    try {
      if (wasFollowing) {
        await repo.unfollowUser(followeeId);
      } else {
        await repo.followUser(followeeId);
      }
      // Profil-Cache invalidieren damit Follower-Count aktualisiert wird
      ref.invalidate(userProfileProvider(followeeId));
    } catch (_) {
      state = wasFollowing; // rollback
    }
  }
}

final followProvider =
    AutoDisposeNotifierProvider.family<FollowNotifier, bool, String>(
  FollowNotifier.new,
);

// ─── Following-Feed ───────────────────────────────────────────────────────────

final followingFeedProvider =
    FutureProvider.autoDispose<List<FeedItem>>((ref) async {
  return ref.read(userProfileRepositoryProvider).fetchFollowingFeed();
});

// ─── Öffentliche Rezepte eines Users ─────────────────────────────────────────

final userPublicRecipesProvider =
    FutureProvider.autoDispose.family<List<CommunityRecipe>, String>(
        (ref, userId) async {
  return ref.read(userProfileRepositoryProvider).fetchPublicRecipes(userId);
});

// ─── Öffentliche Wochenpläne eines Users ─────────────────────────────────────

final userPublicMealPlansProvider =
    FutureProvider.autoDispose.family<List<CommunityMealPlan>, String>(
        (ref, userId) async {
  return ref.read(userProfileRepositoryProvider).fetchPublicMealPlans(userId);
});

// ─── Follower eines Users ──────────────────────────────────────────────────────

final userFollowersProvider =
    FutureProvider.autoDispose.family<List<UserProfile>, String>(
        (ref, userId) async {
  return ref.read(userProfileRepositoryProvider).fetchFollowers(userId);
});

// ─── Wem ein User folgt ───────────────────────────────────────────────────────

final userFollowingProvider =
    FutureProvider.autoDispose.family<List<UserProfile>, String>(
        (ref, userId) async {
  return ref.read(userProfileRepositoryProvider).fetchFollowing(userId);
});

// ─── Feed-Filter ─────────────────────────────────────────────────────────────

/// Welche FeedItemTypes im Mein-Feed angezeigt werden.
final feedFilterProvider = StateProvider<Set<FeedItemType>>(
  (_) => {FeedItemType.post, FeedItemType.recipe, FeedItemType.plan},
);

/// Gefilterter Feed – hängt vom feedFilterProvider ab.
final filteredFeedProvider = Provider.autoDispose<AsyncValue<List<FeedItem>>>((ref) {
  final raw = ref.watch(followingFeedProvider);
  final filter = ref.watch(feedFilterProvider);
  return raw.whenData((items) => items.where((i) => filter.contains(i.type)).toList());
});

// ─── Post-Kommentare ──────────────────────────────────────────────────────────

final postCommentsProvider =
    FutureProvider.autoDispose.family<List<SocialPostComment>, String>(
        (ref, postId) async {
  return ref.read(userProfileRepositoryProvider).fetchPostComments(postId);
});
