import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/meal_plan/presentation/meal_plan_provider.dart';
import 'package:kokomu/models/recipe.dart';

/// Zeigt ein BottomSheet zum Hinzufügen eines Rezepts zum Wochenplan.
/// Tag-Auswahl als Chips, darunter Slot-Auswahl als Chips.
/// Bei Auswahl beider → sofort speichern + Sheet schließen + SnackBar.
Future<void> showMealPlanPickerSheet(
  BuildContext context,
  WidgetRef ref,
  FoodRecipe recipe,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _MealPlanPickerSheet(recipe: recipe, ref: ref),
  );
}

class _MealPlanPickerSheet extends StatefulWidget {
  final FoodRecipe recipe;
  final WidgetRef ref;
  const _MealPlanPickerSheet({required this.recipe, required this.ref});

  @override
  State<_MealPlanPickerSheet> createState() => _MealPlanPickerSheetState();
}

class _MealPlanPickerSheetState extends State<_MealPlanPickerSheet> {
  int? _selectedDay;
  MealSlot? _selectedSlot;
  bool _saving = false;

  static const _dayNames = [
    'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
    'Freitag', 'Samstag', 'Sonntag',
  ];
  static const _dayShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  Future<void> _save() async {
    if (_selectedDay == null || _selectedSlot == null) return;
    setState(() => _saving = true);
    await widget.ref
        .read(mealPlanProvider.notifier)
        .setMeal(_selectedDay!, _selectedSlot!, widget.recipe);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
    // SnackBar im Parent-Context
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(
      content: Text(
        '${widget.recipe.title} → '
        '${_dayShort[_selectedDay!]} ${_selectedSlot!.label} ✅',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSave = _selectedDay != null && _selectedSlot != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Titel
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Zum Wochenplan hinzufügen',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.recipe.title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Tag-Auswahl
          Text('Tag', style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(7, (i) {
              final isSelected = _selectedDay == i;
              return ChoiceChip(
                label: Text(_dayNames[i]),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedDay = i),
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : null,
                ),
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
          const SizedBox(height: 20),

          // Mahlzeit-Auswahl
          Text('Mahlzeit', style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: MealSlot.values.map((slot) {
              final isSelected = _selectedSlot == slot;
              return ChoiceChip(
                avatar: Text(slot.emoji,
                    style: const TextStyle(fontSize: 14)),
                label: Text(slot.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedSlot = slot),
                selectedColor: theme.colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onSecondaryContainer
                      : null,
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Hinzufügen-Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canSave && !_saving ? _save : null,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white))
                  : const Icon(Icons.add_rounded),
              label: Text(canSave
                  ? 'Zu ${_dayNames[_selectedDay!]} – ${_selectedSlot!.label} hinzufügen'
                  : 'Tag & Mahlzeit auswählen'),
            ),
          ),
        ],
      ),
    );
  }
}

