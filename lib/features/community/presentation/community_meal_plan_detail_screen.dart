import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomi/features/community/presentation/publish_meal_plan_sheet.dart';
import 'package:kokomi/features/meal_plan/presentation/meal_plan_provider.dart';
import 'package:kokomi/features/meal_plan/presentation/new_meal_plan_screen.dart';
import 'package:kokomi/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomi/features/profile/presentation/profile_provider.dart';
import 'package:kokomi/models/shopping_list.dart';
import 'package:kokomi/models/community_meal_plan.dart';
import 'package:kokomi/models/recipe.dart';
import 'package:kokomi/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:kokomi/widgets/cooking_spoon_rating.dart';

class CommunityMealPlanDetailScreen extends ConsumerStatefulWidget {
  final CommunityMealPlan plan;
  const CommunityMealPlanDetailScreen({super.key, required this.plan});

  @override
  ConsumerState<CommunityMealPlanDetailScreen> createState() =>
      _CommunityMealPlanDetailScreenState();
}

class _CommunityMealPlanDetailScreenState
    extends ConsumerState<CommunityMealPlanDetailScreen> {
  late CommunityMealPlan _plan;
  int _selectedDay = 0;
  int _myRating = 0;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    if (_plan.entries.isNotEmpty) {
      _selectedDay = _plan.entries.first.dayIndex;
    }
    _loadMyRating();
    // View-Count inkrementieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProfileRepositoryProvider).incrementMealPlanViewCount(_plan.id);
    });
  }

  Future<void> _loadMyRating() async {
    final repo = ref.read(communityMealPlanRepositoryProvider);
    final rating = await repo.getMyPlanRating(_plan.id);
    if (mounted && rating != null) {
      setState(() => _myRating = rating);
    }
  }

  Future<void> _toggleLike() async {
    await ref.read(communityMealPlanFeedProvider.notifier).toggleLike(_plan);
  }

  Future<void> _toggleSave() async {
    await ref.read(communityMealPlanFeedProvider.notifier).toggleSave(_plan);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_plan.isSavedByMe ? 'Gespeichert entfernt' : '✅ Wochenplan gespeichert'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _rate(int stars) async {
    setState(() => _myRating = stars);
    await ref.read(communityMealPlanFeedProvider.notifier).ratePlan(_plan, stars);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🥄 Danke für deine Bewertung!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _editPlan() async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => NewMealPlanScreen(plan: _plan)));
    if (result == true || result == null) {
      // Plan wurde geändert – Provider invalidieren
      ref.invalidate(myAllMealPlansProvider);
      ref.invalidate(myPublishedMealPlansProvider);
    }
  }

  Future<void> _publishPlan() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PublishMealPlanSheet(
        entries: _plan.entries,
        planId: _plan.id,
        initialTitle: _plan.title,
        initialDescription: _plan.description,
        initialTags: _plan.tags,
      ),
    );
    ref.invalidate(myAllMealPlansProvider);
    ref.invalidate(myPublishedMealPlansProvider);
    if (mounted) {
      // Plan-Status updaten
      final repo = ref.read(communityMealPlanRepositoryProvider);
      final updated = await repo.getMyAllPlans(
          ref.read(userProfileRepositoryProvider).currentUserId ?? '');
      final fresh = updated.firstWhere((p) => p.id == _plan.id,
          orElse: () => _plan);
      setState(() => _plan = fresh);
    }
  }

  Future<void> _unpublishPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Veröffentlichung zurückziehen?'),
        content: Text(
            '"${_plan.title}" wird aus der Community entfernt.\nDein Plan bleibt als Entwurf erhalten.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Zurückziehen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = ref.read(communityMealPlanRepositoryProvider);
    await repo.unpublishPlan(_plan.id);
    ref.invalidate(myAllMealPlansProvider);
    ref.invalidate(myPublishedMealPlansProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Plan zurückgezogen'),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _plan = _plan.copyWith(isLikedByMe: _plan.isLikedByMe));
    }
  }

  Future<void> _deletePlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Plan löschen?'),
        content: Text('"${_plan.title}" wird dauerhaft gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = ref.read(communityMealPlanRepositoryProvider);
    await repo.delete(_plan.id);
    ref.invalidate(myAllMealPlansProvider);
    ref.invalidate(myPublishedMealPlansProvider);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showRateDialog() async {
    final stars = await showRatingDialog(
      context,
      title: 'Wochenplan bewerten',
      currentRating: _myRating > 0 ? _myRating : null,
    );
    if (stars != null) {
      await _rate(stars);
    }
  }

  String _ratingLabel(int r) => switch (r) {
        1 => '😞 Na ja',
        2 => '😐 OK',
        3 => '😊 Gut',
        4 => '😋 Super!',
        5 => '🤩 Fantastisch!',
        _ => '',
      };

  Future<void> _importPlan() async {
    final entries = _plan.entries;
    if (entries.isEmpty) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan übernehmen'),
        content: const Text('Möchtest du den bestehenden Plan ersetzen oder die Rezepte hinzufügen?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('merge'), child: const Text('Hinzufügen')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop('replace'), child: const Text('Ersetzen')),
        ],
      ),
    );
    if (choice == null) return;

    final notifier = ref.read(mealPlanProvider.notifier);
    if (choice == 'replace') await notifier.clearAll();
    for (final entry in entries) {
      await notifier.setMeal(entry.dayIndex, entry.slot, entry.recipe);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(choice == 'replace' ? '✅ Plan übernommen!' : '✅ Rezepte hinzugefügt!'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// Öffnet Sheet: Checkboxen für alle Rezepte → Zutaten zur Einkaufsliste
  Future<void> _addToShoppingList() async {
    final allRecipes = _plan.entries.map((e) => e.recipe).toList();
    if (allRecipes.isEmpty) return;

    // Deduplizieren nach Titel
    final unique = <String, FoodRecipe>{};
    for (final r in allRecipes) {
      unique[r.title] = r;
    }
    final recipes = unique.values.toList();

    final selected = Set<int>.from(List.generate(recipes.length, (i) => i));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, scrollCtrl) => Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      const SizedBox(width: 8),
                      Text('Rezepte zur Einkaufsliste',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Alle auswählen
                CheckboxListTile(
                  value: selected.length == recipes.length,
                  tristate: true,
                  title: const Text('Alle auswählen', style: TextStyle(fontWeight: FontWeight.w600)),
                  onChanged: (v) => setSheetState(() {
                    if (v == true) selected.addAll(List.generate(recipes.length, (i) => i));
                    else selected.clear();
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: recipes.length,
                    itemBuilder: (_, i) {
                      final r = recipes[i];
                      final ingredientCount = r.ingredients.length;
                      return CheckboxListTile(
                        value: selected.contains(i),
                        title: Text(r.title),
                        subtitle: Text('$ingredientCount Zutaten · ${r.cookingTimeMinutes} Min.',
                            style: Theme.of(ctx).textTheme.bodySmall),
                        onChanged: (v) => setSheetState(() {
                          if (v == true) selected.add(i);
                          else selected.remove(i);
                        }),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      onPressed: selected.isEmpty ? null : () async {
                        Navigator.pop(ctx);
                        await _doAddToShoppingList(
                            selected.map((i) => recipes[i]).toList());
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text('${selected.length} Rezepte hinzufügen'),
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _doAddToShoppingList(List<FoodRecipe> recipes) async {
    // Alle Zutaten aller gewählten Rezepte zusammenführen (dedupliziert)
    final ingredientMap = <String, String>{};
    for (final recipe in recipes) {
      for (final ing in recipe.ingredients) {
        final key = ing.name.toLowerCase().trim();
        if (!ingredientMap.containsKey(key)) {
          ingredientMap[key] = ing.name;
        }
      }
    }

    final listsNotifier = ref.read(shoppingListsProvider.notifier);
    final lists = ref.read(shoppingListsProvider).valueOrNull ?? [];

    // Aktive Liste holen oder neue erstellen
    ShoppingList? targetList;
    if (lists.isNotEmpty) {
      targetList = lists.first;
    } else {
      await listsNotifier.createList('Wochenplan: ${_plan.title}');
      final updated = ref.read(shoppingListsProvider).valueOrNull ?? [];
      if (updated.isNotEmpty) targetList = updated.first;
    }

    if (targetList == null) return;

    // Liste aktiv setzen und Items hinzufügen
    ref.read(selectedShoppingListProvider.notifier).state = targetList;
    final itemNotifier = ref.read(shoppingListProvider.notifier);
    for (final name in ingredientMap.values) {
      await itemNotifier.addItem(name);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${ingredientMap.length} Zutaten zur Einkaufsliste hinzugefügt'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Zur Liste', onPressed: () {}),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _plan.entries;
    const dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    final daysWithEntries = entries.map((e) => e.dayIndex).toSet().toList()..sort();
    final dayEntries = entries.where((e) => e.dayIndex == _selectedDay).toList()
      ..sort((a, b) => a.slot.index.compareTo(b.slot.index));

    final feedPlan = ref.watch(communityMealPlanFeedProvider).valueOrNull
        ?.firstWhere((p) => p.id == _plan.id, orElse: () => _plan);
    final livePlan = feedPlan ?? _plan;

    final isMyPlan = ref.read(userProfileRepositoryProvider).currentUserId == _plan.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_plan.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (isMyPlan) ...[
            // Eigener Plan: Bearbeiten-Button + Dot-Menu
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Plan bearbeiten',
              onPressed: _editPlan,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) async {
                switch (v) {
                  case 'publish':   await _publishPlan(); break;
                  case 'unpublish': await _unpublishPlan(); break;
                  case 'delete':    await _deletePlan(); break;
                }
              },
              itemBuilder: (_) => [
                if (!_plan.isPublished)
                  const PopupMenuItem(
                    value: 'publish',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.cloud_upload_outlined),
                      title: Text('In Community teilen'),
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'unpublish',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.cloud_off_outlined),
                      title: Text('Nicht mehr teilen'),
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                    title: Text('Löschen',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Fremder Plan: Speichern + Like
            IconButton(
              icon: Icon(
                livePlan.isSavedByMe
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: livePlan.isSavedByMe ? theme.colorScheme.primary : null,
              ),
              tooltip: livePlan.isSavedByMe ? 'Gespeichert' : 'Speichern',
              onPressed: _toggleSave,
            ),
            IconButton(
              icon: Icon(
                livePlan.isLikedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: livePlan.isLikedByMe ? Colors.red : null,
              ),
              onPressed: _toggleLike,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: theme.colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_plan.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_plan.description, style: theme.textTheme.bodyMedium),
                  ),
                // Autor + Stats
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(_plan.authorName,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Icon(Icons.favorite_border_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${livePlan.likeCount}', style: theme.textTheme.bodySmall),
                    if (_plan.avgDailyCalories > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('~${_plan.avgDailyCalories} kcal/Tag',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
                // Tags
                if (_plan.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: _plan.tags.map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        )).toList(),
                  ),
                ],
                // ── Kochlöffel-Bewertung ──────────────────────────────
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      // Community-Ø
                      if (livePlan.ratingCount > 0) ...[
                        Row(
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 5),
                            Text('Community',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(width: 8),
                            Icon(Icons.soup_kitchen_rounded,
                                size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 3),
                            Text(
                              '${livePlan.avgRating?.toStringAsFixed(1) ?? '–'} (${livePlan.ratingCount})',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                      ],
                      // Eigene Bewertung
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 5),
                          Text('Meine Wertung',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(width: 8),
                          CookingSpoonRating(
                            myRating: _myRating > 0 ? _myRating : null,
                            onRate: _rate,
                            size: 22,
                            showCount: false,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _myRating > 0
                                  ? _ratingLabel(_myRating)
                                  : 'Tippe zum Bewerten',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _myRating > 0
                                    ? Colors.orange.shade700
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: _myRating > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tages-Auswahl ────────────────────────────────────────────
          if (daysWithEntries.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: daysWithEntries.length,
                itemBuilder: (_, i) {
                  final dayIdx = daysWithEntries[i];
                  final isSelected = dayIdx == _selectedDay;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDay = dayIdx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dayNames[dayIdx.clamp(0, 6)],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // ── Mahlzeiten des Tages ──────────────────────────────────────
          Expanded(
            child: dayEntries.isEmpty
                ? Center(
                    child: Text('Keine Mahlzeiten für diesen Tag',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: dayEntries.length,
                    itemBuilder: (_, i) => _MealCard(
                      entry: dayEntries[i],
                      onTap: () => _openRecipe(dayEntries[i].recipe),
                      onAddToList: () => _addSingleRecipeToList(dayEntries[i].recipe),
                    ),
                  ),
          ),
        ],
      ),
      // ── Bottom Buttons ──────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToShoppingList,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Einkaufsliste'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _importPlan,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Plan übernehmen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSingleRecipeToList(FoodRecipe recipe) async {
    await _doAddToShoppingList([recipe]);
  }

  void _openRecipe(FoodRecipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealPlanEntry entry;
  final VoidCallback onTap;
  final VoidCallback onAddToList;

  const _MealCard({required this.entry, required this.onTap, required this.onAddToList});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(entry.slot.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.slot.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    Text(entry.recipe.title,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    if (entry.recipe.nutrition?.calories != null && entry.recipe.nutrition!.calories > 0)
                      Text('${entry.recipe.nutrition!.calories} kcal · ${entry.recipe.cookingTimeMinutes} Min.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              // Einkaufsliste-Button pro Rezept
              IconButton(
                icon: Icon(Icons.add_shopping_cart_outlined,
                    size: 20, color: theme.colorScheme.primary),
                tooltip: 'Zur Einkaufsliste',
                onPressed: onAddToList,
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

