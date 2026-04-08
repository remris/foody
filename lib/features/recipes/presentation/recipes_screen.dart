import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomi/features/recipes/presentation/recipe_provider.dart';
import 'package:kokomi/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomi/features/recipes/presentation/ingredient_selection_sheet.dart';
import 'package:kokomi/features/recipes/presentation/recipe_favorites_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_category_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_rating_provider.dart';
import 'package:kokomi/features/recipes/presentation/cooking_streak_provider.dart';
import 'package:kokomi/features/recipes/presentation/recipe_collections_provider.dart';
import 'package:kokomi/features/recipes/presentation/ai_chat_tab.dart';
import 'package:kokomi/features/settings/presentation/ai_usage_provider.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/features/settings/presentation/paywall_screen.dart';
import 'package:kokomi/models/recipe.dart';
import 'package:kokomi/widgets/main_shell.dart' show AppBarMoreButton;

class RecipesScreen extends ConsumerStatefulWidget {
  /// Wenn aus dem Inventar-Screen kommend, bereits vorausgewählte Zutaten
  final List<String>? preSelectedIngredients;

  const RecipesScreen({super.key, this.preSelectedIngredients});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen>
    with SingleTickerProviderStateMixin {
  final _promptController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Wenn Zutaten übergeben wurden → direkt nach dem ersten Frame Sheet öffnen
    if (widget.preSelectedIngredients != null &&
        widget.preSelectedIngredients!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(recipeProvider.notifier).generateFromSelection(
              widget.preSelectedIngredients!,
            );
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _generateFromPrompt() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    ref.read(recipeProvider.notifier).generateFromPrompt(prompt);
    FocusScope.of(context).unfocus();
  }

  void _showIngredientSelection() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const IngredientSelectionSheet(),
    );

    if (result != null && mounted) {
      final ingredients = result['ingredients'] as List<String>;
      final prompt = result['prompt'] as String?;
      ref.read(recipeProvider.notifier).generateFromSelection(
            ingredients,
            additionalPrompt: prompt,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipeProvider);
    final savedAsync = ref.watch(savedRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezepte'),
        actions: [
          // Streak-Badge
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
          if (recipesAsync.valueOrNull?.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => ref.read(recipeProvider.notifier).clear(),
            ),
          const AppBarMoreButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'KI'),
            Tab(icon: Icon(Icons.bookmark, size: 18), text: 'Gespeichert'),
          ],
        ),
      ),
      // Chat-FAB
      floatingActionButton: FloatingActionButton(
        heroTag: 'recipe_chat',
        onPressed: () => _openChatSheet(context),
        tooltip: 'Küchen-Assistent',
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: KI Generieren
          _GenerateTab(
            recipesAsync: recipesAsync,
            promptController: _promptController,
            onGenerateFromPrompt: _generateFromPrompt,
            onShowIngredientSelection: _showIngredientSelection,
          ),
          // Tab 2: Gespeichert
          _SavedTab(savedAsync: savedAsync),
        ],
      ),
    );
  }

  void _openChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => const AiChatTab(),
      ),
    );
  }
}

class _GenerateTab extends ConsumerStatefulWidget {
  final AsyncValue<List<FoodRecipe>> recipesAsync;
  final TextEditingController promptController;
  final VoidCallback onGenerateFromPrompt;
  final VoidCallback onShowIngredientSelection;

  const _GenerateTab({
    required this.recipesAsync,
    required this.promptController,
    required this.onGenerateFromPrompt,
    required this.onShowIngredientSelection,
  });

  @override
  ConsumerState<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends ConsumerState<_GenerateTab> {
  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final usageAsync = ref.watch(aiUsageProvider);
    final usedThisWeek = usageAsync.valueOrNull?.usedThisWeek ?? 0;
    final weeklyLimit = AiUsageNotifier.freeWeeklyLimit;
    final remaining = (weeklyLimit - usedThisWeek).clamp(0, weeklyLimit);

    return Column(
      children: [
        // ── Pro-Banner für Free-User ─────────────────────────────────────
        if (!isPro)
          _ProBanner(remaining: remaining, weeklyLimit: weeklyLimit),

        // ── Prompt-Eingabe ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: widget.promptController,
            decoration: InputDecoration(
              hintText: 'z.B. "Schnelles gesundes Mittagessen"',
              prefixIcon: const Icon(Icons.auto_awesome),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: widget.onGenerateFromPrompt,
              ),
            ),
            onSubmitted: (_) => widget.onGenerateFromPrompt(),
            textInputAction: TextInputAction.send,
          ),
        ),
        // ── Hauptaktionen (kompakt) ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ref
                      .read(recipeProvider.notifier)
                      .generateFromInventory(),
                  icon: const Icon(Icons.kitchen, size: 18),
                  label: const Text('Aus Vorrat'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onShowIngredientSelection,
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('Zutaten wählen'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Überrasch mich!',
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(recipeProvider.notifier)
                      .generateFromPrompt('Überrasche mich mit einem kreativen Rezept'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.shuffle_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
        // ── Schnell-Chips ────────────────────────────────────────────────
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              ...['🇮🇹 Italienisch', '🇯🇵 Asiatisch', '🇩🇪 Deutsch',
                   '🇲🇽 Mexikanisch', '🇮🇳 Indisch', '💪 High Protein',
                   '🥗 Leicht', '🍲 Meal Prep'].map(
                (style) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(style, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final clean = style.replaceAll(RegExp(r'[^\w\sÀ-ÿ]'), '').trim();
                      ref.read(recipeProvider.notifier)
                          .generateFromPrompt('$clean Rezepte');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // ── Rezept-Liste ─────────────────────────────────────────────────
        Expanded(
          child: widget.recipesAsync.when(
            loading: () => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('KI generiert Rezepte...'),
                ],
              ),
            ),
            error: (e, _) {
              final isLimitReached =
                  e.toString().contains('KI-LIMIT_REACHED');
              if (isLimitReached) {
                return _KiLimitReachedWidget(ref: ref);
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64,
                          color: Colors.red),
                      const SizedBox(height: 16),
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(recipeProvider.notifier)
                            .generateFromInventory(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              );
            },
            data: (recipes) => recipes.isEmpty
                ? _EmptyRecipes(
                    onGenerate: () => ref
                        .read(recipeProvider.notifier)
                        .generateFromInventory(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) => _RecipeCard(
                      recipe: recipes[index],
                      onTap: () => context.push(
                        '/recipes/detail',
                        extra: recipes[index],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SavedTab extends ConsumerStatefulWidget {
  final AsyncValue<List<FoodRecipe>> savedAsync;
  const _SavedTab({required this.savedAsync});

  @override
  ConsumerState<_SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<_SavedTab> {
  bool _showFavoritesOnly = false;
  RecipeMealType? _categoryFilter;
  String? _cookingTimeFilter; // 'quick', 'medium', 'long'
  String? _collectionFilter; // Collection ID

  List<FoodRecipe> _applyFilters(List<FoodRecipe> recipes) {
    var filtered = recipes;

    // Favoriten-Filter
    if (_showFavoritesOnly) {
      final favorites = ref.read(recipeFavoritesProvider);
      filtered = filtered.where((r) => favorites.contains(r.id)).toList();
    }

    // Kategorie-Filter
    if (_categoryFilter != null) {
      final categories = ref.read(recipeCategoryProvider);
      filtered =
          filtered.where((r) => categories[r.id] == _categoryFilter).toList();
    }

    // Kochzeit-Filter
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

    // Collection-Filter
    if (_collectionFilter != null) {
      final collections = ref.read(recipeCollectionsProvider);
      final collection = collections
          .where((c) => c.id == _collectionFilter)
          .firstOrNull;
      if (collection != null) {
        filtered = filtered
            .where((r) => collection.recipeTitles.contains(r.title))
            .toList();
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context, ) {
    // Watch providers to react to changes
    ref.watch(recipeFavoritesProvider);
    ref.watch(recipeCategoryProvider);

    return widget.savedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (recipes) {
        if (recipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Noch keine Rezepte gespeichert',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Speichere Rezepte über das Bookmark-Icon',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        final filtered = _applyFilters(recipes);
        final hasActiveFilter =
            _showFavoritesOnly ||
            _categoryFilter != null ||
            _cookingTimeFilter != null ||
            _collectionFilter != null;
        final collections = ref.watch(recipeCollectionsProvider);

        return Column(
          children: [
            // Filter-Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  // Collection-Chips
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
                  if (collections.isNotEmpty)
                    const SizedBox(width: 4),
                  // Favoriten-Filter
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
                  // Kochzeit-Filter
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('⚡ < 20 Min.'),
                      selected: _cookingTimeFilter == 'quick',
                      onSelected: (val) => setState(() =>
                          _cookingTimeFilter = val ? 'quick' : null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('🕐 20–45 Min.'),
                      selected: _cookingTimeFilter == 'medium',
                      onSelected: (val) => setState(() =>
                          _cookingTimeFilter = val ? 'medium' : null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('🍳 > 45 Min.'),
                      selected: _cookingTimeFilter == 'long',
                      onSelected: (val) => setState(() =>
                          _cookingTimeFilter = val ? 'long' : null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  // Kategorie-Filter
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
                  // Reset
                  if (hasActiveFilter)
                    ActionChip(
                      label: const Text('✕ Reset'),
                      onPressed: () => setState(() {
                        _showFavoritesOnly = false;
                        _categoryFilter = null;
                        _cookingTimeFilter = null;
                      }),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            // Ergebniszähler
            if (hasActiveFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filtered.length} von ${recipes.length} Rezepten',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            // Liste
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Keine Rezepte mit diesen Filtern gefunden',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
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
                        onTap: () => context.push(
                          '/recipes/detail',
                          extra: filtered[index],
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

/// Kompaktes Banner oben im KI-Tab für Free-User mit verbleibenden Nutzungen.
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
                    fontSize: 13,
                  ),
                ),
                Text(
                  isEmpty
                      ? 'Unlimitierte KI-Rezepte mit Pro ⭐'
                      : 'Pro: Unlimitiert + mehr Features',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/settings/paywall'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 1),
              ),
              child: const Text(
                'Pro ✨',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
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
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _TipChip('🥗 Vegetarisch'),
              _TipChip('⚡ Unter 20 Min.'),
              _TipChip('💪 High Protein'),
              _TipChip('🍝 Pasta'),
              _TipChip('🥘 Suppe'),
              _TipChip('🌶️ Scharf'),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Aus Vorrat generieren'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  const _TipChip(this.label);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        // Chip-Label (ohne Emoji) als Prompt nutzen
        final prompt = label.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        // Zurück zum parent navigieren und Prompt setzen
        final notifier = ProviderScope.containerOf(context)
            .read(recipeProvider.notifier);
        notifier.generateFromPrompt(prompt);
      },
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
    final favorites = ref.watch(recipeFavoritesProvider);
    final isFavorite = favorites.contains(recipe.id);

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
                    child: Text(
                      recipe.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Favorit-Herzchen
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
                      color: isFavorite ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DifficultyBadge(difficulty: recipe.difficulty),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('${recipe.cookingTimeMinutes} Min.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(width: 16),
                  Icon(Icons.restaurant_outlined, size: 16,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('${recipe.ingredients.length} Zutaten',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const Spacer(),
                  // Sterne-Bewertung
                  if (rating > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        rating,
                        (_) => const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14,
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
        style: TextStyle(
            color: _color(), fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}


// ── KI-Limit Widget ──────────────────────────────────────────
class _KiLimitReachedWidget extends ConsumerWidget {
  final WidgetRef ref;
  const _KiLimitReachedWidget({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usageAsync = ref.watch(aiUsageProvider);
    final usage = usageAsync.valueOrNull;

    // Tage bis nächsten Montag berechnen
    final now = DateTime.now();
    final daysUntilMonday = 8 - now.weekday; // 1=Mo, also 8-weekday = Tage bis nächsten Mo
    final nextMonday = now.add(Duration(days: daysUntilMonday == 7 ? 7 : daysUntilMonday));
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
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'KI-Limit erreicht',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Du hast ${usage?.weeklyLimit ?? 5} von ${usage?.weeklyLimit ?? 5} KI-Generierungen '
              'diese Woche genutzt.\nNeues Limit ab $resetLabel 🗓️',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // Fortschrittsbalken
            if (usage != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.error),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${usage.usedThisWeek} / ${usage.weeklyLimit} genutzt',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Pro-Features Highlight
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _ProFeatureRow('Unlimitierte KI-Rezepte jeden Tag'),
                  _ProFeatureRow('Mahlzeiten-Wochenplaner'),
                  _ProFeatureRow('Nährwert-Tracking & Makros'),
                  _ProFeatureRow('Supermarkt-Angebote nutzen'),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
              onPressed: () =>
                  ref.read(recipeProvider.notifier).clear(),
              child: Text(
                'Später vielleicht',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProFeatureRow extends StatelessWidget {
  final String text;
  const _ProFeatureRow(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

