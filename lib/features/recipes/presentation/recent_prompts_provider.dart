import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider für die letzten KI-Rezept-Prompts (Quick-Repeat).
class RecentPromptsNotifier extends Notifier<List<String>> {
  static const _key = 'recent_recipe_prompts';
  static const _maxCount = 5;

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> addPrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;
    final trimmed = prompt.trim();
    // Entferne Duplikate und füge oben ein
    final updated = [
      trimmed,
      ...state.where((p) => p.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxCount).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }
}

final recentPromptsProvider =
    NotifierProvider<RecentPromptsNotifier, List<String>>(
  RecentPromptsNotifier.new,
);

