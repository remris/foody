import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/inventory/presentation/inventory_provider.dart';

/// BottomSheet zur Auswahl von Zutaten aus dem Inventar für die Rezeptgenerierung.
class IngredientSelectionSheet extends ConsumerStatefulWidget {
  const IngredientSelectionSheet({super.key});

  @override
  ConsumerState<IngredientSelectionSheet> createState() =>
      _IngredientSelectionSheetState();
}

class _IngredientSelectionSheetState
    extends ConsumerState<IngredientSelectionSheet> {
  final Set<String> _selected = {};
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryProvider).valueOrNull ?? [];
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Zutaten auswählen',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selected.length} von ${items.length} ausgewählt',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // Alle / Keine Buttons
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selected.addAll(
                          items.map((e) => e.ingredientName));
                    }),
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text('Alle'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _selected.clear()),
                    icon: const Icon(Icons.deselect, size: 18),
                    label: const Text('Keine'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Zutatenliste
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected =
                        _selected.contains(item.ingredientName);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(item.ingredientName),
                      subtitle: item.ingredientCategory != null
                          ? Text(item.ingredientCategory!,
                              style: theme.textTheme.bodySmall)
                          : null,
                      secondary: item.ingredientImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.ingredientImageUrl!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.fastfood, size: 24),
                              ),
                            )
                          : null,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selected.add(item.ingredientName);
                          } else {
                            _selected.remove(item.ingredientName);
                          }
                        });
                      },
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Zusätzlicher Wunsch
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  hintText: 'Zusätzlicher Wunsch (optional)...',
                  prefixIcon: Icon(Icons.auto_awesome),
                ),
              ),
              const SizedBox(height: 12),
              // Generieren Button
              FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop({
                          'ingredients': _selected.toList(),
                          'prompt': _promptController.text.trim(),
                        });
                      },
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  'Rezepte generieren (${_selected.length} Zutaten)',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

