import 'package:kokomu/models/shopping_list.dart';
import 'package:kokomu/models/shopping_list_item.dart';

abstract class ShoppingListRepository {
  // Listen-CRUD
  Future<List<ShoppingList>> getLists(String userId);
  Future<List<ShoppingList>> getHouseholdLists(String householdId);
  Future<ShoppingList> createList(ShoppingList list);
  Future<ShoppingList> updateList(ShoppingList list);
  Future<void> deleteList(String id);

  // Haushalt-Sharing
  Future<ShoppingList> shareWithHousehold(String listId, String householdId);
  Future<ShoppingList> unshareFromHousehold(String listId);

  // Items-CRUD
  Future<List<ShoppingListItem>> getItems(String listId);
  Future<ShoppingListItem> addItem(ShoppingListItem item);
  Future<ShoppingListItem> updateItem(ShoppingListItem item);
  Future<ShoppingListItem> toggleChecked(String id, bool isChecked);
  Future<void> deleteItem(String id);
  Future<void> clearChecked(String listId);
}
