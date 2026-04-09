import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:kokomu/core/data/ingredient_catalog.dart';
import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/features/recipes/presentation/saved_recipes_provider.dart';
import 'package:kokomu/models/recipe.dart';

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
  String? _category;
  final _ingredients = <_IngredientEntry>[];
  final _steps = <TextEditingController>[];
  final _tags = <String>[];
  final _tagCtrl = TextEditingController();
  final _tagFocus = FocusNode();

  static const _kCategories = [
    'Frühstück', 'Mittagessen', 'Abendessen', 'Snack',
  ];

  // Bild
  String? _imageUrl;
  bool _isUploadingImage = false;

  static const _kSuggestedTags = [
    'Airfryer', 'OnePot', 'MealPrep', 'Vegan', 'Vegetarisch',
    'Glutenfrei', 'Low Carb', 'High Protein', 'Schnell', 'Backen',
    'Suppe', 'Salat', 'Frühstück', 'Dessert', 'Snack',
    'Scharf', 'Comfort Food', 'Festlich', 'Familienküche',
  ];

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
    _tagCtrl.dispose();
    _tagFocus.dispose();
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Foto entfernen',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _imageUrl = null);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await ImagePicker().pickImage(
        source: source, imageQuality: 85, maxWidth: 1200);
    if (file == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final userId =
          SupabaseService.client.auth.currentUser?.id ?? 'unknown';
      final recipeId = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'recipe_images/$userId/${recipeId}_new.$ext';

      await SupabaseService.client.storage.from('recipe-images').uploadBinary(
            path,
            bytes,
            fileOptions:
                FileOptions(upsert: true, contentType: 'image/$ext'),
          );

      final url = SupabaseService.client.storage
          .from('recipe-images')
          .getPublicUrl(path);

      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bild-Upload fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
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
      tags: List.from(_tags),
      category: _category,
      imageUrl: _imageUrl,
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
            // ── Foto ──────────────────────────────────────────────────────
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  image: _imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _isUploadingImage
                    ? const Center(child: CircularProgressIndicator())
                    : _imageUrl == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Foto hinzufügen (optional)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.5),
                                child: const Icon(Icons.edit,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Titel ─────────────────────────────────────────────────────
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
            // ── Zutaten ───────────────────────────────────────────────────
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
            const SizedBox(height: 24),

            // ── Kategorie (horizontaler Slider) ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kategorie',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('optional',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _kCategories.map((cat) {
                  final sel = _category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      onSelected: (_) => setState(() => _category = sel ? null : cat),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Tags (RawAutocomplete + horizontale Chip-Zeile) ───────────
            Text('Tags',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RawAutocomplete<String>(
              textEditingController: _tagCtrl,
              focusNode: _tagFocus,
              optionsBuilder: (tv) {
                final q = tv.text.toLowerCase();
                if (q.isEmpty) {
                  return _kSuggestedTags
                      .where((t) => !_tags.contains(t))
                      .take(8);
                }
                return _kSuggestedTags
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
              fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => TextField(
                controller: ctrl,
                focusNode: focus,
                style: theme.textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Tag tippen oder auswählen…',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  prefixIcon: const Icon(Icons.label_outline_rounded, size: 18),
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
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
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _tags
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InputChip(
                              label: Text(t,
                                  style: const TextStyle(fontSize: 11)),
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
                return IngredientCatalog.searchCooking(q, maxResults: 8).map((e) => e.name);
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

// ─── Tag-Auswahl Bottom-Sheet ─────────────────────────────────────────────────

class _TagPickerSheet extends StatefulWidget {
  final List<String> selected;
  final List<String> suggestions;

  const _TagPickerSheet({
    required this.selected,
    required this.suggestions,
  });

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late final List<String> _selected;
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _addCustom() {
    final t = _customCtrl.text.trim();
    if (t.isNotEmpty && !_selected.contains(t)) {
      setState(() => _selected.add(t));
      _customCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('Tags auswählen',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen')),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text('Fertig'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Eigenen Tag eingeben
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _customCtrl,
              decoration: InputDecoration(
                hintText: 'Eigenen Tag eingeben…',
                isDense: true,
                prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_rounded, size: 20),
                  onPressed: _addCustom,
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _addCustom(),
            ),
          ),
          // Ausgewählte Tags
          if (_selected.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ausgewählt',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _selected
                    .map((t) => InputChip(
                          label: Text(t,
                              style: const TextStyle(fontSize: 12)),
                          deleteIcon:
                              const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _selected.remove(t)),
                          selected: true,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
          ],
          // Vorschläge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Vorschläge',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.suggestions
                    .where((t) => !_selected.contains(t))
                    .map((t) => ActionChip(
                          label: Text(t,
                              style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              setState(() => _selected.add(t)),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

