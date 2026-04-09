import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/community/presentation/community_provider.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_tab.dart';
import 'package:kokomu/features/community/presentation/community_recipe_detail_screen.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_detail_screen.dart';
import 'package:kokomu/features/community/presentation/publish_recipe_sheet.dart';
import 'package:kokomu/features/community/presentation/publish_meal_plan_sheet.dart';
import 'package:kokomu/features/community/presentation/spoonacular_provider.dart';
import 'package:kokomu/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/features/settings/presentation/paywall_screen.dart';
import 'package:kokomu/models/community_recipe.dart';
import 'package:kokomu/models/community_meal_plan.dart';
import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/widgets/main_shell.dart' show AppBarMoreButton;
import 'package:kokomu/widgets/cooking_spoon_rating.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openPublishSheet() async {
    final currentTab = _tabController.index;
    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;

    if (currentTab == 1 && !isPro) {
      // Plan teilen – nur Pro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⭐ Plan teilen ist nur mit Pro verfügbar'),
          action: SnackBarAction(
            label: 'Pro holen',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const PaywallScreen(),
              );
            },
          ),
        ),
      );
      return;
    }

    if (currentTab == 1) {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const PublishMealPlanSheet(),
      );
      ref.invalidate(myPublishedMealPlansProvider);
    } else {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const PublishRecipeSheet(),
      );
      if (result == true) ref.invalidate(myPublishedRecipesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Teilen',
            onPressed: _openPublishSheet,
          ),
          const AppBarMoreButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_outlined, size: 18), text: 'Rezepte'),
            Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Wochenpläne'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Community-Rezepte-Feed ──
          const _CommunityRecipeFeedTab(),
          // ── Tab 2: Community-Wochenpläne-Feed ──
          const CommunityMealPlanTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublishSheet,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 1 ? 'Plan teilen' : 'Rezept teilen'),
      ),
    );
  }
}

// ─── Tab 1: Community-Rezepte-Feed (sauber getrennt) ──────────────────

class _CommunityRecipeFeedTab extends ConsumerStatefulWidget {
  const _CommunityRecipeFeedTab();

  @override
  ConsumerState<_CommunityRecipeFeedTab> createState() =>
      _CommunityRecipeFeedTabState();
}

class _CommunityRecipeFeedTabState
    extends ConsumerState<_CommunityRecipeFeedTab> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _activeCategory;
  bool _showSearch = false;

  static const _categories = [
    'Frühstück', 'Mittagessen', 'Abendessen', 'Snack',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(communityFeedProvider.notifier).loadMore();
    }
  }

  void _applyFilter({String? category}) {
    setState(() => _activeCategory = category);
    ref.read(communityFeedProvider.notifier).setFilter(
          category: category,
          searchQuery: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Column(
      children: [
        // ── Suchleiste ──
        if (_showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rezepte suchen...',
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showSearch = false;
                      _searchController.clear();
                    });
                    _applyFilter(category: _activeCategory);
                  },
                ),
              ),
              onSubmitted: (_) => _applyFilter(category: _activeCategory),
            ),
          ),

        // ── Kategorie-Filter ──
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: const Icon(Icons.search, size: 16),
                  onPressed: () =>
                      setState(() => _showSearch = !_showSearch),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('Alle', style: TextStyle(fontSize: 12)),
                  selected: _activeCategory == null,
                  onSelected: (_) => _applyFilter(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              ..._categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: _activeCategory == cat,
                      onSelected: (_) => _applyFilter(
                          category: _activeCategory == cat ? null : cat),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Rezepte-Feed ──
        Expanded(
          child: feedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(communityFeedProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
            data: (state) {
              if (state.recipes.isEmpty) {
                return _EmptyCommunityState(
                  onPublish: () => showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const PublishRecipeSheet(),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.read(communityFeedProvider.notifier).refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemCount:
                      state.recipes.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.recipes.length) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator()));
                    }
                    return _CommunityRecipeCard(
                      recipe: state.recipes[index],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CommunityRecipeDetailScreen(
                                  recipe: state.recipes[index]))),
                      onLike: () => ref
                          .read(communityFeedProvider.notifier)
                          .toggleLike(state.recipes[index].id),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Tab 3: Meine Inhalte ────────────────────────────────────────────────

class _MyContentTab extends ConsumerStatefulWidget {
  const _MyContentTab();

  @override
  ConsumerState<_MyContentTab> createState() => _MyContentTabState();
}

class _MyContentTabState extends ConsumerState<_MyContentTab> {
  int _segment = 0; // 0=Rezepte, 1=Wochenpläne

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // Segmented Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Meine Rezepte'), icon: Icon(Icons.restaurant_outlined, size: 16)),
              ButtonSegment(value: 1, label: Text('Meine Pläne'), icon: Icon(Icons.calendar_month_outlined, size: 16)),
            ],
            selected: {_segment},
            onSelectionChanged: (s) => setState(() => _segment = s.first),
          ),
        ),
        Expanded(
          child: _segment == 0 ? const _MyRecipesTab() : const _MyPlansTab(),
        ),
      ],
    );
  }
}

// ─── Meine Rezepte ────────────────────────────────────────────────────────

class _MyRecipesTab extends ConsumerWidget {
  const _MyRecipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myAsync = ref.watch(myPublishedRecipesProvider);

    return myAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (recipes) {
        if (recipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Noch keine eigenen Rezepte',
                      style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Teile deine Lieblingsrezepte mit der Community!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
          itemCount: recipes.length,
          itemBuilder: (context, i) {
            final r = recipes[i];
            return _CommunityRecipeCard(
              recipe: r,
              showDeleteButton: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CommunityRecipeDetailScreen(recipe: r))),
              onLike: () {},
              onDelete: () => _confirmDelete(context, ref, r.id),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept löschen?'),
        content: const Text('Das Rezept wird unwiderruflich aus der Community entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(myPublishedRecipesProvider.notifier).delete(id);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

// ─── Meine Wochenpläne ────────────────────────────────────────────────────

class _MyPlansTab extends ConsumerWidget {
  const _MyPlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plansAsync = ref.watch(myPublishedMealPlansProvider);

    return plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Noch keine geteilten Wochenpläne',
                      style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Erstelle einen Wochenplan und teile ihn mit der Community!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
          itemCount: plans.length,
          itemBuilder: (context, i) {
            final plan = plans[i];
            return _MealPlanListCard(
              plan: plan,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CommunityMealPlanDetailScreen(plan: plan))),
            );
          },
        );
      },
    );
  }
}

// ─── Wochenplan List Card ────────────────────────────────────────────────

class _MealPlanListCard extends StatelessWidget {
  final CommunityMealPlan plan;
  final VoidCallback onTap;

  const _MealPlanListCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(plan.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  // Rating kompakt
                  _RatingBadge(
                    rating: plan.avgRating,
                    count: plan.ratingCount,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.favorite_border_rounded, size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${plan.likeCount}', style: theme.textTheme.bodySmall),
                ],
              ),
              if (plan.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(plan.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
              if (plan.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: plan.tags.take(4)
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('#$t',
                                style: TextStyle(fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Community Rezept Card ─────────────────────────────────────────────────

class _CommunityRecipeCard extends StatelessWidget {
  final CommunityRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const _CommunityRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onLike,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = SupabaseService.client.auth.currentUser?.id ?? '';
    final isOwn = recipe.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel + Rating + Schwierigkeits-Badge
              Row(
                children: [
                  Expanded(
                    child: Text(recipe.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  _RatingBadge(
                    rating: recipe.avgRating,
                    count: recipe.ratingCount,
                  ),
                  const SizedBox(width: 6),
                  _DifficultyBadge(difficulty: recipe.difficulty),
                ],
              ),
              const SizedBox(height: 4),
              // Autor
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      recipe.authorName.isNotEmpty
                          ? recipe.authorName[0].toUpperCase()
                          : 'F',
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(recipe.authorName,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  if (isOwn) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Du',
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onPrimaryContainer)),
                    ),
                  ],
                ],
              ),
              if (recipe.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 10),
              // Meta-Zeile
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('${recipe.cookingTimeMinutes} Min.',
                      style: theme.textTheme.bodySmall),
                  if (recipe.category != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.restaurant_outlined,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(recipe.category!, style: theme.textTheme.bodySmall),
                  ],
                  const Spacer(),
                  // Like-Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onLike();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          recipe.isLikedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: recipe.isLikedByMe
                              ? Colors.redAccent
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text('${recipe.likeCount}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.comment_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${recipe.commentCount}',
                      style: theme.textTheme.bodySmall),
                  if (showDeleteButton && isOwn) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(Icons.delete_outline,
                          size: 18, color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: recipe.tags.take(4)
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('#$t',
                                style: TextStyle(fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kompaktes Rating-Badge: "🥄 4.5 (12)" oder "(0)" wenn noch keine Bewertung
class _RatingBadge extends StatelessWidget {
  final double? rating;
  final int count;
  const _RatingBadge({this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRating = rating != null && count > 0;
    final color = hasRating ? Colors.orange.shade700 : theme.colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasRating ? Icons.soup_kitchen_rounded : Icons.soup_kitchen_outlined,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          hasRating ? '${rating!.toStringAsFixed(1)} ($count)' : '(0)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: hasRating ? FontWeight.w700 : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  Color _color() {
    switch (difficulty.toLowerCase()) {
      case 'einfach': return Colors.green;
      case 'mittel': return Colors.orange;
      case 'schwer': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(difficulty,
          style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Sort & Rating Filter Bottom Sheet ───────────────────────────────────

class _SortFilterSheet extends StatefulWidget {
  final String currentSort;
  final double currentMinRating;
  final void Function(String sort, double minRating) onApply;

  const _SortFilterSheet({
    required this.currentSort,
    required this.currentMinRating,
    required this.onApply,
  });

  @override
  State<_SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<_SortFilterSheet> {
  late String _sort;
  late double _minRating;

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
    _minRating = widget.currentMinRating;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Sortierung & Filter',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _sort = 'random';
                      _minRating = 0;
                    });
                  },
                  child: const Text('Zurücksetzen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Sortieren nach', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ('random', 'Entdecken', Icons.shuffle_rounded),
                ('newest', 'Neueste', Icons.new_releases_outlined),
                ('top_rated', 'Top bewertet', Icons.soup_kitchen_rounded),
              ].map((t) {
                final isSelected = _sort == t.$1;
                return ChoiceChip(
                  avatar: Icon(t.$3, size: 16),
                  label: Text(t.$2),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _sort = t.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Mindestbewertung', style: theme.textTheme.labelLarge),
                const Spacer(),
                if (_minRating > 0)
                  Text(
                    '${_minRating.toInt()} Kochlöffel',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  )
                else
                  Text('Alle',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RatingFilterButton(
                    value: 0, current: _minRating, label: 'Alle',
                    onTap: () => setState(() => _minRating = 0)),
                ...List.generate(5, (i) {
                  final v = (i + 1).toDouble();
                  return _RatingFilterButton(
                    value: v,
                    current: _minRating,
                    label: '${i + 1}🥄+',
                    onTap: () => setState(() => _minRating = v),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_sort, _minRating);
                },
                child: const Text('Anwenden'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingFilterButton extends StatelessWidget {
  final double value;
  final double current;
  final String label;
  final VoidCallback onTap;

  const _RatingFilterButton({
    required this.value,
    required this.current,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  final Future<bool?> Function() onPublish;
  const _EmptyCommunityState({required this.onPublish});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle),
            child: Icon(Icons.people_alt_rounded, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Die Community wartet auf dich!',
              style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Sei der Erste und teile dein Lieblingsrezept.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onPublish,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Erstes Rezept teilen'),
          ),
        ],
      ),
    );
  }
}

// ─── Entdecken Tab (Spoonacular) – bleibt als Hilfsklasse ─────────────────
// (wird nicht mehr im Tab gezeigt, aber von anderen Screens verwendet)

class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab();
  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  final _searchController = TextEditingController();
  String? _activeDiet;

  static const _diets = [
    ('Alle', null),
    ('Vegetarisch', 'vegetarian'),
    ('Vegan', 'vegan'),
    ('Glutenfrei', 'glutenFree'),
  ];

  static const _quickSearches = [
    'Pasta', 'Suppe', 'Salat', 'Pizza', 'Curry',
    'Risotto', 'Steak', 'Hähnchen', 'Dessert', 'Frühstück',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(spoonacularProvider);
      if (state.recipes.isEmpty && !state.isLoading) {
        ref.read(spoonacularProvider.notifier).loadRandom();
      }
    });
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(spoonacularProvider);
    final service = ref.read(spoonacularProvider.notifier);
    final isConfigured = ref.read(spoonacularServiceProvider.select((s) => s.isConfigured));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Deutsche Rezepte entdecken...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(icon: const Icon(Icons.close), onPressed: () {
                  _searchController.clear();
                  service.loadRandom();
                  setState(() {});
                }),
            ],
            onSubmitted: (q) { if (q.trim().isNotEmpty) service.search(query: q, diet: _activeDiet); },
            onChanged: (_) => setState(() {}),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: _diets.map((d) {
              final isSelected = _activeDiet == d.$2;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(d.$1),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _activeDiet = isSelected ? null : d.$2);
                    final q = _searchController.text.trim();
                    service.search(query: q.isEmpty ? 'Rezept' : q, diet: isSelected ? null : d.$2);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        if (state.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (state.recipes.isEmpty)
          Expanded(child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Keine Rezepte gefunden.'),
              TextButton(onPressed: () => service.loadRandom(), child: const Text('Zufällige laden')),
            ],
          )))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
              itemCount: state.recipes.length,
              itemBuilder: (context, i) {
                final recipe = state.recipes[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${recipe.cookingTimeMinutes} Min. · ${recipe.difficulty}',
                        style: theme.textTheme.bodySmall),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe))),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
