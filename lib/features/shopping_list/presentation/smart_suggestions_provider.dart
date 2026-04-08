import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service für intelligente Einkaufsvorschläge basierend auf Kaufhistorie.
/// Analysiert welche Artikel regelmäßig gekauft werden und wann zuletzt.

class SmartSuggestion {
  final String name;
  final String? category;
  final double score; // Relevanz 0–1
  final String reason; // z.B. "Letzte Woche gekauft"

  const SmartSuggestion({
    required this.name,
    this.category,
    required this.score,
    required this.reason,
  });
}

class SmartSuggestionsService {
  static const _historyKey = 'shopping_purchase_history';
  static const _maxHistory = 200;

  /// Registriert einen gekauften Artikel in der Kaufhistorie.
  static Future<void> recordPurchase(String itemName) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _loadHistory(prefs);
    final now = DateTime.now().toIso8601String();
    final entry = {'name': itemName.toLowerCase().trim(), 'date': now};

    // Vorne einfügen (neueste zuerst)
    history.insert(0, entry);
    // Limit einhalten
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }

    await prefs.setString(_historyKey, json.encode(history));
  }

  /// Gibt intelligente Vorschläge basierend auf Kaufhistorie zurück.
  static Future<List<SmartSuggestion>> getSuggestions({
    List<String>? currentItems, // aktuell auf der Liste
    List<String>? inventoryItems, // aktuell im Vorrat
    int maxSuggestions = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _loadHistory(prefs);

    if (history.isEmpty) return _getDefaultSuggestions();

    // Artikel-Frequenz-Map aufbauen
    final Map<String, List<DateTime>> purchaseDates = {};
    for (final entry in history) {
      final name = entry['name'] as String? ?? '';
      final dateStr = entry['date'] as String? ?? '';
      if (name.isEmpty) continue;
      try {
        final date = DateTime.parse(dateStr);
        purchaseDates.putIfAbsent(name, () => []).add(date);
      } catch (_) {}
    }

    final now = DateTime.now();
    final suggestions = <SmartSuggestion>[];

    for (final entry in purchaseDates.entries) {
      final name = entry.key;
      final dates = entry.value..sort((a, b) => b.compareTo(a));
      final lastPurchase = dates.first;
      final daysSince = now.difference(lastPurchase).inDays;

      // Durchschnittlicher Kaufzyklus berechnen
      double avgCycleDays = 7.0;
      if (dates.length > 1) {
        final totalDiff = dates.first.difference(dates.last).inDays;
        avgCycleDays = totalDiff / (dates.length - 1);
      }

      // Score berechnen: je näher am Kaufzyklus, desto höher
      double score = 0;
      String reason = '';

      if (daysSince >= avgCycleDays * 0.8) {
        // Fällig zum Nachkauf
        score = (daysSince / avgCycleDays).clamp(0.1, 2.0);
        reason = daysSince < 7
            ? 'Letzte Woche gekauft'
            : daysSince < 14
                ? 'Vor ${daysSince} Tagen gekauft'
                : 'Regelmäßig im Einkauf';
      } else {
        // Noch nicht fällig
        final daysUntilDue = (avgCycleDays - daysSince).round();
        score = 0.1;
        reason = 'In ~$daysUntilDue Tagen fällig';
      }

      // Artikel die häufig gekauft werden bekommen Bonus
      if (dates.length >= 5) score *= 1.3;
      if (dates.length >= 10) score *= 1.2;

      // Artikel die bereits auf der Liste sind überspringen
      final lowerName = name.toLowerCase();
      if (currentItems != null &&
          currentItems.any((i) => i.toLowerCase().contains(lowerName))) {
        continue;
      }

      // Artikel die im Vorrat sind leicht abwerten (aber nicht ausblenden)
      if (inventoryItems != null &&
          inventoryItems.any((i) => i.toLowerCase().contains(lowerName))) {
        score *= 0.3;
        reason = '🏠 Im Vorrat vorhanden';
      }

      suggestions.add(SmartSuggestion(
        name: _capitalize(name),
        score: score,
        reason: reason,
      ));
    }

    // Nach Score sortieren
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(maxSuggestions).toList();
  }

  /// Gibt Standardvorschläge wenn noch keine Historie vorhanden.
  static List<SmartSuggestion> _getDefaultSuggestions() {
    const defaults = [
      'Milch', 'Brot', 'Butter', 'Eier', 'Joghurt', 'Käse',
      'Tomaten', 'Gurke', 'Bananen', 'Äpfel', 'Kartoffeln', 'Zwiebeln',
    ];
    return defaults.map((name) => SmartSuggestion(
      name: name,
      score: 0.5,
      reason: 'Häufig gekauft',
    )).toList();
  }

  /// Kaufhistorie löschen (für Tests/Reset).
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static Future<List<Map<String, dynamic>>> _loadHistory(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ── Riverpod Provider ──

final smartSuggestionsProvider =
    FutureProvider.autoDispose.family<List<SmartSuggestion>, List<String>>(
  (ref, currentItems) async {
    return SmartSuggestionsService.getSuggestions(
      currentItems: currentItems,
      maxSuggestions: 8,
    );
  },
);

