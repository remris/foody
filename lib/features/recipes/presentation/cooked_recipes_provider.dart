import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Eintrag für ein kürzlich gekochtes Rezept.
class CookedRecipeEntry {
  final String recipeId;
  final String title;
  final DateTime cookedAt;

  const CookedRecipeEntry({
    required this.recipeId,
    required this.title,
    required this.cookedAt,
  });

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'title': title,
        'cookedAt': cookedAt.toIso8601String(),
      };

  factory CookedRecipeEntry.fromJson(Map<String, dynamic> json) =>
      CookedRecipeEntry(
        recipeId: json['recipeId'] as String,
        title: json['title'] as String,
        cookedAt: DateTime.parse(json['cookedAt'] as String),
      );
}

/// Provider für zuletzt gekochte Rezepte.
class CookedRecipesNotifier extends Notifier<List<CookedRecipeEntry>> {
  static const _key = 'cooked_recipes';
  static const _maxCount = 20;

  @override
  List<CookedRecipeEntry> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    state = raw
        .map((s) => CookedRecipeEntry.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      state.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> markAsCooked(String recipeId, String title) async {
    final entry = CookedRecipeEntry(
      recipeId: recipeId,
      title: title,
      cookedAt: DateTime.now(),
    );
    state = [entry, ...state].take(_maxCount).toList();
    await _save();
  }

  int getCookCount(String recipeId) =>
      state.where((e) => e.recipeId == recipeId).length;

  DateTime? getLastCooked(String recipeId) {
    final entries =
        state.where((e) => e.recipeId == recipeId).toList();
    if (entries.isEmpty) return null;
    return entries.first.cookedAt;
  }
}

final cookedRecipesProvider =
    NotifierProvider<CookedRecipesNotifier, List<CookedRecipeEntry>>(
  CookedRecipesNotifier.new,
);

