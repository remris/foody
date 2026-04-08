import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomi/features/community/presentation/community_provider.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_tab.dart';
import 'package:kokomi/features/community/presentation/community_recipe_detail_screen.dart';
import 'package:kokomi/features/community/presentation/publish_recipe_sheet.dart';
import 'package:kokomi/features/community/presentation/publish_meal_plan_sheet.dart';
import 'package:kokomi/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomi/models/community_recipe.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/widgets/main_shell.dart' show AppBarMoreButton;

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _tabIndex) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openPublishSheet() async {
    if (_tabIndex == 1) {
      await showModalBottomSheet<bool>(
        context: context, isScrollControlled: true, useSafeArea: true,
        builder: (_) => const PublishMealPlanSheet(),
      );
      ref.invalidate(myPublishedMealPlansProvider);
    } else {
      final result = await showModalBottomSheet<bool>(
        context: context, isScrollControlled: true, useSafeArea: true,
        builder: (_) => const PublishRecipeSheet(),
      );
      if (result == true) ref.invalidate(myPublishedRecipesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entdecken'),
        actions: [
          const AppBarMoreButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.restaurant_outlined, size: 18),
              text: 'Rezepte',
            ),
            Tab(
              icon: Icon(Icons.calendar_month_outlined, size: 18),
              text: 'Wochenpläne',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CommunityRecipeFeedTab(),
          CommunityMealPlanTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublishSheet,
        icon: const Icon(Icons.upload_rounded),
        label: Text(_tabIndex == 1 ? 'Plan teilen' : 'Rezept teilen'),
      ),
    );
  }
}

// ─── Community Rezepte Feed ───────────────────────────────────────────────

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
  // einmal cachen statt bei jedem Card-Build abzufragen
  final String _currentUserId =
      SupabaseService.client.auth.currentUser?.id ?? '';

  static const _categories = [
    'Frühstück',
    'Mittagessen',
    'Abendessen',
    'Snack',
    'Dessert',
    'Backen',
    'Vegetarisch',
    'Vegan',
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
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: const Icon(Icons.search, size: 16),
                  onPressed: () =>
                      setState(() => _showSearch = !_showSearch),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('Alle',
                      style: TextStyle(fontSize: 12)),
                  selected: _activeCategory == null,
                  onSelected: (_) => _applyFilter(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              ..._categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(cat,
                          style: const TextStyle(fontSize: 12)),
                      selected: _activeCategory == cat,
                      onSelected: (_) => _applyFilter(
                          category:
                              _activeCategory == cat ? null : cat),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: feedAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(communityFeedProvider),
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
                onRefresh: () async => ref
                    .read(communityFeedProvider.notifier)
                    .refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemCount: state.recipes.length +
                      (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.recipes.length) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  CircularProgressIndicator()));
                    }
                    return _CommunityRecipeCard(
                      recipe: state.recipes[index],
                      currentUserId: _currentUserId,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CommunityRecipeDetailScreen(
                                      recipe:
                                          state.recipes[index]))),
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

// ─── Community Rezept Card ─────────────────────────────────────────────────

class _CommunityRecipeCard extends ConsumerWidget {
  final CommunityRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final String currentUserId;

  const _CommunityRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onLike,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOwn = recipe.userId == currentUserId;
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;
    final savedRecipes = ref.watch(savedRecipesProvider).valueOrNull ?? [];
    final isSaved = savedRecipes.any((r) => r.title == recipe.title);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Bild oder Placeholder ───
            Stack(
              children: [
                if (hasImage)
                  Image.network(
                    recipe.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderHeader(theme),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(height: 160, color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else
                  _buildPlaceholderHeader(theme),
                // Like + Save Overlay
                Positioned(
                  top: 8, right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Save-Button
                      GestureDetector(
                        onTap: isSaved ? null : () async {
                          await ref.read(savedRecipesProvider.notifier).saveRecipe(recipe.toFoodRecipe());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${recipe.title} gespeichert ✅'), duration: const Duration(seconds: 2)),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 16, color: isSaved ? Colors.amber : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Like-Button
                      _LikeButton(recipe: recipe, onLike: onLike),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel + Rating + Difficulty
                  Row(
                    children: [
                      Expanded(
                        child: Text(recipe.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      _RatingBadge(rating: recipe.avgRating, count: recipe.ratingCount),
                      const SizedBox(width: 6),
                      _DifficultyBadge(difficulty: recipe.difficulty),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: isOwn ? null : () => context.push('/profile/${recipe.userId}'),
                    child: Row(
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
                                color: isOwn
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.primary,
                                decoration: isOwn ? null : TextDecoration.underline)),
                        if (isOwn) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(recipe.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${recipe.cookingTimeMinutes} Min.', style: theme.textTheme.bodySmall),
                      if (recipe.category != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.restaurant_outlined, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(recipe.category!, style: theme.textTheme.bodySmall),
                      ],
                  const Spacer(),
                  Icon(Icons.comment_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text('${recipe.commentCount}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Icon(Icons.favorite_border_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text('${recipe.likeCount}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: recipe.tags.take(4).map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('#$t',
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderHeader(ThemeData theme) {
    final cat = (recipe.category ?? '').toLowerCase();
    final Color colorA;
    final Color colorB;
    final IconData icon;

    if (cat.contains('frühstück')) {
      colorA = const Color(0xFFF9A825); colorB = const Color(0xFFFF8F00);
      icon = Icons.wb_sunny_outlined;
    } else if (cat.contains('mittag')) {
      colorA = const Color(0xFF43A047); colorB = const Color(0xFF2E7D32);
      icon = Icons.lunch_dining_outlined;
    } else if (cat.contains('abend')) {
      colorA = const Color(0xFF1565C0); colorB = const Color(0xFF0D47A1);
      icon = Icons.dinner_dining_outlined;
    } else if (cat.contains('dessert') || cat.contains('snack')) {
      colorA = const Color(0xFFE91E63); colorB = const Color(0xFF880E4F);
      icon = Icons.cake_outlined;
    } else {
      colorA = theme.colorScheme.primary;
      colorB = theme.colorScheme.secondary;
      icon = Icons.restaurant_menu_outlined;
    }

    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorA, colorB],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -10, bottom: -20,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Icon(icon, size: 36, color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

/// Like-Button (inline oder über Bild)
class _LikeButton extends StatelessWidget {
  final CommunityRecipe recipe;
  final VoidCallback onLike;
  const _LikeButton({required this.recipe, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onLike,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              recipe.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 14,
              color: recipe.isLikedByMe ? Colors.redAccent : Colors.white,
            ),
            const SizedBox(width: 4),
            Text('${recipe.likeCount}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
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
      case 'einfach':
        return Colors.green;
      case 'mittel':
        return Colors.orange;
      case 'schwer':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(difficulty,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w700)),
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
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle),
            child: Icon(Icons.people_alt_rounded,
                size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Die Community wartet auf dich!',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center),
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

