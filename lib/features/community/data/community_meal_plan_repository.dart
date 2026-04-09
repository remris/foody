import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/models/community_meal_plan.dart';

class CommunityMealPlanRepository {
  static const _table = 'community_meal_plans';
  static const _likesTable = 'meal_plan_likes';
  static const _savesTable = 'community_meal_plan_saves';
  static const _ratingsTable = 'community_meal_plan_ratings';
  static const _pageSize = 20;

  final _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;
  String get currentAuthorName =>
      _client.auth.currentUser?.email?.split('@').first ?? 'kokomu-User';

  // ─── Feed ────────────────────────────────────────────────────────────────

  Future<List<CommunityMealPlan>> getFeed({
    int page = 0,
    String? tag,
    String? searchQuery,
  }) async {
    final userId = _client.auth.currentUser?.id;

    var baseQuery = _client
        .from(_table)
        .select('*, like_count:meal_plan_likes(count)')
        .eq('is_published', true);

    // Eigene Einträge aus dem Community-Feed ausblenden
    if (userId != null) {
      baseQuery = baseQuery.neq('user_id', userId);
    }

    final data = await baseQuery
        .order('created_at', ascending: false)
        .range(page * _pageSize, (page + 1) * _pageSize - 1) as List<dynamic>;

    Set<String> likedIds = {};
    if (userId != null && data.isNotEmpty) {
      final ids = data.map((e) => e['id'] as String).toList();
      final likes = await _client
          .from(_likesTable)
          .select('plan_id')
          .eq('user_id', userId)
          .inFilter('plan_id', ids);
      likedIds = (likes as List).map((l) => l['plan_id'] as String).toSet();
    }

    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['is_liked_by_me'] = likedIds.contains(map['id'] as String);
      return CommunityMealPlan.fromJson(map);
    }).where((p) {
      if (searchQuery == null || searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).where((p) {
      if (tag == null) return true;
      return p.tags.any((t) => t.toLowerCase() == tag.toLowerCase());
    }).toList();
  }

  /// Nur veröffentlichte eigene Pläne – für "Mein Bereich"
  Future<List<CommunityMealPlan>> getMyPlans(String userId) async {
    final data = await _client
        .from(_table)
        .select('*, like_count:meal_plan_likes(count)')
        .eq('user_id', userId)
        .eq('is_published', true)
        .order('created_at', ascending: false) as List<dynamic>;

    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['is_liked_by_me'] = false;
      return CommunityMealPlan.fromJson(map);
    }).toList();
  }

  /// Alle eigenen Pläne (auch unveröffentlichte) – für Vorlage-Sheet
  Future<List<CommunityMealPlan>> getMyAllPlans(String userId) async {
    final data = await _client
        .from(_table)
        .select('*, like_count:meal_plan_likes(count)')
        .eq('user_id', userId)
        .order('created_at', ascending: false) as List<dynamic>;

    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['is_liked_by_me'] = false;
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

  // ─── Publish / Delete ────────────────────────────────────────────────────

  Future<CommunityMealPlan> publish({
    required String title,
    required String description,
    required List<dynamic> planJson,
    required List<String> tags,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Nicht eingeloggt');

    final result = await _client.from(_table).insert({
      'user_id': userId,
      'author_name': currentAuthorName,
      'title': title,
      'description': description,
      'plan_json': planJson,
      'tags': tags,
      'is_published': true,
    }).select().single();

    final map = Map<String, dynamic>.from(result as Map);
    map['like_count'] = 0;
    map['is_liked_by_me'] = false;
    return CommunityMealPlan.fromJson(map);
  }

  /// Speichert einen Wochenplan als privaten Entwurf (noch nicht veröffentlicht)
  Future<CommunityMealPlan> savePlanAsDraft({
    required String title,
    required List<dynamic> planJson,
    String description = '',
    List<String> tags = const [],
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Nicht eingeloggt');

    final result = await _client.from(_table).insert({
      'user_id': userId,
      'author_name': currentAuthorName,
      'title': title,
      'description': description,
      'plan_json': planJson,
      'tags': tags,
      'is_published': false,
    }).select().single();

    final map = Map<String, dynamic>.from(result as Map);
    map['like_count'] = 0;
    map['is_liked_by_me'] = false;
    return CommunityMealPlan.fromJson(map);
  }

  /// Veröffentlicht einen bereits existierenden Entwurf (UPDATE statt INSERT)
  Future<void> publishExistingPlan({
    required String planId,
    required String title,
    required String description,
    required List<dynamic> planJson,
    required List<String> tags,
  }) async {
    await _client.from(_table).update({
      'title': title,
      'description': description,
      'plan_json': planJson,
      'tags': tags,
      'is_published': true,
    }).eq('id', planId);
  }

  /// Aktualisiert einen bestehenden Plan (Titel, Beschreibung, Einträge, Tags)
  /// ohne den Veröffentlichungs-Status zu verändern
  Future<void> updateExistingPlan({
    required String planId,
    required String title,
    required String description,
    required List<dynamic> planJson,
    required List<String> tags,
  }) async {
    await _client.from(_table).update({
      'title': title,
      'description': description,
      'plan_json': planJson,
      'tags': tags,
    }).eq('id', planId);
  }

  Future<void> delete(String planId) async {
    await _client.from(_table).delete().eq('id', planId);
  }

  Future<void> unpublishPlan(String planId) async {
    await _client
        .from(_table)
        .update({'is_published': false})
        .eq('id', planId);
  }

  // ─── Likes ───────────────────────────────────────────────────────────────

  Future<CommunityMealPlan> toggleLike(CommunityMealPlan plan) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Nicht eingeloggt');

    if (plan.isLikedByMe) {
      await _client
          .from(_likesTable)
          .delete()
          .eq('plan_id', plan.id)
          .eq('user_id', userId);
      return plan.copyWith(
        isLikedByMe: false,
        likeCount: (plan.likeCount - 1).clamp(0, 99999),
      );
    } else {
      await _client.from(_likesTable).upsert({
        'plan_id': plan.id,
        'user_id': userId,
      });
      return plan.copyWith(
        isLikedByMe: true,
        likeCount: plan.likeCount + 1,
      );
    }
  }

  // ─── Saves / Favoriten ───────────────────────────────────────────────────

  Future<void> savePlan(String planId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Nicht eingeloggt');
    await _client.from(_savesTable).upsert({
      'plan_id': planId,
      'user_id': userId,
    });
  }

  Future<void> unsavePlan(String planId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Nicht eingeloggt');
    await _client.from(_savesTable).delete()
        .eq('plan_id', planId)
        .eq('user_id', userId);
  }

  Future<List<CommunityMealPlan>> getSavedPlans(String userId) async {
    final saves = await _client
        .from(_savesTable)
        .select('plan_id')
        .eq('user_id', userId) as List<dynamic>;

    if (saves.isEmpty) return [];

    final ids = saves.map((s) => s['plan_id'] as String).toList();
    final data = await _client
        .from(_table)
        .select('*, like_count:meal_plan_likes(count)')
        .inFilter('id', ids)
        .neq('user_id', userId) // eigene Pläne im Gespeichert-Tab ausblenden
        .order('created_at', ascending: false) as List<dynamic>;

    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['is_liked_by_me'] = false;
      map['is_saved_by_me'] = true;
      return CommunityMealPlan.fromJson(map);
    }).toList();
  }

  // ─── Bewertungen ─────────────────────────────────────────────────────────

  Future<void> ratePlan(String planId, int stars) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Nicht eingeloggt');
    await _client.from(_ratingsTable).upsert({
      'plan_id': planId,
      'user_id': userId,
      'stars': stars,
    }, onConflict: 'plan_id,user_id');

    // avg_rating und rating_count in community_meal_plans aktualisieren
    final ratings = await _client
        .from(_ratingsTable)
        .select('stars')
        .eq('plan_id', planId) as List<dynamic>;
    if (ratings.isNotEmpty) {
      final avg = ratings
              .map((r) => (r['stars'] as num).toInt())
              .reduce((a, b) => a + b) /
          ratings.length;
      await _client.from(_table).update({
        'avg_rating': avg,
        'rating_count': ratings.length,
      }).eq('id', planId);
    }
  }

  Future<int?> getMyPlanRating(String planId) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _client
        .from(_ratingsTable)
        .select('stars')
        .eq('plan_id', planId)
        .eq('user_id', userId)
        .maybeSingle();
    return data?['stars'] as int?;
  }
}
