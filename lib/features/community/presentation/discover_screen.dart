import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomu/features/community/presentation/community_provider.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_tab.dart';
import 'package:kokomu/features/community/presentation/community_recipe_detail_screen.dart';
import 'package:kokomu/features/community/presentation/publish_recipe_sheet.dart';
import 'package:kokomu/features/community/presentation/publish_meal_plan_sheet.dart';
import 'package:kokomu/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/features/settings/presentation/paywall_screen.dart';
import 'package:kokomu/models/community_recipe.dart';
import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/widgets/main_shell.dart' show AppBarMoreButton;

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
    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;

    if (_tabIndex == 1 && !isPro) {
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Rezepte'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Wochenpläne'),
                ],
              ),
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
  // User-Suche (@username)
  bool _isUserSearch = false;
  List<Map<String, dynamic>> _userResults = [];
  bool _isSearchingUsers = false;
  // Ernährungsfilter
  final _activeNutritionFilters = <String>{};

  final String _currentUserId =
      SupabaseService.client.auth.currentUser?.id ?? '';

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

  Future<void> _onSearchChanged(String val) async {
    if (val.startsWith('@')) {
      setState(() => _isUserSearch = true);
      final q = val.substring(1).trim();
      if (q.length < 1) {
        setState(() { _userResults = []; _isSearchingUsers = false; });
        return;
      }
      setState(() => _isSearchingUsers = true);
      try {
        final res = await SupabaseService.client
            .from('social_profiles')
            .select('id, display_name, avatar_url, bio')
            .ilike('display_name', '%$q%')
            .limit(20);
        if (mounted) setState(() {
          _userResults = List<Map<String, dynamic>>.from(res as List);
          _isSearchingUsers = false;
        });
      } catch (_) {
        if (mounted) setState(() { _userResults = []; _isSearchingUsers = false; });
      }
    } else {
      setState(() { _isUserSearch = false; _userResults = []; });
      _applyFilter(category: _activeCategory);
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
    final theme = Theme.of(context);
    final feedAsync = ref.watch(communityFeedProvider);

    return Column(
      children: [
        if (_showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: RawAutocomplete<Map<String, dynamic>>(
              textEditingController: _searchController,
              focusNode: FocusNode(),
              optionsBuilder: (tv) async {
                final val = tv.text;
                if (!val.startsWith('@') || val.length < 2) return [];
                final q = val.substring(1).trim();
                if (q.isEmpty) return [];
                try {
                  final res = await SupabaseService.client
                      .from('social_profiles')
                      .select('id, display_name, avatar_url, bio')
                      .ilike('display_name', '%$q%')
                      .limit(8);
                  return List<Map<String, dynamic>>.from(res as List);
                } catch (_) {
                  return [];
                }
              },
              displayStringForOption: (u) => '@${u['display_name']}',
              onSelected: (u) {
                setState(() {
                  _isUserSearch = true;
                  _userResults = [u];
                  _isSearchingUsers = false;
                });
                final uid = u['id'] as String?;
                if (uid != null) context.push('/profile/$uid');
              },
              fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => TextField(
                controller: ctrl,
                focusNode: focus,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rezepte suchen oder @username...',
                  isDense: true,
                  prefixIcon: Icon(
                    _isUserSearch ? Icons.person_search : Icons.search,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showSearch = false;
                        _isUserSearch = false;
                        _userResults = [];
                        _searchController.clear();
                      });
                      _applyFilter(category: _activeCategory);
                    },
                  ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) {
                  if (!_isUserSearch) _applyFilter(category: _activeCategory);
                },
              ),
              optionsViewBuilder: (ctx, onSel, opts) {
                final theme = Theme.of(ctx);
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        children: opts.map((u) {
                          final name = u['display_name'] as String? ?? '';
                          final avatar = u['avatar_url'] as String?;
                          final bio = u['bio'] as String?;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null
                                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: theme.textTheme.bodySmall)
                                  : null,
                            ),
                            title: Text('@$name',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: bio != null && bio.isNotEmpty
                                ? Text(bio, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall)
                                : null,
                            onTap: () => onSel(u),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        // User-Suchergebnisse
        if (_isUserSearch) ...[
          if (_isSearchingUsers)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (_userResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _searchController.text.length > 1
                    ? 'Kein User gefunden'
                    : 'Mindestens 2 Zeichen nach @ eingeben',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _userResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = _userResults[i];
                  final name = u['display_name'] as String? ?? 'Unbekannt';
                  final avatar = u['avatar_url'] as String?;
                  final bio = u['bio'] as String?;
                  final uid = u['id'] as String?;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: bio != null && bio.isNotEmpty
                        ? Text(bio, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: uid != null ? () => context.push('/profile/$uid') : null,
                  );
                },
              ),
            ),
        ] else ...[
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
        // Ernährungsfilter
        if (_activeNutritionFilters.isNotEmpty || true)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              children: [
                for (final filter in ['💪 High Protein', '🔥 Low Carb', '🍬 Kein Zucker'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(filter, style: const TextStyle(fontSize: 11)),
                      selected: _activeNutritionFilters.contains(filter),
                      onSelected: (v) => setState(() {
                        if (v) { _activeNutritionFilters.add(filter); }
                        else { _activeNutritionFilters.remove(filter); }
                      }),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
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
              // Ernährungsfilter anwenden
              var recipes = state.recipes;
              if (_activeNutritionFilters.isNotEmpty) {
                recipes = recipes.where((r) {
                  final n = r.nutrition;
                  if (n == null) return false; // Ohne Nährwerte → ausschließen
                  final servings = r.servings > 0 ? r.servings : 1;
                  for (final f in _activeNutritionFilters) {
                    if (f.contains('High Protein') && n.protein / servings < 20) return false;
                    if (f.contains('Low Carb') && n.carbs / servings > 30) return false;
                    if (f.contains('Kein Zucker') && n.sugar / servings > 5) return false;
                  }
                  return true;
                }).toList();
              }
              if (recipes.isEmpty) {
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
                  itemCount: recipes.length +
                      (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == recipes.length) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  CircularProgressIndicator()));
                    }
                    return _CommunityRecipeCard(
                      recipe: recipes[index],
                      currentUserId: _currentUserId,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CommunityRecipeDetailScreen(
                                      recipe:
                                          recipes[index]))),
                      onLike: () => ref
                          .read(communityFeedProvider.notifier)
                          .toggleLike(recipes[index].id),
                    );
                  },
                ),
              );
            },
          ),
        ),
        ], // Ende else (kein User-Suche)
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
                        const SizedBox(width: 8),
                        Icon(Icons.restaurant_outlined, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(recipe.category!,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis),
                        ),
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

// ─── User-Suche Tab ───────────────────────────────────────────────────────

class _UserSearchTab extends ConsumerStatefulWidget {
  const _UserSearchTab();

  @override
  ConsumerState<_UserSearchTab> createState() => _UserSearchTabState();
}

class _UserSearchTabState extends ConsumerState<_UserSearchTab> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final supabase = SupabaseService.client;
      final res = await supabase
          .from('social_profiles')
          .select('id, display_name, avatar_url, bio')
          .ilike('display_name', '%$q%')
          .limit(20);
      setState(() {
        _results = List<Map<String, dynamic>>.from(res as List);
        _hasSearched = true;
      });
    } catch (_) {
      setState(() { _results = []; _hasSearched = true; });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '@username oder Name suchen...',
              prefixIcon: const Icon(Icons.person_search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                    )
                  : null,
              isDense: true,
            ),
            onSubmitted: _search,
            onChanged: (v) {
              setState(() {});
              if (v.length >= 2) _search(v);
            },
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          )
        else if (_results.isEmpty && _hasSearched)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('Keine User gefunden.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          )
        else if (!_hasSearched)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('Suche nach @username',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Finde andere User und entdecke ihre Rezepte.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = _results[i];
                final name = u['display_name'] as String? ?? 'Unbekannt';
                final avatar = u['avatar_url'] as String?;
                final bio = u['bio'] as String?;
                final uid = u['id'] as String?;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: theme.textTheme.titleMedium)
                        : null,
                  ),
                  title: Text(name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: bio != null && bio.isNotEmpty
                      ? Text(bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall)
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: uid != null
                      ? () => context.push('/profile/$uid')
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }
}
