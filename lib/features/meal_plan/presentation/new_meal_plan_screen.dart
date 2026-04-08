import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/community/data/community_meal_plan_repository.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomi/features/community/presentation/publish_meal_plan_sheet.dart';
import 'package:kokomi/features/meal_plan/presentation/meal_plan_provider.dart';
import 'package:kokomi/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomi/models/recipe.dart';

import 'package:kokomi/models/community_meal_plan.dart';

// ── Lokaler State-Provider für den neuen Plan ─────────────────────────────

final _newPlanEntriesProvider =
    StateNotifierProvider.autoDispose<_NewPlanNotifier, List<MealPlanEntry>>(
  (_) => _NewPlanNotifier(),
);

class _NewPlanNotifier extends StateNotifier<List<MealPlanEntry>> {
  _NewPlanNotifier() : super([]);

  void setMeal(int dayIndex, MealSlot slot, FoodRecipe recipe) {
    final entries = state.toList();
    entries.removeWhere((e) => e.dayIndex == dayIndex && e.slot == slot);
    entries.add(MealPlanEntry(
      id: '${dayIndex}_${slot.name}',
      dayIndex: dayIndex,
      slot: slot,
      recipe: recipe,
    ));
    state = entries;
  }

  void removeMeal(int dayIndex, MealSlot slot) {
    state = state
        .where((e) => !(e.dayIndex == dayIndex && e.slot == slot))
        .toList();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────

class NewMealPlanScreen extends ConsumerStatefulWidget {
  /// Wenn gesetzt → Edit-Modus: bestehenden Plan bearbeiten
  final CommunityMealPlan? plan;
  const NewMealPlanScreen({super.key, this.plan});

  @override
  ConsumerState<NewMealPlanScreen> createState() => _NewMealPlanScreenState();
}

class _NewMealPlanScreenState extends ConsumerState<NewMealPlanScreen> {
  int _selectedDay = DateTime.now().weekday - 1;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final _tagCtrl  = TextEditingController(text: '');
  final _tagFocus = FocusNode();
  final List<String> _tags = [];

  bool get _isEditMode => widget.plan != null;

  // Vorschlag-Tags zum Antippen
  static const _suggestedTags = [
    'Vegan', 'Vegetarisch', 'Glutenfrei', 'Laktosefrei',
    'Low Carb', 'High Protein', 'Meal Prep', 'Günstig',
    'Familie', 'Für Kinder', 'Mediterran', 'Asiatisch',
    'Fitness', 'Backen', 'Brot', 'Sauerteig',
    'Schnell', 'Sommer', 'Winter', 'Herbst',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final p = widget.plan!;
      _nameCtrl = TextEditingController(text: p.title);
      _descCtrl = TextEditingController(text: p.description);
      _tags.addAll(p.tags);
      // Einträge in den Provider laden
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final entry in p.entries) {
          ref.read(_newPlanEntriesProvider.notifier)
              .setMeal(entry.dayIndex, entry.slot, entry.recipe);
        }
      });
    } else {
      // Vorschlag: heutige KW als Name
      final now = DateTime.now();
      final kw = _isoWeekNumber(now);
      _nameCtrl = TextEditingController(text: 'KW $kw – ${now.year}');
      _descCtrl = TextEditingController(text: '');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday <= 4
        ? startOfYear.subtract(Duration(days: startOfYear.weekday - 1))
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));
    final diff = date.difference(firstMonday).inDays;
    return (diff / 7).floor() + 1;
  }

  Future<void> _save({bool andPublish = false}) async {
    final entries = ref.read(_newPlanEntriesProvider);
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib dem Plan einen Namen.')),
      );
      return;
    }
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Plan ist noch leer.')),
      );
      return;
    }

    try {
      final repo = ref.read(communityMealPlanRepositoryProvider);
      final planJson = entries.map((e) => e.toJson()).toList();

      // ── Edit-Modus: bestehenden Plan updaten ──────────────────────
      if (_isEditMode) {
        final planId = widget.plan!.id;
        await repo.updateExistingPlan(
          planId: planId,
          title: name,
          description: description,
          planJson: planJson,
          tags: _tags,
        );
        ref.invalidate(myAllMealPlansProvider);
        ref.invalidate(myPublishedMealPlansProvider);
        if (!mounted) return;
        if (andPublish) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => PublishMealPlanSheet(
              entries: entries,
              planId: planId,
              initialTitle: name,
              initialDescription: description,
              initialTags: List<String>.from(_tags),
            ),
          );
          ref.invalidate(myAllMealPlansProvider);
          ref.invalidate(myPublishedMealPlansProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ „$name" aktualisiert!')),
          );
        }
        if (mounted) Navigator.pop(context);
        return;
      }

      // ── Neu-Modus ─────────────────────────────────────────────────
      if (andPublish) {
        final draft = await repo.savePlanAsDraft(
          title: name,
          planJson: planJson,
          description: description,
          tags: _tags,
        );
        ref.invalidate(myAllMealPlansProvider);
        if (!mounted) return;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => PublishMealPlanSheet(
            entries: entries,
            planId: draft.id,
            initialTitle: name,
            initialDescription: description,
            initialTags: List<String>.from(_tags),
          ),
        );
        ref.invalidate(myAllMealPlansProvider);
        ref.invalidate(myPublishedMealPlansProvider);
        if (mounted) Navigator.pop(context);
      } else {
        await repo.savePlanAsDraft(
          title: name,
          planJson: planJson,
          description: description,
          tags: _tags,
        );
        ref.invalidate(myAllMealPlansProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ „$name" gespeichert!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = ref.watch(_newPlanEntriesProvider);
    final totalMeals = entries.length;

    const dayShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    const dayFull = [
      'Montag', 'Dienstag', 'Mittwoch',
      'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'
    ];

    final dayEntries =
        entries.where((e) => e.dayIndex == _selectedDay).toList();
    final slots = [
      MealSlot.breakfast,
      MealSlot.lunch,
      MealSlot.dinner,
      MealSlot.snack
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Plan bearbeiten' : 'Neuer Wochenplan'),
        actions: [
          if (totalMeals > 0)
            TextButton.icon(
              onPressed: () => _save(andPublish: true),
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('Teilen'),
            ),
          FilledButton.icon(
            onPressed: totalMeals > 0 ? () => _save() : null,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Speichern'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Plan-Metadaten: Name, Beschreibung, Tags ─────────────────
          // SingleChildScrollView verhindert RenderFlex-Overflow
          SingleChildScrollView(
            child: Container(
              color: theme.colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name ──
                  TextField(
                    controller: _nameCtrl,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Planname *',
                      hintText: 'z. B. Mediterrane Sommerwoche',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      prefixIcon: const Icon(Icons.edit_calendar_outlined),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  // ── Beschreibung ──
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    minLines: 2,
                    maxLength: 200,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      labelText: 'Beschreibung (optional)',
                      hintText: 'Worum geht es in diesem Plan?',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.notes_rounded),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      counterText: '',
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 10),
                  // ── Tags als Autocomplete ──
                  RawAutocomplete<String>(
                    textEditingController: _tagCtrl,
                    focusNode: _tagFocus,
                    optionsBuilder: (tv) {
                      final q = tv.text.toLowerCase();
                      if (q.isEmpty) {
                        return _suggestedTags
                            .where((t) => !_tags.contains(t))
                            .take(8);
                      }
                      return _suggestedTags
                          .where((t) =>
                              !_tags.contains(t) &&
                              t.toLowerCase().contains(q))
                          .take(6);
                    },
                    onSelected: (t) {
                      setState(() => _tags.add(t));
                      _tagCtrl.clear();
                      _tagFocus.unfocus();
                    },
                    fieldViewBuilder: (ctx, ctrl, focus, onSubmit) =>
                        TextField(
                      controller: ctrl,
                      focusNode: focus,
                      style: theme.textTheme.bodySmall,
                      decoration: InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Tippen oder auswählen…',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        prefixIcon: const Icon(Icons.label_outline_rounded,
                            size: 18),
                        suffixIcon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 20),
                      ),
                      onSubmitted: (v) {
                        final tag = v.trim();
                        if (tag.isNotEmpty && !_tags.contains(tag)) {
                          setState(() => _tags.add(tag));
                        }
                        _tagCtrl.clear();
                      },
                    ),
                    optionsViewBuilder: (ctx, onSel, opts) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            children: opts
                                .map((t) => ListTile(
                                      dense: true,
                                      leading: Icon(Icons.add_rounded,
                                          size: 16,
                                          color: theme.colorScheme.primary),
                                      title: Text(t,
                                          style: theme.textTheme.bodySmall),
                                      onTap: () => onSel(t),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Aktive Tags (horizontal scrollbar) ──
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _tags
                            .map((t) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InputChip(
                                    label: Text(t),
                                    labelStyle:
                                        const TextStyle(fontSize: 11),
                                    selected: true,
                                    onDeleted: () =>
                                        setState(() => _tags.remove(t)),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            color: theme.colorScheme.surfaceContainerLow,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: List.generate(7, (i) {
                  final dayMeals =
                      entries.where((e) => e.dayIndex == i).length;
                  final isSelected = _selectedDay == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDay = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayShort[i],
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            if (dayMeals > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$dayMeals',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Slot-Liste für den gewählten Tag ────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // Tages-Titel
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    dayFull[_selectedDay],
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ...slots.map((slot) {
                  final entry = dayEntries
                      .where((e) => e.slot == slot)
                      .firstOrNull;
                  return _NewPlanSlotCard(
                    slot: slot,
                    entry: entry,
                    dayIndex: _selectedDay,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      // ── Fortschritts-Chip am unteren Rand ───────────────────────────
      bottomNavigationBar: totalMeals > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$totalMeals Mahlzeit${totalMeals != 1 ? 'en' : ''} geplant',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _save(),
                      child: const Text('Speichern'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ── Slot-Karte für den neuen Plan ─────────────────────────────────────────

class _NewPlanSlotCard extends ConsumerWidget {
  final MealSlot slot;
  final MealPlanEntry? entry;
  final int dayIndex;

  const _NewPlanSlotCard({
    required this.slot,
    required this.entry,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (entry == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPicker(context, ref),
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
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text('Tippe um ein Rezept zuzuweisen',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline)),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPicker(context, ref),
        onLongPress: () => _showOptions(context, ref),
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
                            fontSize: 11)),
                    Text(entry!.recipe.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600)),
                    if (entry!.recipe.nutrition?.calories != null &&
                        entry!.recipe.nutrition!.calories > 0)
                      Text('${entry!.recipe.nutrition!.calories} kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                onPressed: () {
                  ref
                      .read(_newPlanEntriesProvider.notifier)
                      .removeMeal(dayIndex, slot);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final savedAsync = ref.read(savedRecipesProvider);
    final recipes = savedAsync.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
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
                      'Rezept für ${slot.emoji} ${slot.label}',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recipes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Noch keine Rezepte gespeichert.\nSpeichere zuerst Rezepte in der Küche.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: recipes.length,
                    itemBuilder: (ctx, i) {
                      final recipe = recipes[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(Icons.restaurant,
                                size: 18,
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                          title: Text(recipe.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${recipe.cookingTimeMinutes} Min.'
                            '${recipe.nutrition != null ? ' · ${recipe.nutrition!.calories} kcal' : ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            ref
                                .read(_newPlanEntriesProvider.notifier)
                                .setMeal(dayIndex, slot, recipe);
                            HapticFeedback.lightImpact();
                          },
                        ),
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
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Rezept tauschen'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPicker(context, ref);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text('Entfernen',
                    style: TextStyle(color: theme.colorScheme.error)),
                onTap: () {
                  ref
                      .read(_newPlanEntriesProvider.notifier)
                      .removeMeal(dayIndex, slot);
                  Navigator.pop(ctx);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

