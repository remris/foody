import 'dart:math';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/models/community_recipe.dart';

class CommunityRecipeRepository {
  static const _table = 'community_recipes';
  static const _likesTable = 'recipe_likes';
  static const _commentsTable = 'recipe_comments';
  static const _ratingsTable = 'recipe_ratings';
  static const _pageSize = 20;

  final _client = SupabaseService.client;

  /// Aktuell eingeloggter User
  String? get currentUserId => _client.auth.currentUser?.id;

  /// E-Mail-Prefix als Display-Name
  String get currentAuthorName =>
      _client.auth.currentUser?.email?.split('@').first ?? 'Kokomi-User';

  // ─── Feed ────────────────────────────────────────────────────────────────

  /// Lade Community-Feed, optional gefiltert nach Kategorie/Tag.
  /// [sortBy]: 'newest' | 'top_rated' | 'random'
  /// [minRating]: nur Rezepte mit avg_rating >= minRating
  Future<List<CommunityRecipe>> getFeed({
    int page = 0,
    String? category,
    String? tag,
    String? searchQuery,
    String sortBy = 'random',
    double minRating = 0,
  }) async {
    final userId = _client.auth.currentUser?.id;

    var baseQuery = _client
        .from(_table)
        .select('*, like_count:recipe_likes(count), comment_count:recipe_comments(count)')
        .eq('is_published', true);

    // Eigene Einträge aus dem Community-Feed ausblenden
    if (userId != null) {
      baseQuery = baseQuery.neq('user_id', userId);
    }

    if (category != null) {
      baseQuery = baseQuery.eq('category', category);
    }

    // Sortierung
    final ascending = false;
    late List<dynamic> data;
    if (sortBy == 'top_rated') {
      data = await baseQuery
          .order('avg_rating', ascending: ascending, nullsFirst: false)
          .order('created_at', ascending: ascending)
          .range(page * _pageSize, (page + 1) * _pageSize - 1) as List<dynamic>;
    } else if (sortBy == 'random') {
      // Größeres Fenster laden und lokal shufflen für Variation
      final offset = page * _pageSize;
      final windowSize = _pageSize * 3;
      final rawData = await baseQuery
          .order('created_at', ascending: false)
          .range(0, windowSize - 1) as List<dynamic>;
      final shuffled = List<dynamic>.from(rawData)..shuffle(Random());
      data = shuffled.skip(page == 0 ? 0 : offset % windowSize).take(_pageSize).toList();
    } else {
      // newest
      data = await baseQuery
          .order('created_at', ascending: false)
          .range(page * _pageSize, (page + 1) * _pageSize - 1) as List<dynamic>;
    }

    // Lade Likes des aktuellen Users für diese Rezepte
    Set<String> likedIds = {};
    if (userId != null && data.isNotEmpty) {
      final ids = data.map((e) => e['id'] as String).toList();
      final likes = await _client
          .from(_likesTable)
          .select('recipe_id')
          .eq('user_id', userId)
          .inFilter('recipe_id', ids);
      likedIds = (likes as List).map((l) => l['recipe_id'] as String).toSet();
    }

    // Lade eigene Bewertungen
    Map<String, int> myRatings = {};
    if (userId != null && data.isNotEmpty) {
      final ids = data.map((e) => e['id'] as String).toList();
      final ratings = await _client
          .from(_ratingsTable)
          .select('recipe_id, stars')
          .eq('user_id', userId)
          .inFilter('recipe_id', ids);
      myRatings = {
        for (final r in (ratings as List)) r['recipe_id'] as String: r['stars'] as int
      };
    }

    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['comment_count'] = _extractCount(map['comment_count']);
      map['is_liked_by_me'] = likedIds.contains(map['id'] as String);
      map['my_rating'] = myRatings[map['id'] as String];
      return CommunityRecipe.fromJson(map);
    }).where((r) {
      if (minRating > 0) {
        final avg = r.avgRating ?? 0.0;
        if (avg < minRating) return false;
      }
      if (searchQuery == null || searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.tags.any((t) => t.toLowerCase().contains(q));
    }).where((r) {
      if (tag == null) return true;
      return r.tags.any((t) => t.toLowerCase() == tag.toLowerCase());
    }).toList();
  }

  /// Alle eigenen veröffentlichten Rezepte
  Future<List<CommunityRecipe>> getMyRecipes(String userId) async {
    final data = await _client
        .from(_table)
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

  /// Alle eigenen Rezepte inkl. Entwürfe – für Post-Attachment Picker
  Future<List<CommunityRecipe>> getMyAllRecipes(String userId) async {
    final data = await _client
        .from(_table)
        .select('*, like_count:recipe_likes(count), comment_count:recipe_comments(count)')
        .eq('user_id', userId)
        .order('created_at', ascending: false) as List<dynamic>;

    return data.map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['like_count'] = _extractCount(map['like_count']);
      map['comment_count'] = _extractCount(map['comment_count']);
      map['is_liked_by_me'] = false;
      return CommunityRecipe.fromJson(map);
    }).toList();
  }

  /// Hilfsmethode: Supabase gibt count als [{count: n}] zurück – wir flachen das ab
  int _extractCount(dynamic raw) {
    if (raw is int) return raw;
    if (raw is List && raw.isNotEmpty) {
      return (raw.first as Map)['count'] as int? ?? 0;
    }
    return 0;
  }

  // ─── Publish / Delete ────────────────────────────────────────────────────

  Future<CommunityRecipe> publishRecipe(CommunityRecipe recipe) async {
    final data = await _client
        .from(_table)
        .insert(recipe.toJson())
        .select()
        .single();
    return CommunityRecipe.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteRecipe(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  Future<void> incrementViewCount(String id) async {
    await _client.rpc('increment_view_count', params: {'recipe_id': id});
  }

  // ─── Likes ────────────────────────────────────────────────────────────────

  Future<bool> toggleLike(String recipeId, String userId) async {
    // Prüfe ob bereits geliket
    final existing = await _client
        .from(_likesTable)
        .select('id')
        .eq('recipe_id', recipeId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from(_likesTable)
          .delete()
          .eq('recipe_id', recipeId)
          .eq('user_id', userId);
      return false; // Like entfernt
    } else {
      await _client.from(_likesTable).insert({
        'recipe_id': recipeId,
        'user_id': userId,
      });
      return true; // Like gesetzt
    }
  }

  Future<int> getLikeCount(String recipeId) async {
    final result = await _client
        .from(_likesTable)
        .select('id')
        .eq('recipe_id', recipeId) as List<dynamic>;
    return result.length;
  }

  // ─── Kommentare ──────────────────────────────────────────────────────────

  Future<List<RecipeComment>> getComments(String recipeId) async {
    final data = await _client
        .from(_commentsTable)
        .select()
        .eq('recipe_id', recipeId)
        .order('created_at', ascending: true) as List<dynamic>;
    return data
        .map((e) => RecipeComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeComment> addComment({
    required String recipeId,
    required String userId,
    required String authorName,
    required String content,
  }) async {
    final data = await _client.from(_commentsTable).insert({
      'recipe_id': recipeId,
      'user_id': userId,
      'author_name': authorName,
      'content': content,
    }).select().single();
    return RecipeComment.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from(_commentsTable).delete().eq('id', commentId);
  }

  /// Anzahl der eigenen veröffentlichten Rezepte (für Free-Limit-Check)
  Future<int> getMyPublishedCount(String userId) async {
    final data = await _client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .eq('is_published', true) as List<dynamic>;
    return data.length;
  }

  /// Veröffentlichung zurückziehen (löscht den Eintrag aus der Community)
  Future<void> unpublishRecipe(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Eigenes veröffentlichtes Rezept aktualisieren
  Future<void> updateRecipe(String id, Map<String, dynamic> fields) async {
    await _client.from(_table).update(fields).eq('id', id);
  }

  // ─── Bewertungen ─────────────────────────────────────────────────────────

  /// Rezept bewerten (1-5 Kochlöffel). Upsert: überschreibt vorherige Bewertung.
  Future<void> rateRecipe(String recipeId, int stars) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Nicht eingeloggt');
    await _client.from(_ratingsTable).upsert({
      'recipe_id': recipeId,
      'user_id': userId,
      'stars': stars,
    }, onConflict: 'recipe_id, user_id');

    // avg_rating und rating_count in community_recipes aktualisieren
    final ratings = await _client
        .from(_ratingsTable)
        .select('stars')
        .eq('recipe_id', recipeId) as List<dynamic>;
    if (ratings.isNotEmpty) {
      final avg = ratings.map((r) => r['stars'] as int).reduce((a, b) => a + b) / ratings.length;
      await _client.from(_table).update({
        'avg_rating': avg,
        'rating_count': ratings.length,
      }).eq('id', recipeId);
    }
  }

  /// Eigene Bewertung eines Rezepts laden
  Future<int?> getMyRating(String recipeId) async {
    final userId = currentUserId;
    if (userId == null) return null;
    final data = await _client
        .from(_ratingsTable)
        .select('stars')
        .eq('recipe_id', recipeId)
        .eq('user_id', userId)
        .maybeSingle();
    return data?['stars'] as int?;
  }
}

