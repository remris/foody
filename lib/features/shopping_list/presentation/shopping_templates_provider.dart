import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ein Einkaufslisten-Template (Vorlage).
class ShoppingTemplate {
  final String id;
  final String name;
  final List<String> items;

  const ShoppingTemplate({
    required this.id,
    required this.name,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items,
      };

  factory ShoppingTemplate.fromJson(Map<String, dynamic> json) =>
      ShoppingTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List).cast<String>(),
      );
}

/// Provider für Einkaufslisten-Templates.
class ShoppingTemplatesNotifier extends Notifier<List<ShoppingTemplate>> {
  static const _key = 'shopping_templates';

  @override
  List<ShoppingTemplate> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    state = raw
        .map((s) => ShoppingTemplate.fromJson(
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

  Future<void> saveTemplate(String name, List<String> items) async {
    if (name.trim().isEmpty || items.isEmpty) return;
    final template = ShoppingTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      items: items,
    );
    state = [...state, template];
    await _save();
  }

  Future<void> deleteTemplate(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _save();
  }
}

final shoppingTemplatesProvider =
    NotifierProvider<ShoppingTemplatesNotifier, List<ShoppingTemplate>>(
  ShoppingTemplatesNotifier.new,
);

