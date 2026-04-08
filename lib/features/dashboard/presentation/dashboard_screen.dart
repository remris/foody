import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomi/core/utils/extensions.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/features/nutrition/presentation/nutrition_provider.dart';
import 'package:kokomi/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomi/features/recipes/presentation/cooking_streak_provider.dart';
import 'package:kokomi/features/meal_plan/presentation/meal_plan_provider.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/features/household/presentation/household_provider.dart';
import 'package:kokomi/features/profile/presentation/profile_provider.dart';
import 'package:kokomi/features/profile/presentation/following_feed_screen.dart';
import 'package:kokomi/models/inventory_item.dart';
import 'package:kokomi/widgets/main_shell.dart' show AppBarMoreButton;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = 'Hi';
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(ownProfileProvider).valueOrNull;
    final name = (profile?.displayName.isNotEmpty == true)
        ? profile!.displayName
        : (user?.email?.split('@').first ?? '');
    final isPro = ref.watch(isProProvider);
    final theme = Theme.of(context);
    final isFeedTab = _tabController.index == 1;

    // Filter-Aktivität aus Provider
    final feedFilter = ref.watch(feedFilterProvider);
    final filterActive = feedFilter.length < 3;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isFeedTab) ...[
            // Filter-Button mit Punkt wenn aktiv
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  tooltip: 'Feed-Filter',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => const FeedFilterSheet(),
                  ),
                ),
                if (filterActive)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
           if (!isFeedTab) ...[Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Scanner',
              onPressed: () => context.push('/scanner'),
            ),
          ),
          ],
          const AppBarMoreButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            tabs: [
              const Tab(text: 'Home'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    const Text('Mein Feed'),
                  ],
                ),
              ),
            ],
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: Home-Übersicht
          _HomeContent(
            greeting: greeting,
            name: name,
            isPro: isPro,
            theme: theme,
            now: now,
          ),
          // Tab 1: Mein Feed (von gefolgten Usern)
          const FollowingFeedScreen(),
        ],
      ),
    );
  }
}

// ── Home-Content Widget ───────────────────────────────────────────────────────

class _HomeContent extends ConsumerWidget {
  final String greeting;
  final String name;
  final bool isPro;
  final ThemeData theme;
  final DateTime now;

  const _HomeContent({
    required this.greeting,
    required this.name,
    required this.isPro,
    required this.theme,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(inventoryProvider);
        ref.invalidate(shoppingListsProvider);
        ref.invalidate(mealPlanProvider);
      },
      child: CustomScrollView(
          slivers: [
            // ── Greeting Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting${name.isNotEmpty ? ', $name' : ''}! 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formattedDate(now),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
//                     if (isPro)
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFFFFB700), Color(0xFFFF6B00)],
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.star_rounded,
//                                 size: 14, color: Colors.white),
//                             SizedBox(width: 4),
//                             Text('Pro',
//                                 style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12)),
//                           ],
//                         ),
//                       ),
                  ],
                ),
              ),
            ),

            // ── Inhalt ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Heute im Wochenplan ──
                  const _TodayMealPlanCard(),
                  const SizedBox(height: 12),

                  // ── Einkaufslisten ──
                  const _ShoppingListsCard(),
                  const SizedBox(height: 12),

                  // ── Schnellzugriff ──
                  const _QuickActionsRow(),
                  const SizedBox(height: 12),

                  // ── Vorrat kompakt ──
                  const _InventoryOverviewCard(),
                  const SizedBox(height: 12),

                  // ── Ernährung ──
                  const _NutritionCard(),
                  const SizedBox(height: 12),

                  // ── Streak + Wasser nebeneinander ──
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        Expanded(child: _StreakCard()),
                        SizedBox(width: 10),
                        Expanded(child: _WaterCard()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Haushalt ──
                  const _HouseholdCard(),
                ]),
              ),
            ),
          ],
      ),
    );
  }

  String _formattedDate(DateTime d) {
    const weekdays = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    const months = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Streak-Card ──────────────────────────────────────────────────────────────

class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(cookingStreakProvider);
    final theme = Theme.of(context);
    final hasStreak = streak.currentStreak > 0;

    return _DashCard(
      onTap: () => context.go('/kitchen'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(streak.streakEmoji, style: const TextStyle(fontSize: 28)),
              const Spacer(),
              if (streak.longestStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('🏆 ${streak.longestStreak}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasStreak ? '${streak.currentStreak} Tage' : 'Kein Streak',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Koch-Streak',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (hasStreak) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (streak.currentStreak % 7) / 7,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(Colors.orange),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${7 - (streak.currentStreak % 7)} bis zur nächsten Woche',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Wasser-Card ──────────────────────────────────────────────────────────────

class _WaterCard extends ConsumerWidget {
  const _WaterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final water = ref.watch(waterTrackerProvider);
    final theme = Theme.of(context);
    final progress = water.progress.clamp(0.0, 1.0);

    return _DashCard(
      onTap: () => context.push('/settings/nutrition'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                water.goalReached ? '💧✅' : '💧',
                style: const TextStyle(fontSize: 28),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => ref.read(waterTrackerProvider.notifier).addWater(250),
                tooltip: '+250ml',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${water.currentLiters.toStringAsFixed(1)}L',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'von ${water.goalLiters.toStringAsFixed(1)}L',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                water.goalReached ? Colors.green : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            water.goalReached ? 'Ziel erreicht! 🎉' : '${water.remainingMl}ml fehlen noch',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.goalReached(water) ? Colors.green : theme.colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vorrats-Übersicht ────────────────────────────────────────────────────────

class _InventoryOverviewCard extends ConsumerWidget {
  const _InventoryOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryProvider);
    final theme = Theme.of(context);

    return _DashCard(
      onTap: () => context.go('/inventory'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.kitchen_rounded,
            iconColor: theme.colorScheme.primary,
            title: 'Mein Vorrat',
          ),
          const SizedBox(height: 10),
          itemsAsync.when(
            loading: () => const _SkeletonRow(),
            error: (_, __) => _ErrorText(theme: theme),
            data: (items) {
              if (items.isEmpty) {
                return _EmptyHint(
                  icon: Icons.add_box_outlined,
                  text: 'Noch leer – Artikel hinzufügen!',
                  theme: theme,
                );
              }
              final expired = items.where((i) => i.expiryDate != null && i.expiryDate!.isExpired).length;
              final soon = items.where((i) => i.expiryDate != null && !i.expiryDate!.isExpired && i.expiryDate!.isExpiringSoon).length;
              final ok = items.length - expired - soon;

              return Column(
                children: [
                  Row(
                    children: [
                      _MiniStat(value: '${items.length}', label: 'Gesamt', color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      _MiniStat(value: '$ok', label: 'Gut', color: Colors.green),
                      const SizedBox(width: 8),
                      if (soon > 0) _MiniStat(value: '$soon', label: 'Bald ab', color: Colors.orange),
                      if (soon > 0) const SizedBox(width: 8),
                      if (expired > 0) _MiniStat(value: '$expired', label: 'Abgelaufen', color: theme.colorScheme.error),
                    ],
                  ),
                  if (expired > 0 || soon > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (expired > 0 ? theme.colorScheme.error : Colors.orange).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            expired > 0 ? Icons.warning_rounded : Icons.hourglass_bottom_rounded,
                            size: 14,
                            color: expired > 0 ? theme.colorScheme.error : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expired > 0
                                ? '$expired Artikel abgelaufen – bitte prüfen!'
                                : '$soon Artikel laufen bald ab',
                            style: TextStyle(
                              fontSize: 12,
                              color: expired > 0 ? theme.colorScheme.error : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Ernährung ────────────────────────────────────────────────────────────────

class _NutritionCard extends ConsumerWidget {
  const _NutritionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(nutritionProfileProvider);
    final summary = ref.watch(todayNutritionSummaryProvider);
    final theme = Theme.of(context);

    return _DashCard(
      onTap: () => context.push('/settings/nutrition'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.deepOrange,
            title: 'Ernährung heute',
            trailing: profile != null
                ? Text(
                    '${summary.totalCalories} / ${profile.calorieGoal} kcal',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          if (profile == null)
            _EmptyHint(
              icon: Icons.tune_rounded,
              text: 'Ernährungsziel einrichten',
              theme: theme,
            )
          else ...[
            // Kalorienbalken
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: profile.calorieGoal > 0
                    ? (summary.totalCalories / profile.calorieGoal).clamp(0.0, 1.0)
                    : 0,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  summary.totalCalories > profile.calorieGoal ? theme.colorScheme.error : Colors.deepOrange,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Makro-Row
            Row(
              children: [
                _MacroBar(
                  label: 'Protein',
                  value: summary.totalProtein,
                  target: profile.proteinGoalG,
                  color: Colors.blue,
                  unit: 'g',
                ),
                const SizedBox(width: 8),
                _MacroBar(
                  label: 'Carbs',
                  value: summary.totalCarbs,
                  target: profile.carbsGoalG,
                  color: Colors.amber.shade700,
                  unit: 'g',
                ),
                const SizedBox(width: 8),
                _MacroBar(
                  label: 'Fett',
                  value: summary.totalFat,
                  target: profile.fatGoalG,
                  color: Colors.green,
                  unit: 'g',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;
  final String unit;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('${value.round()}$unit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Heute im Wochenplan ──────────────────────────────────────────────────────

/// Gibt den aktuell relevanten MealSlot basierend auf der Uhrzeit zurück.
MealSlot _currentMealSlot(int hour) {
  if (hour < 10) return MealSlot.breakfast;
  if (hour < 15) return MealSlot.lunch;
  if (hour < 18) return MealSlot.snack;
  return MealSlot.dinner;
}

class _TodayMealPlanCard extends ConsumerWidget {
  const _TodayMealPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(mealPlanProvider);
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final activeSlot = _currentMealSlot(now.hour);
    final theme = Theme.of(context);

    return _DashCard(
      onTap: () => context.push('/kitchen/meal-plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.today_rounded,
            iconColor: theme.colorScheme.secondary,
            title: 'Heute kochen',
          ),
          const SizedBox(height: 10),
          planAsync.when(
            loading: () => const _SkeletonRow(),
            error: (_, __) => _ErrorText(theme: theme),
            data: (entries) {
              final todayEntries = entries
                  .where((e) => e.dayIndex == todayIndex)
                  .toList()
                ..sort((a, b) => a.slot.index.compareTo(b.slot.index));

              if (todayEntries.isEmpty) {
                return _EmptyHint(
                  icon: Icons.calendar_today_outlined,
                  text: 'Noch nichts geplant – Wochenplan öffnen',
                  theme: theme,
                );
              }

              return Column(
                children: todayEntries.map((entry) {
                  final isActive = entry.slot == activeSlot;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _showCookingSheet(context, ref, entry),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.secondaryContainer.withOpacity(0.4)
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: isActive
                              ? Border.all(
                                  color: theme.colorScheme.secondary,
                                  width: 1.5,
                                )
                              : Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                  width: 0.5,
                                ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  entry.slot.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.recipe.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? theme.colorScheme.onSecondaryContainer
                                          : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${entry.slot.label}${entry.calories > 0 ? ' · ${entry.calories} kcal' : ''}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: isActive
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCookingSheet(BuildContext context, WidgetRef ref, MealPlanEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CookingDoneSheet(entry: entry),
    );
  }
}

// ─── Reste-Dialog ─────────────────────────────────────────────────────────────

class _CookingDoneSheet extends ConsumerStatefulWidget {
  final MealPlanEntry entry;
  const _CookingDoneSheet({required this.entry});

  @override
  ConsumerState<_CookingDoneSheet> createState() => _CookingDoneSheetState();
}

class _CookingDoneSheetState extends ConsumerState<_CookingDoneSheet> {
  bool _hasLeftovers = false;
  final _portionController = TextEditingController(text: '1');
  bool _saving = false;

  @override
  void dispose() {
    _portionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_hasLeftovers) {
        final userId = ref.read(currentUserProvider)?.id ?? '';
        if (userId.isEmpty) throw Exception('Nicht eingeloggt');
        final household = ref.read(householdProvider).valueOrNull;
        final portions = int.tryParse(_portionController.text.trim()) ?? 1;
        final item = InventoryItem(
          id: '',
          userId: userId,
          householdId: household?.id,
          ingredientId: 'reste_${DateTime.now().millisecondsSinceEpoch}',
          ingredientName: 'Reste: ${widget.entry.recipe.title}',
          ingredientCategory: 'Gekochtes',   // exakt wie im Filter
          quantity: portions.toDouble(),
          unit: 'Portion(en)',
          expiryDate: DateTime.now().add(const Duration(days: 2)),
          tags: const ['reste', 'gekochtes'], // exakt wie im Filter
          createdAt: DateTime.now(),
        );
        await ref.read(inventoryProvider.notifier).addItem(item);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasLeftovers
                ? '✅ Reste als Vorrat gespeichert!'
                : '👨‍🍳 Guten Appetit!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text(widget.entry.slot.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jetzt kochen',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.entry.recipe.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Zum Rezept
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/kitchen/meal-plan');
            },
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Rezept anzeigen'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Gibt es noch Reste? 🍲',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Reste werden automatisch in deinen Vorrat eingetragen.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _hasLeftovers = false),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: !_hasLeftovers
                        ? theme.colorScheme.secondaryContainer
                        : null,
                  ),
                  child: const Text('Keine Reste'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _hasLeftovers = true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _hasLeftovers
                        ? theme.colorScheme.secondaryContainer
                        : null,
                  ),
                  child: const Text('Ja, Reste'),
                ),
              ),
            ],
          ),
          if (_hasLeftovers) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Portionen:'),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _portionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Fertig'),
          ),
        ],
      ),
    );
  }
}

// ─── Haushalt-Card ────────────────────────────────────────────────────────────

class _HouseholdCard extends ConsumerWidget {
  const _HouseholdCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(householdProvider);
    final theme = Theme.of(context);

    return householdAsync.when(
      loading: () => _DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: Icons.people_alt_rounded,
              iconColor: Colors.indigo,
              title: 'Mein Haushalt',
            ),
            const SizedBox(height: 10),
            const _SkeletonRow(),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (household) {
        if (household == null) {
          // Kein Haushalt – Einladung zum Erstellen/Beitreten
          return _DashCard(
            onTap: () => context.go('/household'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  icon: Icons.people_alt_rounded,
                  iconColor: Colors.indigo,
                  title: 'Mein Haushalt',
                ),
                const SizedBox(height: 10),
                _EmptyHint(
                  icon: Icons.group_add_outlined,
                  text: 'Haushalt erstellen oder beitreten',
                  theme: theme,
                ),
              ],
            ),
          );
        }

        final activityAsync = ref.watch(householdActivityProvider);

        return _DashCard(
          onTap: () => context.go('/household'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                icon: Icons.people_alt_rounded,
                iconColor: Colors.indigo,
                title: household.name,
              ),
              const SizedBox(height: 10),
              activityAsync.when(
                loading: () => const _SkeletonRow(),
                error: (_, __) => _EmptyHint(
                  icon: Icons.history_rounded,
                  text: 'Keine Aktivitäten',
                  theme: theme,
                ),
                data: (activities) {
                  if (activities.isEmpty) {
                    return _EmptyHint(
                      icon: Icons.history_rounded,
                      text: 'Noch keine Aktivitäten',
                      theme: theme,
                    );
                  }
                  final recent = activities.take(3).toList();
                  return Column(
                    children: recent.map((entry) {
                      final actionIcon = switch (entry.action) {
                        'added' => Icons.add_circle_outline_rounded,
                        'deleted' => Icons.remove_circle_outline_rounded,
                        'checked' => Icons.check_circle_outline_rounded,
                        _ => Icons.edit_outlined,
                      };
                      final actionColor = switch (entry.action) {
                        'added' => Colors.green,
                        'deleted' => theme.colorScheme.error,
                        'checked' => Colors.blue,
                        _ => Colors.orange,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(actionIcon, size: 14, color: actionColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: theme.textTheme.bodySmall,
                                  children: [
                                    TextSpan(
                                      text: '${entry.displayName} ',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(text: '${entry.actionLabel} '),
                                    TextSpan(
                                      text: entry.itemName,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.relativeTime,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Einkaufslisten ───────────────────────────────────────────────────────────

class _ShoppingListsCard extends ConsumerWidget {
  const _ShoppingListsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(shoppingListsProvider);
    final theme = Theme.of(context);

    return _DashCard(
      onTap: () => context.go('/shopping'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.checklist_rounded,
            iconColor: theme.colorScheme.secondary,
            title: 'Einkaufslisten',
          ),
          const SizedBox(height: 10),
          listsAsync.when(
            loading: () => const _SkeletonRow(),
            error: (_, __) => _ErrorText(theme: theme),
            data: (lists) {
              if (lists.isEmpty) {
                return _EmptyHint(
                  icon: Icons.add_shopping_cart_rounded,
                  text: 'Noch keine Liste – jetzt erstellen',
                  theme: theme,
                );
              }
              return Column(
                children: lists.take(3).map((list) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(_iconForList(list.icon), size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            list.name,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (list.householdId != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.people_alt_outlined, size: 14, color: theme.colorScheme.primary),
                          ),
                        const Icon(Icons.chevron_right_rounded, size: 16),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _iconForList(String? icon) {
    switch (icon) {
      case 'shopping_cart': return Icons.shopping_cart_outlined;
      case 'group': return Icons.people_alt_outlined;
      case 'favorite': return Icons.favorite_outline;
      case 'local_grocery_store': return Icons.local_grocery_store_outlined;
      default: return Icons.checklist_rounded;
    }
  }
}

// ─── Schnellzugriff ───────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      (Icons.people_alt_rounded, 'Haushalt', Colors.indigo, () => context.go('/household')),
      (Icons.calendar_month_outlined, 'Wochenplan', theme.colorScheme.secondary, () => context.push('/kitchen/meal-plan')),
      (Icons.explore_outlined, 'Entdecken', Colors.orange, () => context.go('/discover')),
      (Icons.shopping_cart_rounded, 'Einkauf', Colors.teal, () => context.go('/shopping')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Schnellzugriff',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _QuickTile(icon: a.$1, label: a.$2, color: a.$3, onTap: a.$4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wiederverwendbare Basis-Card ─────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _DashCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

// ─── Card Header ──────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  const _CardHeader({required this.icon, required this.iconColor, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (trailing != null) trailing!
        else Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
      ],
    );
  }
}

// ─── Mini-Stat ────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 9)),
        ],
      ),
    );
  }
}

// ─── Hilfstexte ───────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const _EmptyHint({required this.icon, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final ThemeData theme;
  const _ErrorText({required this.theme});

  @override
  Widget build(BuildContext context) =>
      Text('Fehler beim Laden', style: TextStyle(color: theme.colorScheme.error, fontSize: 12));
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

// ─── Extension ───────────────────────────────────────────────────────────────

extension _WaterGoalExt on ThemeData {
  bool goalReached(WaterTrackerState w) => w.goalReached;
}

