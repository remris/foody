import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomu/models/inventory_item.dart';

/// Generiert realistische Testdaten für einen typischen deutschen Haushalt.
class SeedDataService {
  /// Fügt ~32 typische Haushaltszutaten in den Vorrat ein.
  static Future<void> seedInventory(WidgetRef ref) async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final now = DateTime.now();

    final items = [
      // ── Kühlschrank ──
      _item(userId, 'Vollmilch', 'Milchprodukte', qty: 1.5, unit: 'L',
          expiry: now.add(const Duration(days: 5)), tags: ['kühlschrank']),
      _item(userId, 'Butter', 'Milchprodukte', qty: 250, unit: 'g',
          expiry: now.add(const Duration(days: 21)), tags: ['kühlschrank']),
      _item(userId, 'Gouda', 'Milchprodukte', qty: 200, unit: 'g',
          expiry: now.add(const Duration(days: 14)), tags: ['kühlschrank']),
      _item(userId, 'Joghurt (Natur)', 'Milchprodukte', qty: 500, unit: 'g',
          expiry: now.add(const Duration(days: 8)), tags: ['kühlschrank']),
      _item(userId, 'Eier', 'Milchprodukte', qty: 10, unit: 'Stück',
          expiry: now.add(const Duration(days: 18)), tags: ['kühlschrank']),
      _item(userId, 'Hähnchenbrust', 'Fleisch & Fisch', qty: 500, unit: 'g',
          expiry: now.add(const Duration(days: 2)), tags: ['kühlschrank', 'fleisch']),
      _item(userId, 'Lachsfilet', 'Fleisch & Fisch', qty: 300, unit: 'g',
          expiry: now.add(const Duration(days: 1)), tags: ['kühlschrank', 'fisch']),
      _item(userId, 'Tomate', 'Obst & Gemüse', qty: 6, unit: 'Stück',
          expiry: now.add(const Duration(days: 5)), tags: ['kühlschrank', 'gemüse']),
      _item(userId, 'Paprika', 'Obst & Gemüse', qty: 3, unit: 'Stück',
          expiry: now.add(const Duration(days: 6)), tags: ['kühlschrank', 'gemüse']),
      _item(userId, 'Karotten', 'Obst & Gemüse', qty: 500, unit: 'g',
          expiry: now.add(const Duration(days: 12)), tags: ['kühlschrank', 'gemüse']),
      _item(userId, 'Brokkoli', 'Obst & Gemüse', qty: 1, unit: 'Stück',
          expiry: now.add(const Duration(days: 4)), tags: ['kühlschrank', 'gemüse']),
      _item(userId, 'Spinat (frisch)', 'Obst & Gemüse', qty: 200, unit: 'g',
          expiry: now.add(const Duration(days: 3)), tags: ['kühlschrank', 'gemüse']),
      _item(userId, 'Orangen', 'Obst & Gemüse', qty: 5, unit: 'Stück',
          expiry: now.add(const Duration(days: 10)), tags: ['obst']),
      _item(userId, 'Äpfel', 'Obst & Gemüse', qty: 6, unit: 'Stück',
          expiry: now.add(const Duration(days: 14)), tags: ['obst']),
      // ── Vorratskammer ──
      _item(userId, 'Spaghetti', 'Nudeln & Getreide', qty: 500, unit: 'g',
          tags: ['vorrat', 'nudeln']),
      _item(userId, 'Penne', 'Nudeln & Getreide', qty: 500, unit: 'g',
          tags: ['vorrat', 'nudeln']),
      _item(userId, 'Basmatireis', 'Nudeln & Getreide', qty: 1, unit: 'kg',
          tags: ['vorrat']),
      _item(userId, 'Haferflocken', 'Frühstück', qty: 500, unit: 'g',
          tags: ['vorrat', 'frühstück']),
      _item(userId, 'Olivenöl', 'Öle & Essig', qty: 500, unit: 'ml',
          tags: ['vorrat']),
      _item(userId, 'Tomaten (Dose)', 'Konserven', qty: 2, unit: 'Dose',
          tags: ['vorrat', 'konserve']),
      _item(userId, 'Kichererbsen (Dose)', 'Konserven', qty: 1, unit: 'Dose',
          tags: ['vorrat', 'konserve']),
      _item(userId, 'Tomatenmark', 'Konserven', qty: 3, unit: 'EL',
          tags: ['vorrat']),
      _item(userId, 'Gemüsebrühe', 'Gewürze & Soßen', qty: 1, unit: 'Liter',
          tags: ['vorrat']),
      _item(userId, 'Sojasauce', 'Gewürze & Soßen', qty: 150, unit: 'ml',
          tags: ['vorrat']),
      _item(userId, 'Mehl (405)', 'Backen', qty: 1, unit: 'kg',
          tags: ['vorrat', 'backen']),
      _item(userId, 'Zucker', 'Backen', qty: 500, unit: 'g',
          tags: ['vorrat', 'backen']),
      _item(userId, 'Backpulver', 'Backen', qty: 1, unit: 'Päckchen',
          tags: ['vorrat', 'backen']),
      // ── Tiefkühl ──
      _item(userId, 'Erbsen (TK)', 'Tiefkühl', qty: 450, unit: 'g',
          expiry: now.add(const Duration(days: 180)), tags: ['tiefkühl']),
      _item(userId, 'Blattspinat (TK)', 'Tiefkühl', qty: 450, unit: 'g',
          expiry: now.add(const Duration(days: 120)), tags: ['tiefkühl']),
      _item(userId, 'Hackfleisch (TK)', 'Fleisch & Fisch', qty: 500, unit: 'g',
          expiry: now.add(const Duration(days: 60)), tags: ['tiefkühl', 'fleisch']),
      // ── Getränke ──
      _item(userId, 'Mineralwasser', 'Getränke', qty: 6, unit: 'Flasche',
          tags: ['getränke']),
      _item(userId, 'Orangensaft', 'Getränke', qty: 1, unit: 'Liter',
          expiry: now.add(const Duration(days: 7)), tags: ['kühlschrank', 'getränke']),
    ];

    final notifier = ref.read(inventoryProvider.notifier);
    for (final item in items) {
      await notifier.addItem(item);
    }
  }

  /// Erstellt 2 typische Einkaufslisten mit Artikeln.
  static Future<void> seedShoppingLists(WidgetRef ref) async {
    final listsNotifier = ref.read(shoppingListsProvider.notifier);
    final itemsNotifier = ref.read(shoppingListProvider.notifier);

    // ── Liste 1: Wocheneinkauf Edeka ──
    await listsNotifier.createList('Wocheneinkauf', icon: 'shopping_cart');
    final weeklyItems = [
      'Vollmilch (2L)', 'Butter (250g)', 'Eier (10er)',
      'Hähnchenbrust (500g)', 'Hackfleisch (500g)',
      'Tomate (6 Stück)', 'Paprika (3 Stück)', 'Brokkoli',
      'Karotten (500g)', 'Zwiebeln (1kg)',
      'Spaghetti (500g)', 'Reis (1kg)',
      'Tomaten (Dose)', 'Kichererbsen (Dose)',
      'Olivenöl (500ml)', 'Joghurt (500g)',
      'Gouda (200g)', 'Brot (Vollkorn)',
      'Bananen', 'Äpfel (6 Stück)',
      'Orangensaft (1L)', 'Mineralwasser (6x1,5L)',
    ];
    for (final name in weeklyItems) {
      await itemsNotifier.addItem(name);
    }

    // ── Liste 2: Lidl – Schnelleinkauf ──
    await listsNotifier.createList('Schnelleinkauf Lidl', icon: 'store');
    final quickItems = [
      'Milch', 'Brot', 'Butter', 'Käse', 'Eier',
      'Nudeln', 'Tomatensoße',
      'Äpfel', 'Bananen',
      'Wasser (6er-Pack)',
    ];
    for (final name in quickItems) {
      await itemsNotifier.addItem(name);
    }
  }

  static InventoryItem _item(
    String userId,
    String name,
    String category, {
    double? qty,
    String? unit,
    DateTime? expiry,
    List<String> tags = const [],
  }) {
    return InventoryItem(
      id: '',
      userId: userId,
      ingredientId: name.toLowerCase().replaceAll(' ', '_'),
      ingredientName: name,
      ingredientCategory: category,
      quantity: qty,
      unit: unit,
      expiryDate: expiry,
      minThreshold: 0,
      tags: tags,
      createdAt: DateTime.now(),
    );
  }
}

