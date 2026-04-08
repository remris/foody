import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/community/data/community_recipe_repository.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/models/community_recipe.dart';

// ─── Repository Provider ─────────────────────────────────────────────────

final communityRepositoryProvider = Provider<CommunityRecipeRepository>(
  (ref) => CommunityRecipeRepository(),
);

// ─── Feed State ──────────────────────────────────────────────────────────

class CommunityFeedState {
  final List<CommunityRecipe> recipes;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String sortBy; // 'random' | 'newest' | 'top_rated'
  final double minRating; // 0 = alle

  const CommunityFeedState({
    this.recipes = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.sortBy = 'random',
    this.minRating = 0,
  });

  CommunityFeedState copyWith({
    List<CommunityRecipe>? recipes,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? sortBy,
    double? minRating,
  }) =>
      CommunityFeedState(
        recipes: recipes ?? this.recipes,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        sortBy: sortBy ?? this.sortBy,
        minRating: minRating ?? this.minRating,
      );
}

// ─── Feed Notifier ────────────────────────────────────────────────────────

class CommunityFeedNotifier
    extends AutoDisposeAsyncNotifier<CommunityFeedState> {
  String? _category;
  String? _tag;
  String? _searchQuery;
  String _sortBy = 'random';
  double _minRating = 0;

  @override
  Future<CommunityFeedState> build() async {
    final recipes = await _load(page: 0);
    return CommunityFeedState(
      recipes: recipes,
      hasMore: recipes.length >= 20,
      page: 1,
      sortBy: _sortBy,
      minRating: _minRating,
    );
  }

  Future<List<CommunityRecipe>> _load({required int page}) {
    return ref.read(communityRepositoryProvider).getFeed(
          page: page,
          category: _category,
          tag: _tag,
          searchQuery: _searchQuery,
          sortBy: _sortBy,
          minRating: _minRating,
        );
  }

  Future<void> refresh() async {
    // Bestehende Daten sichtbar lassen bis neue geladen sind (kein Flicker)
    try {
      final recipes = await _load(page: 0);
      state = AsyncValue.data(CommunityFeedState(
        recipes: recipes,
        hasMore: recipes.length >= 20,
        page: 1,
        sortBy: _sortBy,
        minRating: _minRating,
      ));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final more = await _load(page: current.page);
      state = AsyncValue.data(current.copyWith(
        recipes: [...current.recipes, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 20,
        page: current.page + 1,
      ));
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  void setFilter({String? category, String? tag, String? searchQuery}) {
    _category = category;
    _tag = tag;
    _searchQuery = searchQuery;
    refresh();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    refresh();
  }

  void setMinRating(double minRating) {
    _minRating = minRating;
    refresh();
  }

  /// Like/Unlike mit optimistischem Update
  Future<void> toggleLike(String recipeId) async {
    final repo = ref.read(communityRepositoryProvider);
    final userId = repo.currentUserId;
    if (userId == null) return;

    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistisches Update
    final updated = current.recipes.map((r) {
      if (r.id != recipeId) return r;
      final wasLiked = r.isLikedByMe;
      return r.copyWith(
        isLikedByMe: !wasLiked,
        likeCount: wasLiked ? r.likeCount - 1 : r.likeCount + 1,
      );
    }).toList();
    state = AsyncValue.data(current.copyWith(recipes: updated));

    // Server-Call
    try {
      await repo.toggleLike(recipeId, userId);
    } catch (_) {
      // Rollback bei Fehler
      state = AsyncValue.data(current);
    }
  }

  /// Rezept bewerten (1-5 Kochlöffel) mit optimistischem Update
  Future<void> rateRecipe(String recipeId, int stars) async {
    final repo = ref.read(communityRepositoryProvider);
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistisches Update
    final updated = current.recipes.map((r) {
      if (r.id != recipeId) return r;
      final wasRated = r.myRating != null;
      final oldStars = r.myRating ?? 0;
      final newCount = wasRated ? r.ratingCount : r.ratingCount + 1;
      final newAvg = wasRated
          ? ((r.avgRating ?? 0) * r.ratingCount - oldStars + stars) / newCount
          : ((r.avgRating ?? 0) * r.ratingCount + stars) / newCount;
      return r.copyWith(
        myRating: stars,
        avgRating: newAvg,
        ratingCount: newCount,
      );
    }).toList();
    state = AsyncValue.data(current.copyWith(recipes: updated));

    try {
      await repo.rateRecipe(recipeId, stars);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }
}

final communityFeedProvider =
    AutoDisposeAsyncNotifierProvider<CommunityFeedNotifier, CommunityFeedState>(
  CommunityFeedNotifier.new,
);

// ─── Meine Rezepte Provider ───────────────────────────────────────────────

class MyPublishedRecipesNotifier
    extends AutoDisposeAsyncNotifier<List<CommunityRecipe>> {
  @override
  Future<List<CommunityRecipe>> build() async {
    final repo = ref.read(communityRepositoryProvider);
    final userId = repo.currentUserId;
    if (userId == null) return [];
    return repo.getMyRecipes(userId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(communityRepositoryProvider).deleteRecipe(id);
    refresh();
  }
}

final myPublishedRecipesProvider = AutoDisposeAsyncNotifierProvider<
    MyPublishedRecipesNotifier, List<CommunityRecipe>>(
  MyPublishedRecipesNotifier.new,
);

// ─── Kommentare Provider ──────────────────────────────────────────────────

/// Kommentare für ein bestimmtes Rezept laden
final recipeCommentsProvider =
    AsyncNotifierProvider.autoDispose.family<_RecipeCommentsNotifier, List<RecipeComment>, String>(
  _RecipeCommentsNotifier.new,
);

class _RecipeCommentsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<RecipeComment>, String> {
  @override
  Future<List<RecipeComment>> build(String arg) async {
    return ref.read(communityRepositoryProvider).getComments(arg);
  }

  Future<void> addComment(String content) async {
    final repo = ref.read(communityRepositoryProvider);
    final userId = repo.currentUserId;
    if (userId == null) return;

    final comment = await repo.addComment(
      recipeId: arg,
      userId: userId,
      authorName: repo.currentAuthorName,
      content: content,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, comment]);
  }

  Future<void> deleteComment(String commentId) async {
    await ref.read(communityRepositoryProvider).deleteComment(commentId);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((c) => c.id != commentId).toList());
  }
}

// ─── Publish Notifier ─────────────────────────────────────────────────────

class PublishRecipeNotifier extends AutoDisposeNotifier<AsyncValue<void>> {
  static const _freeLimit = 3;

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Gibt null zurück bei Erfolg, sonst den Fehlertext
  Future<String?> publish(CommunityRecipe recipe) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(communityRepositoryProvider);
      final userId = repo.currentUserId;
      if (userId == null) throw Exception('Nicht angemeldet');

      // Free-Limit nur für Nicht-Pro-User prüfen
      final isPro = ref.read(isProProvider);
      if (!isPro) {
        final count = await repo.getMyPublishedCount(userId);
        if (count >= _freeLimit) {
          state = AsyncValue.error('FREE_LIMIT_REACHED', StackTrace.current);
          return 'FREE_LIMIT_REACHED';
        }
      }

      await repo.publishRecipe(recipe.copyWith(userId: userId));
      state = const AsyncValue.data(null);

      ref.invalidate(communityFeedProvider);
      ref.invalidate(myPublishedRecipesProvider);
      return null;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return e.toString();
    }
  }

  /// Gibt null zurück bei Erfolg, sonst den Fehlertext
  Future<String?> unpublish(String recipeId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.unpublishRecipe(recipeId);
      state = const AsyncValue.data(null);
      ref.invalidate(communityFeedProvider);
      ref.invalidate(myPublishedRecipesProvider);
      return null; // Erfolg
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return e.toString();
    }
  }
}

final publishRecipeProvider =
    AutoDisposeNotifierProvider<PublishRecipeNotifier, AsyncValue<void>>(
  PublishRecipeNotifier.new,
);

