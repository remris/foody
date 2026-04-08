import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/community/presentation/community_provider.dart';
import 'package:kokomi/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomi/models/community_recipe.dart';
import 'package:kokomi/models/recipe.dart';
import 'package:kokomi/core/services/supabase_service.dart';

/// Sheet zum Veröffentlichen eines Rezepts in der Community.
/// Unterstützt:
/// - Gespeichertes Rezept teilen
/// - Neues Rezept von Grund auf erstellen
class PublishRecipeSheet extends ConsumerStatefulWidget {
  final FoodRecipe? initialRecipe;
  const PublishRecipeSheet({super.key, this.initialRecipe});

  @override
  ConsumerState<PublishRecipeSheet> createState() => _PublishRecipeSheetState();
}

class _PublishRecipeSheetState extends ConsumerState<PublishRecipeSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Gemeinsam
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  String? _selectedCategory;
  final List<String> _tags = [];
  bool _isPublishing = false;
  int _cookingTime = 30;
  String _difficulty = 'Mittel';
  int _servings = 2;

  // Tab 1: Gespeichertes Rezept teilen
  FoodRecipe? _selectedRecipe;

  // Tab 2: Neues Rezept erstellen
  final List<_IngredientEntry> _ingredients = [];
  final List<TextEditingController> _stepControllers = [];
  final _ingredientNameCtrl = TextEditingController();
  final _ingredientAmountCtrl = TextEditingController();

  static const _categories = [
    'Frühstück', 'Mittagessen', 'Abendessen',
    'Snack', 'Dessert', 'Backen', 'Vegetarisch', 'Vegan',
  ];
  static const _difficulties = ['Einfach', 'Mittel', 'Schwer'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Standardmäßig einen leeren Schritt
    _stepControllers.add(TextEditingController());

    if (widget.initialRecipe != null) {
      _selectedRecipe = widget.initialRecipe;
      _titleController.text = widget.initialRecipe!.title;
      _descController.text = widget.initialRecipe!.description;
      // Direkt zum "Teilen"-Tab
      _tabController.index = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    _ingredientNameCtrl.dispose();
    _ingredientAmountCtrl.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _addIngredient() {
    final name = _ingredientNameCtrl.text.trim();
    final amount = _ingredientAmountCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _ingredients.add(_IngredientEntry(name: name, amount: amount));
      _ingredientNameCtrl.clear();
      _ingredientAmountCtrl.clear();
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  Future<void> _publish() async {
    final isNew = _tabController.index == 1;

    if (_titleController.text.trim().isEmpty) {
      _showSnack('Bitte einen Titel eingeben.');
      return;
    }

    FoodRecipe? recipe;

    if (isNew) {
      // Aus den Eingaben ein FoodRecipe bauen
      if (_ingredients.isEmpty) {
        _showSnack('Bitte mindestens eine Zutat hinzufügen.');
        return;
      }
      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (steps.isEmpty) {
        _showSnack('Bitte mindestens einen Zubereitungsschritt eingeben.');
        return;
      }

      recipe = FoodRecipe(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        cookingTimeMinutes: _cookingTime,
        difficulty: _difficulty,
        servings: _servings,
        ingredients: _ingredients
            .map((e) => RecipeIngredient(name: e.name, amount: e.amount))
            .toList(),
        steps: steps,
        nutrition: const NutritionInfo(
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
          fiber: 0,
        ),
      );
    } else {
      if (_selectedRecipe == null) {
        _showSnack('Bitte ein gespeichertes Rezept auswählen.');
        return;
      }
      recipe = _selectedRecipe;
    }

    setState(() => _isPublishing = true);

    final user = SupabaseService.client.auth.currentUser;
    final authorName = user?.email?.split('@').first ?? 'Kokomi-User';

    final communityRecipe = CommunityRecipe.fromFoodRecipe(
      recipe!,
      userId: user?.id ?? '',
      authorName: authorName,
    ).copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      tags: List<String>.from(_tags),
      difficulty: _difficulty,
      cookingTimeMinutes: _cookingTime,
      servings: _servings,
    );

    bool success = false;
    String? errorMsg;

    try {
      errorMsg = await ref.read(publishRecipeProvider.notifier).publish(communityRecipe);
      success = errorMsg == null;
    } catch (e) {
      errorMsg = e.toString();
    }

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (errorMsg != null) {
      // Fehler direkt im Sheet anzeigen – kein externer Context nötig
      final isFreeLimit = errorMsg.contains('FREE_LIMIT_REACHED');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isFreeLimit ? Icons.workspace_premium_rounded : Icons.error_outline,
                color: isFreeLimit ? Colors.orange : Theme.of(ctx).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(isFreeLimit ? 'Free-Plan Limit' : 'Fehler'),
            ],
          ),
          content: Text(
            isFreeLimit
                ? 'Du hast das Free-Plan-Limit von 3 Rezepten erreicht.\n\nMit einem Pro-Upgrade kannst du unbegrenzt Rezepte teilen.'
                : 'Beim Veröffentlichen ist ein Fehler aufgetreten:\n\n$errorMsg',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            if (isFreeLimit)
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.star_rounded, size: 16),
                label: const Text('Pro upgraden'),
              ),
          ],
        ),
      );
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      // SnackBar über den rootScaffoldMessenger um sicherzustellen dass er sichtbar ist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Rezept erfolgreich veröffentlicht!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      builder: (_, scrollController) => Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          title: const Text('Rezept veröffentlichen 🌟'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            _isPublishing
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.icon(
                      onPressed: _publish,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Veröffentlichen'),
                    ),
                  ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.bookmark_outline, size: 18), text: 'Gespeichertes teilen'),
              Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Neu erstellen'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: Gespeichertes Rezept teilen ──────────────────────
            _ShareSavedTab(
              scrollController: scrollController,
              titleController: _titleController,
              descController: _descController,
              tagController: _tagController,
              selectedRecipe: _selectedRecipe,
              selectedCategory: _selectedCategory,
              tags: _tags,
              cookingTime: _cookingTime,
              difficulty: _difficulty,
              servings: _servings,
              categories: _categories,
              difficulties: _difficulties,
              onRecipeSelected: (r) => setState(() {
                _selectedRecipe = r;
                _titleController.text = r.title;
                _descController.text = r.description;
              }),
              onCategoryChanged: (c) => setState(() => _selectedCategory = c),
              onTagAdded: _addTag,
              onTagRemoved: (t) => setState(() => _tags.remove(t)),
              onCookingTimeChanged: (v) => setState(() => _cookingTime = v),
              onDifficultyChanged: (v) => setState(() => _difficulty = v),
              onServingsChanged: (v) => setState(() => _servings = v),
            ),
            // ── Tab 2: Neues Rezept von Grund auf ───────────────────────
            _CreateNewTab(
              scrollController: scrollController,
              titleController: _titleController,
              descController: _descController,
              tagController: _tagController,
              ingredientNameCtrl: _ingredientNameCtrl,
              ingredientAmountCtrl: _ingredientAmountCtrl,
              ingredients: _ingredients,
              stepControllers: _stepControllers,
              selectedCategory: _selectedCategory,
              tags: _tags,
              cookingTime: _cookingTime,
              difficulty: _difficulty,
              servings: _servings,
              categories: _categories,
              difficulties: _difficulties,
              onCategoryChanged: (c) => setState(() => _selectedCategory = c),
              onTagAdded: _addTag,
              onTagRemoved: (t) => setState(() => _tags.remove(t)),
              onIngredientAdded: _addIngredient,
              onIngredientRemoved: (i) => setState(() => _ingredients.removeAt(i)),
              onStepAdded: _addStep,
              onStepRemoved: (i) {
                setState(() {
                  _stepControllers[i].dispose();
                  _stepControllers.removeAt(i);
                });
              },
              onCookingTimeChanged: (v) => setState(() => _cookingTime = v),
              onDifficultyChanged: (v) => setState(() => _difficulty = v),
              onServingsChanged: (v) => setState(() => _servings = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Datenklasse für Zutaten im Neu-Erstellen-Formular ───────────────────────
class _IngredientEntry {
  final String name;
  final String amount;
  _IngredientEntry({required this.name, required this.amount});
}

// ─── Gemeinsame Metadaten-Widgets ────────────────────────────────────────────

Widget _buildMetaSection({
  required BuildContext context,
  required String? selectedCategory,
  required List<String> categories,
  required List<String> difficulties,
  required String difficulty,
  required int cookingTime,
  required int servings,
  required List<String> tags,
  required TextEditingController tagController,
  required ValueChanged<String?> onCategoryChanged,
  required VoidCallback onTagAdded,
  required ValueChanged<String> onTagRemoved,
  required ValueChanged<int> onCookingTimeChanged,
  required ValueChanged<String> onDifficultyChanged,
  required ValueChanged<int> onServingsChanged,
}) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Kategorie', style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: categories.map((cat) {
          final sel = selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: sel,
            onSelected: (_) => onCategoryChanged(sel ? null : cat),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      // Schwierigkeit + Zeit + Portionen
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: difficulty,
              decoration: const InputDecoration(
                  labelText: 'Schwierigkeit', isDense: true),
              items: difficulties
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => onDifficultyChanged(v ?? difficulty),
            ),
          ),
          SizedBox(
            width: 110,
            child: TextFormField(
              initialValue: cookingTime.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Zeit (min)', isDense: true),
              onChanged: (v) =>
                  onCookingTimeChanged(int.tryParse(v) ?? cookingTime),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: servings.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Portionen', isDense: true),
              onChanged: (v) =>
                  onServingsChanged(int.tryParse(v) ?? servings),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text('Tags', style: theme.textTheme.labelLarge),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: tagController,
              decoration: const InputDecoration(
                  hintText: 'Tag und Enter drücken', isDense: true),
              onSubmitted: (_) => onTagAdded(),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onTagAdded),
        ],
      ),
      if (tags.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: tags
              .map((t) => Chip(
                    label: Text(t),
                    onDeleted: () => onTagRemoved(t),
                    visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
      ],
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Free-Plan: bis zu 3 Rezepte teilen.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
    ],
  );
}

// ─── Tab 1: Gespeichertes Rezept teilen ──────────────────────────────────────
class _ShareSavedTab extends ConsumerWidget {
  final ScrollController scrollController;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController tagController;
  final FoodRecipe? selectedRecipe;
  final String? selectedCategory;
  final List<String> tags;
  final int cookingTime;
  final String difficulty;
  final int servings;
  final List<String> categories;
  final List<String> difficulties;
  final ValueChanged<FoodRecipe> onRecipeSelected;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onTagAdded;
  final ValueChanged<String> onTagRemoved;
  final ValueChanged<int> onCookingTimeChanged;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<int> onServingsChanged;

  const _ShareSavedTab({
    required this.scrollController,
    required this.titleController,
    required this.descController,
    required this.tagController,
    required this.selectedRecipe,
    required this.selectedCategory,
    required this.tags,
    required this.cookingTime,
    required this.difficulty,
    required this.servings,
    required this.categories,
    required this.difficulties,
    required this.onRecipeSelected,
    required this.onCategoryChanged,
    required this.onTagAdded,
    required this.onTagRemoved,
    required this.onCookingTimeChanged,
    required this.onDifficultyChanged,
    required this.onServingsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final savedAsync = ref.watch(savedRecipesProvider);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Text('Gespeichertes Rezept wählen', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        savedAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text('Fehler: $e', style: TextStyle(color: theme.colorScheme.error)),
          data: (recipes) => recipes.isEmpty
              ? Text('Noch keine gespeicherten Rezepte.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
              : SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final r = recipes[i];
                      final isSelected = selectedRecipe?.id == r.id;
                      return ChoiceChip(
                        label: Text(r.title,
                            style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) => onRecipeSelected(r),
                      );
                    },
                  ),
                ),
        ),
        const Divider(height: 28),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
              labelText: 'Titel *', hintText: 'z.B. Omas Apfelkuchen'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descController,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Beschreibung',
              hintText: 'Was macht dein Rezept besonders?'),
        ),
        const SizedBox(height: 16),
        _buildMetaSection(
          context: context,
          selectedCategory: selectedCategory,
          categories: categories,
          difficulties: difficulties,
          difficulty: difficulty,
          cookingTime: cookingTime,
          servings: servings,
          tags: tags,
          tagController: tagController,
          onCategoryChanged: onCategoryChanged,
          onTagAdded: onTagAdded,
          onTagRemoved: onTagRemoved,
          onCookingTimeChanged: onCookingTimeChanged,
          onDifficultyChanged: onDifficultyChanged,
          onServingsChanged: onServingsChanged,
        ),
      ],
    );
  }
}

// ─── Tab 2: Neues Rezept erstellen ───────────────────────────────────────────
class _CreateNewTab extends StatelessWidget {
  final ScrollController scrollController;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController tagController;
  final TextEditingController ingredientNameCtrl;
  final TextEditingController ingredientAmountCtrl;
  final List<_IngredientEntry> ingredients;
  final List<TextEditingController> stepControllers;
  final String? selectedCategory;
  final List<String> tags;
  final int cookingTime;
  final String difficulty;
  final int servings;
  final List<String> categories;
  final List<String> difficulties;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onTagAdded;
  final ValueChanged<String> onTagRemoved;
  final VoidCallback onIngredientAdded;
  final ValueChanged<int> onIngredientRemoved;
  final VoidCallback onStepAdded;
  final ValueChanged<int> onStepRemoved;
  final ValueChanged<int> onCookingTimeChanged;
  final ValueChanged<String> onDifficultyChanged;
  final ValueChanged<int> onServingsChanged;

  const _CreateNewTab({
    required this.scrollController,
    required this.titleController,
    required this.descController,
    required this.tagController,
    required this.ingredientNameCtrl,
    required this.ingredientAmountCtrl,
    required this.ingredients,
    required this.stepControllers,
    required this.selectedCategory,
    required this.tags,
    required this.cookingTime,
    required this.difficulty,
    required this.servings,
    required this.categories,
    required this.difficulties,
    required this.onCategoryChanged,
    required this.onTagAdded,
    required this.onTagRemoved,
    required this.onIngredientAdded,
    required this.onIngredientRemoved,
    required this.onStepAdded,
    required this.onStepRemoved,
    required this.onCookingTimeChanged,
    required this.onDifficultyChanged,
    required this.onServingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Titel & Beschreibung
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
              labelText: 'Titel *', hintText: 'z.B. Hausgemachte Lasagne'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descController,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Beschreibung',
              hintText: 'Kurze Beschreibung des Rezepts'),
        ),
        const SizedBox(height: 24),

        // ── Zutaten ─────────────────────────────────────────────────────
        Row(
          children: [
            Text('Zutaten', style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: onIngredientAdded,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Hinzufügen'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        // Zutat-Eingabe
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: ingredientNameCtrl,
                decoration: const InputDecoration(
                    hintText: 'Zutat (z.B. Mehl)', isDense: true),
                onSubmitted: (_) => onIngredientAdded(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: ingredientAmountCtrl,
                decoration: const InputDecoration(
                    hintText: 'Menge (z.B. 200g)', isDense: true),
                onSubmitted: (_) => onIngredientAdded(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIngredientAdded,
            ),
          ],
        ),
        if (ingredients.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...ingredients.asMap().entries.map((e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fiber_manual_record, size: 8),
                title: Text('${e.value.name}'
                    '${e.value.amount.isNotEmpty ? "  –  ${e.value.amount}" : ""}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onIngredientRemoved(e.key),
                ),
              )),
        ],
        const SizedBox(height: 24),

        // ── Zubereitungsschritte ─────────────────────────────────────────
        Row(
          children: [
            Text('Zubereitung', style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: onStepAdded,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Schritt'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        ...stepControllers.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, right: 8),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: Text('${e.key + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Schritt ${e.key + 1} beschreiben...',
                        isDense: true,
                      ),
                    ),
                  ),
                  if (stepControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onStepRemoved(e.key),
                    ),
                ],
              ),
            )),
        const SizedBox(height: 24),

        // ── Metadaten ────────────────────────────────────────────────────
        _buildMetaSection(
          context: context,
          selectedCategory: selectedCategory,
          categories: categories,
          difficulties: difficulties,
          difficulty: difficulty,
          cookingTime: cookingTime,
          servings: servings,
          tags: tags,
          tagController: tagController,
          onCategoryChanged: onCategoryChanged,
          onTagAdded: onTagAdded,
          onTagRemoved: onTagRemoved,
          onCookingTimeChanged: onCookingTimeChanged,
          onDifficultyChanged: onDifficultyChanged,
          onServingsChanged: onServingsChanged,
        ),
      ],
    );
  }
}
