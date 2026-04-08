import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomi/features/recipes/presentation/recipe_provider.dart';
import 'package:kokomi/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_favorites_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_category_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_rating_provider.dart';
import 'package:kokomi/features/recipes/presentation/cooking_streak_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_collections_provider.dart';
// import 'package:kokomi/features/recipes/presentation/ai_chat_tab.dart'; // Küchenassistent deaktiviert
import 'package:kokomi/features/meal_plan/presentation/meal_plan_screen.dart';
import 'package:kokomi/features/meal_plan/presentation/meal_plan_provider.dart';
import 'package:kokomi/features/settings/presentation/ai_usage_provider.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/features/settings/presentation/paywall_screen.dart';
import 'package:kokomi/features/community/presentation/community_provider.dart';
import 'package:kokomi/features/community/presentation/publish_recipe_sheet.dart';
import 'package:kokomi/models/recipe.dart';
import 'package:kokomi/widgets/main_shell.dart' show AppBarMoreButton;
import 'package:kokomi/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomi/widgets/meal_plan_picker_sheet.dart';
import 'package:kokomi/features/recipes/presentation/recipe_detail_screen.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  final int initialTab; // 0=Gespeichert, 1=Wochenplan

  const KitchenScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Widget> _mealPlanActions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Küchenassistent vorübergehend deaktiviert
  // void _openChatSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     useSafeArea: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //     ),
  //     builder: (_) => DraggableScrollableSheet(
  //       initialChildSize: 0.85,
  //       minChildSize: 0.5,
  //       maxChildSize: 0.95,
  //       expand: false,
  //       builder: (context, scrollController) => const AiChatTab(),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedRecipesProvider);
    final isWochenplan = _tabController.index == 1;
    // Standard-Actions (Tab 0)
    final defaultActions = [
      Consumer(
        builder: (context, ref, _) {
          final streak = ref.watch(cookingStreakProvider);
          if (streak.currentStreak < 1) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: streak.streakMessage,
              child: Chip(
                avatar: Text(streak.streakEmoji,
                    style: const TextStyle(fontSize: 14)),
                label: Text('${streak.currentStreak}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
            ),
          );
        },
      ),
      // Küchenassistent-Button deaktiviert
      // IconButton(
      //   icon: const Icon(Icons.chat_bubble_outline_rounded),
      //   tooltip: 'Küchen-Assistent',
      //   onPressed: _openChatSheet,
      // ),
      const AppBarMoreButton(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isWochenplan ? 'Wochenplan' : 'Küche'),
        actions: isWochenplan
            ? [..._mealPlanActions, const AppBarMoreButton()]
            : defaultActions,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_outline_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Gespeichert'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Wochenplan'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SavedTab(savedAsync: savedAsync),
          // Voller MealPlanScreen ohne eigenen Scaffold eingebettet
          MealPlanScreen(
            embedded: true,
            onActionsChanged: (actions) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _mealPlanActions = actions);
              });
            },
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              heroTag: 'kitchen_create',
              onPressed: () => context.push('/kitchen/create'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Eigenes Rezept'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Tab 0: Gespeicherte Rezepte ─────────────────────────────────────────

class _SavedTab extends ConsumerStatefulWidget {
  final AsyncValue<List<FoodRecipe>> savedAsync;
  const _SavedTab({required this.savedAsync});

  @override
  ConsumerState<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<_SavedTab> {
  bool _showFavoritesOnly = false;
  RecipeMealType? _categoryFilter;
  String? _cookingTimeFilter;
  String? _collectionFilter;
  String? _sourceFilter; // null=Alle, 'own'=Meine, 'community'=Gespeichert, 'ai'=KI

  List<FoodRecipe> _applyFilters(List<FoodRecipe> recipes) {
    var filtered = recipes;

    if (_sourceFilter != null) {
      filtered = filtered.where((r) => r.source == _sourceFilter).toList();
    }
    if (_showFavoritesOnly) {
      final favorites = ref.read(recipeFavoritesProvider);
      filtered = filtered.where((r) => favorites.contains(r.id)).toList();
    }
    if (_categoryFilter != null) {
      final categories = ref.read(recipeCategoryProvider);
      filtered =
          filtered.where((r) => categories[r.id] == _categoryFilter).toList();
    }
    if (_cookingTimeFilter != null) {
      filtered = filtered.where((r) {
        switch (_cookingTimeFilter) {
          case 'quick':
            return r.cookingTimeMinutes < 20;
          case 'medium':
            return r.cookingTimeMinutes >= 20 && r.cookingTimeMinutes <= 45;
          case 'long':
            return r.cookingTimeMinutes > 45;
          default:
            return true;
        }
      }).toList();
    }
    if (_collectionFilter != null) {
      final collections = ref.read(recipeCollectionsProvider);
      final collection =
          collections.where((c) => c.id == _collectionFilter).firstOrNull;
      if (collection != null) {
        filtered = filtered
            .where((r) => collection.recipeTitles.contains(r.title))
            .toList();
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(recipeFavoritesProvider);
    ref.watch(recipeCategoryProvider);

    return widget.savedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (recipes) {
        if (recipes.isEmpty) {
          return _EmptySaved();
        }

        final ownCount = recipes.where((r) => r.source == 'own').length;
        final communityCount = recipes.where((r) => r.source == 'community').length;
        final aiCount = recipes.where((r) => r.source == 'ai').length;

        final filtered = _applyFilters(recipes);
        final hasActiveFilter = _showFavoritesOnly ||
            _categoryFilter != null ||
            _cookingTimeFilter != null ||
            _collectionFilter != null ||
            _sourceFilter != null;
        final collections = ref.watch(recipeCollectionsProvider);

        return Column(
          children: [
            // ── Source-Filter ────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _SourceChip(
                    label: 'Alle',
                    count: recipes.length,
                    selected: _sourceFilter == null,
                    onTap: () => setState(() => _sourceFilter = null),
                  ),
                  const SizedBox(width: 6),
                  _SourceChip(
                    label: 'Meine',
                    icon: Icons.edit_note_rounded,
                    count: ownCount,
                    selected: _sourceFilter == 'own',
                    onTap: () => setState(() => _sourceFilter = _sourceFilter == 'own' ? null : 'own'),
                  ),
                  const SizedBox(width: 6),
                  _SourceChip(
                    label: 'Gespeichert',
                    icon: Icons.bookmark_rounded,
                    count: communityCount,
                    selected: _sourceFilter == 'community',
                    onTap: () => setState(() => _sourceFilter = _sourceFilter == 'community' ? null : 'community'),
                  ),
                  const SizedBox(width: 6),
                  _SourceChip(
                    label: 'KI',
                    icon: Icons.auto_awesome_rounded,
                    count: aiCount,
                    selected: _sourceFilter == 'ai',
                    onTap: () => setState(() => _sourceFilter = _sourceFilter == 'ai' ? null : 'ai'),
                  ),
                ],
              ),
            ),
            const Divider(height: 8),
            // ── Weitere Filter ───────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Row(
                children: [
                  ...collections.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text('${c.emoji} ${c.name}'),
                          selected: _collectionFilter == c.id,
                          onSelected: (val) => setState(
                              () => _collectionFilter = val ? c.id : null),
                          visualDensity: VisualDensity.compact,
                        ),
                      )),
                  if (collections.isNotEmpty) const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('❤️ Favoriten'),
                      selected: _showFavoritesOnly,
                      onSelected: (val) =>
                          setState(() => _showFavoritesOnly = val),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('⚡ < 20 Min.'),
                      selected: _cookingTimeFilter == 'quick',
                      onSelected: (val) => setState(
                          () => _cookingTimeFilter = val ? 'quick' : null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('🕐 20–45 Min.'),
                      selected: _cookingTimeFilter == 'medium',
                      onSelected: (val) => setState(
                          () => _cookingTimeFilter = val ? 'medium' : null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('🍳 > 45 Min.'),
                      selected: _cookingTimeFilter == 'long',
                      onSelected: (val) => setState(
                          () => _cookingTimeFilter = val ? 'long' : null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  ...RecipeMealType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(type.display),
                        selected: _categoryFilter == type,
                        onSelected: (val) => setState(
                            () => _categoryFilter = val ? type : null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  if (hasActiveFilter)
                    ActionChip(
                      label: const Text('✕ Reset'),
                      onPressed: () => setState(() {
                        _showFavoritesOnly = false;
                        _categoryFilter = null;
                        _cookingTimeFilter = null;
                        _collectionFilter = null;
                        _sourceFilter = null;
                      }),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            if (hasActiveFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filtered.length} von ${recipes.length} Rezepten',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Keine Rezepte mit diesen Filtern gefunden',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _RecipeCard(
                        recipe: filtered[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(
                              recipe: filtered[index],
                              isFromCommunity: filtered[index].source == 'community',
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Source-Filter Chip ──────────────────────────────────────────────────────

class _SourceChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _SourceChip({
    required this.label,
    this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: count > 0 ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 0 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                    : theme.colorScheme.outline.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leerer Zustand ──────────────────────────────────────────────────────────

class _EmptySaved extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded,
                size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Noch keine Rezepte gespeichert',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Generiere Rezepte über den ✨ KI-Button oder erstelle eigene Rezepte.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/kitchen/create'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Eigenes Rezept erstellen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: KI Generieren ────────────────────────────────────────────────

class _GenerateTab extends ConsumerStatefulWidget {
  // Parameter werden nicht mehr gebraucht – Tab ist jetzt eigenständig
  final AsyncValue<List<FoodRecipe>> recipesAsync;
  const _GenerateTab({required this.recipesAsync});

  @override
  ConsumerState<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends ConsumerState<_GenerateTab> {
  final _promptController = TextEditingController();
  String? _activeStyle;
  bool _useInventory = true; // Vorrat verwenden?

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
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generate() {
    final prompt = _promptController.text.trim();
    final styleHint = _activeStyle;

    // Kombinierten Prompt aufbauen
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

    // Kein Vorrat oder Toggle aus → nur Prompt
    if (finalPrompt.isNotEmpty) {
      ref.read(recipeProvider.notifier).generateFromPrompt(finalPrompt);
    } else {
      ref.read(recipeProvider.notifier).generateFromPrompt(
          'Überrasche mich mit einem kreativen Rezept');
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
    final theme = Theme.of(context);
    final hasInventory = inventoryItems.isNotEmpty;

    // Loading
    if (widget.recipesAsync.isLoading) {
      return Center(
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
      );
    }

    // Fehler
    if (widget.recipesAsync.hasError) {
      final isLimit = widget.recipesAsync.error
          .toString()
          .contains('KI-LIMIT_REACHED');
      if (isLimit) return _KiLimitReachedWidget();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('${widget.recipesAsync.error}',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    // Rezepte vorhanden → Liste anzeigen
    final recipes = widget.recipesAsync.valueOrNull ?? [];
    if (recipes.isNotEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('${recipes.length} Rezepte',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
                TextButton.icon(
                  onPressed: () => ref.read(recipeProvider.notifier).clear(),
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Neu generieren'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
              itemCount: recipes.length,
              itemBuilder: (context, i) => _RecipeCard(
                recipe: recipes[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(
                      recipe: recipes[i],
                      isFromCommunity: recipes[i].source == 'community',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ── Eingabe-UI ─────────────────────────────────────────────────────
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (!isPro) ...[
          _ProBanner(remaining: remaining, weeklyLimit: weeklyLimit),
          const SizedBox(height: 12),
        ],

        // ── Prompt ─────────────────────────────────────────────────
        TextField(
          controller: _promptController,
          decoration: InputDecoration(
            hintText: 'Was möchtest du kochen? (optional)',
            prefixIcon: const Icon(Icons.auto_awesome_outlined),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send_rounded),
              onPressed: _generate,
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onSubmitted: (_) => _generate(),
          textInputAction: TextInputAction.send,
        ),
        const SizedBox(height: 16),

        // ── Stil-Tags ───────────────────────────────────────────────
        Row(
          children: [
            Text('Küche & Stil',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            if (_activeStyle != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _activeStyle = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _styleTags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final tag = _styleTags[index];
              final isActive = _activeStyle == tag.$2;
              return FilterChip(
                label: Text('${tag.$1} ${tag.$2}',
                    style: const TextStyle(fontSize: 12)),
                selected: isActive,
                onSelected: (_) =>
                    setState(() => _activeStyle = isActive ? null : tag.$2),
                visualDensity: VisualDensity.compact,
                selectedColor: theme.colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── Vorrat Toggle ───────────────────────────────────────────
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
        const SizedBox(height: 16),

        // ── Generieren ──────────────────────────────────────────────
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(_buildLabel(inventoryItems.length)),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
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

  String _buildLabel(int inventoryCount) {
    final parts = <String>[];
    if (_useInventory && inventoryCount > 0) parts.add('Aus Vorrat');
    if (_activeStyle != null) parts.add(_activeStyle!);
    if (_promptController.text.trim().isNotEmpty) parts.add('Wunsch');
    if (parts.isEmpty) return 'Rezepte generieren';
    return 'Generieren · ${parts.join(' · ')}';
  }
}


// ─── Shared Widgets ──────────────────────────────────────────────────────

class _ProBanner extends ConsumerWidget {
  final int remaining;
  final int weeklyLimit;
  const _ProBanner({required this.remaining, required this.weeklyLimit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEmpty = remaining == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEmpty
              ? [Colors.red.shade700, Colors.orange.shade700]
              : [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isEmpty ? Icons.lock_rounded : Icons.auto_awesome,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmpty
                      ? 'Limit erreicht – Upgrade auf Pro'
                      : '$remaining von $weeklyLimit KI-Generierungen übrig',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  isEmpty
                      ? 'Unlimitierte KI-Rezepte mit Pro ⭐'
                      : 'Pro: Unlimitiert + mehr Features',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/settings/paywall'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 1),
              ),
              child: const Text('Pro ✨',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecipes extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyRecipes({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded,
                size: 52, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('Was möchtest du kochen?',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Lass dir Rezepte aus deinem Vorrat generieren oder tippe einen Wunsch ein.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Aus Vorrat generieren'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
          ),
        ],
      ),
    );
  }
}

class _KiLimitReachedWidget extends ConsumerWidget {
  const _KiLimitReachedWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usageAsync = ref.watch(aiUsageProvider);
    final usage = usageAsync.valueOrNull;
    final now = DateTime.now();
    final daysUntilMonday = 8 - now.weekday;
    final nextMonday = now.add(
        Duration(days: daysUntilMonday == 7 ? 7 : daysUntilMonday));
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
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
              'Du hast ${usage?.weeklyLimit ?? 5} von ${usage?.weeklyLimit ?? 5} KI-Generierungen '
              'diese Woche genutzt.\nNeues Limit ab $resetLabel 🗓️',
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
              onPressed: () => ref.read(recipeProvider.notifier).clear(),
              child: Text('Später vielleicht',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  final FoodRecipe recipe;
  final VoidCallback onTap;
  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ratings = ref.watch(recipeRatingProvider);
    final rating = ratings[recipe.id] ?? 0;
    final publishedAsync = ref.watch(myPublishedRecipesProvider);
    final isShared = publishedAsync.valueOrNull?.any((r) => r.title == recipe.title) ?? false;
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Bild oder Gradient-Placeholder ───
            Stack(
              children: [
                if (hasImage)
                  Image.network(
                    recipe.imageUrl!,
                    height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(theme, recipe),
                    loadingBuilder: (_, child, p) => p == null ? child : Container(
                      height: 160, color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else
                  _buildPlaceholder(theme, recipe),
                // Geteilt-Badge + Rating Overlay
                Positioned(
                  top: 8, right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isShared)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text('Geteilt', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (rating > 0)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.soup_kitchen_rounded, size: 12, color: Colors.orange.shade300),
                          const SizedBox(width: 4),
                          Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // ─── Info-Bereich ───
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(recipe.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      _DifficultyBadge(difficulty: recipe.difficulty),
                    ],
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(recipe.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${recipe.cookingTimeMinutes} Min.', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Icon(Icons.restaurant_outlined, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${recipe.ingredients.length} Zutaten', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddToMealPlan(context, ref, recipe),
                        child: Icon(Icons.calendar_today_outlined, size: 18, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showAddToShoppingList(context, ref, recipe),
                        child: Icon(Icons.add_shopping_cart_rounded, size: 18, color: theme.colorScheme.secondary),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPlaceholder(ThemeData theme, FoodRecipe recipe) {
    final str = '${recipe.title} ${recipe.description}'.toLowerCase();
    final Color a, b;
    final IconData icon;
    if (str.contains('frühstück') || str.contains('breakfast') || str.contains('pfannkuchen')) {
      a = const Color(0xFFF9A825); b = const Color(0xFFFF8F00); icon = Icons.wb_sunny_outlined;
    } else if (str.contains('dessert') || str.contains('kuchen') || str.contains('tiramisu') || str.contains('schokolade')) {
      a = const Color(0xFFE91E63); b = const Color(0xFF880E4F); icon = Icons.cake_outlined;
    } else if (str.contains('salat') || str.contains('vegan') || str.contains('vegetarisch')) {
      a = const Color(0xFF26A69A); b = const Color(0xFF00695C); icon = Icons.eco_outlined;
    } else if (str.contains('suppe') || str.contains('eintopf')) {
      a = const Color(0xFFFF7043); b = const Color(0xFFBF360C); icon = Icons.soup_kitchen_outlined;
    } else if (str.contains('pasta') || str.contains('spaghetti') || str.contains('nudel') || str.contains('italienisch')) {
      a = const Color(0xFF43A047); b = const Color(0xFF2E7D32); icon = Icons.dinner_dining_outlined;
    } else if (str.contains('curry') || str.contains('asiatisch') || str.contains('thai') || str.contains('indisch')) {
      a = const Color(0xFFFF8F00); b = const Color(0xFFE65100); icon = Icons.local_fire_department_outlined;
    } else {
      a = theme.colorScheme.primary; b = theme.colorScheme.secondary; icon = Icons.restaurant_menu_outlined;
    }
    return Container(
      height: 160, width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Container(width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)))),
          Center(child: Icon(icon, size: 42, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

void _showAddToMealPlan(BuildContext context, WidgetRef ref, FoodRecipe recipe) {
  showMealPlanPickerSheet(context, ref, recipe);
}

void _showAddToShoppingList(BuildContext context, WidgetRef ref, FoodRecipe recipe) {
  final items = recipe.ingredients.map((i) => '${i.amount} ${i.name}'.trim()).toList();
  for (final item in items) {
    ref.read(shoppingListProvider.notifier).addItem(item);
  }
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${items.length} Zutaten zur Einkaufsliste hinzugefügt ✅')),
  );
}

/// Kompaktes Rating-Badge für Rezept-Karten: "🥄 4.5 (12)" oder "(0)"
class _RecipeRatingBadge extends StatelessWidget {
  final int rating; // 0–5 persönliche Bewertung
  const _RecipeRatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRating = rating > 0;
    final color = hasRating ? Colors.orange.shade700 : theme.colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasRating ? Icons.soup_kitchen_rounded : Icons.soup_kitchen_outlined,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          hasRating ? '$rating (du)' : '(0)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: hasRating ? FontWeight.w700 : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Kompakte Nährwert-Zeile für Rezept-Karten
class _NutritionChips extends StatelessWidget {
  final NutritionInfo nutrition;
  const _NutritionChips({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final chips = <(String, String, Color)>[];
    if (nutrition.calories > 0) {
      chips.add(('🔥', '${nutrition.calories} kcal', Colors.orange));
    }
    if (nutrition.protein > 0) {
      chips.add(('💪', '${nutrition.protein.toStringAsFixed(0)}g P', Colors.blue));
    }
    if (nutrition.carbs > 0) {
      chips.add(('🌾', '${nutrition.carbs.toStringAsFixed(0)}g K', Colors.amber.shade700));
    }
    if (nutrition.fat > 0) {
      chips.add(('🥑', '${nutrition.fat.toStringAsFixed(0)}g F', Colors.green));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips.map((c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.$3.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${c.$1} ${c.$2}',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.$3.withValues(alpha: 0.9))),
      )).toList(),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  Color _color() {
    switch (difficulty.toLowerCase()) {
      case 'einfach':
        return Colors.green;
      case 'mittel':
        return Colors.orange;
      case 'schwer':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        difficulty,
        style:
            TextStyle(color: _color(), fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

