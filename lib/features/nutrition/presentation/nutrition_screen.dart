import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kokomu/features/nutrition/presentation/nutrition_provider.dart';
import 'package:kokomu/features/nutrition/presentation/nutrition_profile_sheet.dart';
import 'package:kokomu/features/nutrition/presentation/macro_ring_chart.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/features/settings/presentation/paywall_screen.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(subscriptionProvider).valueOrNull?.isPro ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ernährung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil bearbeiten',
            onPressed: () => _showProfileSheet(context),
          ),
        ],
      ),
      body: isPro
          ? const _NutritionDashboard()
          : const _ProTeaser(),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const NutritionProfileSheet(),
    );
  }
}

// ── Pro-Teaser für Free-User ──

class _ProTeaser extends ConsumerWidget {
  const _ProTeaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(nutritionProfileProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restaurant_menu_rounded,
                  size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Nährwert-Tracking',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Tracke deine täglichen Kalorien & Makros.\n'
              'Sieh deinen Fortschritt auf einen Blick.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Profil einrichten geht auch für Free-User
            if (profile == null)
              OutlinedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => const NutritionProfileSheet(),
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Profil einrichten (kostenlos)'),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text('Profil eingerichtet',
                              style: theme.textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tagesziel: ${profile.calorieGoal} kcal · '
                        'BMI: ${profile.bmi.toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Demo-Chart (ausgegraut)
            Opacity(
              opacity: 0.4,
              child: MacroRingChart(
                proteinCurrent: 45,
                proteinTarget: 120,
                carbsCurrent: 80,
                carbsTarget: 200,
                fatCurrent: 30,
                fatTarget: 65,
                fiberCurrent: 12,
                fiberTarget: 30,
                sugarCurrent: 28,
                sugarTarget: 50,
                caloriesCurrent: 820,
                caloriesTarget: 2000,
                size: 160,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Vollständiges Tracking mit Pro',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const PaywallScreen(),
              ),
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text('Auf Pro upgraden'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Haupt-Dashboard (Pro) ──

class _NutritionDashboard extends ConsumerWidget {
  const _NutritionDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(nutritionProfileProvider);
    final todaySummary = ref.watch(todayNutritionSummaryProvider);
    final weeklyAsync = ref.watch(weeklyNutritionProvider);

    if (profile == null) {
      return _NoProfileView();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyNutritionProvider);
        ref.invalidate(weeklyNutritionProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tagesziel-Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Heute',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => const NutritionProfileSheet(),
                ),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Profil'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Makro Ring Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: MacroRingChart(
                proteinCurrent: todaySummary.totalProtein,
                proteinTarget: profile.proteinGoalG,
                carbsCurrent: todaySummary.totalCarbs,
                carbsTarget: profile.carbsGoalG,
                fatCurrent: todaySummary.totalFat,
                fatTarget: profile.fatGoalG,
                fiberCurrent: todaySummary.totalFiber,
                fiberTarget: profile.fiberGoalG,
                sugarCurrent: todaySummary.totalSugar,
                sugarTarget: profile.sugarGoalG,
                caloriesCurrent: todaySummary.totalCalories,
                caloriesTarget: profile.calorieGoal,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Heutige Einträge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mahlzeiten',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '${todaySummary.entries.length} Einträge',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (todaySummary.entries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_outlined,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'Noch nichts gekocht heute.\nKoche ein Rezept und tippe „Fertig!" im Kochmodus.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...todaySummary.entries.map((entry) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.restaurant,
                          size: 18,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(entry.recipeTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${entry.calories} kcal · '
                      'P: ${entry.protein.toStringAsFixed(0)}g · '
                      'K: ${entry.carbs.toStringAsFixed(0)}g · '
                      'F: ${entry.fat.toStringAsFixed(0)}g',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '${entry.servings.toStringAsFixed(0)}x',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )),

          // Wassertracker
          const SizedBox(height: 20),
          const _WaterTrackerCard(),

          // Wochenauswertung
          const SizedBox(height: 24),
          Text('Diese Woche',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          weeklyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Fehler: $e'),
            data: (days) => _WeeklyChart(
              days: days,
              calorieGoal: profile.calorieGoal,
            ),
          ),
          const SizedBox(height: 16),

          // Gewichtsverlauf
          const _WeightTrackingCard(),
          const SizedBox(height: 16),

          // Profil-Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Dein Profil',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _ProfileChip(
                          icon: Icons.cake,
                          label: '${profile.age} Jahre'),
                      _ProfileChip(
                          icon: Icons.monitor_weight_outlined,
                          label: '${profile.weightKg.toStringAsFixed(0)} kg'),
                      _ProfileChip(
                          icon: Icons.height,
                          label: '${profile.heightCm.toStringAsFixed(0)} cm'),
                      _ProfileChip(
                          icon: Icons.speed,
                          label:
                              'BMI ${profile.bmi.toStringAsFixed(1)}'),
                      _ProfileChip(
                          icon: Icons.flag_outlined,
                          label: _goalLabel(profile.goal)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _goalLabel(NutritionGoal goal) {
    switch (goal) {
      case NutritionGoal.lose:
        return 'Abnehmen';
      case NutritionGoal.maintain:
        return 'Gewicht halten';
      case NutritionGoal.gain:
        return 'Aufbauen';
    }
  }
}

class _NoProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calculate_outlined,
                  size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Profil einrichten',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Richte dein Ernährungsprofil ein, damit wir dein persönliches Tagesziel berechnen können.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => const NutritionProfileSheet(),
              ),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Jetzt einrichten'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wochen-Balken-Chart ──

class _WeeklyChart extends StatelessWidget {
  final List<DailyNutritionSummary> days;
  final int calorieGoal;

  const _WeeklyChart({required this.days, required this.calorieGoal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = days
        .map((d) => d.totalCalories)
        .fold(calorieGoal, (a, b) => a > b ? a : b);
    final weekDays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final avg = days.isEmpty
        ? 0
        : days.map((d) => d.totalCalories).reduce((a, b) => a + b) ~/
            days.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (i) {
                  final day = days[i];
                  final cal = day.totalCalories;
                  final fraction = maxVal > 0 ? cal / maxVal : 0.0;
                  final goalFraction =
                      maxVal > 0 ? calorieGoal / maxVal : 0.0;
                  final isOver = cal > calorieGoal;
                  final isToday = i == days.length - 1;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (cal > 0)
                            Text(
                              '${(cal / 1000).toStringAsFixed(1)}k',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isOver
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Ziel-Linie
                                Positioned(
                                  bottom: 140 * goalFraction - 1,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 1.5,
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                // Balken
                                FractionallySizedBox(
                                  heightFactor: fraction.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isOver
                                          ? theme.colorScheme.error
                                              .withValues(alpha: 0.7)
                                          : isToday
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.primary
                                                  .withValues(alpha: 0.5),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weekDays[day.date.weekday - 1],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 11,
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ø $avg kcal/Tag',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 1.5,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ziel: $calorieGoal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ProfileChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ── Wassertracker ──

class _WaterTrackerCard extends ConsumerWidget {
  const _WaterTrackerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final water = ref.watch(waterTrackerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Wasser 💧',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              '${water.currentLiters.toStringAsFixed(1)} / ${water.goalLiters.toStringAsFixed(1)} L',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: water.goalReached
                    ? Colors.blue
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Fortschrittsbalken
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: water.progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      water.goalReached
                          ? Colors.blue.shade600
                          : Colors.blue.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (water.goalReached)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '✅ Tagesziel erreicht!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Noch ${water.remainingMl} ml übrig',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Quick-Add Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(waterTrackerProvider.notifier).addWater(250),
                        icon: const Icon(Icons.water_drop_outlined, size: 16),
                        label: const Text('+250 ml'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue.withValues(alpha: 0.4)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            ref.read(waterTrackerProvider.notifier).addWater(500),
                        icon: const Icon(Icons.water_drop, size: 16),
                        label: const Text('+500 ml'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: water.currentMl > 0
                          ? () => ref
                              .read(waterTrackerProvider.notifier)
                              .removeWater(250)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      tooltip: '-250 ml',
                      visualDensity: VisualDensity.compact,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gewichtsverlauf ──

class _WeightTrackingCard extends ConsumerWidget {
  const _WeightTrackingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(weightLogProvider);
    final profile = ref.watch(nutritionProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Gewichtsverlauf ⚖️',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            FilledButton.tonalIcon(
              onPressed: () => _showAddWeightDialog(context, ref, profile),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Eintragen'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: entries.length < 2
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.monitor_weight_outlined,
                            size: 32, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          entries.isEmpty
                              ? 'Trage dein Gewicht regelmäßig ein,\num deinen Verlauf zu sehen.'
                              : 'Noch ein Eintrag nötig für den Chart.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (entries.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Aktuell: ${entries.last.weightKg.toStringAsFixed(1)} kg',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  )
                : _WeightChart(entries: entries),
          ),
        ),
        if (entries.length >= 2) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aktuell: ${entries.last.weightKg.toStringAsFixed(1)} kg',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Builder(builder: (_) {
                  final diff = entries.last.weightKg - entries.first.weightKg;
                  final color = diff < 0 ? Colors.green : diff > 0 ? Colors.red : theme.colorScheme.onSurfaceVariant;
                  final arrow = diff < 0 ? '↓' : diff > 0 ? '↑' : '→';
                  return Text(
                    '$arrow ${diff.abs().toStringAsFixed(1)} kg',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showAddWeightDialog(BuildContext context, WidgetRef ref, NutritionProfile? profile) {
    final controller = TextEditingController(
      text: profile?.weightKg.toStringAsFixed(1) ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gewicht eintragen'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Gewicht (kg)',
            suffixText: 'kg',
            prefixIcon: Icon(Icons.monitor_weight_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final weight = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'));
              if (weight != null && weight > 20 && weight < 500) {
                ref.read(weightLogProvider.notifier).addEntry(weight);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${weight.toStringAsFixed(1)} kg eingetragen ✅'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

// ── Gewichts-Linien-Chart ──

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Nur die letzten 30 Einträge
    final data = entries.length > 30 ? entries.sublist(entries.length - 30) : entries;

    final minWeight = data.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b) - 1;
    final maxWeight = data.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b) + 1;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: minWeight,
          maxY: maxWeight,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxWeight - minWeight) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxWeight - minWeight) / 4,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (data.length / 4).ceilToDouble().clamp(1, 10),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  final d = data[idx].date;
                  return Text(
                    '${d.day}.${d.month}',
                    style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(data.length, (i) =>
                  FlSpot(i.toDouble(), data[i].weightKg)),
              isCurved: true,
              curveSmoothness: 0.2,
              color: theme.colorScheme.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3,
                  color: theme.colorScheme.primary,
                  strokeColor: theme.colorScheme.surface,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withOpacity(0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final entry = data[spot.x.toInt()];
                return LineTooltipItem(
                  '${entry.weightKg.toStringAsFixed(1)} kg\n${entry.date.day}.${entry.date.month}.${entry.date.year}',
                  TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
