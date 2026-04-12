import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/core/services/ingredient_search_provider.dart';
import 'package:kokomu/core/services/nutrition_service.dart';
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
    final nutritionService = ref.watch(nutritionServiceProvider);
    final theme = Theme.of(context);

    // Nährwert-Status der ausgewählten Zutaten
    final missingNutrition = _selected.isNotEmpty
        ? nutritionService.getMissingNutrition(_selected.toList())
        : <String>[];

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
              // Warnung wenn Nährwerte fehlen
              if (missingNutrition.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${missingNutrition.length} Zutat(en) ohne Nährwerte: '
                          '${missingNutrition.take(3).join(", ")}'
                          '${missingNutrition.length > 3 ? " ..." : ""}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                    final nutrition =
                        nutritionService.getNutrition(item.ingredientName);
                    final hasNutrition = nutrition != null;

                    return CheckboxListTile(
                      value: isSelected,
                      title: Row(
                        children: [
                          Expanded(child: Text(item.ingredientName)),
                          // Nährwert-Indikator
                          _NutritionBadge(
                            hasNutrition: hasNutrition,
                            source: nutrition?.source,
                          ),
                        ],
                      ),
                      subtitle: _buildSubtitle(
                        item.ingredientCategory,
                        nutrition,
                        theme,
                      ),
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

  Widget? _buildSubtitle(
    String? category,
    NutritionInfo? nutrition,
    ThemeData theme,
  ) {
    if (category == null && nutrition == null) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category != null)
          Text(category, style: theme.textTheme.bodySmall),
        if (nutrition != null)
          Text(
            '${nutrition.kcalPer100g.round()} kcal · '
            '${nutrition.proteinPer100g.toStringAsFixed(1)}g P · '
            '${nutrition.fatPer100g.toStringAsFixed(1)}g F · '
            '${nutrition.carbsPer100g.toStringAsFixed(1)}g K',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}

/// Badge das den Nährwert-Status einer Zutat anzeigt.
class _NutritionBadge extends StatelessWidget {
  final bool hasNutrition;
  final NutritionSource? source;

  const _NutritionBadge({required this.hasNutrition, this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!hasNutrition) {
      return Tooltip(
        message: 'Keine Nährwerte verfügbar',
        child: Icon(
          Icons.error_outline,
          size: 16,
          color: theme.colorScheme.error.withValues(alpha: 0.7),
        ),
      );
    }

    final (icon, tooltip, color) = switch (source) {
      NutritionSource.scanned => (
          Icons.qr_code_scanner,
          'Nährwerte gescannt (OpenFoodFacts)',
          Colors.green,
        ),
      NutritionSource.catalog => (
          Icons.menu_book,
          'Nährwerte aus Katalog',
          theme.colorScheme.primary,
        ),
      NutritionSource.manual => (
          Icons.edit,
          'Nährwerte manuell eingegeben',
          Colors.orange,
        ),
      NutritionSource.estimated => (
          Icons.auto_fix_high,
          'Nährwerte geschätzt (Durchschnitt)',
          Colors.amber,
        ),
      _ => (
          Icons.check_circle_outline,
          'Nährwerte vorhanden',
          theme.colorScheme.primary,
        ),
    };

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
    );
  }
}
