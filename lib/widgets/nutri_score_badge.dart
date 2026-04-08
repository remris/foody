import 'package:flutter/material.dart';

/// Nutri-Score Badge: A (grün) bis E (rot).
/// Wird in Vorrat-Karten, Detail-Screens und Rezepten verwendet.
class NutriScoreBadge extends StatelessWidget {
  final String score; // 'a','b','c','d','e' (case-insensitive)
  final double size;
  const NutriScoreBadge({super.key, required this.score, this.size = 20});

  static Color colorFor(String s) {
    switch (s.toLowerCase()) {
      case 'a': return const Color(0xFF1A7C3E);
      case 'b': return const Color(0xFF53A830);
      case 'c': return const Color(0xFFF5C300);
      case 'd': return const Color(0xFFEF7D00);
      case 'e': return const Color(0xFFE63312);
      default:  return Colors.grey;
    }
  }

  /// Alias für colorFor – für externe Verwendung mit sprechendem Namen.
  static Color colorForScore(String s) => colorFor(s);

  @override
  Widget build(BuildContext context) {
    final s = score.toLowerCase();
    final color = colorFor(s);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          s.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.55,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Volle Nutri-Score Skala (A–E) mit Hervorhebung des aktiven Scores.
class NutriScoreScale extends StatelessWidget {
  final String score;
  const NutriScoreScale({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['a', 'b', 'c', 'd', 'e'].map((s) {
        final isActive = s == score.toLowerCase();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 3),
          width: isActive ? 28 : 20,
          height: isActive ? 28 : 20,
          decoration: BoxDecoration(
            color: NutriScoreBadge.colorFor(s)
                .withValues(alpha: isActive ? 1.0 : 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              s.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: isActive ? 14 : 10,
                height: 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

