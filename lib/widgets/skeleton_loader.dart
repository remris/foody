import 'package:flutter/material.dart';

/// Shimmer-Effekt Widget für Skeleton-Loading.
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Skeleton-Zeile (für Text-Platzhalter).
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton-Card für Inventar-Items.
class InventorySkeletonCard extends StatelessWidget {
  const InventorySkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Avatar
            const SkeletonLine(width: 48, height: 48, borderRadius: 12),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: MediaQuery.of(context).size.width * 0.4),
                  const SizedBox(height: 6),
                  const SkeletonLine(width: 80, height: 10),
                ],
              ),
            ),
            // Ablaufdatum
            const SkeletonLine(width: 60, height: 36, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}

/// Skeleton-Card für Einkaufsliste-Items.
class ShoppingSkeletonCard extends StatelessWidget {
  const ShoppingSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            const SkeletonLine(width: 24, height: 24, borderRadius: 4),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: MediaQuery.of(context).size.width * 0.5),
                  const SizedBox(height: 4),
                  const SkeletonLine(width: 60, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton-Card für Rezepte.
class RecipeSkeletonCard extends StatelessWidget {
  const RecipeSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLine(width: MediaQuery.of(context).size.width * 0.6),
            const SizedBox(height: 8),
            const SkeletonLine(width: double.infinity, height: 10),
            const SizedBox(height: 4),
            const SkeletonLine(width: 180, height: 10),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SkeletonLine(width: 70, height: 28, borderRadius: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generischer Skeleton-Loading Wrapper.
/// Zeigt [count] skeleton Cards während [isLoading] true ist.
class SkeletonList extends StatelessWidget {
  final int count;
  final Widget Function() builder;

  const SkeletonList({
    super.key,
    this.count = 5,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        itemBuilder: (_, __) => builder(),
      ),
    );
  }
}

