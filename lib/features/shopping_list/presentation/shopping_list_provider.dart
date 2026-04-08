import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/household/presentation/household_provider.dart';
import 'package:kokomi/features/shopping_list/data/shopping_list_realtime_service.dart';
import 'package:kokomi/features/shopping_list/data/shopping_list_repository_impl.dart';
import 'package:kokomi/features/shopping_list/domain/shopping_list_repository.dart';
import 'package:kokomi/models/shopping_list.dart';
import 'package:kokomi/models/shopping_list_item.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepositoryImpl();
});

// ── Aktuell ausgewählte Liste ──
final selectedShoppingListProvider = StateProvider<ShoppingList?>((ref) => null);

// ── Listen-Verwaltung (CRUD) ──
class ShoppingListsNotifier extends AsyncNotifier<List<ShoppingList>> {
  @override
  Future<List<ShoppingList>> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return [];
    final lists =
        await ref.read(shoppingListRepositoryProvider).getLists(userId);

    // Default-Liste erstellen falls noch keine existiert
    if (lists.isEmpty) {
      final defaultList = await ref
          .read(shoppingListRepositoryProvider)
          .createList(ShoppingList(
            id: '',
            userId: userId,
            name: 'Einkauf',
            icon: 'shopping_cart',
            createdAt: DateTime.now(),
          ));
      ref.read(selectedShoppingListProvider.notifier).state = defaultList;
      return [defaultList];
    }

    // Wenn noch keine ausgewählt → erste nehmen
    if (ref.read(selectedShoppingListProvider) == null) {
      ref.read(selectedShoppingListProvider.notifier).state = lists.first;
    }
    return lists;
  }

  Future<void> createList(String name, {String icon = 'shopping_cart'}) async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final newList = await ref
        .read(shoppingListRepositoryProvider)
        .createList(ShoppingList(
          id: '',
          userId: userId,
          name: name,
          icon: icon,
          createdAt: DateTime.now(),
        ));
    state = AsyncData([...(state.valueOrNull ?? []), newList]);
    ref.read(selectedShoppingListProvider.notifier).state = newList;
  }

  /// Neue Liste erstellen und direkt mit dem Haushalt teilen.
  Future<void> createSharedList(String name,
      {String icon = 'group'}) async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final householdId = ref.read(householdProvider).valueOrNull?.id;
    if (householdId == null) {
      await createList(name, icon: icon);
      return;
    }
    final newList = await ref
        .read(shoppingListRepositoryProvider)
        .createList(ShoppingList(
          id: '',
          userId: userId,
          name: name,
          icon: icon,
          createdAt: DateTime.now(),
          householdId: householdId,
        ));
    state = AsyncData([...(state.valueOrNull ?? []), newList]);
    ref.read(selectedShoppingListProvider.notifier).state = newList;
  }

  /// Bestehende Liste mit dem Haushalt teilen.
  Future<void> shareWithHousehold(String listId) async {
    final householdId = ref.read(householdProvider).valueOrNull?.id;
    if (householdId == null) return;
    final updated = await ref
        .read(shoppingListRepositoryProvider)
        .shareWithHousehold(listId, householdId);
    final lists = (state.valueOrNull ?? [])
        .map((l) => l.id == listId ? updated : l)
        .toList();
    state = AsyncData(lists);
    // Selektion aktualisieren
    if (ref.read(selectedShoppingListProvider)?.id == listId) {
      ref.read(selectedShoppingListProvider.notifier).state = updated;
    }
  }

  /// Sharing einer Liste aufheben (wieder privat machen).
  Future<void> unshare(String listId) async {
    final updated = await ref
        .read(shoppingListRepositoryProvider)
        .unshareFromHousehold(listId);
    final lists = (state.valueOrNull ?? [])
        .map((l) => l.id == listId ? updated : l)
        .toList();
    state = AsyncData(lists);
    if (ref.read(selectedShoppingListProvider)?.id == listId) {
      ref.read(selectedShoppingListProvider.notifier).state = updated;
    }
  }

  Future<void> renameList(String id, String newName) async {
    final lists = state.valueOrNull ?? [];
    final list = lists.firstWhere((l) => l.id == id);
    final updated = await ref
        .read(shoppingListRepositoryProvider)
        .updateList(list.copyWith(name: newName));
    state = AsyncData(
        lists.map((l) => l.id == id ? updated : l).toList());

    // Selektion aktualisieren
    final selected = ref.read(selectedShoppingListProvider);
    if (selected?.id == id) {
      ref.read(selectedShoppingListProvider.notifier).state = updated;
    }
  }

  Future<void> deleteList(String id) async {
    await ref.read(shoppingListRepositoryProvider).deleteList(id);
    final lists =
        (state.valueOrNull ?? []).where((l) => l.id != id).toList();
    state = AsyncData(lists);

    // Wenn die gelöschte Liste ausgewählt war → zur ersten wechseln
    final selected = ref.read(selectedShoppingListProvider);
    if (selected?.id == id && lists.isNotEmpty) {
      ref.read(selectedShoppingListProvider.notifier).state = lists.first;
    }
  }
}

final shoppingListsProvider =
    AsyncNotifierProvider<ShoppingListsNotifier, List<ShoppingList>>(
  ShoppingListsNotifier.new,
);

// ── Items der aktuell gewählten Liste ──
class ShoppingListNotifier extends AsyncNotifier<List<ShoppingListItem>> {
  @override
  Future<List<ShoppingListItem>> build() async {
    final list = ref.watch(selectedShoppingListProvider);
    if (list == null) return [];

    // Realtime nur für geteilte Haushaltslisten aktivieren
    if (list.householdId != null) {
      final realtimeService = ref.read(shoppingListRealtimeProvider);
      realtimeService.subscribe(list.id, () {
        // Debounce: nicht zu oft neu laden
        Future.delayed(const Duration(milliseconds: 300), _reload);
      });
      // Beim Wechsel der Liste alte Sub beenden
      ref.onDispose(() => realtimeService.unsubscribe());
    }

    return ref.read(shoppingListRepositoryProvider).getItems(list.id);
  }

  Future<void> _reload() async {
    final list = ref.read(selectedShoppingListProvider);
    if (list == null) return;
    state = AsyncData(
        await ref.read(shoppingListRepositoryProvider).getItems(list.id));
  }

  /// Gibt `true` zurück wenn neu hinzugefügt, `false` wenn Menge erhöht wurde.
  Future<bool> addItem(String name, {String? quantity}) async {
    final list = ref.read(selectedShoppingListProvider);
    final userId = ref.read(currentUserProvider)?.id ?? '';
    if (list == null) return false;

    // Vor dem Hinzufügen prüfen ob Name schon existiert
    final existsBefore = (state.valueOrNull ?? [])
        .any((i) => i.name.toLowerCase() == name.toLowerCase());

    final item = ShoppingListItem(
      id: '',
      listId: list.id,
      userId: userId,
      name: name,
      quantity: quantity,
      isChecked: false,
      createdAt: DateTime.now(),
    );
    await ref.read(shoppingListRepositoryProvider).addItem(item);
    await _reload();
    return !existsBefore; // true = neu, false = Menge erhöht
  }

  Future<void> toggleChecked(String id, bool isChecked) async {
    await ref
        .read(shoppingListRepositoryProvider)
        .toggleChecked(id, isChecked);
    await _reload();
  }

  Future<void> deleteItem(String id) async {
    await ref.read(shoppingListRepositoryProvider).deleteItem(id);
    await _reload();
  }

  Future<void> updateItem(ShoppingListItem item) async {
    await ref.read(shoppingListRepositoryProvider).updateItem(item);
    await _reload();
  }

  Future<void> clearChecked() async {
    final list = ref.read(selectedShoppingListProvider);
    if (list == null) return;
    await ref.read(shoppingListRepositoryProvider).clearChecked(list.id);
    await _reload();
  }

  /// Lokale Reihenfolge per Drag & Drop ändern.
  void reorderItems(int oldIndex, int newIndex) {
    final items = state.valueOrNull?.toList();
    if (items == null) return;
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = AsyncData(items);
  }
}

final shoppingListProvider =
    AsyncNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>(
  ShoppingListNotifier.new,
);

