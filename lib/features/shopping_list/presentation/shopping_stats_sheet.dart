import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/shopping_list/presentation/shopping_stats_provider.dart';

/// Bottom Sheet mit Einkaufslisten-Statistiken.
class ShoppingStatsSheet extends ConsumerWidget {
  const ShoppingStatsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(shoppingStatsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Einkaufs-Statistiken 📊',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (stats) {
                if (stats.totalPurchases == 0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Noch keine Daten',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Schließe deinen ersten Einkauf ab\num Statistiken zu sehen.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Überblick Kacheln ──
                    Row(
                      children: [
                        _StatCard(
                          icon: Icons.shopping_bag_rounded,
                          label: 'Gesamt\nEinkäufe',
                          value: stats.totalPurchases.toString(),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.today_rounded,
                          label: 'Diese\nWoche',
                          value: stats.thisWeekPurchases.toString(),
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          icon: Icons.list_alt_rounded,
                          label: 'Ø Artikel\npro Einkauf',
                          value: stats.averageListSize.toStringAsFixed(1),
                          color: Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Wochenaktivität ──
                    Text(
                      'Aktivität nach Wochentag',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WeekActivityChart(activity: stats.weeklyActivity),

                    const SizedBox(height: 20),

                    // ── Top Artikel ──
                    if (stats.topItems.isNotEmpty) ...[
                      Text(
                        '🏆 Häufigste Artikel',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...stats.topItems.take(10).toList().asMap().entries.map(
                        (entry) {
                          final rank = entry.key + 1;
                          final item = entry.value;
                          final maxCount = stats.topItems.first.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '#$rank',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: rank <= 3
                                          ? Colors.amber[700]
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: rank <= 3
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.key,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      LinearProgressIndicator(
                                        value: item.value / maxCount,
                                        backgroundColor: theme
                                            .colorScheme.surfaceContainerHighest,
                                        valueColor: AlwaysStoppedAnimation(
                                          rank == 1
                                              ? Colors.amber
                                              : rank == 2
                                                  ? Colors.grey[400]!
                                                  : rank == 3
                                                      ? Colors.brown[300]!
                                                      : theme
                                                          .colorScheme.primary,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${item.value}×',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekActivityChart extends StatelessWidget {
  final Map<String, int> activity;

  const _WeekActivityChart({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final maxVal = activity.values.fold(0, (a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((day) {
        final count = activity[day] ?? 0;
        final height = maxVal > 0 ? (count / maxVal * 60).clamp(4.0, 60.0) : 4.0;
        final isToday = day ==
            ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                [DateTime.now().weekday - 1];

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (count > 0)
                Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                day,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

