import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/settings/presentation/subscription_provider.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/models/recipe.dart';

// ── Enums ──

enum Gender { male, female, other }

enum NutritionGoal { lose, maintain, gain }

// ── Ernährungsprofil (lokal) ──

class NutritionProfile {
  final int age;
  final Gender gender;
  final double weightKg;
  final double heightCm;
  final NutritionGoal goal;
  final int calorieGoal; // Manuell überschreibbar
  final double proteinGoalG;
  final double carbsGoalG;
  final double fatGoalG;

  const NutritionProfile({
    required this.age,
    required this.gender,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.calorieGoal,
    required this.proteinGoalG,
    required this.carbsGoalG,
    required this.fatGoalG,
  });

  /// Harris-Benedict-Formel → BMR → TDEE → Zielanpassung.
  factory NutritionProfile.calculate({
    required int age,
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required NutritionGoal goal,
    int? customCalorieGoal,
  }) {
    // BMR berechnen (Mifflin-St Jeor)
    double bmr;
    if (gender == Gender.female) {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    }

    // TDEE (leicht aktiv = Faktor 1.375)
    final tdee = bmr * 1.375;

    // Zielanpassung
    int targetCal;
    switch (goal) {
      case NutritionGoal.lose:
        targetCal = (tdee - 500).round();
      case NutritionGoal.maintain:
        targetCal = tdee.round();
      case NutritionGoal.gain:
        targetCal = (tdee + 300).round();
    }

    if (customCalorieGoal != null) targetCal = customCalorieGoal;

    // Makro-Split: 30% Protein, 40% Carbs, 30% Fat
    final proteinG = (targetCal * 0.30) / 4; // 4 kcal/g
    final carbsG = (targetCal * 0.40) / 4; // 4 kcal/g
    final fatG = (targetCal * 0.30) / 9; // 9 kcal/g

    return NutritionProfile(
      age: age,
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      goal: goal,
      calorieGoal: targetCal,
      proteinGoalG: proteinG,
      carbsGoalG: carbsG,
      fatGoalG: fatG,
    );
  }

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender.name,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'goal': goal.name,
        'calorieGoal': calorieGoal,
        'proteinGoalG': proteinGoalG,
        'carbsGoalG': carbsGoalG,
        'fatGoalG': fatGoalG,
      };

  factory NutritionProfile.fromJson(Map<String, dynamic> json) {
    return NutritionProfile(
      age: json['age'] as int,
      gender: Gender.values.firstWhere((e) => e.name == json['gender'],
          orElse: () => Gender.other),
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      goal: NutritionGoal.values.firstWhere((e) => e.name == json['goal'],
          orElse: () => NutritionGoal.maintain),
      calorieGoal: json['calorieGoal'] as int,
      proteinGoalG: (json['proteinGoalG'] as num).toDouble(),
      carbsGoalG: (json['carbsGoalG'] as num).toDouble(),
      fatGoalG: (json['fatGoalG'] as num).toDouble(),
    );
  }

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Untergewicht';
    if (bmi < 25) return 'Normalgewicht';
    if (bmi < 30) return 'Übergewicht';
    return 'Adipositas';
  }
}

// ── Profile Provider ──

class NutritionProfileNotifier extends Notifier<NutritionProfile?> {
  static const _key = 'nutrition_profile';

  @override
  NutritionProfile? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        state = NutritionProfile.fromJson(jsonDecode(json));
      } catch (_) {
        state = null;
      }
    }
  }

  Future<void> saveProfile(NutritionProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
    state = profile;
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = null;
  }
}

final nutritionProfileProvider =
    NotifierProvider<NutritionProfileNotifier, NutritionProfile?>(
  NutritionProfileNotifier.new,
);

// ── Tages-Einträge ──

class NutritionEntry {
  final String id;
  final String recipeTitle;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double servings;
  final DateTime loggedAt;

  const NutritionEntry({
    required this.id,
    required this.recipeTitle,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.servings,
    required this.loggedAt,
  });

  factory NutritionEntry.fromJson(Map<String, dynamic> json) => NutritionEntry(
        id: json['id'] as String? ?? '',
        recipeTitle: json['recipe_title'] as String? ?? '',
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
        servings: (json['servings'] as num?)?.toDouble() ?? 1,
        loggedAt: DateTime.tryParse(
                json['logged_at'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'recipe_title': recipeTitle,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'servings': servings,
      };
}

class DailyNutritionSummary {
  final DateTime date;
  final List<NutritionEntry> entries;

  const DailyNutritionSummary({required this.date, required this.entries});

  int get totalCalories => entries.fold(0, (s, e) => s + e.calories);
  double get totalProtein => entries.fold(0.0, (s, e) => s + e.protein);
  double get totalCarbs => entries.fold(0.0, (s, e) => s + e.carbs);
  double get totalFat => entries.fold(0.0, (s, e) => s + e.fat);
  double get totalFiber => entries.fold(0.0, (s, e) => s + e.fiber);
}

// ── Daily Nutrition Log Provider ──

class DailyNutritionNotifier extends AsyncNotifier<List<NutritionEntry>> {
  @override
  Future<List<NutritionEntry>> build() async {
    return _loadToday();
  }

  Future<List<NutritionEntry>> _loadToday() async {
    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;
    if (isPro) {
      return _loadFromSupabase();
    }
    return _loadFromLocal();
  }

  Future<List<NutritionEntry>> _loadFromSupabase() async {
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return [];
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final data = await SupabaseService.client
          .from('nutrition_log')
          .select()
          .eq('user_id', userId)
          .eq('logged_at', todayStr)
          .order('created_at', ascending: true);
      return (data as List).map((e) => NutritionEntry.fromJson(e)).toList();
    } catch (_) {
      return _loadFromLocal();
    }
  }

  Future<List<NutritionEntry>> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final json = prefs.getString(today);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => NutritionEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return 'nutrition_log_${now.year}_${now.month}_${now.day}';
  }

  /// Mahlzeit loggen nach dem Kochen.
  Future<void> logMeal(FoodRecipe recipe, double servings) async {
    final nutrition = recipe.nutrition;
    if (nutrition == null) return;

    final perServing = NutritionEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recipeTitle: recipe.title,
      calories: (nutrition.calories * servings / recipe.servings).round(),
      protein: nutrition.protein * servings / recipe.servings,
      carbs: nutrition.carbs * servings / recipe.servings,
      fat: nutrition.fat * servings / recipe.servings,
      fiber: nutrition.fiber * servings / recipe.servings,
      servings: servings,
      loggedAt: DateTime.now(),
    );

    final isPro = ref.read(subscriptionProvider).valueOrNull?.isPro ?? false;

    if (isPro) {
      await _saveToSupabase(perServing);
    }
    await _saveToLocal(perServing);

    // State aktualisieren
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, perServing]);
  }

  Future<void> _saveToSupabase(NutritionEntry entry) async {
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;
      await SupabaseService.client.from('nutrition_log').insert({
        'user_id': userId,
        ...entry.toJson(),
      });
    } catch (_) {
      // Silently fail, lokal ist schon gespeichert
    }
  }

  Future<void> _saveToLocal(NutritionEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    final existing = prefs.getString(key);
    List<Map<String, dynamic>> list = [];
    if (existing != null) {
      try {
        list = (jsonDecode(existing) as List).cast<Map<String, dynamic>>();
      } catch (_) {}
    }
    list.add(entry.toJson());
    await prefs.setString(key, jsonEncode(list));
  }

  /// Letzten Eintrag entfernen.
  Future<void> removeLastEntry() async {
    final current = state.valueOrNull ?? [];
    if (current.isEmpty) return;
    final updated = current.sublist(0, current.length - 1);
    state = AsyncData(updated);

    // Lokal aktualisieren
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    await prefs.setString(
      key,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }
}

final dailyNutritionProvider =
    AsyncNotifierProvider<DailyNutritionNotifier, List<NutritionEntry>>(
  DailyNutritionNotifier.new,
);

// ── Tages-Zusammenfassung ──

final todayNutritionSummaryProvider = Provider<DailyNutritionSummary>((ref) {
  final entries = ref.watch(dailyNutritionProvider).valueOrNull ?? [];
  return DailyNutritionSummary(date: DateTime.now(), entries: entries);
});

// ── Kalorien-Fortschritt (0.0–1.0) ──

final calorieProgressProvider = Provider<double>((ref) {
  final summary = ref.watch(todayNutritionSummaryProvider);
  final profile = ref.watch(nutritionProfileProvider);
  if (profile == null || profile.calorieGoal <= 0) return 0.0;
  return (summary.totalCalories / profile.calorieGoal).clamp(0.0, 1.5);
});

// ── Wochen-Daten (letzte 7 Tage, lokal) ──

final weeklyNutritionProvider =
    FutureProvider<List<DailyNutritionSummary>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final days = <DailyNutritionSummary>[];
  final now = DateTime.now();

  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final key = 'nutrition_log_${date.year}_${date.month}_${date.day}';
    final json = prefs.getString(key);
    List<NutritionEntry> entries = [];
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        entries = list.map((e) => NutritionEntry.fromJson(e)).toList();
      } catch (_) {}
    }
    days.add(DailyNutritionSummary(date: date, entries: entries));
  }
  return days;
});

// ── Wassertracker ──

class WaterTrackerState {
  final int currentMl;
  final int goalMl;

  const WaterTrackerState({this.currentMl = 0, this.goalMl = 2500});

  double get progress => goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.5) : 0;
  bool get goalReached => currentMl >= goalMl;
  int get remainingMl => (goalMl - currentMl).clamp(0, goalMl);
  double get currentLiters => currentMl / 1000;
  double get goalLiters => goalMl / 1000;
}

class WaterTrackerNotifier extends Notifier<WaterTrackerState> {
  static const _keyMl = 'water_ml';
  static const _keyGoal = 'water_goal_ml';
  static const _keyDate = 'water_date';

  @override
  WaterTrackerState build() {
    _load();
    return const WaterTrackerState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);
    final ml = prefs.getInt(_keyMl) ?? 0;
    final goal = prefs.getInt(_keyGoal) ?? 2500;
    state = WaterTrackerState(currentMl: ml, goalMl: goal);
  }

  void _resetIfNewDay(SharedPreferences prefs) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final stored = prefs.getString(_keyDate) ?? '';
    if (stored != todayStr) {
      prefs.setInt(_keyMl, 0);
      prefs.setString(_keyDate, todayStr);
    }
  }

  Future<void> addWater(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewDay(prefs);
    final current = prefs.getInt(_keyMl) ?? 0;
    final newVal = current + ml;
    await prefs.setInt(_keyMl, newVal);
    state = WaterTrackerState(currentMl: newVal, goalMl: state.goalMl);
  }

  Future<void> removeWater(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyMl) ?? 0;
    final newVal = (current - ml).clamp(0, 99999);
    await prefs.setInt(_keyMl, newVal);
    state = WaterTrackerState(currentMl: newVal, goalMl: state.goalMl);
  }

  Future<void> setGoal(int goalMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGoal, goalMl);
    state = WaterTrackerState(currentMl: state.currentMl, goalMl: goalMl);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMl, 0);
    state = WaterTrackerState(currentMl: 0, goalMl: state.goalMl);
  }
}

final waterTrackerProvider =
    NotifierProvider<WaterTrackerNotifier, WaterTrackerState>(
  WaterTrackerNotifier.new,
);


