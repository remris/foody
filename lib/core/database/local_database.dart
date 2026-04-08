import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

// ── Tabellen ──────────────────────────────────────────────────────────────

/// Vorrats-Items (Offline-Kopie der Supabase inventory_items-Tabelle)
class LocalInventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get ingredientName => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get expiryDate => text().nullable()(); // ISO-String
  TextColumn get barcode => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get updatedAt => integer()(); // millisecondsSinceEpoch
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Einkaufslisten (Offline-Kopie)
class LocalShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  TextColumn get name => text()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Einkaufslisten-Items (Offline-Kopie)
class LocalShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get name => text()();
  TextColumn get quantity => text().nullable()();
  BoolColumn get isChecked =>
      boolean().withDefault(const Constant(false))();
  TextColumn get category => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Gespeicherte Rezepte (Offline-Kopie)
class LocalSavedRecipes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get recipeJson => text()(); // JSON-String
  IntColumn get savedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Datenbank ─────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  LocalInventoryItems,
  LocalShoppingLists,
  LocalShoppingItems,
  LocalSavedRecipes,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Inventory ────────────────────────────────────────────────────────

  Future<List<LocalInventoryItem>> getAllInventoryItems(String userId) =>
      (select(localInventoryItems)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.asc(t.ingredientName)]))
          .get();

  Future<void> upsertInventoryItem(LocalInventoryItemsCompanion item) =>
      into(localInventoryItems).insertOnConflictUpdate(item);

  Future<void> deleteInventoryItem(String id) =>
      (delete(localInventoryItems)..where((t) => t.id.equals(id))).go();

  Future<List<LocalInventoryItem>> getPendingInventorySync() =>
      (select(localInventoryItems)
            ..where((t) => t.needsSync.equals(true)))
          .get();

  Future<void> markInventorySynced(String id) =>
      (update(localInventoryItems)..where((t) => t.id.equals(id))).write(
        const LocalInventoryItemsCompanion(
            needsSync: Value(false)),
      );

  // ── Shopping Lists ────────────────────────────────────────────────────

  Future<List<LocalShoppingList>> getAllShoppingLists(String userId) =>
      (select(localShoppingLists)
            ..where((t) =>
                t.userId.equals(userId) | t.userId.isNull()))
          .get();

  Future<void> upsertShoppingList(LocalShoppingListsCompanion list) =>
      into(localShoppingLists).insertOnConflictUpdate(list);

  Future<void> deleteShoppingList(String id) =>
      (delete(localShoppingLists)..where((t) => t.id.equals(id))).go();

  // ── Shopping Items ────────────────────────────────────────────────────

  Future<List<LocalShoppingItem>> getItemsForList(String listId) =>
      (select(localShoppingItems)
            ..where((t) => t.listId.equals(listId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<void> upsertShoppingItem(LocalShoppingItemsCompanion item) =>
      into(localShoppingItems).insertOnConflictUpdate(item);

  Future<void> deleteShoppingItem(String id) =>
      (delete(localShoppingItems)..where((t) => t.id.equals(id))).go();

  Future<List<LocalShoppingItem>> getPendingShoppingItemSync() =>
      (select(localShoppingItems)
            ..where((t) => t.needsSync.equals(true)))
          .get();

  // ── Saved Recipes ─────────────────────────────────────────────────────

  Future<List<LocalSavedRecipe>> getSavedRecipes(String userId) =>
      (select(localSavedRecipes)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
          .get();

  Future<void> upsertSavedRecipe(LocalSavedRecipesCompanion recipe) =>
      into(localSavedRecipes).insertOnConflictUpdate(recipe);

  Future<void> deleteSavedRecipe(String id) =>
      (delete(localSavedRecipes)..where((t) => t.id.equals(id))).go();

  // ── Hilfsmethoden ────────────────────────────────────────────────────

  /// Löscht alle lokalen Daten (bei Logout)
  Future<void> clearAll() async {
    await delete(localInventoryItems).go();
    await delete(localShoppingLists).go();
    await delete(localShoppingItems).go();
    await delete(localSavedRecipes).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'Kokomi_offline.db'));
    return NativeDatabase.createInBackground(file);
  });
}

