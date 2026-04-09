import 'package:kokomu/models/inventory_item.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getInventory(String userId, {String? householdId});
  Future<InventoryItem> addItem(InventoryItem item);
  Future<void> addItems(List<InventoryItem> items);
  Future<InventoryItem> updateItem(InventoryItem item);
  Future<void> deleteItem(String id);
  Future<int> migrateItemsToHousehold(String householdId);
  Future<int> migrateItemsFromHousehold(String householdId);
  /// Einzelne Items zwischen Scopes verschieben (household_id setzen/entfernen).
  Future<void> transferItems(List<String> itemIds, String? householdId);
}

