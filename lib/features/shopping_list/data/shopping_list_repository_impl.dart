import 'package:kokomi/core/constants/app_constants.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/features/shopping_list/domain/shopping_list_repository.dart';
import 'package:kokomi/models/shopping_list.dart';
import 'package:kokomi/models/shopping_list_item.dart';

class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final _client = SupabaseService.client;

  // ── Listen-CRUD ──

  @override
  Future<List<ShoppingList>> getLists(String userId) async {
    // RLS filtert automatisch: eigene Listen + geteilte Haushaltslisten
    final data = await _client
        .from(AppConstants.tableShoppingLists)
        .select()
        .order('created_at', ascending: true);
    return (data as List).map((e) => ShoppingList.fromJson(e)).toList();
  }

  @override
  Future<List<ShoppingList>> getHouseholdLists(String householdId) async {
    final data = await _client
        .from(AppConstants.tableShoppingLists)
        .select()
        .eq('household_id', householdId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ShoppingList.fromJson(e)).toList();
  }

  @override
  Future<ShoppingList> createList(ShoppingList list) async {
    final json = list.toJson()..remove('id');
    final data = await _client
        .from(AppConstants.tableShoppingLists)
        .insert(json)
        .select()
        .single();
    return ShoppingList.fromJson(data);
  }

  @override
  Future<ShoppingList> updateList(ShoppingList list) async {
    final data = await _client
        .from(AppConstants.tableShoppingLists)
        .update({'name': list.name, 'icon': list.icon})
        .eq('id', list.id)
        .select()
        .single();
    return ShoppingList.fromJson(data);
  }

  @override
  Future<void> deleteList(String id) async {
    // Erst Items löschen, dann Liste
    await _client
        .from(AppConstants.tableShoppingList)
        .delete()
        .eq('list_id', id);
    await _client
        .from(AppConstants.tableShoppingLists)
        .delete()
        .eq('id', id);
  }

  // ── Haushalt-Sharing ──

  @override
  Future<ShoppingList> shareWithHousehold(
      String listId, String householdId) async {
    final data = await _client
        .from(AppConstants.tableShoppingLists)
        .update({'household_id': householdId})
        .eq('id', listId)
        .select()
        .single();
    return ShoppingList.fromJson(data);
  }

  @override
  Future<ShoppingList> unshareFromHousehold(String listId) async {
    final data = await _client
        .from(AppConstants.tableShoppingLists)
        .update({'household_id': null})
        .eq('id', listId)
        .select()
        .single();
    return ShoppingList.fromJson(data);
  }

  // ── Items-CRUD ──

  @override
  Future<List<ShoppingListItem>> getItems(String listId) async {
    final data = await _client
        .from(AppConstants.tableShoppingList)
        .select()
        .eq('list_id', listId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ShoppingListItem.fromJson(e)).toList();
  }

  @override
  Future<ShoppingListItem> addItem(ShoppingListItem item) async {
    // Prüfen ob Item mit gleichem Name (case-insensitive) schon in der Liste ist
    final existing = await _client
        .from(AppConstants.tableShoppingList)
        .select()
        .eq('list_id', item.listId)
        .ilike('name', item.name)
        .maybeSingle();

    if (existing != null) {
      // Bereits vorhanden → Menge zusammenführen
      final existingItem = ShoppingListItem.fromJson(existing);
      final mergedQty = _mergeQuantities(existingItem.quantity, item.quantity);
      final updated = await _client
          .from(AppConstants.tableShoppingList)
          .update({'quantity': mergedQty, 'is_checked': false})
          .eq('id', existingItem.id)
          .select()
          .single();
      return ShoppingListItem.fromJson(updated);
    }

    final json = item.toJson()..remove('id');
    final data = await _client
        .from(AppConstants.tableShoppingList)
        .insert(json)
        .select()
        .single();
    return ShoppingListItem.fromJson(data);
  }

  /// Fügt zwei Mengenangaben zusammen.
  /// Wenn incoming == null → bestehende um 1 erhöhen
  String? _mergeQuantities(String? existing, String? incoming) {
    // Beide null → war 1x vorhanden, jetzt 2x
    if (existing == null && incoming == null) return '2';
    // Nur incoming → als neue Menge setzen
    if (existing == null) return incoming;

    // Bestehende Zahl + Einheit extrahieren
    final parts = existing.trim().split(RegExp(r'\s+'));
    final existingNum = double.tryParse(parts.first.replaceAll(',', '.'));

    // incoming == null → um 1 erhöhen
    if (incoming == null) {
      if (existingNum != null) {
        final sum = existingNum + 1;
        final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        final sumStr = sum == sum.roundToDouble()
            ? sum.toInt().toString()
            : sum.toStringAsFixed(1);
        return unit.isNotEmpty ? '$sumStr $unit' : sumStr;
      }
      // Nicht parsebar → anhängen
      return '$existing + 1';
    }

    // Beide vorhanden → numerisch addieren wenn möglich
    final incomingParts = incoming.trim().split(RegExp(r'\s+'));
    final incomingNum = double.tryParse(incomingParts.first.replaceAll(',', '.'));

    if (existingNum != null && incomingNum != null) {
      final sum = existingNum + incomingNum;
      final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final sumStr = sum == sum.roundToDouble()
          ? sum.toInt().toString()
          : sum.toStringAsFixed(1);
      return unit.isNotEmpty ? '$sumStr $unit' : sumStr;
    }

    return '$existing + $incoming';
  }

  @override
  Future<ShoppingListItem> updateItem(ShoppingListItem item) async {
    final data = await _client
        .from(AppConstants.tableShoppingList)
        .update({'name': item.name, 'quantity': item.quantity})
        .eq('id', item.id)
        .select()
        .single();
    return ShoppingListItem.fromJson(data);
  }

  @override
  Future<ShoppingListItem> toggleChecked(String id, bool isChecked) async {
    final data = await _client
        .from(AppConstants.tableShoppingList)
        .update({'is_checked': isChecked})
        .eq('id', id)
        .select()
        .single();
    return ShoppingListItem.fromJson(data);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _client.from(AppConstants.tableShoppingList).delete().eq('id', id);
  }

  @override
  Future<void> clearChecked(String listId) async {
    await _client
        .from(AppConstants.tableShoppingList)
        .delete()
        .eq('list_id', listId)
        .eq('is_checked', true);
  }
}

