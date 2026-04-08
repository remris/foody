import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Einkaufslisten-Statistiken: häufigste Artikel, Wocheneinkäufe etc.
class ShoppingStats {
  final int totalPurchases; // Gesamtzahl Einkäufe
  final int thisWeekPurchases; // Einkäufe diese Woche
  final List<MapEntry<String, int>> topItems; // Häufigste Artikel (Name → Anzahl)
  final double averageListSize; // Durchschnittliche Listengröße
  final Map<String, int> weeklyActivity; // Tag → Anzahl Einkäufe (Mo-So)

  const ShoppingStats({
    required this.totalPurchases,
    required this.thisWeekPurchases,
    required this.topItems,
    required this.averageListSize,
    required this.weeklyActivity,
  });
}

class ShoppingStatsService {
  static const _statsKey = 'shopping_stats_log';

  /// Loggt einen abgeschlossenen Einkauf (Liste mit Artikeln).
  static Future<void> logCompletedShop(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    final log = await _loadLog(prefs);

    final entry = {
      'date': DateTime.now().toIso8601String(),
      'items': items,
      'count': items.length,
    };
    log.insert(0, entry);

    // Maximal 100 Einkäufe speichern
    if (log.length > 100) log.removeRange(100, log.length);

    await prefs.setString(_statsKey, json.encode(log));
  }

  /// Berechnet Statistiken aus dem Einkaufslog.
  static Future<ShoppingStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final log = await _loadLog(prefs);

    if (log.isEmpty) {
      return const ShoppingStats(
        totalPurchases: 0,
        thisWeekPurchases: 0,
        topItems: [],
        averageListSize: 0,
        weeklyActivity: {},
      );
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    int thisWeekCount = 0;
    double totalItems = 0;
    final itemFrequency = <String, int>{};
    final weeklyActivity = <String, int>{
      'Mo': 0, 'Di': 0, 'Mi': 0, 'Do': 0, 'Fr': 0, 'Sa': 0, 'So': 0,
    };
    final dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    for (final entry in log) {
      final dateStr = entry['date'] as String? ?? '';
      final items = (entry['items'] as List? ?? []).cast<String>();

      DateTime? date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        continue;
      }

      // Diese-Woche-Zähler
      if (date.isAfter(weekStartDate)) thisWeekCount++;

      // Gesamtartikel
      totalItems += items.length;

      // Artikel-Häufigkeit
      for (final item in items) {
        final key = item.toLowerCase().trim();
        itemFrequency[key] = (itemFrequency[key] ?? 0) + 1;
      }

      // Wochenaktivität (letzten 4 Wochen)
      if (date.isAfter(now.subtract(const Duration(days: 28)))) {
        final dayIndex = date.weekday - 1; // 0=Mo, 6=So
        if (dayIndex < 7) {
          final dayName = dayNames[dayIndex];
          weeklyActivity[dayName] = (weeklyActivity[dayName] ?? 0) + 1;
        }
      }
    }

    // Top-10 Artikel
    final sortedItems = itemFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topItems = sortedItems
        .take(10)
        .map((e) => MapEntry(
              e.key.isNotEmpty
                  ? e.key[0].toUpperCase() + e.key.substring(1)
                  : e.key,
              e.value,
            ))
        .toList();

    return ShoppingStats(
      totalPurchases: log.length,
      thisWeekPurchases: thisWeekCount,
      topItems: topItems,
      averageListSize: log.isNotEmpty ? totalItems / log.length : 0,
      weeklyActivity: weeklyActivity,
    );
  }

  static Future<List<Map<String, dynamic>>> _loadLog(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_statsKey);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

// ── Provider ──

final shoppingStatsProvider = FutureProvider.autoDispose<ShoppingStats>(
  (ref) => ShoppingStatsService.getStats(),
);

