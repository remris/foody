import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/nutrition/presentation/nutrition_provider.dart';

/// Bottom Sheet zum Einrichten des Ernährungsprofils.
class NutritionProfileSheet extends ConsumerStatefulWidget {
  const NutritionProfileSheet({super.key});

  @override
  ConsumerState<NutritionProfileSheet> createState() =>
      _NutritionProfileSheetState();
}

class _NutritionProfileSheetState
    extends ConsumerState<NutritionProfileSheet> {
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _calorieController = TextEditingController();

  Gender _gender = Gender.male;
  NutritionGoal _goal = NutritionGoal.maintain;
  bool _customCalories = false;
  NutritionProfile? _preview;

  @override
  void initState() {
    super.initState();
    // Vorhandene Daten laden
    final existing = ref.read(nutritionProfileProvider);
    if (existing != null) {
      _ageController.text = existing.age.toString();
      _weightController.text = existing.weightKg.toStringAsFixed(0);
      _heightController.text = existing.heightCm.toStringAsFixed(0);
      _gender = existing.gender;
      _goal = existing.goal;
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  void _calculate() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age == null || weight == null || height == null) return;

    final customCal = _customCalories
        ? int.tryParse(_calorieController.text)
        : null;

    setState(() {
      _preview = NutritionProfile.calculate(
        age: age,
        gender: _gender,
        weightKg: weight,
        heightCm: height,
        goal: _goal,
        customCalorieGoal: customCal,
      );
    });
  }

  void _save() {
    if (_preview == null) _calculate();
    if (_preview == null) return;

    ref.read(nutritionProfileProvider.notifier).saveProfile(_preview!);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ernährungsprofil gespeichert ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Ernährungsprofil',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Dein persönliches Tagesziel wird automatisch berechnet.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Geschlecht
            Text('Geschlecht', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Gender>(
                segments: const [
                  ButtonSegment(
                      value: Gender.male,
                      label: Text('Männlich'),
                      icon: Icon(Icons.male, size: 18)),
                  ButtonSegment(
                      value: Gender.female,
                      label: Text('Weiblich'),
                      icon: Icon(Icons.female, size: 18)),
                  ButtonSegment(
                      value: Gender.other,
                      label: Text('Divers'),
                      icon: Icon(Icons.transgender, size: 18)),
                ],
                selected: {_gender},
                onSelectionChanged: (s) {
                  setState(() => _gender = s.first);
                  _calculate();
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Alter, Gewicht, Größe
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Alter',
                      suffixText: 'J.',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Gewicht',
                      suffixText: 'kg',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Größe',
                      suffixText: 'cm',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ziel
            Text('Ziel', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<NutritionGoal>(
                segments: const [
                  ButtonSegment(
                      value: NutritionGoal.lose,
                      label: Text('Abnehmen'),
                      icon: Icon(Icons.trending_down, size: 16)),
                  ButtonSegment(
                      value: NutritionGoal.maintain,
                      label: Text('Halten'),
                      icon: Icon(Icons.balance, size: 16)),
                  ButtonSegment(
                      value: NutritionGoal.gain,
                      label: Text('Aufbauen'),
                      icon: Icon(Icons.trending_up, size: 16)),
                ],
                selected: {_goal},
                onSelectionChanged: (s) {
                  setState(() => _goal = s.first);
                  _calculate();
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kalorienziel manuell überschreiben
            SwitchListTile(
              value: _customCalories,
              onChanged: (v) => setState(() => _customCalories = v),
              title: const Text('Kalorienziel manuell festlegen'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (_customCalories) ...[
              TextField(
                controller: _calorieController,
                decoration: const InputDecoration(
                  labelText: 'Tägliches Kalorienziel',
                  suffixText: 'kcal',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 8),
            ],

            // Vorschau
            if (_preview != null) ...[
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate_outlined,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Berechnetes Tagesziel',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _PreviewRow(
                          icon: Icons.local_fire_department,
                          label: 'Kalorien',
                          value: '${_preview!.calorieGoal} kcal'),
                      _PreviewRow(
                          icon: Icons.fitness_center,
                          label: 'Protein',
                          value: '${_preview!.proteinGoalG.toStringAsFixed(0)} g'),
                      _PreviewRow(
                          icon: Icons.grain,
                          label: 'Kohlenhydrate',
                          value: '${_preview!.carbsGoalG.toStringAsFixed(0)} g'),
                      _PreviewRow(
                          icon: Icons.opacity,
                          label: 'Fett',
                          value: '${_preview!.fatGoalG.toStringAsFixed(0)} g'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'BMI: ${_preview!.bmi.toStringAsFixed(1)} (${_preview!.bmiCategory})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _preview != null ? _save : null,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PreviewRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

