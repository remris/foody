import 'package:flutter/material.dart';
import 'package:kokomu/features/community/presentation/community_recipe_detail_screen.dart';
import 'package:kokomu/models/community_recipe.dart';

/// Zeigt Rezepte eines User-Profils mit Links/Rechts-Swipe-Navigation.
class ProfileRecipePageView extends StatefulWidget {
  final List<CommunityRecipe> recipes;
  final int initialIndex;

  const ProfileRecipePageView({
    super.key,
    required this.recipes,
    required this.initialIndex,
  });

  @override
  State<ProfileRecipePageView> createState() => _ProfileRecipePageViewState();
}

class _ProfileRecipePageViewState extends State<ProfileRecipePageView> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.recipes.length;

    return Scaffold(
      body: Stack(
        children: [
          // ── PageView ────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) => CommunityRecipeDetailScreen(
              recipe: widget.recipes[i],
              embedded: true,
            ),
          ),

          // ── Zurück-Button (oben links, innerhalb SafeArea) ──────────
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),

          // ── Seitenindikator (oben rechts, innerhalb SafeArea) ───────
          if (total > 1)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / $total',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Linker Pfeil ────────────────────────────────────────────
          if (total > 1 && _currentIndex > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.surface.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant),
                    ),
                    child: Icon(Icons.chevron_left_rounded,
                        size: 22,
                        color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),

          // ── Rechter Pfeil ───────────────────────────────────────────
          if (total > 1 && _currentIndex < total - 1)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.surface.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant),
                    ),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 22,
                        color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),

          // ── Punkt-Indikator unten ───────────────────────────────────
          if (total > 1 && total <= 10)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

