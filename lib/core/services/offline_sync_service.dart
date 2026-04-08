import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/core/database/local_database.dart';
import 'package:kokomi/core/services/connectivity_service.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:drift/drift.dart';

/// Synchronisiert ausstehende lokale Änderungen mit Supabase.
/// Wird aufgerufen wenn das Gerät wieder online geht.
class OfflineSyncService {
  final LocalDatabase _db;

  OfflineSyncService(this._db);

  /// Synchronisiert alle pending Änderungen.
  /// Gibt die Anzahl synchronisierter Items zurück.
  Future<int> syncAll(String userId) async {
    int count = 0;
    count += await _syncInventory(userId);
    count += await _syncShoppingItems(userId);
    return count;
  }

  // ── Inventar ──────────────────────────────────────────────────────────

  Future<int> _syncInventory(String userId) async {
    final pending = await _db.getPendingInventorySync();
    if (pending.isEmpty) return 0;

    int synced = 0;
    for (final item in pending) {
      try {
        await SupabaseService.client.from('inventory_items').upsert({
          'id': item.id,
          'user_id': userId,
          'ingredient_name': item.ingredientName,
          'quantity': item.quantity,
          'unit': item.unit,
          'category': item.category,
          'location': item.location,
          'expiry_date': item.expiryDate,
          'barcode': item.barcode,
          'notes': item.notes,
        });
        await _db.markInventorySynced(item.id);
        synced++;
      } catch (_) {
        // Fehler ignorieren – nächstes Mal nochmal versuchen
      }
    }
    return synced;
  }

  // ── Einkaufslisten-Items ──────────────────────────────────────────────

  Future<int> _syncShoppingItems(String userId) async {
    final pending = await _db.getPendingShoppingItemSync();
    if (pending.isEmpty) return 0;

    int synced = 0;
    for (final item in pending) {
      try {
        await SupabaseService.client.from('shopping_items').upsert({
          'id': item.id,
          'list_id': item.listId,
          'name': item.name,
          'quantity': item.quantity,
          'is_checked': item.isChecked,
          'category': item.category,
          'sort_order': item.sortOrder,
        });
        await (_db.update(_db.localShoppingItems)
              ..where((t) => t.id.equals(item.id)))
            .write(const LocalShoppingItemsCompanion(
                needsSync: Value(false)));
        synced++;
      } catch (_) {}
    }
    return synced;
  }

  // ── Initialsync: Daten von Supabase in lokale DB laden ────────────────

  /// Lädt alle Daten von Supabase und speichert sie lokal.
  /// Nur beim ersten Start oder nach Logout/Login nötig.
  Future<void> initialSync(String userId) async {
    await _syncInventoryFromSupabase(userId);
    await _syncShoppingListsFromSupabase(userId);
    await _syncSavedRecipesFromSupabase(userId);
  }

  Future<void> _syncInventoryFromSupabase(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('inventory_items')
          .select()
          .eq('user_id', userId);

      for (final item in data as List) {
        await _db.upsertInventoryItem(LocalInventoryItemsCompanion(
          id: Value(item['id'] as String),
          userId: Value(userId),
          ingredientName: Value(item['ingredient_name'] as String),
          quantity: Value((item['quantity'] as num?)?.toDouble()),
          unit: Value(item['unit'] as String?),
          category: Value(item['category'] as String?),
          location: Value(item['location'] as String?),
          expiryDate: Value(item['expiry_date'] as String?),
          barcode: Value(item['barcode'] as String?),
          notes: Value(item['notes'] as String?),
          updatedAt:
              Value(DateTime.now().millisecondsSinceEpoch),
          needsSync: const Value(false),
        ));
      }
    } catch (_) {}
  }

  Future<void> _syncShoppingListsFromSupabase(String userId) async {
    try {
      final lists = await SupabaseService.client
          .from('shopping_lists')
          .select('*, shopping_items(*)')
          .eq('user_id', userId);

      for (final list in lists as List) {
        final listId = list['id'] as String;
        await _db.upsertShoppingList(LocalShoppingListsCompanion(
          id: Value(listId),
          userId: Value(userId),
          householdId: Value(list['household_id'] as String?),
          name: Value(list['name'] as String? ?? 'Einkaufsliste'),
          isCompleted: Value(list['is_completed'] as bool? ?? false),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          needsSync: const Value(false),
        ));

        final items = list['shopping_items'] as List? ?? [];
        for (final item in items) {
          await _db.upsertShoppingItem(LocalShoppingItemsCompanion(
            id: Value(item['id'] as String),
            listId: Value(listId),
            name: Value(item['name'] as String),
            quantity: Value(item['quantity'] as String?),
            isChecked: Value(item['is_checked'] as bool? ?? false),
            category: Value(item['category'] as String?),
            sortOrder: Value(item['sort_order'] as int? ?? 0),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            needsSync: const Value(false),
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _syncSavedRecipesFromSupabase(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('saved_recipes')
          .select()
          .eq('user_id', userId);

      for (final recipe in data as List) {
        await _db.upsertSavedRecipe(LocalSavedRecipesCompanion(
          id: Value(recipe['id'] as String),
          userId: Value(userId),
          recipeJson: Value(jsonEncode(recipe['recipe_json'] ?? {})),
          savedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
      }
    } catch (_) {}
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return OfflineSyncService(db);
});

/// Startet automatische Synchronisation wenn Gerät online geht.
final autoSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) async {
    final wasOffline = prev?.valueOrNull == false;
    final isNowOnline = next.valueOrNull == true;

    if (wasOffline && isNowOnline) {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final syncService = ref.read(offlineSyncServiceProvider);
      final count = await syncService.syncAll(userId);
      if (count > 0) {
        // Provider invalidieren damit UI aktualisiert wird
        // ignore: unused_result
      }
    }
  });
});

