import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Koch-Streak-System: Zählt aufeinanderfolgende Tage an denen gekocht wurde.
class CookingStreakState {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCookedDate;
  final int totalDaysCooked;

  const CookingStreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCookedDate,
    this.totalDaysCooked = 0,
  });

  bool get cookedToday {
    if (lastCookedDate == null) return false;
    final now = DateTime.now();
    return lastCookedDate!.year == now.year &&
        lastCookedDate!.month == now.month &&
        lastCookedDate!.day == now.day;
  }

  String get streakEmoji {
    if (currentStreak >= 30) return '👨‍🍳';
    if (currentStreak >= 14) return '🔥🔥🔥';
    if (currentStreak >= 7) return '🔥🔥';
    if (currentStreak >= 3) return '🔥';
    if (currentStreak >= 1) return '🍳';
    return '💤';
  }

  String get streakMessage {
    if (currentStreak >= 30) return 'Meisterkoch! $currentStreak Tage am Stück!';
    if (currentStreak >= 14) return 'Unglaublich! $currentStreak Tage in Folge!';
    if (currentStreak >= 7) return 'Eine ganze Woche! Weiter so!';
    if (currentStreak >= 3) return '$currentStreak Tage in Folge – super!';
    if (currentStreak == 1) return 'Guter Start! Morgen wieder kochen?';
    return 'Koch heute etwas um deinen Streak zu starten!';
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCookedDate': lastCookedDate?.toIso8601String(),
        'totalDaysCooked': totalDaysCooked,
      };

  factory CookingStreakState.fromJson(Map<String, dynamic> json) {
    return CookingStreakState(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastCookedDate: json['lastCookedDate'] != null
          ? DateTime.tryParse(json['lastCookedDate'] as String)
          : null,
      totalDaysCooked: json['totalDaysCooked'] as int? ?? 0,
    );
  }
}

class CookingStreakNotifier extends Notifier<CookingStreakState> {
  static const _key = 'cooking_streak';

  @override
  CookingStreakState build() {
    _load();
    return const CookingStreakState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        final data = CookingStreakState.fromJson(jsonDecode(json));
        // Prüfen ob der Streak noch gültig ist (nicht älter als gestern)
        state = _validateStreak(data);
      } catch (_) {
        state = const CookingStreakState();
      }
    }
  }

  CookingStreakState _validateStreak(CookingStreakState data) {
    if (data.lastCookedDate == null) return data;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      data.lastCookedDate!.year,
      data.lastCookedDate!.month,
      data.lastCookedDate!.day,
    );
    final diff = today.difference(lastDay).inDays;

    if (diff > 1) {
      // Streak gebrochen
      return CookingStreakState(
        currentStreak: 0,
        longestStreak: data.longestStreak,
        lastCookedDate: data.lastCookedDate,
        totalDaysCooked: data.totalDaysCooked,
      );
    }
    return data;
  }

  /// Aufrufen wenn ein Rezept fertig gekocht wurde.
  Future<void> recordCooking() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schon heute gekocht? Nichts tun
    if (state.cookedToday) return;

    int newStreak;
    if (state.lastCookedDate != null) {
      final lastDay = DateTime(
        state.lastCookedDate!.year,
        state.lastCookedDate!.month,
        state.lastCookedDate!.day,
      );
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        // Aufeinanderfolgender Tag
        newStreak = state.currentStreak + 1;
      } else if (diff == 0) {
        // Selber Tag (sollte nicht vorkommen wegen guard oben)
        newStreak = state.currentStreak;
      } else {
        // Streak gebrochen, neuer Start
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > state.longestStreak ? newStreak : state.longestStreak;

    state = CookingStreakState(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastCookedDate: now,
      totalDaysCooked: state.totalDaysCooked + 1,
    );

    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

final cookingStreakProvider =
    NotifierProvider<CookingStreakNotifier, CookingStreakState>(
  CookingStreakNotifier.new,
);

