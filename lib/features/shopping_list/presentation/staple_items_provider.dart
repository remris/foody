import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider für Stammartikel – Artikel die man regelmäßig kauft.
/// Lokal gespeichert via SharedPreferences.
class StapleItemsNotifier extends Notifier<List<String>> {
  static const _key = 'staple_items';

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_key) ?? [];
    state = items;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> addItem(String name) async {
    if (name.trim().isEmpty) return;
    final trimmed = name.trim();
    if (state.any((e) => e.toLowerCase() == trimmed.toLowerCase())) return;
    state = [...state, trimmed];
    await _save();
  }

  Future<void> removeItem(String name) async {
    state = state.where((e) => e != name).toList();
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final items = state.toList();
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
    await _save();
  }
}

final stapleItemsProvider =
    NotifierProvider<StapleItemsNotifier, List<String>>(
  StapleItemsNotifier.new,
);

