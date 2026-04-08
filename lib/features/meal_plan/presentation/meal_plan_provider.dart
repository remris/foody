import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomi/features/household/presentation/household_provider.dart';
import 'package:kokomi/features/household/presentation/household_meal_plan_preference_provider.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/models/recipe.dart';

// ── Enums ──

enum MealSlot { breakfast, lunch, dinner, snack }

extension MealSlotExt on MealSlot {
  String get label {
    switch (this) {
      case MealSlot.breakfast:
        return 'Frühstück';
      case MealSlot.lunch:
        return 'Mittagessen';
      case MealSlot.dinner:
        return 'Abendessen';
      case MealSlot.snack:
        return 'Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealSlot.breakfast:
        return '🌅';
      case MealSlot.lunch:
        return '☀️';
      case MealSlot.dinner:
        return '🌙';
      case MealSlot.snack:
        return '🍪';
    }
  }

  IconLabel get iconLabel {
    switch (this) {
      case MealSlot.breakfast:
        return const IconLabel('wb_twilight', 'Frühstück');
      case MealSlot.lunch:
        return const IconLabel('wb_sunny', 'Mittagessen');
      case MealSlot.dinner:
        return const IconLabel('nightlight_round', 'Abendessen');
      case MealSlot.snack:
        return const IconLabel('cookie', 'Snack');
    }
  }
}

class IconLabel {
  final String iconName;
  final String label;
  const IconLabel(this.iconName, this.label);
}

// ── Datenmodelle ──

class MealPlanEntry {
  final String id;
  final int dayIndex; // 0=Mo, 6=So
  final MealSlot slot;
  final FoodRecipe recipe;

  const MealPlanEntry({
    required this.id,
    required this.dayIndex,
    required this.slot,
    required this.recipe,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayIndex': dayIndex,
        'slot': slot.name,
        'recipe': recipe.toJson(),
      };

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        dayIndex: json['dayIndex'] as int? ?? json['day_index'] as int? ?? 0,
        slot: MealSlot.values.firstWhere(
          (s) => s.name == (json['slot'] as String? ?? ''),
          orElse: () => MealSlot.lunch,
        ),
        recipe: FoodRecipe.fromJson(
          json['recipe'] is Map
              ? json['recipe'] as Map<String, dynamic>
              : json['recipe_json'] is Map
                  ? json['recipe_json'] as Map<String, dynamic>
                  : {},
        ),
      );

  int get calories => recipe.nutrition?.calories ?? 0;
}

class MealPlanDay {
  final int dayIndex;
  final List<MealPlanEntry> entries;

  const MealPlanDay({required this.dayIndex, required this.entries});

  MealPlanEntry? getSlot(MealSlot slot) {
    try {
      return entries.firstWhere((e) => e.slot == slot);
    } catch (_) {
      return null;
    }
  }

  int get totalCalories => entries.fold(0, (s, e) => s + e.calories);

  String get dayName {
    const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return names[dayIndex.clamp(0, 6)];
  }

  String get dayNameFull {
    const names = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    return names[dayIndex.clamp(0, 6)];
  }
}

// ── Provider ──

/// Aktuell angezeigte Wochen-Offset (0 = diese Woche, 1 = nächste Woche, ...)
final weekOffsetProvider = StateProvider<int>((ref) => 0);

class MealPlanNotifier extends AsyncNotifier<List<MealPlanEntry>> {
  static const _localKeyPrefix = 'meal_plan_entries';

  int get _offset => ref.read(weekOffsetProvider);

  /// Ob gerade der Haushalt-Plan aktiv ist.
  bool get _isHouseholdMode =>
      ref.read(isUsingHouseholdPlanProvider);

  /// Haushalt-ID des aktuellen Users (oder null).
  String? get _householdId =>
      ref.read(householdProvider).valueOrNull?.id;

  @override
  Future<List<MealPlanEntry>> build() async {
    // Neu laden wenn Offset ODER Haushalt-Präferenz sich ändern
    ref.watch(weekOffsetProvider);
    ref.watch(householdMealPlanPreferenceProvider);
    ref.watch(householdProvider);
    return _load();
  }

  Future<List<MealPlanEntry>> _load() async {
    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;
    if (isPro) {
      return _loadFromSupabase();
    }
    return _loadFromLocal();
  }

  String _localKey(int offset) => '${_localKeyPrefix}_w${offset}';

  DateTime weekStart([int? offset]) {
    final off = offset ?? _offset;
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return monday.add(Duration(days: off * 7));
  }

  /// Anzeige-Label für die aktuelle Woche im Header
  String weekLabel([int? offset]) {
    final off = offset ?? _offset;
    if (off == 0) return 'Diese Woche';
    if (off == 1) return 'Nächste Woche';
    if (off == -1) return 'Letzte Woche';
    final start = weekStart(off);
    final end = start.add(const Duration(days: 6));
    return '${_d(start)} – ${_d(end)}';
  }

  String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.';

  Future<List<MealPlanEntry>> _loadFromSupabase() async {
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return _loadFromLocal();

      final ws = weekStart().toIso8601String().split('T')[0];

      // Haushalt-Modus: nach household_id filtern
      if (_isHouseholdMode && _householdId != null) {
        final data = await SupabaseService.client
            .from('meal_plans')
            .select()
            .eq('household_id', _householdId!)
            .eq('week_start', ws)
            .order('day_index', ascending: true);

        return (data as List).map((e) {
          return MealPlanEntry(
            id: e['id'] as String,
            dayIndex: e['day_index'] as int,
            slot: MealSlot.values.firstWhere(
              (s) => s.name == (e['slot'] as String),
              orElse: () => MealSlot.lunch,
            ),
            recipe:
                FoodRecipe.fromJson(e['recipe_json'] as Map<String, dynamic>),
          );
        }).toList();
      }

      // Persönlicher Modus (Standard)
      final data = await SupabaseService.client
          .from('meal_plans')
          .select()
          .eq('user_id', userId)
          .isFilter('household_id', null)
          .eq('week_start', ws)
          .order('day_index', ascending: true);

      return (data as List).map((e) {
        return MealPlanEntry(
          id: e['id'] as String,
          dayIndex: e['day_index'] as int,
          slot: MealSlot.values.firstWhere(
            (s) => s.name == (e['slot'] as String),
            orElse: () => MealSlot.lunch,
          ),
          recipe:
              FoodRecipe.fromJson(e['recipe_json'] as Map<String, dynamic>),
        );
      }).toList();
    } catch (_) {
      return _loadFromLocal();
    }
  }

  Future<List<MealPlanEntry>> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    // Versuche offset-spezifischen Key, dann legacy key
    final json = prefs.getString(_localKey(_offset))
        ?? (_offset == 0 ? prefs.getString(_localKeyPrefix) : null);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => MealPlanEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal() async {
    final entries = state.valueOrNull ?? [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localKey(_offset),
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Rezept in einen Slot setzen.
  Future<void> setMeal(int dayIndex, MealSlot slot, FoodRecipe recipe) async {
    final entries = (state.valueOrNull ?? []).toList();
    entries.removeWhere((e) => e.dayIndex == dayIndex && e.slot == slot);

    final id = '${weekStart().toIso8601String().split('T')[0]}_${dayIndex}_${slot.name}';
    final entry = MealPlanEntry(id: id, dayIndex: dayIndex, slot: slot, recipe: recipe);
    entries.add(entry);
    state = AsyncData(entries);
    await _saveLocal();

    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;
    if (isPro) {
      try {
        final userId = ref.read(currentUserProvider)?.id;
        if (userId == null) return;
        final ws = weekStart().toIso8601String().split('T')[0];
        final householdId = _isHouseholdMode ? _householdId : null;
        await SupabaseService.client.from('meal_plans').upsert({
          'user_id': userId,
          'household_id': householdId,
          'week_start': ws,
          'day_index': dayIndex,
          'slot': slot.name,
          'recipe_json': recipe.toJson(),
        });
      } catch (_) {}
    }
  }

  /// Slot leeren.
  Future<void> removeMeal(int dayIndex, MealSlot slot) async {
    final entries = (state.valueOrNull ?? []).toList();
    entries.removeWhere((e) => e.dayIndex == dayIndex && e.slot == slot);
    state = AsyncData(entries);
    await _saveLocal();

    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;
    if (isPro) {
      try {
        final userId = ref.read(currentUserProvider)?.id;
        if (userId == null) return;
        final ws = weekStart().toIso8601String().split('T')[0];
        if (_isHouseholdMode && _householdId != null) {
          await SupabaseService.client
              .from('meal_plans')
              .delete()
              .eq('household_id', _householdId!)
              .eq('week_start', ws)
              .eq('day_index', dayIndex)
              .eq('slot', slot.name);
        } else {
          await SupabaseService.client
              .from('meal_plans')
              .delete()
              .eq('user_id', userId)
              .isFilter('household_id', null)
              .eq('week_start', ws)
              .eq('day_index', dayIndex)
              .eq('slot', slot.name);
        }
      } catch (_) {}
    }
  }

  /// Plan der aktuellen Woche leeren.
  Future<void> clearAll() async {
    state = const AsyncData([]);
    await _saveLocal();

    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;
    if (isPro) {
      try {
        final userId = ref.read(currentUserProvider)?.id;
        if (userId == null) return;
        final ws = weekStart().toIso8601String().split('T')[0];
        if (_isHouseholdMode && _householdId != null) {
          await SupabaseService.client
              .from('meal_plans')
              .delete()
              .eq('household_id', _householdId!)
              .eq('week_start', ws);
        } else {
          await SupabaseService.client
              .from('meal_plans')
              .delete()
              .eq('user_id', userId)
              .isFilter('household_id', null)
              .eq('week_start', ws);
        }
      } catch (_) {}
    }
  }

  /// Alle Zutaten der Woche auf die Einkaufsliste setzen.
  Future<int> addAllIngredientsToShoppingList() async {
    final entries = state.valueOrNull ?? [];
    if (entries.isEmpty) return 0;

    final ingredientMap = <String, String>{};
    for (final entry in entries) {
      for (final ing in entry.recipe.ingredients) {
        final key = ing.name.toLowerCase().trim();
        if (ingredientMap.containsKey(key)) {
          ingredientMap[key] = '${ingredientMap[key]} + ${ing.amount}'.trim();
        } else {
          ingredientMap[key] = ing.amount;
        }
      }
    }

    final notifier = ref.read(shoppingListProvider.notifier);
    for (final entry in ingredientMap.entries) {
      await notifier.addItem(entry.key, quantity: entry.value);
    }

    return ingredientMap.length;
  }

  /// 7 Tage für die angezeigte Woche aufbauen.
  List<MealPlanDay> get weekDays {
    final entries = state.valueOrNull ?? [];
    return List.generate(7, (i) {
      final dayEntries = entries.where((e) => e.dayIndex == i).toList();
      return MealPlanDay(dayIndex: i, entries: dayEntries);
    });
  }
}

final mealPlanProvider =
    AsyncNotifierProvider<MealPlanNotifier, List<MealPlanEntry>>(
  MealPlanNotifier.new,
);

/// Die 7 Tage der angezeigten Woche mit ihren Einträgen.
final weekDaysProvider = Provider<List<MealPlanDay>>((ref) {
  final entries = ref.watch(mealPlanProvider).valueOrNull ?? [];
  return List.generate(7, (i) {
    final dayEntries = entries.where((e) => e.dayIndex == i).toList();
    return MealPlanDay(dayIndex: i, entries: dayEntries);
  });
});

/// Label der aktuell angezeigten Woche.
final weekLabelProvider = Provider<String>((ref) {
  final offset = ref.watch(weekOffsetProvider);
  final notifier = ref.read(mealPlanProvider.notifier);
  return notifier.weekLabel(offset);
});

/// Gesamtkalorien der angezeigten Woche.
final weekTotalCaloriesProvider = Provider<int>((ref) {
  final entries = ref.watch(mealPlanProvider).valueOrNull ?? [];
  return entries.fold(0, (s, e) => s + e.calories);
});

