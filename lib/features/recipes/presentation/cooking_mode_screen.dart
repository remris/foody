import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:kokomi/features/recipes/presentation/cooked_recipes_provider.dart';
import 'package:kokomi/features/recipes/presentation/cooking_streak_provider.dart';
import 'package:kokomi/features/nutrition/presentation/nutrition_provider.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/models/recipe.dart';

/// Vollbild Schritt-für-Schritt Kochmodus.
/// Bildschirm bleibt an, Wisch-Navigation zwischen Schritten.
class CookingModeScreen extends ConsumerStatefulWidget {
  final FoodRecipe recipe;
  const CookingModeScreen({super.key, required this.recipe});

  @override
  ConsumerState<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends ConsumerState<CookingModeScreen> {
  // Timer
  Timer? _timer;
  int _timerSeconds = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    setState(() {
      _timerSeconds = minutes * 60;
      _timerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerSeconds <= 0) {
        _timer?.cancel();
        setState(() => _timerRunning = false);
        HapticFeedback.heavyImpact();
        _showTimerDoneDialog();
        return;
      }
      setState(() => _timerSeconds--);
    });
  }

  void _toggleTimer() {
    if (_timerRunning) {
      _timer?.cancel();
      setState(() => _timerRunning = false);
    } else if (_timerSeconds > 0) {
      setState(() => _timerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_timerSeconds <= 0) {
          _timer?.cancel();
          setState(() => _timerRunning = false);
          HapticFeedback.heavyImpact();
          _showTimerDoneDialog();
          return;
        }
        setState(() => _timerSeconds--);
      });
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 0;
      _timerRunning = false;
    });
  }

  void _showTimerDoneDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.timer_off_rounded, size: 48, color: Colors.green),
        title: const Text('⏰ Timer abgelaufen!'),
        content: const Text('Dein Koch-Timer ist fertig.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTimerPicker() {
    final presets = [1, 3, 5, 10, 15, 20, 30, 45, 60];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⏱ Timer stellen',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((m) {
                  return ActionChip(
                    label: Text('$m Min.'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startTimer(m);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Timer-Anzeige / Button
          if (_timerSeconds > 0)
            GestureDetector(
              onTap: _toggleTimer,
              onLongPress: _cancelTimer,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _timerRunning
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _timerRunning ? Icons.pause : Icons.play_arrow,
                      size: 16,
                      color: _timerRunning
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimer(_timerSeconds),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: [const FontFeature.tabularFigures()],
                        color: _timerRunning
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.timer_outlined),
              tooltip: 'Timer stellen',
              onPressed: _showTimerPicker,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // ── Info-Chips ──
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.timer_outlined, size: 16),
                label: Text('${recipe.cookingTimeMinutes} Min.'),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                avatar: const Icon(Icons.people_outline, size: 16),
                label: Text('${recipe.servings} Portionen'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Zutaten ──
          _SectionHeader(
            icon: Icons.restaurant_menu_rounded,
            iconColor: theme.colorScheme.primary,
            title: 'Zutaten',
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: recipe.ingredients.map((ing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      children: [
                        Icon(Icons.fiber_manual_record,
                            size: 8, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ing.name,
                              style: theme.textTheme.bodyMedium),
                        ),
                        Text(
                          ing.amount,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Zubereitung ──
          _SectionHeader(
            icon: Icons.format_list_numbered_rounded,
            iconColor: theme.colorScheme.secondary,
            title: 'Zubereitung',
          ),
          const SizedBox(height: 8),
          ...recipe.steps.asMap().entries.map((e) {
            final stepNum = e.key + 1;
            final stepText = e.value;
            return _StepCard(
              stepNumber: stepNum,
              totalSteps: recipe.steps.length,
              stepText: stepText,
              theme: theme,
              onTimerTap: _showTimerPicker,
            );
          }),
        ],
      ),
      // ── Fertig-Button unten ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () async {
              HapticFeedback.heavyImpact();
              ref.read(cookedRecipesProvider.notifier).markAsCooked(
                widget.recipe.id,
                widget.recipe.title,
              );
              if (widget.recipe.nutrition != null) {
                ref.read(dailyNutritionProvider.notifier).logMeal(widget.recipe, 1.0);
              }
              ref.read(cookingStreakProvider.notifier).recordCooking();
              final streak = ref.read(cookingStreakProvider);
              if (context.mounted) {
                await _showDeductIngredientsDialog(context, ref, widget.recipe);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.recipe.nutrition != null
                          ? 'Guten Appetit! 🍽️ (${widget.recipe.nutrition!.calories} kcal)${streak.currentStreak > 1 ? ' ${streak.streakEmoji} ${streak.currentStreak} Tage Streak!' : ''}'
                          : 'Guten Appetit! 🍽️${streak.currentStreak > 1 ? ' ${streak.streakEmoji} ${streak.currentStreak} Tage Streak!' : ''}',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Fertig gekocht! 🎉'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 52),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abschnitts-Header mit Icon und Titel
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  const _SectionHeader({required this.icon, required this.iconColor, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Eine Kochschritt-Karte in der Scroll-Liste
class _StepCard extends StatefulWidget {
  final int stepNumber;
  final int totalSteps;
  final String stepText;
  final ThemeData theme;
  final VoidCallback onTimerTap;

  const _StepCard({
    required this.stepNumber,
    required this.totalSteps,
    required this.stepText,
    required this.theme,
    required this.onTimerTap,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isLast = widget.stepNumber == widget.totalSteps;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schritt-Nummer + Verbindungslinie
          Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _done = !_done),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _done
                        ? Colors.green
                        : theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _done
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : Text(
                            '${widget.stepNumber}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Inhalt
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: theme.textTheme.bodyLarge!.copyWith(
                      height: 1.5,
                      color: _done
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : theme.colorScheme.onSurface,
                      decoration: _done ? TextDecoration.lineThrough : null,
                    ),
                    child: Text(widget.stepText),
                  ),
                  const SizedBox(height: 6),
                  // Timer-Shortcut
                  GestureDetector(
                    onTap: widget.onTimerTap,
                    child: Text(
                      '⏱ Timer stellen',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog zum Abziehen von Zutaten vom Vorrat nach dem Kochen.
Future<void> _showDeductIngredientsDialog(
  BuildContext context,
  WidgetRef ref,
  FoodRecipe recipe,
) async {
  final inventory = ref.read(inventoryProvider).valueOrNull ?? [];
  if (inventory.isEmpty) return;

  // Zutaten matchen mit Vorrat
  final matched = <int, bool>{};
  for (var i = 0; i < recipe.ingredients.length; i++) {
    final ingName = recipe.ingredients[i].name.toLowerCase();
    final inStock = inventory.any(
      (item) => item.ingredientName.toLowerCase().contains(ingName) ||
          ingName.contains(item.ingredientName.toLowerCase()),
    );
    matched[i] = inStock;
  }

  // Wenn nichts im Vorrat → kein Dialog
  if (!matched.values.any((v) => v)) return;

  final selected = Map<int, bool>.from(matched);

  final result = await showDialog<Map<int, bool>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Zutaten vom Vorrat abziehen?'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Markiere die Zutaten, die du verbraucht hast:',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ...List.generate(recipe.ingredients.length, (i) {
                final ing = recipe.ingredients[i];
                final inStock = matched[i] ?? false;
                return CheckboxListTile(
                  value: selected[i] ?? false,
                  onChanged: inStock
                      ? (val) => setDialogState(() => selected[i] = val ?? false)
                      : null,
                  title: Text(
                    ing.name,
                    style: TextStyle(
                      color: inStock ? null : Theme.of(ctx).colorScheme.outlineVariant,
                    ),
                  ),
                  subtitle: Text(
                    inStock ? ing.amount : 'Nicht im Vorrat',
                    style: TextStyle(
                      fontSize: 12,
                      color: inStock
                          ? Theme.of(ctx).colorScheme.onSurfaceVariant
                          : Theme.of(ctx).colorScheme.outlineVariant,
                    ),
                  ),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Überspringen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, selected),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const Text('Abziehen'),
          ),
        ],
      ),
    ),
  );

  if (result == null) return;

  // Ausgewählte Zutaten vom Vorrat entfernen
  int removed = 0;
  for (final entry in result.entries) {
    if (!entry.value) continue;
    final ingName = recipe.ingredients[entry.key].name.toLowerCase();
    final match = inventory.where(
      (item) => item.ingredientName.toLowerCase().contains(ingName) ||
          ingName.contains(item.ingredientName.toLowerCase()),
    );
    for (final item in match) {
      await ref.read(inventoryProvider.notifier).deleteItem(item.id);
      removed++;
    }
  }

  if (removed > 0 && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$removed Zutat(en) vom Vorrat entfernt 🗑️')),
    );
  }
}
