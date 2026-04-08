import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/core/utils/extensions.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/widgets/nutri_score_badge.dart';

/// Kompakte einklappbare Vorrats-Statistik-Zeile.
/// Standard: eine schmale Zeile mit Farbbalken + Zähler.
/// Beim Tippen klappt sich eine detailliertere Ansicht aus.
class InventoryStatsCard extends ConsumerStatefulWidget {
  const InventoryStatsCard({super.key});

  @override
  ConsumerState<InventoryStatsCard> createState() => _InventoryStatsCardState();
}

class _InventoryStatsCardState extends ConsumerState<InventoryStatsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryProvider).valueOrNull ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final total = items.length;
    final expired = items
        .where((i) => i.expiryDate != null && i.expiryDate!.isExpired)
        .length;
    final expiringSoon = items
        .where((i) =>
            i.expiryDate != null &&
            !i.expiryDate!.isExpired &&
            i.expiryDate!.isExpiringSoon)
        .length;
    final noExpiry = items.where((i) => i.expiryDate == null).length;
    final ok = total - expired - expiringSoon - noExpiry;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // ── Kompakte Zeile (immer sichtbar) ──────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Farbbalken mini
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 6,
                          child: Row(
                            children: [
                              if (ok > 0)
                                Expanded(
                                    flex: ok,
                                    child: Container(color: Colors.green)),
                              if (expiringSoon > 0)
                                Expanded(
                                    flex: expiringSoon,
                                    child: Container(color: Colors.orange)),
                              if (expired > 0)
                                Expanded(
                                    flex: expired,
                                    child: Container(color: Colors.red)),
                              if (noExpiry > 0)
                                Expanded(
                                    flex: noExpiry,
                                    child: Container(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Zähler
                    Text(
                      '$total Artikel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Warn-Badges inline
                    if (expired > 0) ...[
                      const SizedBox(width: 8),
                      _InlineBadge(
                          count: expired, color: Colors.red, icon: Icons.warning_rounded),
                    ],
                    if (expiringSoon > 0) ...[
                      const SizedBox(width: 4),
                      _InlineBadge(
                          count: expiringSoon,
                          color: Colors.orange,
                          icon: Icons.schedule_rounded),
                    ],
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),

              // ── Ausgeklappter Detail-Bereich ──────────────────────────
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 8),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          if (ok > 0)
                            _StatChip(
                                color: Colors.green,
                                label: '$ok frisch',
                                icon: Icons.check_circle_outline),
                          if (expiringSoon > 0)
                            _StatChip(
                                color: Colors.orange,
                                label: '$expiringSoon bald ablaufend',
                                icon: Icons.schedule),
                          if (expired > 0)
                            _StatChip(
                                color: Colors.red,
                                label: '$expired abgelaufen',
                                icon: Icons.warning_amber_rounded),
                          if (noExpiry > 0)
                            _StatChip(
                                color: theme.colorScheme.onSurfaceVariant,
                                label: '$noExpiry ohne MHD',
                                icon: Icons.help_outline),
                        ],
                      ),
                      // Nutri-Score Gesundheits-Score
                      Builder(builder: (_) {
                        final scored = items
                            .where((i) => i.nutriScore != null)
                            .toList();
                        if (scored.isEmpty) return const SizedBox.shrink();

                        // Score: A=5, B=4, C=3, D=2, E=1
                        final scoreMap = {'a': 5, 'b': 4, 'c': 3, 'd': 2, 'e': 1};
                        final total = scored.fold<int>(
                            0,
                            (s, i) =>
                                s + (scoreMap[i.nutriScore!.toLowerCase()] ?? 3));
                        final avg = total / scored.length;

                        // Verteilung
                        final counts = <String, int>{};
                        for (final i in scored) {
                          final k = i.nutriScore!.toLowerCase();
                          counts[k] = (counts[k] ?? 0) + 1;
                        }

                        final label = avg >= 4.5
                            ? '🟢 Sehr gesund'
                            : avg >= 3.5
                                ? '🟡 Gut'
                                : avg >= 2.5
                                    ? '🟠 Mittelmäßig'
                                    : '🔴 Verbesserungswürdig';

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '🥗 Vorrats-Gesundheitsscore',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    label,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Nutri-Score Verteilung als Balken
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  height: 8,
                                  child: Row(
                                    children: [
                                      for (final grade in ['a', 'b', 'c', 'd', 'e'])
                                        if ((counts[grade] ?? 0) > 0)
                                          Expanded(
                                            flex: counts[grade]!,
                                            child: Container(
                                              color: NutriScoreBadge.colorForScore(grade),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: [
                                  for (final grade in ['a', 'b', 'c', 'd', 'e'])
                                    if ((counts[grade] ?? 0) > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: NutriScoreBadge.colorForScore(grade),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${grade.toUpperCase()}: ${counts[grade]}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: theme.colorScheme
                                                    .onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                ],
                              ),
                              Text(
                                'Basiert auf ${scored.length} von ${items.length} Artikeln mit Nutri-Score',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Top-Kategorien
                      Builder(builder: (_) {
                        final catCounts = <String, int>{};
                        for (final item in items) {
                          final cat =
                              item.ingredientCategory ?? 'Sonstige';
                          catCounts[cat] = (catCounts[cat] ?? 0) + 1;
                        }
                        final topCats = catCounts.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        if (topCats.length <= 1) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: topCats.take(5).map((e) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${e.key} ${e.value}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  final int count;
  final Color color;
  final IconData icon;
  const _InlineBadge(
      {required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text('$count',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  const _StatChip(
      {required this.color, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
