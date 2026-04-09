import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kokomu/features/meal_plan/presentation/meal_plan_provider.dart';
import 'package:kokomu/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomu/features/recipes/presentation/recipe_category_provider.dart';
import 'package:kokomu/features/recipes/presentation/recipe_rating_provider.dart';
import 'package:kokomu/features/nutrition/presentation/nutrition_provider.dart';
import 'package:kokomu/features/settings/presentation/subscription_provider.dart';
import 'package:kokomu/features/settings/presentation/paywall_screen.dart';
import 'package:kokomu/features/community/presentation/publish_meal_plan_sheet.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomu/features/community/presentation/community_meal_plan_detail_screen.dart';
import 'package:kokomu/features/meal_plan/presentation/new_meal_plan_screen.dart';
import 'package:kokomu/models/community_meal_plan.dart';
import 'package:kokomu/features/household/presentation/household_provider.dart';
import 'package:kokomu/features/household/presentation/household_meal_plan_preference_provider.dart';
import 'package:kokomu/core/services/pdf_export_service.dart';
import 'package:kokomu/models/recipe.dart';
import 'package:kokomu/features/recipes/presentation/cooking_mode_screen.dart';
import 'package:kokomu/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:go_router/go_router.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  /// Wenn true: kein eigener Scaffold/AppBar – für Einbettung in KitchenScreen
  final bool embedded;
  /// Callback damit der Parent die AppBar-Actions rendern kann
  final ValueChanged<List<Widget>>? onActionsChanged;

  const MealPlanScreen({super.key, this.embedded = false, this.onActionsChanged});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  int _selectedDayIndex = 0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = DateTime.now().weekday - 1;
    // Actions nach dem ersten Frame an Parent melden
    if (widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pushActions());
    }
  }

  void _pushActions() {
    if (!widget.embedded) return;
    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;
    widget.onActionsChanged?.call(_buildActions(isPro));
  }

  List<Widget> _buildActions(bool isPro) => [
        if (isPro)
          _isGenerating
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'KI-Wochenplan generieren',
                  onPressed: _generateAiPlan,
                ),
        // ── Neuer Plan: nur Pro ──
        Tooltip(
          message: isPro ? 'Neuen Plan erstellen' : '⭐ Pro: Neuen Plan erstellen',
          child: IconButton(
            icon: Icon(Icons.add_rounded,
                color: isPro ? null : Theme.of(context).disabledColor),
            onPressed: isPro
                ? () => context.push('/kitchen/meal-plan/new')
                : () => _showProHint(context),
          ),
        ),
        // ── Pläne & Vorlagen: nur Pro ──
        Tooltip(
          message: isPro ? 'Pläne & Vorlagen laden' : '⭐ Pro: Pläne & Vorlagen laden',
          child: IconButton(
            icon: Icon(Icons.folder_open_outlined,
                color: isPro ? null : Theme.of(context).disabledColor),
            onPressed: isPro ? _loadTemplate : () => _showProHint(context),
          ),
        ),
        // ── Drei-Punkte-Menü: bei Non-Pro komplett ausgegraut ──
        if (isPro)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              if (action == 'shopping') _addToShoppingList();
              if (action == 'save_template') _saveAsTemplate();
              if (action == 'share') _sharePlan();
              if (action == 'clear') _confirmClearPlan();
              if (action == 'pdf') _exportAsPdf();
              if (action == 'share_community') _shareToCommunity();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'shopping',
                child: ListTile(
                    leading: Icon(Icons.add_shopping_cart),
                    title: Text('Zutaten einkaufen'),
                    dense: true,
                    contentPadding: EdgeInsets.zero),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                    leading: Icon(Icons.share_rounded),
                    title: Text('Plan teilen'),
                    dense: true,
                    contentPadding: EdgeInsets.zero),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Als PDF exportieren'),
                    dense: true,
                    contentPadding: EdgeInsets.zero),
              ),
              const PopupMenuItem(
                value: 'save_template',
                child: ListTile(
                    leading: Icon(Icons.bookmark_add_outlined),
                    title: Text('Als Plan speichern'),
                    dense: true,
                    contentPadding: EdgeInsets.zero),
              ),
              const PopupMenuItem(
                value: 'share_community',
                child: ListTile(
                    leading: Icon(Icons.cloud_upload_outlined),
                    title: Text('In Community teilen'),
                    dense: true,
                    contentPadding: EdgeInsets.zero),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                    leading: Icon(Icons.delete_sweep, color: Colors.red),
                    title: Text('Plan leeren',
                        style: TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero),
              ),
            ],
          )
        else
          Tooltip(
            message: '⭐ Pro: Weitere Optionen',
            child: IconButton(
              icon: Icon(Icons.more_vert,
                  color: Theme.of(context).disabledColor),
              onPressed: () => _showProHint(context),
            ),
          ),
      ];

  void _showProHint(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('⭐ Diese Funktion ist nur mit Pro verfügbar.'),
          action: SnackBarAction(
            label: 'Pro holen',
            onPressed: () => context.push('/settings/paywall'),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(subscriptionProvider).valueOrNull?.isPro ?? false;

    // Im embedded-Modus: kein eigener Scaffold, nur den Body zurückgeben
    if (widget.embedded) {
      return isPro ? _buildPlannerBody() : const _ProTeaser();
    }

    // Standalone-Modus: voller Scaffold mit AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wochenplan'),
        actions: _buildActions(isPro),
      ),
      body: isPro ? _buildPlannerBody() : const _ProTeaser(),
    );
  }

  Widget _buildPlannerBody() {
    final weekDays = ref.watch(weekDaysProvider);
    final theme = Theme.of(context);
    final profile = ref.watch(nutritionProfileProvider);
    final offset = ref.watch(weekOffsetProvider);
    // Heute-Index nur bei offset==0 relevant
    final today = offset == 0 ? DateTime.now().weekday - 1 : -1;
    final isHouseholdMode = ref.watch(isUsingHouseholdPlanProvider);
    final household = ref.watch(householdProvider).valueOrNull;

    return Column(
      children: [
        // ── Haushalt-Hinweis (nur wenn Haushalt existiert aber persönlicher Plan aktiv) ──
        // Wenn Haushalt-Plan aktiv: kein Banner nötig – der Wochenplan IST der Haushalt-Plan.
        // Wenn persönlicher Plan aktiv aber Haushalt vorhanden: dezenter Hinweis.
        if (household != null && !isHouseholdMode)
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            child: InkWell(
              onTap: () async {
                await ref
                    .read(householdMealPlanPreferenceProvider.notifier)
                    .setUseHouseholdPlan(true);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.groups_rounded,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Haushalt-Plan verfügbar: ${household.name}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      'Aktivieren',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        // ── Wochen-Navigation ──────────────────────────────────────────
        Container(
          color: isHouseholdMode
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : theme.colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              // Zurück (max. 4 Wochen in Vergangenheit)
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: offset > -4
                    ? () => ref.read(weekOffsetProvider.notifier).state--
                    : null,
                tooltip: 'Vorherige Woche',
              ),
              Expanded(
                child: GestureDetector(
                  onTap: offset != 0
                      ? () => ref.read(weekOffsetProvider.notifier).state = 0
                      : null,
                  child: Column(
                    children: [
                      // Haushalt-Badge wenn aktiv
                      if (isHouseholdMode && household != null)
                        GestureDetector(
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Zurück zum eigenen Plan?'),
                                content: Text(
                                  'Du wechselst zurück auf deinen persönlichen Plan.\n\n'
                                  'Der Haushalt-Plan von „${household.name}" bleibt erhalten.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Abbrechen'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Eigener Plan'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref
                                  .read(householdMealPlanPreferenceProvider.notifier)
                                  .setUseHouseholdPlan(false);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.groups_rounded,
                                    size: 12,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  household.name,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Text(
                        ref.watch(weekLabelProvider),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: offset == 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (offset != 0)
                        Text(
                          'Tippe für heute',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      // Datumsbereich
                      Builder(builder: (_) {
                        final notifier = ref.read(mealPlanProvider.notifier);
                        final start = notifier.weekStart(offset);
                        final end = start.add(const Duration(days: 6));
                        final fmt = (DateTime d) =>
                            '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
                        return Text(
                          '${fmt(start)} – ${fmt(end)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Vor (max. 12 Wochen in Zukunft)
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: offset < 12
                    ? () => ref.read(weekOffsetProvider.notifier).state++
                    : null,
                tooltip: 'Nächste Woche',
              ),
            ],
          ),
        ),

        // ── Tages-Chips ────────────────────────────────────────────────
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: 7,
            itemBuilder: (context, i) {
              final day = weekDays[i];
              final isSelected = i == _selectedDayIndex;
              final isToday = i == today;
              final cal = day.totalCalories;
              final calColor = profile != null && profile.calorieGoal > 0
                  ? cal > profile.calorieGoal
                      ? theme.colorScheme.error
                      : cal > 0
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant;

              // Konkretes Datum für diesen Tag berechnen
              final notifier = ref.read(mealPlanProvider.notifier);
              final weekStartDate = notifier.weekStart(offset);
              final dayDate = weekStartDate.add(Duration(days: i));

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : isToday
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: isToday && !isSelected
                          ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.dayName,
                          style: TextStyle(
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${dayDate.day}.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${day.entries.length}',
                          style: TextStyle(
                            fontSize: 10,
                            color: calColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (cal > 0)
                          Text(
                            cal >= 1000 ? '${(cal / 1000).toStringAsFixed(1)}k' : '${cal}',
                            style: TextStyle(fontSize: 9, color: calColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Mahlzeiten des gewählten Tags ─────────────────────────────
        Expanded(
          child: _DayPlanView(
            day: weekDays[_selectedDayIndex],
            dayIndex: _selectedDayIndex,
            calorieGoal: profile?.calorieGoal,
          ),
        ),
      ],
    );
  }

  Future<void> _addToShoppingList() async {
    final count = await ref
        .read(mealPlanProvider.notifier)
        .addAllIngredientsToShoppingList();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$count Zutaten auf die Einkaufsliste gesetzt ✅')),
    );
  }

  /// Zeigt Dialog zur Auswahl von Diätpräferenzen vor KI-Generierung.
  Future<List<String>?> _showDietPreferencesDialog() async {
    final selected = <String>{};
    const options = [
      ('🌱', 'Vegetarisch'),
      ('🌿', 'Vegan'),
      ('💪', 'High Protein'),
      ('🔥', 'Low Carb'),
      ('🍬', 'Zuckerarm'),
      ('🚫', 'Glutenfrei'),
      ('🥛', 'Laktosefrei'),
      ('🐟', 'Pescetarisch'),
      ('🥩', 'Keto'),
      ('⚖️', 'Kalorienarm'),
      ('🏋️', 'Fitness'),
      ('🍲', 'Meal Prep'),
    ];

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ernährungspräferenzen'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wähle optionale Präferenzen für deinen Wochenplan:',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: options.map((opt) {
                    final isActive = selected.contains(opt.$2);
                    return FilterChip(
                      label: Text('${opt.$1} ${opt.$2}', style: const TextStyle(fontSize: 12)),
                      selected: isActive,
                      onSelected: (val) => setDialogState(() {
                        if (val) { selected.add(opt.$2); } else { selected.remove(opt.$2); }
                      }),
                      selectedColor: Theme.of(ctx).colorScheme.primaryContainer,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, selected.toList()),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(selected.isEmpty ? 'Ohne Präferenz generieren' : 'Generieren'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAiPlan() async {
    // Gespeicherte Rezepte laden
    final allSaved = ref.read(savedRecipesProvider).valueOrNull ?? [];
    if (allSaved.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keine gespeicherten Rezepte vorhanden.\nSpeichere zuerst einige Rezepte in der Küche.'),
          action: SnackBarAction(label: 'Zur Küche', onPressed: () => context.go('/kitchen')),
        ),
      );
      return;
    }

    // Diätpräferenzen abfragen
    final preferences = await _showDietPreferencesDialog();
    if (preferences == null) return; // User hat abgebrochen

    setState(() => _isGenerating = true);
    _pushActions();

    try {
      final categories = ref.read(recipeCategoryProvider);
      final ratings = ref.read(recipeRatingProvider);

      // Rezepte filtern wenn Präferenzen gewählt
      var pool = List<FoodRecipe>.from(allSaved);
      if (preferences.isNotEmpty) {
        final prefLower = preferences.map((p) => p.toLowerCase()).toList();
        // Filtern nach Tags in Titel/Beschreibung
        final filtered = pool.where((r) {
          final text = '${r.title} ${r.description}'.toLowerCase();
          return prefLower.any((p) {
            if (p == 'vegetarisch') return !_hasMeat(text);
            if (p == 'vegan') return !_hasMeat(text) && !_hasDairy(text);
            if (p == 'glutenfrei') return !text.contains('nudel') && !text.contains('mehl') && !text.contains('brot');
            return text.contains(p) || r.title.toLowerCase().contains(p);
          });
        }).toList();
        // Nur gefilterten Pool verwenden wenn genug Rezepte da sind
        if (filtered.length >= 7) pool = filtered;
      }

      // Rezepte nach Rating sortieren (bessere zuerst), dann shufflen
      pool.sort((a, b) {
        final rA = ratings[a.id] ?? 0;
        final rB = ratings[b.id] ?? 0;
        return rB.compareTo(rA);
      });
      // Gewichtetes Mischen: Top-Hälfte bleibt vorne
      final topHalf = pool.take((pool.length / 2).ceil()).toList()..shuffle();
      final bottomHalf = pool.skip((pool.length / 2).ceil()).toList()..shuffle();
      pool = [...topHalf, ...bottomHalf];

      // Rezepte nach Mahlzeit-Typ in separate Queues aufteilen
      // Queue = Liste die wir der Reihe nach abarbeiten, ohne Wiederholung
      final breakfastQueue = pool.where((r) => categories[r.id] == RecipeMealType.breakfast).toList();
      final lunchQueue     = pool.where((r) => categories[r.id] == RecipeMealType.lunch).toList();
      final dinnerQueue    = pool.where((r) => categories[r.id] == RecipeMealType.dinner).toList();
      final uncategorized  = pool.where((r) => categories[r.id] == null).toList();

      // Hilfsfunktion: nächstes nicht-wiederholtes Rezept oder null
      // Jede Queue wird einmalig durchlaufen – kein zyklisches Wrap-around
      FoodRecipe? takeNext(List<FoodRecipe> queue, Set<String> usedIds) {
        // Bevorzugt: aus der spezifischen Queue
        for (final r in queue) {
          if (!usedIds.contains(r.id)) {
            usedIds.add(r.id);
            return r;
          }
        }
        // Fallback: aus unkategorisierten
        for (final r in uncategorized) {
          if (!usedIds.contains(r.id)) {
            usedIds.add(r.id);
            return r;
          }
        }
        // Fallback 2: aus dem gesamten Pool (wenn sehr wenige Rezepte)
        for (final r in pool) {
          if (!usedIds.contains(r.id)) {
            usedIds.add(r.id);
            return r;
          }
        }
        // Pool erschöpft → Slot bleibt leer
        return null;
      }

      // Pro Tag eigene usedIds → kein Duplikat am selben Tag
      // Global-Set über alle Tage → kein Duplikat in der gesamten Woche (wenn möglich)
      final weekUsedIds = <String>{};

      // Plan aufbauen: 7 Tage × 3 Slots
      final entries = <({int dayIndex, MealSlot slot, FoodRecipe recipe})>[];
      for (int day = 0; day < 7; day++) {
        final dayUsedIds = <String>{};
        for (final slot in [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]) {
          final queue = switch (slot) {
            MealSlot.breakfast => breakfastQueue,
            MealSlot.lunch     => lunchQueue,
            _                  => dinnerQueue,
          };
          // Kombiniertes Set: kein Duplikat am Tag UND in der Woche bevorzugt
          final combinedUsed = {...weekUsedIds, ...dayUsedIds};
          final recipe = takeNext(queue, combinedUsed);
          if (recipe != null) {
            // Nur zum Wochen-Set hinzufügen wenn noch nicht drin
            weekUsedIds.add(recipe.id);
            dayUsedIds.add(recipe.id);
            entries.add((dayIndex: day, slot: slot, recipe: recipe));
            // Aus den Queues entfernen damit nicht nochmal gezogen wird
            breakfastQueue.remove(recipe);
            lunchQueue.remove(recipe);
            dinnerQueue.remove(recipe);
          }
          // Bei null: Slot bleibt einfach leer → kein Entry
        }
      }

      if (!mounted) return;

      // Vorschau-BottomSheet: User sieht Plan und kann ihn direkt speichern
      final confirmed = await _showPlanPreviewSheet(entries, preferences);
      if (!mounted || !confirmed) return;

      await ref.read(mealPlanProvider.notifier).clearAll();
      for (final e in entries) {
        await ref.read(mealPlanProvider.notifier).setMeal(e.dayIndex, e.slot, e.recipe);
      }

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final prefText = preferences.isNotEmpty ? ' · ${preferences.join(', ')}' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Wochenplan gespeichert$prefText')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
        _pushActions();
      }
    }
  }

  bool _hasMeat(String text) =>
      ['fleisch', 'hähnchen', 'huhn', 'rind', 'schwein', 'wurst', 'speck',
       'lachs', 'thunfisch', 'fisch', 'steak', 'hackfleisch', 'chicken',
       'beef', 'pork', 'bacon', 'meat'].any(text.contains);

  bool _hasDairy(String text) =>
      ['milch', 'käse', 'butter', 'sahne', 'joghurt', 'quark', 'rahm',
       'milk', 'cheese', 'cream', 'yogurt', 'dairy'].any(text.contains);

  /// Vollständige Vorschau des generierten Plans als BottomSheet.
  /// Gibt true zurück wenn der User den Plan speichern möchte.
  Future<bool> _showPlanPreviewSheet(
    List<({int dayIndex, MealSlot slot, FoodRecipe recipe})> entries,
    List<String> preferences,
  ) async {
    final dayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    // Leere Slots ermitteln (21 mögliche Slots - tatsächlich belegte)
    final emptySlots = 21 - entries.length;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) => Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          size: 20, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                        Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dein Wochenplan',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (preferences.isNotEmpty)
                            Text(preferences.join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600))
                          else
                            Text('Basierend auf deinen gespeicherten Rezepten',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Info bei leeren Slots
              if (emptySlots > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16,
                          color: Theme.of(ctx).colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          preferences.isNotEmpty
                              ? '$emptySlots Slot${emptySlots > 1 ? 's' : ''} leer – '
                                'zu wenig Rezepte passend zu: ${preferences.join(', ')}.'
                              : '$emptySlots Slot${emptySlots > 1 ? 's' : ''} leer – '
                                'nicht genug verschiedene Rezepte für alle ${21} Slots.',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.onTertiaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: 7,
                  itemBuilder: (ctx, dayIndex) {
                    final dayEntries = entries
                        .where((e) => e.dayIndex == dayIndex)
                        .toList()
                      ..sort((a, b) => a.slot.index.compareTo(b.slot.index));
                    final allSlots = [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                          child: Text(
                            dayNames[dayIndex],
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        ...allSlots.map((slot) {
                          final entry = dayEntries.where((e) => e.slot == slot).firstOrNull;
                          if (entry != null) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Text(entry.slot.emoji,
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.slot.label,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            entry.recipe.title,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (entry.recipe.cookingTimeMinutes > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.timer_outlined,
                                              size: 13,
                                              color: theme.colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${entry.recipe.cookingTimeMinutes} Min.',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Leerer Slot
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(slot.emoji,
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: theme.colorScheme.outlineVariant)),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${slot.label} – kein Rezept verfügbar',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outlineVariant,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            );
                          }
                        }),
                        if (dayIndex < 6)
                          const Divider(height: 8, indent: 4, endIndent: 4),
                      ],
                    );
                  },
                ),
              ),
              // Aktions-Buttons
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Verwerfen'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Plan speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  void _saveAsTemplate() {
    final entries = ref.read(mealPlanProvider).valueOrNull ?? [];
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Plan zum Speichern vorhanden.')),
      );
      return;
    }
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan speichern'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name des Plans',
            hintText: 'z.B. Muskelaufbau-Woche',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final repo = ref.read(communityMealPlanRepositoryProvider);
                final planJson = entries.map((e) => e.toJson()).toList();
                await repo.savePlanAsDraft(title: name, planJson: planJson);
                ref.invalidate(myAllMealPlansProvider);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Plan „$name" gespeichert ✅')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler beim Speichern: $e')),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _loadTemplate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TemplatePickerSheet(
        onLoad: (entries, name) async {
          await ref.read(mealPlanProvider.notifier).clearAll();
          for (final e in entries) {
            await ref
                .read(mealPlanProvider.notifier)
                .setMeal(e.dayIndex, e.slot, e.recipe);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('„$name" geladen ✅')),
            );
          }
        },
      ),
    );
  }

  void _confirmClearPlan() {
    final label = ref.read(weekLabelProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wochenplan leeren?'),
        content: Text('„$label" wird vollständig geleert.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(mealPlanProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
  }

  void _sharePlan() {
    final weekDays = ref.read(weekDaysProvider);
    final buffer = StringBuffer('📅 Mein Wochenplan\n\n');
    for (final day in weekDays) {
      if (day.entries.isEmpty) continue;
      buffer.writeln('${day.dayNameFull}:');
      for (final slot in MealSlot.values) {
        final entry = day.getSlot(slot);
        if (entry != null) {
          buffer.writeln('  ${slot.emoji} ${slot.label}: ${entry.recipe.title}'
              '${entry.calories > 0 ? ' (${entry.calories} kcal)' : ''}');
        }
      }
      buffer.writeln();
    }
    buffer.writeln('— erstellt mit kokomu');
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Future<void> _shareToCommunity() async {
    final entries = ref.read(mealPlanProvider).valueOrNull ?? [];
    if (entries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dein Wochenplan ist leer.')),
        );
      }
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PublishMealPlanSheet(entries: entries),
    );
  }

  Future<void> _exportAsPdf() async {
    try {
      final plan = ref.read(mealPlanProvider).valueOrNull ?? [];
      if (plan.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wochenplan ist leer.')),
          );
        }
        return;
      }
      final bytes = await PdfExportService.generateMealPlanPdf(plan);
      await PdfExportService.sharePdf(bytes, 'Wochenplan_kokomu.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF-Fehler: $e')),
        );
      }
    }
  }
}

// ── Tages-Ansicht mit Slots ──

class _DayPlanView extends ConsumerWidget {
  final MealPlanDay day;
  final int dayIndex;
  final int? calorieGoal;

  const _DayPlanView({
    required this.day,
    required this.dayIndex,
    this.calorieGoal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final slots = [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner, MealSlot.snack];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tages-Header mit Kaloriensumme
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day.dayNameFull,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (day.totalCalories > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _calColor(theme).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${day.totalCalories} kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _calColor(theme),
                  ),
                ),
              ),
          ],
        ),
        if (calorieGoal != null && day.totalCalories > 0) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (day.totalCalories / calorieGoal!).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(_calColor(theme)),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Meal Slots
        ...slots.map((slot) {
          final entry = day.getSlot(slot);
          return _MealSlotCard(
            slot: slot,
            entry: entry,
            dayIndex: dayIndex,
          );
        }),
      ],
    );
  }

  Color _calColor(ThemeData theme) {
    if (calorieGoal == null || calorieGoal! <= 0) {
      return theme.colorScheme.primary;
    }
    if (day.totalCalories > calorieGoal!) return theme.colorScheme.error;
    if (day.totalCalories > calorieGoal! * 0.8) return Colors.orange;
    return Colors.green;
  }
}

// ── Einzelner Meal-Slot ──

class _MealSlotCard extends ConsumerWidget {
  final MealSlot slot;
  final MealPlanEntry? entry;
  final int dayIndex;

  const _MealSlotCard({
    required this.slot,
    required this.entry,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (entry == null) {
      // Leerer Slot
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRecipePicker(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(slot.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slot.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      Text('Tippe um ein Rezept zuzuweisen',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          )),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline,
                    color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      );
    }

    // Befüllter Slot
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRecipePreview(context, ref),
        onLongPress: () => _showSlotOptions(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(slot.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        )),
                    Text(entry!.recipe.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (entry!.calories > 0)
                          _SmallBadge(
                            icon: Icons.local_fire_department,
                            label: '${entry!.calories} kcal',
                            color: theme.colorScheme.primary,
                          ),
                        _SmallBadge(
                          icon: Icons.timer_outlined,
                          label: '${entry!.recipe.cookingTimeMinutes} Min.',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.swap_horiz,
                    color: theme.colorScheme.primary, size: 20),
                tooltip: 'Ändern',
                onPressed: () => _showRecipePicker(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecipePreview(BuildContext context, WidgetRef ref) {
    final recipe = entry!.recipe;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(recipe.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(recipe.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (entry!.calories > 0)
                    Chip(
                      avatar: const Icon(Icons.local_fire_department, size: 14),
                      label: Text('${entry!.calories} kcal', style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                    ),
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 14),
                    label: Text('${recipe.cookingTimeMinutes} Min.', style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    avatar: const Icon(Icons.restaurant_outlined, size: 14),
                    label: Text('${recipe.ingredients.length} Zutaten', style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(recipe: recipe),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CookingModeScreen(recipe: recipe),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Kochen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRecipePicker(context, ref);
                      },
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Ändern'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(mealPlanProvider.notifier).removeMeal(dayIndex, slot);
                        Navigator.pop(ctx);
                      },
                      icon: Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.error),
                      label: Text('Entfernen', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecipePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RecipePickerSheet(
        slotLabel: '${slot.emoji} ${slot.label}',
        onSelect: (recipe) {
          ref.read(mealPlanProvider.notifier).setMeal(dayIndex, slot, recipe);
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _showSlotOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Rezept ändern'),
              onTap: () {
                Navigator.pop(ctx);
                _showRecipePicker(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Entfernen',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () {
                ref
                    .read(mealPlanProvider.notifier)
                    .removeMeal(dayIndex, slot);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SmallBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

// ── Rezept-Auswahl Bottom Sheet ──

class _RecipePickerSheet extends ConsumerWidget {
  final String slotLabel;
  final ValueChanged<FoodRecipe> onSelect;

  const _RecipePickerSheet({
    required this.slotLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedRecipesProvider);
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rezept für $slotLabel',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Wähle ein gespeichertes Rezept aus.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: savedAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Fehler: $e')),
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_border,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Noch keine Rezepte gespeichert.\n\nGeneriere zuerst KI-Rezepte oder speichere Online-Rezepte.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(Icons.restaurant,
                                size: 18,
                                color:
                                    theme.colorScheme.onPrimaryContainer),
                          ),
                          title: Text(recipe.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${recipe.cookingTimeMinutes} Min. · ${recipe.ingredients.length} Zutaten'
                            '${recipe.nutrition != null ? ' · ${recipe.nutrition!.calories} kcal' : ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            onSelect(recipe);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pro-Teaser ──

class _ProTeaser extends StatelessWidget {
  const _ProTeaser();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_month_rounded,
                  size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Mahlzeiten-Wochenplaner',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Plane deine Woche im Voraus.\n'
              '7 Tage · 4 Mahlzeiten pro Tag\n'
              'Alle Zutaten mit einem Klick auf die Einkaufsliste.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // Demo-Vorschau
            Opacity(
              opacity: 0.4,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _demoSlot('🌅', 'Frühstück', 'Overnight Oats', '350 kcal'),
                      _demoSlot('☀️', 'Mittagessen', 'Pasta Pesto', '520 kcal'),
                      _demoSlot('🌙', 'Abendessen', 'Lachs Bowl', '480 kcal'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const PaywallScreen(),
              ),
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text('Auf Pro upgraden'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoSlot(
      String emoji, String slot, String recipe, String cal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                Text(recipe,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(cal,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Vorlage-Picker Sheet ──────────────────────────────────────────────────

class _TemplatePickerSheet extends ConsumerStatefulWidget {
  final Future<void> Function(List<MealPlanEntry> entries, String name) onLoad;

  const _TemplatePickerSheet({required this.onLoad});

  @override
  ConsumerState<_TemplatePickerSheet> createState() =>
      _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<_TemplatePickerSheet>
    with SingleTickerProviderStateMixin {
  static const _tabCount = 2;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Text('Pläne & Vorlagen',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Meine Pläne'),
              Tab(text: 'Gespeichert'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _MyPlansTab(onLoad: widget.onLoad),
                _SavedCommunityTab(onLoad: widget.onLoad),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Meine gespeicherten Pläne (aus Supabase, auch unveröffentlichte) ────

class _MyPlansTab extends ConsumerWidget {
  final Future<void> Function(List<MealPlanEntry> entries, String name) onLoad;
  const _MyPlansTab({required this.onLoad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plansAsync = ref.watch(myAllMealPlansProvider);

    return plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Noch keine Pläne gespeichert',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Erstelle einen Plan und speichere ihn über das Menü.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final plan = plans[i];
            final isPublished = plan.isPublished;
            final mealCount = plan.planJson.length;
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => _MyPlanDetailSheet(
                    plan: plan,
                    onLoad: onLoad,
                    onChanged: () => ref.invalidate(myAllMealPlansProvider),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(plan.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '$mealCount Mahlzeit${mealCount != 1 ? 'en' : ''} · '
                        '${isPublished ? "✅ Veröffentlicht" : "📝 Entwurf"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPublished
                              ? Colors.green.shade700
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                    if (plan.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Wrap(
                          spacing: 4,
                          children: plan.tags.take(4).map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('#$t',
                                style: theme.textTheme.labelSmall),
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Detail-Sheet für eigenen Plan (im Template-Picker) ────────────────────

class _MyPlanDetailSheet extends ConsumerStatefulWidget {
  final CommunityMealPlan plan;
  final Future<void> Function(List<MealPlanEntry> entries, String name) onLoad;
  final VoidCallback onChanged;

  const _MyPlanDetailSheet({
    required this.plan,
    required this.onLoad,
    required this.onChanged,
  });

  @override
  ConsumerState<_MyPlanDetailSheet> createState() => _MyPlanDetailSheetState();
}

class _MyPlanDetailSheetState extends ConsumerState<_MyPlanDetailSheet> {
  late CommunityMealPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  Future<void> _loadPlan() async {
    final entries = _plan.entries;
    await widget.onLoad(entries, _plan.title);
    if (mounted) Navigator.pop(context);
  }

  void _showProHint(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: const Text('⭐ Diese Funktion ist nur mit Pro verfügbar'),
        action: SnackBarAction(
          label: 'Pro holen',
          onPressed: () {
            ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
            showModalBottomSheet(
              context: ctx,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const PaywallScreen(),
            );
          },
        ),
      ),
    );
  }

  Future<void> _editPlan() async {
    Navigator.pop(context);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewMealPlanScreen(plan: _plan),
      ),
    );
    if (result == true) {
      ref.invalidate(myAllMealPlansProvider);
      ref.invalidate(myPublishedMealPlansProvider);
      widget.onChanged();
    }
  }

  Future<void> _publish() async {
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
    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _unpublish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Zurückziehen?'),
        content: Text('"${_plan.title}" wird aus der Community entfernt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(c).colorScheme.error),
              child: const Text('Zurückziehen')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(communityMealPlanRepositoryProvider)
        .unpublishPlan(_plan.id);
    ref.invalidate(myAllMealPlansProvider);
    ref.invalidate(myPublishedMealPlansProvider);
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Aus Community entfernt')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = _plan.isPublished;
    final isPro = ref.watch(subscriptionProvider).valueOrNull?.isPro ?? false;
    final entries = _plan.entries;
    final uniqueRecipes = entries.map((e) => e.recipe.title).toSet().length;
    const dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final preview = <String, List<String>>{};
    for (final e in entries) {
      final day = dayNames[e.dayIndex.clamp(0, 6)];
      preview.putIfAbsent(day, () => []).add(e.recipe.title);
    }
    const dayOrder = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(_plan.title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPublished
                            ? Colors.green.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPublished ? Icons.public_rounded : Icons.drafts_outlined,
                            size: 12,
                            color: isPublished
                                ? Colors.green.shade700
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPublished ? 'Veröffentlicht' : 'Entwurf',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPublished
                                  ? Colors.green.shade700
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$uniqueRecipes Rezepte · ${entries.length} Mahlzeiten',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),

                // Stats (nur wenn veröffentlicht)
                if (isPublished) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _PlanStatItem(
                          icon: Icons.favorite_rounded,
                          color: Colors.redAccent,
                          label: '${_plan.likeCount}',
                          sub: 'Likes',
                        ),
                        _PlanStatItem(
                          icon: Icons.remove_red_eye_outlined,
                          color: Colors.blueAccent,
                          label: '${_plan.viewCount}',
                          sub: 'Aufrufe',
                        ),
                        if (_plan.avgRating != null && _plan.avgRating! > 0)
                          _PlanStatItem(
                            icon: Icons.star_rounded,
                            color: Colors.amber,
                            label: _plan.avgRating!.toStringAsFixed(1),
                            sub: 'Bewertung (${_plan.ratingCount})',
                          ),
                      ],
                    ),
                  ),
                ],

                // Tags
                if (_plan.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: _plan.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('#$t',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSecondaryContainer)),
                    )).toList(),
                  ),
                ],

                // Wochentage-Vorschau
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text('Wochenübersicht',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...dayOrder
                      .where((d) => preview.containsKey(d))
                      .map((day) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text(day,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                preview[day]!.join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                // Aktions-Buttons
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _editPlan,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Plan bearbeiten'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44)),
                ),
                const SizedBox(height: 8),
                // Plan übernehmen – nur Pro
                Tooltip(
                  message: isPro ? '' : '⭐ Nur mit Pro verfügbar',
                  child: FilledButton.icon(
                    onPressed: isPro ? _loadPlan : () => _showProHint(context),
                    icon: Icon(Icons.download_rounded,
                        size: 18,
                        color: isPro ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                    label: Text('In aktuellen Plan laden',
                        style: isPro ? null : TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                    style: isPro ? null : FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                ),
                const SizedBox(height: 10),
                if (!isPublished)
                  // In Community teilen – nur Pro
                  Tooltip(
                    message: isPro ? '' : '⭐ Nur mit Pro verfügbar',
                    child: OutlinedButton.icon(
                      onPressed: isPro ? _publish : () => _showProHint(context),
                      icon: Icon(Icons.cloud_upload_outlined,
                          size: 18,
                          color: isPro ? Colors.green : Theme.of(context).disabledColor),
                      label: Text('In Community teilen',
                          style: TextStyle(
                              color: isPro ? Colors.green : Theme.of(context).disabledColor)),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: isPro ? Colors.green.shade300 : Theme.of(context).disabledColor)),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _unpublish,
                    icon: Icon(Icons.cloud_off_outlined,
                        size: 18, color: theme.colorScheme.error),
                    label: Text('Veröffentlichung zurückziehen',
                        style: TextStyle(color: theme.colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: theme.colorScheme.error.withValues(alpha: 0.5))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  const _PlanStatItem(
      {required this.icon,
      required this.color,
      required this.label,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(sub,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ── Tab 2: Gespeicherte Community-Pläne ───────────────────────────────────

class _SavedCommunityTab extends ConsumerWidget {
  final Future<void> Function(List<MealPlanEntry> entries, String name) onLoad;
  const _SavedCommunityTab({required this.onLoad});

  void _showProHint(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: const Text('⭐ Diese Funktion ist nur mit Pro verfügbar'),
        action: SnackBarAction(
          label: 'Pro holen',
          onPressed: () {
            ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
            showModalBottomSheet(
              context: ctx,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const PaywallScreen(),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final savedAsync = ref.watch(savedMealPlansProvider);
    final isPro = ref.watch(subscriptionProvider).valueOrNull?.isPro ?? false;

    return savedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Keine Pläne gespeichert',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Speichere Wochenpläne aus dem Entdecken-Tab.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final plan = plans[i];
            final entries = plan.entries;
            final mealCount = plan.planJson.length;
            final hasRating = plan.avgRating != null && plan.avgRating! > 0;

            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => CommunityMealPlanDetailScreen(plan: plan),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            theme.colorScheme.secondary,
                            theme.colorScheme.tertiary,
                          ]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(plan.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$mealCount Mahlzeit${mealCount != 1 ? 'en' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 11,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(plan.authorName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant)),
                              if (hasRating) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.star_rounded,
                                    size: 11, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(plan.avgRating!.toStringAsFixed(1),
                                    style: theme.textTheme.labelSmall),
                              ],
                              const SizedBox(width: 8),
                              Icon(Icons.favorite_border_rounded,
                                  size: 11, color: Colors.redAccent),
                              const SizedBox(width: 2),
                              Text('${plan.likeCount}',
                                  style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (action) {
                          if (action == 'load') {
                            if (!isPro) {
                              _showProHint(ctx);
                              return;
                            }
                            Navigator.pop(ctx);
                            onLoad(entries, plan.title);
                          } else if (action == 'detail') {
                            Navigator.pop(ctx);
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CommunityMealPlanDetailScreen(plan: plan),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'load',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.download_rounded,
                                  color: isPro ? null : Theme.of(context).disabledColor),
                              title: Text('In Plan laden',
                                  style: TextStyle(
                                      color: isPro ? null : Theme.of(context).disabledColor)),
                              trailing: isPro ? null : const Icon(Icons.lock_outline, size: 14),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'detail',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.open_in_new_rounded),
                              title: Text('Details öffnen'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (plan.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Wrap(
                          spacing: 4,
                          children: plan.tags.take(4).map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('#$t',
                                style: theme.textTheme.labelSmall),
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}



