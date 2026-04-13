import 'dart:math';
import 'package:flutter/material.dart';

/// Donut-Chart für Makro-Nährwerte (Protein, Carbs, Fat, Ballaststoffe, Zucker).
/// Fünf konzentrische Bögen mit Kalorien-Anzeige in der Mitte.
class MacroRingChart extends StatelessWidget {
  final double proteinCurrent;
  final double proteinTarget;
  final double carbsCurrent;
  final double carbsTarget;
  final double fatCurrent;
  final double fatTarget;
  final double fiberCurrent;
  final double fiberTarget;
  final double sugarCurrent;
  final double sugarTarget;
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
    this.fiberCurrent = 0,
    this.fiberTarget = 30,
    this.sugarCurrent = 0,
    this.sugarTarget = 50,
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
              fiberFraction: fiberTarget > 0
                  ? (fiberCurrent / fiberTarget).clamp(0.0, 1.0)
                  : 0.0,
              sugarFraction: sugarTarget > 0
                  ? (sugarCurrent / sugarTarget).clamp(0.0, 1.0)
                  : 0.0,
              proteinColor: Colors.blue.shade400,
              carbsColor: Colors.orange.shade400,
              fatColor: Colors.amber.shade600,
              fiberColor: Colors.green.shade400,
              sugarColor: Colors.pink.shade300,
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
        // Legende Zeile 1: Protein, Carbs, Fett
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
              label: 'Kohlenhydr.',
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
        const SizedBox(height: 8),
        // Legende Zeile 2: Ballaststoffe, Zucker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _LegendItem(
              color: Colors.green.shade400,
              label: 'Ballaststoffe',
              current: fiberCurrent,
              target: fiberTarget,
              unit: 'g',
            ),
            _LegendItem(
              color: Colors.pink.shade300,
              label: 'Zucker',
              current: sugarCurrent,
              target: sugarTarget,
              unit: 'g',
              isLimit: true,
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
  final bool isLimit;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    this.isLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOver = isLimit && current > target && target > 0;
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
                color: isOver ? theme.colorScheme.error : color,
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
          isLimit
              ? '${current.toStringAsFixed(0)} / max ${target.toStringAsFixed(0)}$unit'
              : '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}$unit',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: isOver ? theme.colorScheme.error : null,
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
  final double fiberFraction;
  final double sugarFraction;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;
  final Color fiberColor;
  final Color sugarColor;
  final Color trackColor;

  _MacroRingPainter({
    required this.proteinFraction,
    required this.carbsFraction,
    required this.fatFraction,
    required this.fiberFraction,
    required this.sugarFraction,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.fiberColor,
    required this.sugarColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.07;
    const startAngle = -pi / 2;

    // Fünf Ringe von außen nach innen:
    // 1=Fett, 2=Carbs, 3=Protein, 4=Ballaststoffe, 5=Zucker
    final rings = [
      (size.width / 2 - strokeWidth * 0.6, fatFraction,     fatColor),
      (size.width / 2 - strokeWidth * 1.8, carbsFraction,   carbsColor),
      (size.width / 2 - strokeWidth * 3.0, proteinFraction, proteinColor),
      (size.width / 2 - strokeWidth * 4.2, fiberFraction,   fiberColor),
      (size.width / 2 - strokeWidth * 5.4, sugarFraction,   sugarColor),
    ];

    for (final (radius, fraction, color) in rings) {
      if (radius <= 0) continue;
      final rect = Rect.fromCircle(center: center, radius: radius);

      canvas.drawArc(
        rect, 0, 2 * pi, false,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      if (fraction > 0) {
        canvas.drawArc(
          rect, startAngle, 2 * pi * fraction, false,
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
      fatFraction != oldDelegate.fatFraction ||
      fiberFraction != oldDelegate.fiberFraction ||
      sugarFraction != oldDelegate.sugarFraction;
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
