import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zählt KI-Rezept-Generierungen pro Woche für Free-User.
/// Setzt sich jeden Montag automatisch zurück.
/// Pro-User sind von diesem Limit ausgenommen (Prüfung im recipe_provider).
class AiUsageNotifier extends AsyncNotifier<AiUsageState> {
  static const _keyUses = 'ai_uses_week';
  static const _keyWeekStart = 'ai_week_start';
  static const freeWeeklyLimit = 5;

  @override
  Future<AiUsageState> build() async {
    return _load();
  }

  Future<AiUsageState> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewWeek(prefs);
    final uses = prefs.getInt(_keyUses) ?? 0;
    return AiUsageState(usedThisWeek: uses, weeklyLimit: freeWeeklyLimit);
  }

  /// Gibt zurück ob eine weitere Generierung erlaubt ist (Free-Limit).
  Future<bool> canGenerate() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewWeek(prefs);
    final uses = prefs.getInt(_keyUses) ?? 0;
    return uses < freeWeeklyLimit;
  }

  /// Zählt eine Nutzung hoch. Muss nach erfolgreicher Generierung aufgerufen werden.
  Future<void> recordUsage() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewWeek(prefs);
    final uses = prefs.getInt(_keyUses) ?? 0;
    await prefs.setInt(_keyUses, uses + 1);
    state = AsyncData(await _load());
  }

  /// Setzt den Zähler zurück wenn eine neue Woche begonnen hat (Montag).
  void _resetIfNewWeek(SharedPreferences prefs) {
    final now = DateTime.now();
    // Anfang der aktuellen Woche (Montag 00:00)
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final storedMs = prefs.getInt(_keyWeekStart) ?? 0;
    final storedWeekStart = DateTime.fromMillisecondsSinceEpoch(storedMs);

    if (weekStartDay.isAfter(storedWeekStart)) {
      prefs.setInt(_keyUses, 0);
      prefs.setInt(_keyWeekStart, weekStartDay.millisecondsSinceEpoch);
    }
  }

  Future<int> remainingUses() async {
    final prefs = await SharedPreferences.getInstance();
    _resetIfNewWeek(prefs);
    final uses = prefs.getInt(_keyUses) ?? 0;
    return (freeWeeklyLimit - uses).clamp(0, freeWeeklyLimit);
  }
}

class AiUsageState {
  final int usedThisWeek;
  final int weeklyLimit;

  const AiUsageState({
    required this.usedThisWeek,
    required this.weeklyLimit,
  });

  int get remaining => (weeklyLimit - usedThisWeek).clamp(0, weeklyLimit);
  bool get canGenerate => usedThisWeek < weeklyLimit;
  double get usageFraction => weeklyLimit > 0 ? usedThisWeek / weeklyLimit : 0;
}

final aiUsageProvider =
    AsyncNotifierProvider<AiUsageNotifier, AiUsageState>(AiUsageNotifier.new);

