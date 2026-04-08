import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lokaler Provider für geschätzte Preise je Einkaufsartikel.
/// Key = item.id, Value = Preis in Euro.
class ItemPricesNotifier extends Notifier<Map<String, double>> {
  static const _key = 'shopping_item_prices';

  @override
  Map<String, double> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state));
  }

  Future<void> setPrice(String itemId, double? price) async {
    final updated = Map<String, double>.from(state);
    if (price == null || price <= 0) {
      updated.remove(itemId);
    } else {
      updated[itemId] = price;
    }
    state = updated;
    await _save();
  }

  double? getPrice(String itemId) => state[itemId];

  double get totalEstimate =>
      state.values.fold(0.0, (sum, price) => sum + price);
}

final itemPricesProvider =
    NotifierProvider<ItemPricesNotifier, Map<String, double>>(
  ItemPricesNotifier.new,
);

