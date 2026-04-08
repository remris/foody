import 'dart:math';
import 'package:flutter/material.dart';

/// Donut-Chart für Makro-Nährwerte (Protein, Carbs, Fat).
/// Drei konzentrische Bögen mit Kalorien-Anzeige in der Mitte.
class MacroRingChart extends StatelessWidget {
  final double proteinCurrent;
  final double proteinTarget;
  final double carbsCurrent;
  final double carbsTarget;
  final double fatCurrent;
  final double fatTarget;
  final int caloriesCurrent;
  final int caloriesTarget;
  final double size;

  const MacroRingChart({
    super.key,
    required this.proteinCurrent,
    required this.proteinTarget,
    required this.carbsCurrent,
    required this.carbsTarget,
    required this.fatCurrent,
    required this.fatTarget,
    required this.caloriesCurrent,
    required this.caloriesTarget,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _MacroRingPainter(
              proteinFraction: proteinTarget > 0
                  ? (proteinCurrent / proteinTarget).clamp(0.0, 1.0)
                  : 0.0,
              carbsFraction: carbsTarget > 0
                  ? (carbsCurrent / carbsTarget).clamp(0.0, 1.0)
                  : 0.0,
              fatFraction: fatTarget > 0
                  ? (fatCurrent / fatTarget).clamp(0.0, 1.0)
                  : 0.0,
              proteinColor: Colors.blue.shade400,
              carbsColor: Colors.orange.shade400,
              fatColor: Colors.amber.shade600,
              trackColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$caloriesCurrent',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: caloriesCurrent > caloriesTarget && caloriesTarget > 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'von $caloriesTarget kcal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legende
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _LegendItem(
              color: Colors.blue.shade400,
              label: 'Protein',
              current: proteinCurrent,
              target: proteinTarget,
              unit: 'g',
            ),
            _LegendItem(
              color: Colors.orange.shade400,
              label: 'Carbs',
              current: carbsCurrent,
              target: carbsTarget,
              unit: 'g',
            ),
            _LegendItem(
              color: Colors.amber.shade600,
              label: 'Fett',
              current: fatCurrent,
              target: fatTarget,
              unit: 'g',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double current;
  final double target;
  final String unit;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}$unit',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double proteinFraction;
  final double carbsFraction;
  final double fatFraction;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;
  final Color trackColor;

  _MacroRingPainter({
    required this.proteinFraction,
    required this.carbsFraction,
    required this.fatFraction,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.085;
    const startAngle = -pi / 2;

    // Drei Ringe von außen nach innen
    final rings = [
      (size.width / 2 - strokeWidth * 0.6, fatFraction, fatColor),
      (size.width / 2 - strokeWidth * 2.0, carbsFraction, carbsColor),
      (size.width / 2 - strokeWidth * 3.4, proteinFraction, proteinColor),
    ];

    for (final (radius, fraction, color) in rings) {
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Track (Hintergrund)
      canvas.drawArc(
        rect,
        0,
        2 * pi,
        false,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      // Fortschritt
      if (fraction > 0) {
        canvas.drawArc(
          rect,
          startAngle,
          2 * pi * fraction,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MacroRingPainter oldDelegate) =>
      proteinFraction != oldDelegate.proteinFraction ||
      carbsFraction != oldDelegate.carbsFraction ||
      fatFraction != oldDelegate.fatFraction;
}

/// Kompakter Kalorien-Fortschrittsbalken für den Inventar-Tab.
class CompactCalorieBar extends StatelessWidget {
  final int current;
  final int target;
  final VoidCallback? onTap;

  const CompactCalorieBar({
    super.key,
    required this.current,
    required this.target,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isOver = current > target && target > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 20,
              color: isOver ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Heute: $current kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isOver
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Ziel: $target kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOver ? theme.colorScheme.error : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

