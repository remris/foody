import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_detail_screen.dart';
import 'package:kokomi/models/community_meal_plan.dart';
import 'package:kokomi/widgets/cooking_spoon_rating.dart';

/// Tab im Community-Screen: Wochenpläne entdecken
class CommunityMealPlanTab extends ConsumerStatefulWidget {
  const CommunityMealPlanTab({super.key});

  @override
  ConsumerState<CommunityMealPlanTab> createState() =>
      _CommunityMealPlanTabState();
}

class _CommunityMealPlanTabState extends ConsumerState<CommunityMealPlanTab> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _activeTag;
  bool _showSearch = false;

  static const _filterTags = [
    'Vegetarisch', 'Vegan', 'Low Carb', 'High Protein',
    'Mediterran', 'Meal Prep', 'Familienfreundlich', 'Abnehmen',
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
      ref.read(communityMealPlanFeedProvider.notifier).loadMore();
    }
  }

  void _applyFilter({String? tag}) {
    setState(() => _activeTag = tag);
    ref.read(communityMealPlanFeedProvider.notifier).setFilter(
          tag: tag,
          searchQuery: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plansAsync = ref.watch(communityMealPlanFeedProvider);

    return Column(
      children: [
        // Suche
        if (_showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Wochenpläne suchen...',
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showSearch = false;
                      _searchController.clear();
                    });
                    _applyFilter(tag: _activeTag);
                  },
                ),
              ),
              onSubmitted: (_) => _applyFilter(tag: _activeTag),
            ),
          ),

        // Filter-Chips
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
                  onPressed: () => setState(() => _showSearch = !_showSearch),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('Alle', style: TextStyle(fontSize: 12)),
                  selected: _activeTag == null,
                  onSelected: (_) => _applyFilter(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              ..._filterTags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      selected: _activeTag == tag,
                      onSelected: (_) =>
                          _applyFilter(tag: _activeTag == tag ? null : tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
            ],
          ),
        ),

        const Divider(height: 1),

        // Feed
        Expanded(
          child: plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 8),
                  Text('Fehler: $e', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(communityMealPlanFeedProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 64,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('Noch keine Wochenpläne',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Sei der Erste und teile deinen Plan!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.read(communityMealPlanFeedProvider.notifier).refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: plans.length,
                  itemBuilder: (_, i) => _PlanCard(
                    plan: plans[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CommunityMealPlanDetailScreen(plan: plans[i]),
                      ),
                    ),
                    onLike: () => ref
                        .read(communityMealPlanFeedProvider.notifier)
                        .toggleLike(plans[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final CommunityMealPlan plan;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onLike,
  });

  static const _dayOrder = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  Widget _buildPlanHeader(ThemeData theme) {
    final str = '${plan.title} ${plan.tags.join(' ')} ${plan.description}'.toLowerCase();
    final Color a, b;
    if (str.contains('mediterran') || str.contains('mittelmeer')) {
      a = const Color(0xFF1E88E5); b = const Color(0xFF0D47A1);
    } else if (str.contains('vegan') || str.contains('vegetarisch')) {
      a = const Color(0xFF26A69A); b = const Color(0xFF00695C);
    } else if (str.contains('asiatisch') || str.contains('thai') || str.contains('koreanisch')) {
      a = const Color(0xFFFF8F00); b = const Color(0xFFE65100);
    } else if (str.contains('fitness') || str.contains('sport') || str.contains('protein')) {
      a = const Color(0xFF7B1FA2); b = const Color(0xFF4A148C);
    } else if (str.contains('herbst') || str.contains('winter') || str.contains('warm')) {
      a = const Color(0xFFBF360C); b = const Color(0xFF7F0000);
    } else {
      a = theme.colorScheme.secondary; b = theme.colorScheme.primary;
    }
    return Container(
      height: 110, width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(children: [
        Positioned(right: -15, bottom: -15, child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
        Center(child: Icon(Icons.calendar_month_rounded, size: 40, color: Colors.white.withValues(alpha: 0.8))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Geteilt-Indikator: prüfen ob dieser Plan von mir stammt
    final myPlansAsync = ref.watch(myPublishedMealPlansProvider);
    final isMyPlan =
        myPlansAsync.valueOrNull?.any((p) => p.id == plan.id) ?? false;
    final preview = plan.weekPreview;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Farbiger Gradient-Header ───
            Stack(
              children: [
                _buildPlanHeader(theme),
                // Like-Overlay oben rechts
                Positioned(
                  top: 8, right: 8,
                  child: InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          plan.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 12, color: plan.isLikedByMe ? Colors.redAccent : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text('${plan.likeCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
                // Wochenplan-Badge oben links
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_month_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text('Wochenplan',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      if (isMyPlan) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Mein Plan',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
            // ─── Info-Bereich ───
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel & Rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      CookingSpoonRating(
                        rating: plan.avgRating,
                        ratingCount: plan.ratingCount,
                        size: 14,
                        compact: true,
                        showCount: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Autor
                  GestureDetector(
                    onTap: isMyPlan ? null : () => context.push('/profile/${plan.userId}'),
                    child: Text(
                      'von ${plan.authorName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isMyPlan
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                        decoration: isMyPlan ? null : TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      plan.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // ─── Mini Wochenvorschau ───
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: _dayOrder
                            .where((d) => preview.containsKey(d))
                            .take(4)
                            .map((day) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        child: Text(day,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            fontSize: 10)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          preview[day]!.join(', '),
                                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (plan.avgDailyCalories > 0) ...[
                        Icon(Icons.local_fire_department_rounded,
                          size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text('~${plan.avgDailyCalories} kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.restaurant_menu_rounded,
                        size: 12, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text('${plan.entries.length} Mahlzeiten',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                      const Spacer(),
                      Text(_formatDate(plan.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                    ],
                  ),
                  if (plan.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: plan.tags.take(4).map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 9)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Heute';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

// ─── Sort & Rating Filter für Wochenpläne ────────────────────────────────

class _MealPlanSortFilterSheet extends StatefulWidget {
  final String currentSort;
  final double currentMinRating;
  final void Function(String sort, double minRating) onApply;

  const _MealPlanSortFilterSheet({
    required this.currentSort,
    required this.currentMinRating,
    required this.onApply,
  });

  @override
  State<_MealPlanSortFilterSheet> createState() => _MealPlanSortFilterSheetState();
}

class _MealPlanSortFilterSheetState extends State<_MealPlanSortFilterSheet> {
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
                  onPressed: () => setState(() {
                    _sort = 'random';
                    _minRating = 0;
                  }),
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
                Text(
                  _minRating > 0 ? '${_minRating.toInt()} Kochlöffel' : 'Alle',
                  style: TextStyle(
                    color: _minRating > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FilterBtn(value: 0, current: _minRating, label: 'Alle',
                    onTap: () => setState(() => _minRating = 0)),
                ...List.generate(5, (i) {
                  final v = (i + 1).toDouble();
                  return _FilterBtn(
                    value: v, current: _minRating, label: '${i + 1}🥄+',
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

class _FilterBtn extends StatelessWidget {
  final double value;
  final double current;
  final String label;
  final VoidCallback onTap;
  const _FilterBtn({required this.value, required this.current, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            )),
      ),
    );
  }
}
