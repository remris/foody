import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:kokomu/core/services/profanity_filter.dart';
import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/models/user_profile.dart';
import 'package:kokomu/models/community_recipe.dart';
import 'package:kokomu/models/community_meal_plan.dart';
import 'package:kokomu/models/feed_item.dart';

class UserProfileRepository {
  final _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // ─── Profil laden ────────────────────────────────────────────────────────────

  Future<UserProfile> fetchProfile(String userId) async {
    final data = await _client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    // Zähle veröffentlichte Rezepte
    final recipeData = await _client
        .from('community_recipes')
        .select('id')
        .eq('user_id', userId)
        .eq('is_published', true) as List<dynamic>;

    // Follower-Anzahl
    final followerData = await _client
        .from('user_follows')
        .select('follower_id')
        .eq('followee_id', userId) as List<dynamic>;

    // Following-Anzahl
    final followingData = await _client
        .from('user_follows')
        .select('followee_id')
        .eq('follower_id', userId) as List<dynamic>;

    // Folge ich diesem User?
    bool isFollowedByMe = false;
    final me = currentUserId;
    if (me != null && me != userId) {
      final followCheck = await _client
          .from('user_follows')
          .select('follower_id')
          .eq('follower_id', me)
          .eq('followee_id', userId)
          .maybeSingle();
      isFollowedByMe = followCheck != null;
    }

    if (data == null) {
      // Profil existiert noch nicht – Fallback
      return UserProfile(
        id: userId,
        displayName: 'kokomu-User',
        recipeCount: recipeData.length,
        followerCount: followerData.length,
        followingCount: followingData.length,
        isFollowedByMe: isFollowedByMe,
      );
    }

    final map = Map<String, dynamic>.from(data);
    map['recipe_count'] = recipeData.length;
    map['follower_count'] = followerData.length;
    map['following_count'] = followingData.length;
    map['is_followed_by_me'] = isFollowedByMe;

    return UserProfile.fromJson(map);
  }

  // ─── Profil aktualisieren ────────────────────────────────────────────────────

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? householdNickname,
    String? bio,
    String? avatarUrl,
    SocialLinks? socialLinks,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (displayName != null) data['display_name'] = displayName;
    if (householdNickname != null) data['household_nickname'] = householdNickname.trim().isEmpty ? null : householdNickname.trim();
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (socialLinks != null) data['social_links'] = socialLinks.toJson();

    await _client
        .from('user_profiles')
        .upsert({'id': userId, ...data});

    // Wenn der Display-Name geändert wurde, author_name in allen
    // veröffentlichten Rezepten und Wochenplänen dieses Users mitaktualisieren
    if (displayName != null && displayName.isNotEmpty) {
      await Future.wait([
        _client
            .from('community_recipes')
            .update({'author_name': displayName})
            .eq('user_id', userId),
        _client
            .from('community_meal_plans')
            .update({'author_name': displayName})
            .eq('user_id', userId),
      ]);
    }
  }

  // ─── Avatar hochladen ─────────────────────────────────────────────────────────

  Future<String> uploadAvatar(String userId, Uint8List bytes, String ext) async {
    final path = '$userId/avatar.$ext';
    await _client.storage
        .from('avatars')
        .uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'));

    return _client.storage.from('avatars').getPublicUrl(path);
  }

  // ─── Follow / Unfollow ───────────────────────────────────────────────────────

  Future<void> followUser(String followeeId) async {
    final me = currentUserId;
    if (me == null) return;
    await _client.from('user_follows').insert({
      'follower_id': me,
      'followee_id': followeeId,
    });
  }

  Future<void> unfollowUser(String followeeId) async {
    final me = currentUserId;
    if (me == null) return;
    await _client
        .from('user_follows')
        .delete()
        .eq('follower_id', me)
        .eq('followee_id', followeeId);
  }

  // ─── Follower-Liste laden ────────────────────────────────────────────────────

  Future<List<UserProfile>> fetchFollowers(String userId) async {
    // Alle die diesem User folgen
    final data = await _client
        .from('user_follows')
        .select('follower_id')
        .eq('followee_id', userId) as List<dynamic>;

    if (data.isEmpty) return [];
    final ids = data.map((e) => e['follower_id'] as String).toList();
    return _fetchProfilesForIds(ids);
  }

  Future<List<UserProfile>> fetchFollowing(String userId) async {
    // Wem dieser User folgt
    final data = await _client
        .from('user_follows')
        .select('followee_id')
        .eq('follower_id', userId) as List<dynamic>;

    if (data.isEmpty) return [];
    final ids = data.map((e) => e['followee_id'] as String).toList();
    return _fetchProfilesForIds(ids);
  }

  Future<List<UserProfile>> _fetchProfilesForIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final me = currentUserId;
    final data = await _client
        .from('user_profiles')
        .select()
        .inFilter('id', ids) as List<dynamic>;

    // Follower-Counts für alle laden
    final follows = me != null
        ? await _client
            .from('user_follows')
            .select('followee_id')
            .eq('follower_id', me)
            .inFilter('followee_id', ids) as List<dynamic>
        : <dynamic>[];
    final followedByMeSet = follows.map((f) => f['followee_id'] as String).toSet();

    return data.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      map['follower_count'] = 0;
      map['following_count'] = 0;
      map['recipe_count'] = 0;
      map['is_followed_by_me'] = followedByMeSet.contains(map['id']);
      return UserProfile.fromJson(map);
    }).toList();
  }



  Future<List<CommunityRecipe>> fetchPublicRecipes(String userId) async {
    final data = await _client
        .from('community_recipes')
        .select('*, like_count:recipe_likes(count), comment_count:recipe_comments(count)')
        .eq('user_id', userId)
        .eq('is_published', true)
        .order('created_at', ascending: false) as List<dynamic>;

    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['comment_count'] = _extractCount(map['comment_count']);
      map['is_liked_by_me'] = false;
      return CommunityRecipe.fromJson(map);
    }).toList();
  }

  // ─── Following-Feed (Rezepte + Wochenpläne) ─────────────────────────────────

  Future<List<FeedItem>> fetchFollowingFeed() async {
    final me = currentUserId;
    if (me == null) return [];

    final follows = await _client
        .from('user_follows')
        .select('followee_id')
        .eq('follower_id', me) as List<dynamic>;

    if (follows.isEmpty) return [];
    final ids = follows.map((f) => f['followee_id'] as String).toList();

    // ── Rezepte ──
    final recipeData = await _client
        .from('community_recipes')
        .select('*, like_count:recipe_likes(count), comment_count:recipe_comments(count)')
        .inFilter('user_id', ids)
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(30) as List<dynamic>;

    final likedRes = await _client
        .from('recipe_likes')
        .select('recipe_id')
        .eq('user_id', me) as List<dynamic>;
    final likedIds = likedRes.map((l) => l['recipe_id'] as String).toSet();

    final recipes = recipeData.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['comment_count'] = _extractCount(map['comment_count']);
      map['is_liked_by_me'] = likedIds.contains(map['id']);
      return FeedItem.recipe(CommunityRecipe.fromJson(map));
    }).toList();

    // ── Wochenpläne ──
    final planData = await _client
        .from('community_meal_plans')
        .select('*, like_count:meal_plan_likes(count)')
        .inFilter('user_id', ids)
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(20) as List<dynamic>;

    final savedRes = await _client
        .from('community_meal_plan_saves')
        .select('plan_id')
        .eq('user_id', me) as List<dynamic>;
    final savedIds = savedRes.map((s) => s['plan_id'] as String).toSet();

    final plans = planData.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['is_liked_by_me'] = false;
      map['is_saved_by_me'] = savedIds.contains(map['id']);
      return FeedItem.plan(CommunityMealPlan.fromJson(map));
    }).toList();

    // ── Social Posts ──
    List<FeedItem> posts = [];
    try {
      final postData = await _client
          .from('social_posts')
          .select('*, like_count:social_post_likes(count), comment_count:social_post_comments(count)')
          .inFilter('user_id', ids)
          .order('created_at', ascending: false)
          .limit(30) as List<dynamic>;

      final likedPostRes = await _client
          .from('social_post_likes')
          .select('post_id')
          .eq('user_id', me) as List<dynamic>;
      final likedPostIds = likedPostRes.map((l) => l['post_id'] as String).toSet();

      // Attached Rezepte/Pläne nachladen
      final attachedRecipeIds = postData
          .where((p) => p['attached_recipe_id'] != null)
          .map((p) => p['attached_recipe_id'] as String)
          .toList();
      final attachedPlanIds = postData
          .where((p) => p['attached_plan_id'] != null)
          .map((p) => p['attached_plan_id'] as String)
          .toList();

      Map<String, CommunityRecipe> recipeMap = {};
      if (attachedRecipeIds.isNotEmpty) {
        final rData = await _client
            .from('community_recipes')
            .select('*, like_count:recipe_likes(count), comment_count:recipe_comments(count)')
            .inFilter('id', attachedRecipeIds) as List<dynamic>;
        for (final r in rData) {
          final m = Map<String, dynamic>.from(r as Map);
          m['like_count'] = _extractCount(m['like_count']);
          m['comment_count'] = _extractCount(m['comment_count']);
          m['is_liked_by_me'] = likedIds.contains(m['id']);
          final cr = CommunityRecipe.fromJson(m);
          recipeMap[cr.id] = cr;
        }
      }

      Map<String, CommunityMealPlan> planMap = {};
      if (attachedPlanIds.isNotEmpty) {
        final pData = await _client
            .from('community_meal_plans')
            .select('*, like_count:meal_plan_likes(count)')
            .inFilter('id', attachedPlanIds) as List<dynamic>;
        for (final p in pData) {
          final m = Map<String, dynamic>.from(p as Map);
          m['like_count'] = _extractCount(m['like_count']);
          m['is_liked_by_me'] = false;
          m['is_saved_by_me'] = savedIds.contains(m['id']);
          final cp = CommunityMealPlan.fromJson(m);
          planMap[cp.id] = cp;
        }
      }

      posts = postData.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        map['like_count'] = _extractCount(map['like_count']);
        map['comment_count'] = _extractCount(map['comment_count']);
        map['is_liked_by_me'] = likedPostIds.contains(map['id'] as String);
        final post = SocialPost.fromJson(map);
        // Attached Objekte einhängen
        final withAttached = SocialPost(
          id: post.id, userId: post.userId, authorName: post.authorName,
          avatarUrl: post.avatarUrl, text: post.text,
          attachedRecipeId: post.attachedRecipeId,
          attachedPlanId: post.attachedPlanId,
          attachedRecipe: post.attachedRecipeId != null ? recipeMap[post.attachedRecipeId] : null,
          attachedPlan: post.attachedPlanId != null ? planMap[post.attachedPlanId] : null,
          likeCount: post.likeCount, commentCount: post.commentCount,
          isLikedByMe: post.isLikedByMe, createdAt: post.createdAt,
        );
        return FeedItem.post(withAttached);
      }).toList();
    } catch (_) {
      // social_posts Tabelle existiert noch nicht → ignorieren
    }

    // ── Chronologisch mischen ──
    final all = [...recipes, ...plans, ...posts];
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  // ─── Social Posts erstellen / liken / kommentieren ───────────────────────────

  Future<SocialPost> createPost({
    required String text,
    String? attachedRecipeId,
    String? attachedPlanId,
  }) async {
    final me = currentUserId;
    if (me == null) throw Exception('Nicht eingeloggt');

    // ── Profanity-Filter ─────────────────────────────────────────────────
    final filterError = ProfanityFilter.validate(text);
    if (filterError != null) throw Exception(filterError);

    // authorName aus Profil holen
    final profile = await _client
        .from('user_profiles')
        .select('display_name')
        .eq('id', me)
        .maybeSingle();
    final authorName = (profile?['display_name'] as String?)?.isNotEmpty == true
        ? profile!['display_name'] as String
        : _client.auth.currentUser?.email?.split('@').first ?? 'kokomu-User';

    final result = await _client.from('social_posts').insert({
      'user_id': me,
      'author_name': authorName,
      'text': text,
      if (attachedRecipeId != null) 'attached_recipe_id': attachedRecipeId,
      if (attachedPlanId != null) 'attached_plan_id': attachedPlanId,
    }).select().single();

    final map = Map<String, dynamic>.from(result as Map);
    map['like_count'] = 0;
    map['comment_count'] = 0;
    map['is_liked_by_me'] = false;
    return SocialPost.fromJson(map);
  }

  Future<SocialPost> togglePostLike(SocialPost post) async {
    final me = currentUserId;
    if (me == null) throw Exception('Nicht eingeloggt');

    if (post.isLikedByMe) {
      await _client.from('social_post_likes').delete()
          .eq('post_id', post.id).eq('user_id', me);
      await _client.from('social_posts').update({
        'like_count': (post.likeCount - 1).clamp(0, 999999),
      }).eq('id', post.id);
      return post.copyWith(isLikedByMe: false, likeCount: (post.likeCount - 1).clamp(0, 999999));
    } else {
      await _client.from('social_post_likes').upsert({'post_id': post.id, 'user_id': me});
      await _client.from('social_posts').update({
        'like_count': post.likeCount + 1,
      }).eq('id', post.id);
      return post.copyWith(isLikedByMe: true, likeCount: post.likeCount + 1);
    }
  }

  Future<List<SocialPostComment>> fetchPostComments(String postId) async {
    final data = await _client
        .from('social_post_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true) as List<dynamic>;
    return data.map((j) => SocialPostComment.fromJson(Map<String, dynamic>.from(j as Map))).toList();
  }

  Future<SocialPostComment> addPostComment(String postId, String text) async {
    final me = currentUserId;
    if (me == null) throw Exception('Nicht eingeloggt');

    // ── Profanity-Filter ─────────────────────────────────────────────────
    final filterError = ProfanityFilter.validate(text);
    if (filterError != null) throw Exception(filterError);

    final profile = await _client
        .from('user_profiles')
        .select('display_name')
        .eq('id', me)
        .maybeSingle();
    final authorName = (profile?['display_name'] as String?)?.isNotEmpty == true
        ? profile!['display_name'] as String
        : _client.auth.currentUser?.email?.split('@').first ?? 'kokomu-User';

    final result = await _client.from('social_post_comments').insert({
      'post_id': postId,
      'user_id': me,
      'author_name': authorName,
      'text': text,
    }).select().single();

    // comment_count inkrementieren (best-effort, Trigger übernimmt das genau)
    try {
      await _client.rpc('increment_post_comment_count', params: {'p_post_id': postId});
    } catch (_) {
      // Tabelle ohne Trigger – manuell hochzählen nicht kritisch
    }

    return SocialPostComment.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<void> deletePost(String postId) async {
    await _client.from('social_posts').delete().eq('id', postId);
  }

  // ─── View-Count inkrementieren ────────────────────────────────────────────────

  Future<void> incrementRecipeViewCount(String recipeId) async {
    try {
      await _client.from('community_recipes').update({
        'view_count': _client.rpc('increment', params: {'row_id': recipeId}),
      }).eq('id', recipeId);
    } catch (_) {
      // Fallback: direktes SQL-Update
      try {
        await _client.rpc('increment_view_count', params: {
          'p_table': 'community_recipes',
          'p_id': recipeId,
        });
      } catch (_) {
        // Silently ignore – viewCount ist nicht kritisch
      }
    }
  }

  Future<void> incrementMealPlanViewCount(String planId) async {
    try {
      await _client.rpc('increment_view_count', params: {
        'p_table': 'community_meal_plans',
        'p_id': planId,
      });
    } catch (_) {
      // Silently ignore
    }
  }

  Future<List<CommunityMealPlan>> fetchPublicMealPlans(String userId) async {
    final me = currentUserId;
    final data = await _client
        .from('community_meal_plans')
        .select('*, like_count:meal_plan_likes(count)')
        .eq('user_id', userId)
        .eq('is_published', true)
        .order('created_at', ascending: false) as List<dynamic>;

    Set<String> savedIds = {};
    if (me != null) {
      final saved = await _client
          .from('community_meal_plan_saves')
          .select('plan_id')
          .eq('user_id', me) as List<dynamic>;
      savedIds = saved.map((s) => s['plan_id'] as String).toSet();
    }

    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['is_liked_by_me'] = false;
      map['is_saved_by_me'] = savedIds.contains(map['id']);
      return CommunityMealPlan.fromJson(map);
    }).toList();
  }

  int _extractCount(dynamic raw) {
    if (raw is int) return raw;
    if (raw is List && raw.isNotEmpty) {
      return (raw.first as Map)['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Posts eines Users (eigene oder öffentliche) abrufen.
  Future<List<SocialPost>> fetchUserPosts(String userId) async {
    try {
      final data = await _client
          .from('social_posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false) as List<dynamic>;
      return data.map((json) => SocialPost.fromJson(Map<String, dynamic>.from(json as Map))).toList();
    } catch (_) {
      return [];
    }
  }
}

