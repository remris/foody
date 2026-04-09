import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/core/constants/food_categories.dart';
import 'package:kokomu/core/services/notification_service.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/household/presentation/household_provider.dart';
import 'package:kokomu/features/inventory/data/inventory_repository_impl.dart';
import 'package:kokomu/features/inventory/domain/inventory_repository.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomu/models/inventory_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl();
});

// ── Scope: Privat / Haushalt / Alle ──
enum InventoryScope { all, household, personal }

final inventoryScopeProvider =
    StateProvider<InventoryScope>((ref) {
  // Default: Haushalt wenn User in einem Haushalt ist, sonst all
  final household = ref.watch(householdProvider).valueOrNull;
  return household != null ? InventoryScope.household : InventoryScope.all;
});

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return [];
    final householdId = ref.watch(householdProvider).valueOrNull?.id;
    final items = await ref
        .read(inventoryRepositoryProvider)
        .getInventory(userId, householdId: householdId);
    // Ablauf-Check nach dem Laden
    _checkExpiringItems(items);
    return items;
  }

  /// Prüft ob Items bald ablaufen und zeigt ggf. eine Notification.
  Future<void> _checkExpiringItems(List<InventoryItem> items) async {
    final enabled = await NotificationService.isEnabled();
    if (!enabled) return;

    final warningDays = await NotificationService.getWarningDays();
    final now = DateTime.now();

    final expiring = items.where((item) {
      if (item.expiryDate == null) return false;
      final daysLeft = item.expiryDate!.difference(now).inDays;
      return daysLeft >= 0 && daysLeft <= warningDays;
    }).toList();

    if (expiring.isEmpty) return;

    final names = expiring
        .take(5)
        .map((e) => e.ingredientName)
        .join(', ');
    final suffix = expiring.length > 5 ? '...' : '';

    await NotificationService.showExpiryNotification(
      count: expiring.length,
      itemNames: '$names$suffix',
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadItems());
  }

  Future<List<InventoryItem>> _loadItems() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return [];
    final householdId = ref.read(householdProvider).valueOrNull?.id;
    return ref
        .read(inventoryRepositoryProvider)
        .getInventory(userId, householdId: householdId);
  }

  /// Alle persönlichen Items in den Haushalt migrieren.
  Future<int> migrateToHousehold() async {
    final householdId = ref.read(householdProvider).valueOrNull?.id;
    if (householdId == null) return 0;
    final count = await ref
        .read(inventoryRepositoryProvider)
        .migrateItemsToHousehold(householdId);
    await refresh();
    return count;
  }

  /// Haushalt-Items zurück zu persönlich (beim Verlassen).
  Future<int> migrateFromHousehold() async {
    final householdId = ref.read(householdProvider).valueOrNull?.id;
    if (householdId == null) return 0;
    final count = await ref
        .read(inventoryRepositoryProvider)
        .migrateItemsFromHousehold(householdId);
    await refresh();
    return count;
  }

  /// Ausgewählte Items zwischen Scopes transferieren.
  /// [toHousehold] = true → Items werden zum Haushalt
  /// [toHousehold] = false → Items werden privat
  Future<void> transferItems(List<String> itemIds, {required bool toHousehold}) async {
    final householdId = toHousehold
        ? ref.read(householdProvider).valueOrNull?.id
        : null;
    await ref
        .read(inventoryRepositoryProvider)
        .transferItems(itemIds, householdId);
    await refresh();
  }

  Future<void> addItem(InventoryItem item) async {
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).addItem(item);
      _logActivity('added', item.ingredientName);
      return _loadItems();
    });
  }

  Future<void> updateItem(InventoryItem item) async {
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).updateItem(item);
      _logActivity('updated', item.ingredientName);
      // Auto-Nachkauf prüfen
      await _checkAutoRestock(item);
      return _loadItems();
    });
  }

  /// Protokolliert eine Aktion im Haushalt-Aktivitätslog (fire-and-forget).
  void _logActivity(String action, String itemName) {
    final household = ref.read(householdProvider).valueOrNull;
    if (household == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    logHouseholdActivity(
      householdId: household.id,
      userId: user.id,
      displayName: user.email?.split('@').first ?? 'Nutzer',
      action: action,
      itemType: 'inventory',
      itemName: itemName,
    );
  }

  /// Prüft ob der Bestand unter den Mindestbestand gefallen ist und fügt
  /// das Item automatisch auf die Einkaufsliste hinzu.
  Future<void> _checkAutoRestock(InventoryItem item) async {
    if (item.minThreshold <= 0) return;
    if (item.quantity == null) return;
    if (item.quantity! > item.minThreshold) return;

    // Prüfe ob Auto-Nachkauf in Settings aktiviert ist
    final prefs = await SharedPreferences.getInstance();
    final autoRestock = prefs.getBool('auto_restock_enabled') ?? true;
    if (!autoRestock) return;

    // Prüfe ob das Item bereits auf der Einkaufsliste ist
    final shoppingItems =
        ref.read(shoppingListProvider).valueOrNull ?? [];
    final alreadyOnList = shoppingItems.any(
      (s) => s.name.toLowerCase() == item.ingredientName.toLowerCase(),
    );
    if (alreadyOnList) return;

    // Auf Einkaufsliste hinzufügen
    await ref.read(shoppingListProvider.notifier).addItem(
          item.ingredientName,
          quantity: item.unit,
        );
  }

  Future<void> deleteItem(String id) async {
    // Item-Name vor dem Löschen merken für das Log
    final itemName = state.valueOrNull
        ?.firstWhere((i) => i.id == id,
            orElse: () => InventoryItem(
                id: '', userId: '', ingredientId: '',
                ingredientName: 'Artikel', createdAt: DateTime.now()))
        .ingredientName ?? 'Artikel';
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).deleteItem(id);
      _logActivity('deleted', itemName);
      return _loadItems();
    });
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(
  InventoryNotifier.new,
);

// Filter-Provider – Mehrfachauswahl
final selectedCategoriesProvider = StateProvider<Set<String>>((ref) => {});

// Suchfeld
final inventorySearchProvider = StateProvider<String>((ref) => '');

// Reste-Filter: Nur Artikel mit niedriger Menge anzeigen
final inventoryShowLeftoversProvider = StateProvider<bool>((ref) => false);

// Sortier-Modus
enum InventorySortMode { expiryDate, nameAZ, nameZA, newestFirst, category }

final inventorySortModeProvider =
    StateProvider<InventorySortMode>((ref) => InventorySortMode.expiryDate);

// ── Zonen-Filter (Kühlschrank, Tiefkühl, Vorratskammer, Obst & Gemüse) ──────
enum StorageZone {
  all('Alle', '🏠', null),
  fridge('Kühlschrank', '🧊', {
    'Milchprodukte',
    'Fleisch & Fisch',
    'Getränke',
    'Obst',
    'Gemüse',
  }),
  freezer('Tiefkühl', '❄️', {'Tiefkühl'}),
  pantry('Vorratskammer', '🏪', {
    'Getreide & Nudeln',
    'Konserven',
    'Öle & Soßen',
    'Gewürze & Kräuter',
    'Süßigkeiten',
    'Snacks',
    'Backwaren',
    'Sonstiges',
  }),
  produce('Obst & Gemüse', '🥦', {'Obst', 'Gemüse'});

  const StorageZone(this.label, this.emoji, this.categories);
  final String label;
  final String emoji;
  final Set<String>? categories;
}

final storageZoneProvider =
    StateProvider<StorageZone>((ref) => StorageZone.all);

final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];
  final categories = ref.watch(selectedCategoriesProvider);
  final search = ref.watch(inventorySearchProvider).toLowerCase().trim();
  final zone = ref.watch(storageZoneProvider);
  final scope = ref.watch(inventoryScopeProvider);
  final showLeftovers = ref.watch(inventoryShowLeftoversProvider);

  var filtered = inventory;

  // Scope-Filter (Privat / Haushalt / Alle)
  switch (scope) {
    case InventoryScope.personal:
      filtered = filtered.where((item) => !item.isHousehold).toList();
    case InventoryScope.household:
      filtered = filtered.where((item) => item.isHousehold).toList();
    case InventoryScope.all:
      break;
  }

  // Reste-Filter: Artikel die als Reste markiert sind oder niedrige Menge haben
  if (showLeftovers) {
    filtered = filtered.where((item) {
      // Explizit als Reste getaggt (z.B. nach dem Kochen eingetragen)
      if (item.tags.any((t) => t.toLowerCase() == 'reste')) return true;
      // Kategorie "Gekochtes" (case-insensitive)
      if (item.ingredientCategory?.toLowerCase() == 'gekochtes') return true;
      // Menge unter Mindestbestand
      if (item.quantity != null &&
          item.minThreshold > 0 &&
          item.quantity! <= item.minThreshold) return true;
      // Menge sehr niedrig (≤ 1 Einheit) – z.B. letzte Flasche, letzte Dose
      if (item.quantity != null && item.quantity! > 0 && item.quantity! <= 1.0) {
        return true;
      }
      return false;
    }).toList();
  }

  // Zonen-Filter
  if (zone != StorageZone.all && zone.categories != null) {
    filtered = filtered
        .where((item) =>
            item.ingredientCategory != null &&
            zone.categories!.contains(item.ingredientCategory))
        .toList();
  }

  // Kategorie-Filter
  if (categories.isNotEmpty) {
    filtered = filtered
        .where((item) =>
            item.ingredientCategory != null &&
            categories.contains(item.ingredientCategory))
        .toList();
  }

  // Such-Filter
  if (search.isNotEmpty) {
    filtered = filtered
        .where((item) =>
            item.ingredientName.toLowerCase().contains(search) ||
            (item.ingredientCategory?.toLowerCase().contains(search) ?? false))
        .toList();
  }

  return filtered;
});

// Sortierung – konfigurierbar
final sortedInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(filteredInventoryProvider).toList();
  final sortMode = ref.watch(inventorySortModeProvider);

  switch (sortMode) {
    case InventorySortMode.expiryDate:
      items.sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });
    case InventorySortMode.nameAZ:
      items.sort((a, b) => a.ingredientName
          .toLowerCase()
          .compareTo(b.ingredientName.toLowerCase()));
    case InventorySortMode.nameZA:
      items.sort((a, b) => b.ingredientName
          .toLowerCase()
          .compareTo(a.ingredientName.toLowerCase()));
    case InventorySortMode.newestFirst:
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case InventorySortMode.category:
      items.sort((a, b) => (a.ingredientCategory ?? 'ZZZ')
          .compareTo(b.ingredientCategory ?? 'ZZZ'));
  }
  return items;
});

// Alle verfügbaren Kategorien – nur die, die im Inventar vorkommen, plus alle vordefinierten
final categoriesProvider = Provider<List<FoodCategory>>((ref) {
  final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];
  final usedLabels = inventory
      .map((e) => e.ingredientCategory)
      .where((c) => c != null)
      .map((c) => c!)
      .toSet();

  // Zeige alle vordefinierten Kategorien, die tatsächlich verwendet werden
  final used = FoodCategory.values
      .where((c) => usedLabels.contains(c.label))
      .toList();

  // Falls es Kategorien gibt die nicht in FoodCategory sind, ignorieren wir sie
  return used;
});

