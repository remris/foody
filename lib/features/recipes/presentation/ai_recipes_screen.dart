import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomi/features/recipes/presentation/recipe_provider.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_favorites_provider.dart';
import 'package:kokomi/features/settings/presentation/ai_usage_provider.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/features/settings/presentation/paywall_screen.dart';
import 'package:kokomi/features/community/presentation/community_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:kokomi/models/recipe.dart';
import 'package:flutter/services.dart';

/// Vollbild-Screen für KI-Rezeptgenerierung – erreichbar über FAB
class AiRecipesScreen extends ConsumerStatefulWidget {
  /// Optionale vorausgewählte Zutaten
  final List<String>? preSelectedIngredients;

  const AiRecipesScreen({super.key, this.preSelectedIngredients});

  @override
  ConsumerState<AiRecipesScreen> createState() => _AiRecipesScreenState();
}

class _AiRecipesScreenState extends ConsumerState<AiRecipesScreen> {
  final _promptController = TextEditingController();
  String? _activeStyle;
  bool _useInventory = true;

  static const _styleTags = [
    ('🇮🇹', 'Italienisch'),
    ('🇯🇵', 'Asiatisch'),
    ('🇩🇪', 'Deutsch'),
    ('🇲🇽', 'Mexikanisch'),
    ('🇮🇳', 'Indisch'),
    ('🇬🇷', 'Griechisch'),
    ('🇯🇵', 'Japanisch'),
    ('🇰🇷', 'Koreanisch'),
    ('🇹🇷', 'Türkisch'),
    ('🇫🇷', 'Französisch'),
    ('💪', 'High Protein'),
    ('🥗', 'Leicht & Frisch'),
    ('🍲', 'Meal Prep'),
    ('🌱', 'Vegetarisch'),
    ('🌿', 'Vegan'),
    ('⚡', 'Unter 20 Min'),
    ('🔥', 'Low Carb'),
    ('🍕', 'Comfort Food'),
    ('🌶️', 'Scharf'),
    ('🎉', 'Festlich'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedIngredients != null &&
        widget.preSelectedIngredients!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generate();
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generate() {
    final prompt = _promptController.text.trim();
    final styleHint = _activeStyle;

    String finalPrompt = '';
    if (prompt.isNotEmpty) {
      finalPrompt = prompt;
      if (styleHint != null) finalPrompt += ', $styleHint Stil';
    } else if (styleHint != null) {
      finalPrompt = '$styleHint Rezepte';
    }

    if (_useInventory) {
      final items = ref.read(inventoryProvider).valueOrNull ?? [];
      final ingredients = items.map((e) => e.ingredientName).toList();
      if (ingredients.isNotEmpty) {
        ref.read(recipeProvider.notifier).generateFromSelection(
              ingredients,
              additionalPrompt: finalPrompt.isEmpty ? null : finalPrompt,
            );
        return;
      }
    }

    if (finalPrompt.isNotEmpty) {
      ref.read(recipeProvider.notifier).generateFromPrompt(finalPrompt);
    } else {
      ref
          .read(recipeProvider.notifier)
          .generateFromPrompt('Überrasche mich mit einem kreativen Rezept');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final usageAsync = ref.watch(aiUsageProvider);
    final usedThisWeek = usageAsync.valueOrNull?.usedThisWeek ?? 0;
    final weeklyLimit = AiUsageNotifier.freeWeeklyLimit;
    final remaining = (weeklyLimit - usedThisWeek).clamp(0, weeklyLimit);
    final inventoryItems = ref.watch(inventoryProvider).valueOrNull ?? [];
    final recipesAsync = ref.watch(recipeProvider);
    final theme = Theme.of(context);
    final hasInventory = inventoryItems.isNotEmpty;

    final hasRecipes = recipesAsync.hasValue &&
        (recipesAsync.valueOrNull ?? []).isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildGradientHeader(
                context, theme, isPro, remaining, weeklyLimit, hasRecipes),
          ),
          SliverToBoxAdapter(
            child: _buildBody(
              context,
              theme,
              isPro,
              remaining,
              weeklyLimit,
              inventoryItems,
              hasInventory,
              recipesAsync,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(
    BuildContext context,
    ThemeData theme,
    bool isPro,
    int remaining,
    int weeklyLimit,
    bool hasRecipes,
  ) {
    final isEmpty = remaining == 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 28,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEmpty && !isPro
              ? [Colors.red.shade600, Colors.orange.shade500]
              : [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back + Neu Row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              if (hasRecipes)
                GestureDetector(
                  onTap: () => ref.read(recipeProvider.notifier).clear(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Neu',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Großes Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          // Titel
          const Text(
            'KI-Rezepte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          // Untertitel
          Text(
            'Lass dir Rezepte generieren',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          // Kontingent-Badge
          if (!isPro)
            GestureDetector(
              onTap: isEmpty
                  ? () => context.push('/settings/paywall')
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isEmpty
                      ? '⚠️ Limit erreicht – Pro upgraden'
                      : '$remaining von $weeklyLimit gratis übrig',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Text(
                '⭐ Pro – Unlimitierte Generierungen',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    bool isPro,
    int remaining,
    int weeklyLimit,
    List<dynamic> inventoryItems,
    bool hasInventory,
    AsyncValue<List<FoodRecipe>> recipesAsync,
  ) {
    // Loading
    if (recipesAsync.isLoading) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('KI generiert Rezepte…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    // Fehler
    if (recipesAsync.hasError) {
      final isLimit =
          recipesAsync.error.toString().contains('KI-LIMIT_REACHED');
      if (isLimit) return _KiLimitReached(weeklyLimit: weeklyLimit);
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('${recipesAsync.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    // Rezepte vorhanden
    final recipes = recipesAsync.valueOrNull ?? [];
    if (recipes.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('${recipes.length} Rezepte generiert',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipes.length,
            itemBuilder: (context, i) => _AiRecipeCard(
              recipe: recipes[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(
                    recipe: recipes[i],
                    isAiRecipe: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Eingabe-UI
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Abschnitt-Label
        Text(
          'Was möchtest du kochen?',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        // Prompt
        TextField(
          controller: _promptController,
          decoration: InputDecoration(
            hintText: 'z.B. Ein leichtes Abendessen mit Hähnchen...',
            prefixIcon: const Icon(Icons.auto_awesome_outlined),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send_rounded),
              onPressed: _generate,
            ),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          minLines: 2,
          maxLines: 3,
          onSubmitted: (_) => _generate(),
          textInputAction: TextInputAction.send,
        ),
        const SizedBox(height: 20),

        // Stil-Tags
        Row(
          children: [
            Text('Stil & Küche',
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700)),
            if (_activeStyle != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _activeStyle = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_activeStyle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.close_rounded,
                          size: 12,
                          color: theme.colorScheme.onPrimaryContainer),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _styleTags.map((tag) {
            final isActive = _activeStyle == tag.$2;
            return FilterChip(
              label: Text('${tag.$1} ${tag.$2}',
                  style: const TextStyle(fontSize: 12)),
              selected: isActive,
              onSelected: (_) =>
                  setState(() => _activeStyle = isActive ? null : tag.$2),
              visualDensity: VisualDensity.compact,
              selectedColor: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 2),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Vorrat Toggle
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _useInventory && hasInventory
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: SwitchListTile(
            value: _useInventory && hasInventory,
            onChanged: hasInventory
                ? (val) => setState(() => _useInventory = val)
                : null,
            title: Text(
              hasInventory
                  ? 'Vorrat verwenden (${inventoryItems.length} Zutaten)'
                  : 'Kein Vorrat vorhanden',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              hasInventory
                  ? _useInventory
                      ? 'Rezepte basieren auf deinen Vorratszutaten'
                      : 'Rezepte werden nur nach Stil/Prompt generiert'
                  : 'Füge zuerst Zutaten zum Vorrat hinzu',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            secondary: Icon(
              Icons.kitchen_rounded,
              color: _useInventory && hasInventory
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          ),
        ),
        const SizedBox(height: 20),

        // Generieren-Button (Gradient wie im Screenshot)
        GestureDetector(
          onTap: _generate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Rezepte generieren',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _promptController.clear();
            setState(() => _activeStyle = null);
            ref.read(recipeProvider.notifier).generateFromPrompt(
                'Überrasche mich mit einem völlig unerwarteten, '
                'kreativen Rezept aus einer anderen Kultur');
          },
          icon: const Icon(Icons.shuffle_rounded, size: 18),
          label: const Text('Überrasch mich!'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}


// ─── KI-Limit erreicht ───────────────────────────────────────────────────

class _KiLimitReached extends ConsumerWidget {
  final int weeklyLimit;
  const _KiLimitReached({required this.weeklyLimit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final daysUntilMonday = 8 - now.weekday;
    final nextMonday =
        now.add(Duration(days: daysUntilMonday == 7 ? 7 : daysUntilMonday));
    final resetLabel =
        '${nextMonday.day.toString().padLeft(2, '0')}.${nextMonday.month.toString().padLeft(2, '0')}.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome,
                  size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('KI-Limit erreicht',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Du hast $weeklyLimit von $weeklyLimit KI-Generierungen diese Woche genutzt.\n'
              'Neues Limit ab $resetLabel 🗓️',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const PaywallScreen(),
                ),
                icon: const Icon(Icons.star_rounded, size: 18),
                label: const Text('Auf Pro upgraden – ab 2,99 €/Monat'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                ref.read(recipeProvider.notifier).clear();
                Navigator.of(context).pop();
              },
              child: Text('Später vielleicht',
                  style:
                      TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rezept-Karte ────────────────────────────────────────────────────────

class _AiRecipeCard extends ConsumerWidget {
  final FoodRecipe recipe;
  final VoidCallback onTap;
  const _AiRecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favorites = ref.watch(recipeFavoritesProvider);
    final isFavorite = favorites.contains(recipe.id);
    final publishedAsync = ref.watch(myPublishedRecipesProvider);
    final isShared =
        publishedAsync.valueOrNull?.any((r) => r.title == recipe.title) ??
            false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(recipe.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  if (isShared)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Tooltip(
                        message: 'In Community geteilt',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt_rounded,
                                  size: 12,
                                  color: theme.colorScheme
                                      .onSecondaryContainer),
                              const SizedBox(width: 3),
                              Text('Geteilt',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme
                                          .onSecondaryContainer)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(recipeFavoritesProvider.notifier)
                          .toggleFavorite(recipe.id);
                    },
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? Colors.redAccent
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(recipe.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('${recipe.cookingTimeMinutes} Min.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  Icon(Icons.restaurant_outlined,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('${recipe.ingredients.length} Zutaten',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

