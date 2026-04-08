import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/core/constants/food_categories.dart';
import 'package:kokomi/core/data/ingredient_catalog.dart';
import 'package:kokomi/core/services/expiry_date_ocr_service.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/household/presentation/household_provider.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/models/inventory_item.dart';

class AddInventoryItemSheet extends ConsumerStatefulWidget {
  final InventoryItem? existingItem;
  const AddInventoryItemSheet({super.key, this.existingItem});

  @override
  ConsumerState<AddInventoryItemSheet> createState() =>
      _AddInventoryItemSheetState();
}

class _AddInventoryItemSheetState
    extends ConsumerState<AddInventoryItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _thresholdController;
  FoodCategory? _selectedCategory;
  DateTime? _expiryDate;
  bool _isLoading = false;
  bool _isHousehold = false;
  bool _defaultApplied = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.ingredientName ?? '');
    _quantityController =
        TextEditingController(text: item?.quantity?.toString() ?? '');
    _unitController = TextEditingController(text: item?.unit ?? '');
    _thresholdController = TextEditingController(
        text: item != null && item.minThreshold > 0
            ? item.minThreshold.toString()
            : '');
    _selectedCategory = FoodCategory.fromLabel(item?.ingredientCategory);
    _expiryDate = item?.expiryDate;
    if (item != null) {
      _isHousehold = item.isHousehold;
      _defaultApplied = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultApplied && widget.existingItem == null) {
      final household = ref.read(householdProvider).valueOrNull;
      if (household != null) _isHousehold = true;
      _defaultApplied = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _expiryDate = date);
  }

  bool _scanningExpiry = false;

  Future<void> _scanExpiryDate() async {
    setState(() => _scanningExpiry = true);
    try {
      final date = await ExpiryDateOcrService.scanExpiryDate();
      if (!mounted) return;
      if (date != null) {
        setState(() => _expiryDate = date);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📅 Datum erkannt: ${date.day}.${date.month}.${date.year}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kein Datum erkannt – bitte manuell eingeben'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Scannen: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _scanningExpiry = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final userId = ref.read(currentUserProvider)?.id ?? '';
    final householdId = _isHousehold
        ? ref.read(householdProvider).valueOrNull?.id
        : null;
    final item = InventoryItem(
      id: widget.existingItem?.id ?? '',
      userId: userId,
      ingredientId: widget.existingItem?.ingredientId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      ingredientName: _nameController.text.trim(),
      ingredientCategory: _selectedCategory?.label,
      quantity: double.tryParse(_quantityController.text),
      unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      expiryDate: _expiryDate,
      minThreshold: double.tryParse(_thresholdController.text) ?? 0,
      barcode: widget.existingItem?.barcode,
      tags: widget.existingItem?.tags ?? [],
      householdId: householdId,
      createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
    );

    if (widget.existingItem != null) {
      await ref.read(inventoryProvider.notifier).updateItem(item);
    } else {
      await ref.read(inventoryProvider.notifier).addItem(item);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existingItem == null ? 'Zutat hinzufügen' : 'Zutat bearbeiten',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // ── Haushalt / Privat Toggle ──
              Builder(builder: (context) {
                final household = ref.watch(householdProvider).valueOrNull;
                if (household == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Haushalt'), icon: Icon(Icons.home_outlined, size: 16)),
                      ButtonSegment(value: false, label: Text('Privat'), icon: Icon(Icons.person_outline, size: 16)),
                    ],
                    selected: {_isHousehold},
                    onSelectionChanged: (s) => setState(() => _isHousehold = s.first),
                    style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                );
              }),
              // ── Name mit Autocomplete ──
              _IngredientAutocomplete(
                controller: _nameController,
                onSelected: (entry) {
                  setState(() {
                    final cat = FoodCategory.fromLabel(entry.category);
                    if (cat != null) _selectedCategory = cat;
                    if (_unitController.text.isEmpty && entry.defaultUnit != null) {
                      _unitController.text = entry.defaultUnit!;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Menge',
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Einheit',
                        hintText: 'g, ml, Stück...',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kategorie',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: FoodCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return FilterChip(
                    avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                    label: Text(cat.label),
                    selected: isSelected,
                    selectedColor: cat.color,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12),
                    onSelected: (selected) => setState(() => _selectedCategory = selected ? cat : null),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mindestbestand (optional)',
                  prefixIcon: Icon(Icons.low_priority),
                  hintText: 'Bei Unterschreitung → Einkaufsliste',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _expiryDate == null
                            ? 'Ablaufdatum wählen'
                            : '${_expiryDate!.day}.${_expiryDate!.month}.${_expiryDate!.year}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Datum per Kamera scannen',
                    child: OutlinedButton(
                      onPressed: _scanningExpiry ? null : _scanExpiryDate,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                      child: _scanningExpiry
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.camera_alt_outlined, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.existingItem == null ? 'Hinzufügen' : 'Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Autocomplete Widget für Zutaten-Katalog ──────────────────────────────────

class _IngredientAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final void Function(IngredientEntry entry)? onSelected;

  const _IngredientAutocomplete({required this.controller, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<IngredientEntry>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text;
        if (query.trim().isEmpty) return const [];
        return IngredientCatalog.search(query, maxResults: 10);
      },
      displayStringForOption: (entry) => entry.name,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Einweg-Sync: wenn von außen ein Wert gesetzt wird
        if (textController.text != controller.text) {
          textController.text = controller.text;
        }
        textController.addListener(() {
          if (controller.text != textController.text) {
            controller.text = textController.text;
          }
        });
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Name *',
            prefixIcon: Icon(Icons.food_bank_outlined),
            hintText: 'z.B. Hähnchenbrust, Brokkoli (TK)...',
          ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
          validator: (v) => v == null || v.isEmpty ? 'Bitte Name eingeben' : null,
        );
      },
      optionsViewBuilder: (context, onAutocompleteSelected, options) {
        final theme = Theme.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 360),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.kitchen_outlined, size: 18, color: theme.colorScheme.primary),
                    title: Text(entry.name, style: theme.textTheme.bodyMedium),
                    trailing: Text(
                      entry.category,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    onTap: () {
                      onAutocompleteSelected(entry);
                      onSelected?.call(entry);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
