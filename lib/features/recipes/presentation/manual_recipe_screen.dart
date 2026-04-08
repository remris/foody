import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/core/data/ingredient_catalog.dart';
import 'package:kokomi/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomi/models/recipe.dart';

// Alle verfügbaren Einheiten â€“ sortiert nach HÃ¤ufigkeit
const _kUnits = [
  // Gewicht
  'g', 'kg',
  // Volumen
  'ml', 'L', 'cl',
  // KüchenmaÃŸe
  'EL', 'TL', 'Tasse', 'Schuss', 'Prise',
  // Stück
  'Stück', 'Scheibe', 'Scheiben', 'Zehe', 'Zehen',
  'Blatt', 'Blätter', 'Bund', 'Zweig', 'Zweige',
  'Dose', 'Glas', 'Packung', 'Pkg.',
  // ohne Einheit
  'nach Geschmack',
];

/// Screen zum manuellen Erstellen eines eigenen Rezepts (ohne KI).
class ManualRecipeScreen extends ConsumerStatefulWidget {
  const ManualRecipeScreen({super.key});

  @override
  ConsumerState<ManualRecipeScreen> createState() => _ManualRecipeScreenState();
}

class _ManualRecipeScreenState extends ConsumerState<ManualRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController(text: '30');
  final _servingsController = TextEditingController(text: '2');
  String _difficulty = 'Einfach';
  final _ingredients = <_IngredientEntry>[];
  final _steps = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _addIngredient();
    _addStep();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    _servingsController.dispose();
    for (final i in _ingredients) {
      i.amountController.dispose();
    }
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(_IngredientEntry(
        nameController: TextEditingController(),
        amountController: TextEditingController(),
        unit: 'g',
      ));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].amountController.dispose();
      _ingredients.removeAt(index);
    });
  }

  void _addStep() {
    setState(() => _steps.add(TextEditingController()));
  }

  void _removeStep(int index) {
    setState(() {
      _steps[index].dispose();
      _steps.removeAt(index);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty || _steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens 1 Zutat und 1 Schritt nÃ¶tig.')),
      );
      return;
    }

    final ingredients = _ingredients
        .where((i) => i.nameController.text.trim().isNotEmpty)
        .map((i) {
          final qty = i.amountController.text.trim();
          final unit = i.unit;
          // "nach Geschmack" braucht keine Zahl davor
          final amount = unit == 'nach Geschmack'
              ? 'nach Geschmack'
              : qty.isEmpty
                  ? unit
                  : '$qty $unit';
          return RecipeIngredient(
            name: i.nameController.text.trim(),
            amount: amount,
          );
        })
        .toList();

    final steps = _steps
        .where((s) => s.text.trim().isNotEmpty)
        .map((s) => s.text.trim())
        .toList();

    if (ingredients.isEmpty || steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte fülle alle Felder aus.')),
      );
      return;
    }

    final recipe = FoodRecipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : 'Eigenes Rezept',
      cookingTimeMinutes: int.tryParse(_timeController.text.trim()) ?? 30,
      difficulty: _difficulty,
      servings: int.tryParse(_servingsController.text.trim()) ?? 2,
      ingredients: ingredients,
      steps: steps,
    );

    ref.read(savedRecipesProvider.notifier).saveRecipe(recipe, source: 'own');

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('â€ž${recipe.title}" gespeichert âœ…')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eigenes Rezept'),
        actions: [
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Speichern'),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titel
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel *',
                hintText: 'z.B. Omas Kartoffelsuppe',
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Titel erforderlich' : null,
            ),
            const SizedBox(height: 12),

            // Beschreibung
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                hintText: 'Kurze Beschreibung...',
                prefixIcon: Icon(Icons.description),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Kochzeit, Portionen, Schwierigkeit
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Kochzeit (Min.)',
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Portionen',
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Schwierigkeit',
                prefixIcon: Icon(Icons.speed),
              ),
              items: ['Einfach', 'Mittel', 'Fortgeschritten']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _difficulty = v ?? 'Einfach'),
            ),
            const SizedBox(height: 24),

            // â”€â”€ Zutaten â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Zutaten',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                FilledButton.tonalIcon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Zutat'),
                  style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Spalten-Header
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 2),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: Text('Zutat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                  const SizedBox(width: 8),
                  const SizedBox(width: 84, child: Text('Menge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                  const SizedBox(width: 8),
                  const SizedBox(width: 88, child: Text('Einheit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            ...List.generate(_ingredients.length, (i) {
              final entry = _ingredients[i];
              return _IngredientRow(
                key: ValueKey(entry),
                entry: entry,
                index: i,
                showRemove: _ingredients.length > 1,
                onRemove: () => _removeIngredient(i),
                onUnitChanged: (unit) => setState(() => entry.unit = unit),
                onNameSelected: (name) {
                  // Einheit aus Katalog vorschlagen
                  final match = IngredientCatalog.all
                      .where((e) => e.name.toLowerCase() == name.toLowerCase())
                      .firstOrNull;
                  if (match?.defaultUnit != null) {
                    setState(() => entry.unit = match!.defaultUnit!);
                  }
                },
              );
            }),
            const SizedBox(height: 24),

            // â”€â”€ Zubereitung â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Zubereitung',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                FilledButton.tonalIcon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Schritt'),
                  style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_steps.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text('${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _steps[i],
                        decoration: InputDecoration(hintText: 'Schritt ${i + 1}'),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    if (_steps.length > 1)
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            size: 18, color: theme.colorScheme.error),
                        onPressed: () => _removeStep(i),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Zutat-Zeile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _IngredientRow extends StatefulWidget {
  const _IngredientRow({
    super.key,
    required this.entry,
    required this.index,
    required this.showRemove,
    required this.onRemove,
    required this.onUnitChanged,
    required this.onNameSelected,
  });

  final _IngredientEntry entry;
  final int index;
  final bool showRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<String> onNameSelected;

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.entry.unit;
  }

  @override
  void didUpdateWidget(_IngredientRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.unit != _selectedUnit) {
      setState(() => _selectedUnit = widget.entry.unit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // â”€â”€ Name (Autocomplete) â”€â”€
          Expanded(
            flex: 3,
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: widget.entry.nameController.text),
              optionsBuilder: (tv) {
                final q = tv.text.trim();
                if (q.length < 2) return [];
                return IngredientCatalog.search(q, maxResults: 8).map((e) => e.name);
              },
              fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                widget.entry.nameController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Zutat ${widget.index + 1}',
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onEditingComplete: onSubmitted,
                );
              },
              onSelected: (s) {
                widget.entry.nameController.text = s;
                widget.onNameSelected(s);
              },
              optionsViewBuilder: (ctx, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 240),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (_, idx) {
                        final opt = options.elementAt(idx);
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.local_grocery_store_outlined,
                              size: 16, color: theme.colorScheme.primary),
                          title: Text(opt, style: const TextStyle(fontSize: 13)),
                          onTap: () => onSelected(opt),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Menge (nur Zahl)
          SizedBox(
            width: 84,
            child: TextField(
              controller: widget.entry.amountController,
              decoration: const InputDecoration(
                hintText: '100',
                isDense: true,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              maxLength: 6,
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(width: 8),

          // â”€â”€ Einheit (Dropdown) â”€â”€
          SizedBox(
            width: 90,
            child: _UnitDropdown(
              value: _selectedUnit,
              onChanged: (unit) {
                setState(() => _selectedUnit = unit);
                widget.onUnitChanged(unit);
              },
            ),
          ),

          // â”€â”€ Entfernen â”€â”€
          if (widget.showRemove)
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  size: 18, color: theme.colorScheme.error),
              onPressed: widget.onRemove,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            )
          else
            const SizedBox(width: 32),
        ],
      ),
    );
  }
}

// â”€â”€ Einheit-Dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sicherstellen dass der aktuelle Wert in der Liste ist
    final units = _kUnits.contains(value) ? _kUnits : [value, ..._kUnits];

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: theme.textTheme.bodyMedium,
          items: units.map((u) => DropdownMenuItem(
            value: u,
            child: Text(u, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

// â”€â”€ Datenmodell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _IngredientEntry {
  TextEditingController nameController;
  final TextEditingController amountController;
  String unit;

  _IngredientEntry({
    required this.nameController,
    required this.amountController,
    this.unit = 'g',
  });
}
