import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Zeigt eine 1-5 Kochlöffel-Bewertung an.
/// Wenn [onRate] angegeben ist, ist das Widget interaktiv.
class CookingSpoonRating extends StatelessWidget {
  final double? rating; // null = keine Bewertung
  final int ratingCount;
  final int? myRating; // eigene Bewertung des Users
  final ValueChanged<int>? onRate; // null = read-only
  final double size;
  final bool showCount;
  final bool compact;

  const CookingSpoonRating({
    super.key,
    this.rating,
    this.ratingCount = 0,
    this.myRating,
    this.onRate,
    this.size = 20,
    this.showCount = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = Colors.orange.shade600;
    final inactiveColor = theme.colorScheme.outlineVariant;

    if (compact) {
      // Kompakte Darstellung: nur Ø-Wert + Icon
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.soup_kitchen_rounded,
              size: size * 0.9, color: rating != null ? activeColor : inactiveColor),
          const SizedBox(width: 3),
          Text(
            rating != null ? rating!.toStringAsFixed(1) : '–',
            style: TextStyle(
              fontSize: size * 0.65,
              fontWeight: FontWeight.w600,
              color: rating != null ? activeColor : inactiveColor,
            ),
          ),
          if (showCount && ratingCount > 0) ...[
            const SizedBox(width: 3),
            Text(
              '($ratingCount)',
              style: TextStyle(
                fontSize: size * 0.55,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }

    // Interaktive oder volle Darstellung: 5 Kochlöffel
    final spoons = List.generate(5, (i) {
      final starIndex = i + 1;
      final isActive = onRate != null
          ? (myRating != null && starIndex <= myRating!)
          : (rating != null && starIndex <= (rating!).round());
      final isHalfActive = onRate == null &&
          rating != null &&
          !isActive &&
          starIndex - 0.5 <= rating!;

      return GestureDetector(
        onTap: onRate != null
            ? () {
                HapticFeedback.lightImpact();
                onRate!(starIndex);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            isActive || isHalfActive
                ? Icons.soup_kitchen_rounded
                : Icons.soup_kitchen_outlined,
            size: size,
            color: isActive || isHalfActive ? activeColor : inactiveColor,
          ),
        ),
      );
    });

    if (!showCount) {
      return Row(mainAxisSize: MainAxisSize.min, children: spoons);
    }

    // Label: "4.2 (12)"  oder "(0)" wenn noch keine
    final label = rating != null
        ? '${rating!.toStringAsFixed(1)}${ratingCount > 0 ? ' ($ratingCount)' : ''}'
        : '(${ratingCount})';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...spoons,
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size * 0.65,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog zum Bewerten eines Rezepts / Wochenplans
Future<int?> showRatingDialog(
  BuildContext context, {
  required String title,
  int? currentRating,
}) async {
  int selectedStars = currentRating ?? 0;

  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wie bewertest du dieses Rezept?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                final isSelected = starIndex <= selectedStars;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => selectedStars = starIndex);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isSelected
                          ? Icons.soup_kitchen_rounded
                          : Icons.soup_kitchen_outlined,
                      size: 36,
                      color: isSelected
                          ? Colors.orange.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              selectedStars == 0
                  ? 'Tippe auf einen Kochlöffel'
                  : _ratingLabel(selectedStars),
              style: TextStyle(
                color: selectedStars > 0
                    ? Colors.orange.shade700
                    : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: selectedStars > 0
                ? () => Navigator.pop(ctx, selectedStars)
                : null,
            child: const Text('Bewerten'),
          ),
        ],
      ),
    ),
  );
}

String _ratingLabel(int stars) {
  switch (stars) {
    case 1:
      return '😞 Nicht gut';
    case 2:
      return '😐 Geht so';
    case 3:
      return '😊 Gut';
    case 4:
      return '😋 Sehr gut';
    case 5:
      return '🤩 Ausgezeichnet!';
    default:
      return '';
  }
}

