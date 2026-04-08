import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/community/presentation/community_meal_plan_provider.dart';
import 'package:kokomi/features/meal_plan/presentation/meal_plan_provider.dart';

/// Sheet zum Teilen des aktuellen Wochenplans in der Community.
class PublishMealPlanSheet extends ConsumerStatefulWidget {
  final List<MealPlanEntry>? entries;
  /// Wenn gesetzt, wird ein bestehender Entwurf veröffentlicht (UPDATE) statt neu erstellt
  final String? planId;
  /// Vorausgefüllter Titel (z.B. aus bestehendem Entwurf)
  final String? initialTitle;
  /// Vorausgefüllte Beschreibung
  final String? initialDescription;
  /// Vorausgefüllte Tags
  final List<String> initialTags;

  const PublishMealPlanSheet({
    super.key,
    this.entries,
    this.planId,
    this.initialTitle,
    this.initialDescription,
    this.initialTags = const [],
  });

  @override
  ConsumerState<PublishMealPlanSheet> createState() =>
      _PublishMealPlanSheetState();
}

class _PublishMealPlanSheetState extends ConsumerState<PublishMealPlanSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _tagCtrl   = TextEditingController();
  final _tagFocus  = FocusNode();
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) _titleCtrl.text = widget.initialTitle!;
    if (widget.initialDescription != null) _descCtrl.text = widget.initialDescription!;
    _selectedTags.addAll(widget.initialTags);
  }

  static const _suggestedTags = [
    'Vegetarisch', 'Vegan', 'Low Carb', 'High Protein',
    'Mediterran', 'Asiatisch', 'Meal Prep', 'Familienfreundlich',
    'Schnell', 'Abnehmen', 'Muskelaufbau', 'Glutenfrei',
    'Laktosefrei', 'Günstig', 'Saisonal', 'Klassisch',
    'Fitness', 'Backen', 'Brot', 'Sauerteig',
    'Sommer', 'Winter', 'Herbst', 'Für Kinder',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final entries = widget.entries ??
        ref.read(mealPlanProvider).valueOrNull ?? [];
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Titel ein.')),
      );
      return;
    }
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Wochenplan ist leer.')),
      );
      return;
    }

    final planId = widget.planId;
    if (planId != null) {
      // Bestehenden Entwurf veröffentlichen (UPDATE)
      await ref.read(publishMealPlanProvider.notifier).publishExisting(
            planId: planId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            entries: entries,
            tags: _selectedTags,
          );
    } else {
      // Neu erstellen (INSERT)
      await ref.read(publishMealPlanProvider.notifier).publish(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            entries: entries,
            tags: _selectedTags,
          );
    }

    if (mounted) {
      final error = ref.read(publishMealPlanProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $error')),
        );
      } else {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Wochenplan geteilt!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublishing = ref.watch(publishMealPlanProvider).isLoading;

    // Vorschau: Wochentage mit Rezepttiteln
    const dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final allEntries = widget.entries ??
        ref.watch(mealPlanProvider).valueOrNull ?? [];
    final preview = <String, List<String>>{};
    for (final entry in allEntries) {
      final day = dayNames[entry.dayIndex.clamp(0, 6)];
      preview.putIfAbsent(day, () => []);
      preview[day]!.add(entry.recipe.title);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.share_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Wochenplan teilen',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Wochenvorschau
                  if (preview.isNotEmpty) ...[
                    Text(
                      'Wochenvorschau',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: preview.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  e.key,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value.join(', '),
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Titel
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Titel *',
                      hintText: 'z.B. "Mein Sommer-Wochenplan"',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Beschreibung
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung (optional)',
                      hintText: 'Erzähl anderen was besonders ist...',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  Text(
                    'Tags',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Autocomplete
                  RawAutocomplete<String>(
                    textEditingController: _tagCtrl,
                    focusNode: _tagFocus,
                    optionsBuilder: (tv) {
                      final q = tv.text.toLowerCase();
                      if (q.isEmpty) {
                        return _suggestedTags
                            .where((t) => !_selectedTags.contains(t))
                            .take(8);
                      }
                      return _suggestedTags
                          .where((t) =>
                              !_selectedTags.contains(t) &&
                              t.toLowerCase().contains(q))
                          .take(6);
                    },
                    onSelected: (t) {
                      setState(() => _selectedTags.add(t));
                      _tagCtrl.clear();
                      _tagFocus.unfocus();
                    },
                    fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => TextField(
                      controller: ctrl,
                      focusNode: focus,
                      style: theme.textTheme.bodySmall,
                      decoration: InputDecoration(
                        labelText: 'Tags hinzufügen',
                        hintText: 'Tippen oder auswählen…',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        prefixIcon: const Icon(Icons.label_outline_rounded,
                            size: 18),
                        suffixIcon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 20),
                      ),
                      onSubmitted: (v) {
                        final tag = v.trim();
                        if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
                          setState(() => _selectedTags.add(tag));
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
                  // Aktive Tags – horizontale Scroll-Zeile
                  if (_selectedTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _selectedTags
                            .map((t) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InputChip(
                                    label: Text(t),
                                    labelStyle:
                                        const TextStyle(fontSize: 11),
                                    selected: true,
                                    onDeleted: () => setState(
                                        () => _selectedTags.remove(t)),
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
                  const SizedBox(height: 24),

                  // Hinweis
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Andere Nutzer können deinen Plan entdecken, liken und für sich übernehmen.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Abbrechen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: isPublishing ? null : _publish,
                        icon: isPublishing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share_rounded),
                        label: Text(isPublishing ? 'Wird geteilt...' : 'Jetzt teilen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

