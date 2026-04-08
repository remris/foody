import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/household/presentation/household_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────
// Haushalt-Wochenplan-Präferenz
// Speichert lokal ob der User den geteilten Haushalt-Plan nutzt.
// "Nein" = persönlicher Plan, jederzeit über HouseholdScreen änderbar.
// ─────────────────────────────────────────────────────────

const _kUseHouseholdPlanKey = 'use_household_meal_plan';

/// Ob der User den geteilten Haushalt-Wochenplan nutzt.
/// false = persönlicher Plan (Standard).
class HouseholdMealPlanPreferenceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kUseHouseholdPlanKey) ?? false;
  }

  /// Einstellung lokal + optional in Supabase speichern.
  Future<void> setUseHouseholdPlan(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseHouseholdPlanKey, value);
    state = AsyncData(value);

    // Auch in Supabase persistieren (damit andere Geräte des Users sync sind)
    try {
      final userId = ref.read(currentUserProvider)?.id;
      final household = ref.read(householdProvider).valueOrNull;
      if (userId == null) return;

      await SupabaseService.client.from('meal_plan_preferences').upsert({
        'user_id': userId,
        'use_household_plan': value,
        'household_id': value ? household?.id : null,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Fehler ignorieren – lokale Einstellung ist ausreichend
    }
  }

  /// Präferenz aus Supabase laden (nach Login / Haushalt-Beitritt).
  Future<void> refreshFromSupabase() async {
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      final data = await SupabaseService.client
          .from('meal_plan_preferences')
          .select('use_household_plan')
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        final value = data['use_household_plan'] as bool? ?? false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kUseHouseholdPlanKey, value);
        state = AsyncData(value);
      }
    } catch (_) {}
  }

  /// Beim Verlassen des Haushalts zurücksetzen auf persönlichen Plan.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseHouseholdPlanKey, false);
    state = const AsyncData(false);
  }
}

final householdMealPlanPreferenceProvider = AsyncNotifierProvider<
    HouseholdMealPlanPreferenceNotifier, bool>(
  HouseholdMealPlanPreferenceNotifier.new,
);

/// Shortcut-Provider: `true` wenn Haushalt existiert UND User den geteilten Plan nutzt.
final isUsingHouseholdPlanProvider = Provider<bool>((ref) {
  final hasHousehold =
      ref.watch(householdProvider).valueOrNull != null;
  final prefersHousehold =
      ref.watch(householdMealPlanPreferenceProvider).valueOrNull ?? false;
  return hasHousehold && prefersHousehold;
});

