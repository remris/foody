import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/community/data/community_meal_plan_repository.dart';
import 'package:kokomu/features/meal_plan/presentation/meal_plan_provider.dart';
import 'package:kokomu/models/community_meal_plan.dart';

final communityMealPlanRepositoryProvider =
    Provider<CommunityMealPlanRepository>((ref) => CommunityMealPlanRepository());

// ── Feed-Provider ──────────────────────────────────────────────────────────

class CommunityMealPlanFeedNotifier
    extends AsyncNotifier<List<CommunityMealPlan>> {
  int _page = 0;
  bool _hasMore = true;
  String? _activeTag;
  String? _searchQuery;

  @override
  Future<List<CommunityMealPlan>> build() async {
    _page = 0;
    _hasMore = true;
    return _load();
  }

  Future<List<CommunityMealPlan>> _load({bool append = false}) async {
    final repo = ref.read(communityMealPlanRepositoryProvider);
    final items = await repo.getFeed(
      page: _page,
      tag: _activeTag,
      searchQuery: _searchQuery,
    );
    if (items.length < 20) _hasMore = false;

    if (append) {
      final existing = state.valueOrNull ?? [];
      return [...existing, ...items];
    }
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    if (state.isLoading) return;
    _page++;
    final next = await _load(append: true);
    state = AsyncData(next);
  }

  void setFilter({String? tag, String? searchQuery}) {
    _page = 0;
    _hasMore = true;
    _activeTag = tag;
    _searchQuery = searchQuery;
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    _page = 0;
    _hasMore = true;
    ref.invalidateSelf();
  }

  void _updateItem(String id, CommunityMealPlan Function(CommunityMealPlan) updater) {
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((p) => p.id == id ? updater(p) : p)
          .toList(),
    );
  }

  Future<void> toggleLike(CommunityMealPlan plan) async {
    final repo = ref.read(communityMealPlanRepositoryProvider);
    final updated = await repo.toggleLike(plan);
    _updateItem(plan.id, (_) => updated);
  }

  Future<void> toggleSave(CommunityMealPlan plan) async {
    final repo = ref.read(communityMealPlanRepositoryProvider);
    try {
      final isSaved = plan.isSavedByMe;
      if (isSaved) {
        await repo.unsavePlan(plan.id);
      } else {
        await repo.savePlan(plan.id);
      }
      _updateItem(plan.id, (p) => p.copyWith(isSavedByMe: !isSaved));
    } catch (e) {
      // silent fail, state bleibt unverändert
    }
  }

  Future<void> ratePlan(CommunityMealPlan plan, int stars) async {
    final repo = ref.read(communityMealPlanRepositoryProvider);
    try {
      await repo.ratePlan(plan.id, stars);
      // Optimistisch avg_rating updaten
      final currentCount = plan.ratingCount;
      final currentAvg = plan.avgRating ?? 0.0;
      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + stars) / newCount;
      _updateItem(plan.id, (p) => p.copyWith(avgRating: newAvg, ratingCount: newCount));
    } catch (e) {
      // silent fail
    }
  }
}

final communityMealPlanFeedProvider =
    AsyncNotifierProvider<CommunityMealPlanFeedNotifier, List<CommunityMealPlan>>(
        CommunityMealPlanFeedNotifier.new);

// ── Eigene Pläne ──────────────────────────────────────────────────────────

final myPublishedMealPlansProvider =
    FutureProvider<List<CommunityMealPlan>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  final repo = ref.read(communityMealPlanRepositoryProvider);
  return repo.getMyPlans(userId);
});

/// Alle eigenen Pläne inkl. unveröffentlichter – für Vorlage-Sheet
final myAllMealPlansProvider =
    FutureProvider<List<CommunityMealPlan>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  final repo = ref.read(communityMealPlanRepositoryProvider);
  return repo.getMyAllPlans(userId);
});

// ── Gespeicherte Pläne ────────────────────────────────────────────────────

final savedMealPlansProvider = FutureProvider<List<CommunityMealPlan>>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];
  final repo = ref.read(communityMealPlanRepositoryProvider);
  return repo.getSavedPlans(userId);
});

// ── Publish ───────────────────────────────────────────────────────────────

class PublishMealPlanNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> publish({
    required String title,
    required String description,
    required List<MealPlanEntry> entries,
    required List<String> tags,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(communityMealPlanRepositoryProvider);
      final planJson = entries.map((e) => e.toJson()).toList();
      await repo.publish(
        title: title,
        description: description,
        planJson: planJson,
        tags: tags,
      );
      ref.invalidate(communityMealPlanFeedProvider);
      ref.invalidate(myPublishedMealPlansProvider);
      ref.invalidate(myAllMealPlansProvider);
    });
  }

  /// Veröffentlicht einen bestehenden Entwurf per UPDATE (kein neuer Datensatz)
  Future<void> publishExisting({
    required String planId,
    required String title,
    required String description,
    required List<MealPlanEntry> entries,
    required List<String> tags,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(communityMealPlanRepositoryProvider);
      final planJson = entries.map((e) => e.toJson()).toList();
      await repo.publishExistingPlan(
        planId: planId,
        title: title,
        description: description,
        planJson: planJson,
        tags: tags,
      );
      ref.invalidate(communityMealPlanFeedProvider);
      ref.invalidate(myPublishedMealPlansProvider);
      ref.invalidate(myAllMealPlansProvider);
    });
  }
}

final publishMealPlanProvider =
    AsyncNotifierProvider<PublishMealPlanNotifier, void>(PublishMealPlanNotifier.new);
