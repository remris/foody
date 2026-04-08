import 'package:kokomi/core/constants/app_constants.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/features/inventory/domain/inventory_repository.dart';
import 'package:kokomi/models/inventory_item.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final _client = SupabaseService.client;

  @override
  Future<List<InventoryItem>> getInventory(String userId, {String? householdId}) async {
    try {
      late final List<dynamic> data;
      if (householdId != null) {
        // Eigene persönliche Items + alle Haushalt-Items
        data = await _client
            .from(AppConstants.tableUserInventory)
            .select()
            .or('user_id.eq.$userId,household_id.eq.$householdId')
            .order('created_at', ascending: false);
      } else {
        data = await _client
            .from(AppConstants.tableUserInventory)
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      }
      return (data as List).map((e) => InventoryItem.fromJson(e)).toList();
    } catch (_) {
      // Fallback: household_id-Spalte existiert noch nicht → einfache Query
      final data = await _client
          .from(AppConstants.tableUserInventory)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => InventoryItem.fromJson(e)).toList();
    }
  }

  @override
  Future<InventoryItem> addItem(InventoryItem item) async {
    final json = item.toJson()..remove('id');
    // Entferne household_id wenn null, damit es vor der Migration nicht crasht
    if (json['household_id'] == null) json.remove('household_id');
    final data = await _client
        .from(AppConstants.tableUserInventory)
        .insert(json)
        .select()
        .single();
    return InventoryItem.fromJson(data);
  }

  @override
  Future<void> addItems(List<InventoryItem> items) async {
    final jsonList = items.map((item) {
      final json = item.toJson()..remove('id');
      if (json['household_id'] == null) json.remove('household_id');
      return json;
    }).toList();
    await _client.from(AppConstants.tableUserInventory).insert(jsonList);
  }

  @override
  Future<InventoryItem> updateItem(InventoryItem item) async {
    final json = item.toJson();
    if (json['household_id'] == null) json.remove('household_id');
    final data = await _client
        .from(AppConstants.tableUserInventory)
        .update(json)
        .eq('id', item.id)
        .select()
        .single();
    return InventoryItem.fromJson(data);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _client
        .from(AppConstants.tableUserInventory)
        .delete()
        .eq('id', id);
  }

  @override
  Future<int> migrateItemsToHousehold(String householdId) async {
    final result = await _client.rpc('migrate_items_to_household', params: {
      'p_household_id': householdId,
    });
    return (result as int?) ?? 0;
  }

  @override
  Future<int> migrateItemsFromHousehold(String householdId) async {
    final result = await _client.rpc('migrate_items_from_household', params: {
      'p_household_id': householdId,
    });
    return (result as int?) ?? 0;
  }

  @override
  Future<void> transferItems(List<String> itemIds, String? householdId) async {
    for (final id in itemIds) {
      try {
        await _client
            .from(AppConstants.tableUserInventory)
            .update({'household_id': householdId})
            .eq('id', id);
      } catch (_) {
        // household_id-Spalte existiert noch nicht → Migration ausstehend
        rethrow;
      }
    }
  }
}

