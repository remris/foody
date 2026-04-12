import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kokomu/features/household/presentation/household_provider.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/scanner/presentation/scanner_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/staple_items_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_templates_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_category.dart';
import 'package:kokomu/features/shopping_list/presentation/item_prices_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/transfer_to_inventory_sheet.dart';
import 'package:kokomu/features/shopping_list/presentation/smart_suggestions_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_stats_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_stats_sheet.dart';
import 'package:kokomu/widgets/main_shell.dart' show AppBarMoreButton;
import 'package:kokomu/core/services/shopping_list_ocr_service.dart';
import 'package:kokomu/core/data/ingredient_catalog.dart';
import 'package:kokomu/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomu/models/inventory_item.dart';
import 'package:kokomu/models/shopping_list.dart';
import 'package:kokomu/models/shopping_list_item.dart';
import 'package:kokomu/widgets/skeleton_loader.dart';
import 'package:kokomu/features/pantry/presentation/pantry_shopping_screen.dart' show PantryTabBar, pantryTabNotifier;

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() =>
      _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _controller = TextEditingController();
  bool _hideChecked = false;
  bool _groupedView = false;
  bool _shoppingMode = false;
  bool _showSuccessPulse = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    _controller.clear();
    HapticFeedback.lightImpact();
    final isNew = await ref.read(shoppingListProvider.notifier).addItem(name);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(isNew ? '✅ $name hinzugefügt' : '➕ $name – Menge erhöht'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  void _shareList(List<ShoppingListItem> items) {
    final selectedList = ref.read(selectedShoppingListProvider);
    final listName = selectedList?.name ?? 'Einkaufsliste';
    final unchecked = items.where((i) => !i.isChecked).toList();
    final checked = items.where((i) => i.isChecked).toList();

    final buffer = StringBuffer('🛒 $listName\n\n');
    for (final item in unchecked) {
      buffer.writeln('☐ ${item.name}${item.quantity != null ? ' (${item.quantity})' : ''}');
    }
    if (checked.isNotEmpty) {
      buffer.writeln('\n✅ Erledigt:');
      for (final item in checked) {
        buffer.writeln('☑ ${item.name}');
      }
    }
    buffer.writeln('\n— gesendet mit kokomu');

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  void _scanAndAddItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ScanToShoppingSheet(),
    ).then((productName) async {
      if (productName != null && productName is String && productName.isNotEmpty) {
        final isNew = await ref.read(shoppingListProvider.notifier).addItem(productName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew ? '✅ „$productName" hinzugefügt' : '➕ „$productName" – Menge erhöht'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  /// Foto-Import: Einkaufszettel fotografieren → OCR → Items auf die Liste
  Future<void> _scanPhotoToList() async {
    // Source wählen: Kamera oder Galerie
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Einkaufszettel scannen',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Fotografiere einen handgeschriebenen oder gedruckten Einkaufszettel',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    // Loading anzeigen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Text wird erkannt...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final items = await ShoppingListOcrService.scanShoppingList(source: source);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Artikel erkannt')),
        );
        return;
      }

      // Ergebnis-Sheet: User kann Items auswählen/abwählen
      final confirmed = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _PhotoOcrResultSheet(detectedItems: items),
      );

      if (confirmed != null && confirmed.isNotEmpty && mounted) {
        for (final name in confirmed) {
          ref.read(shoppingListProvider.notifier).addItem(name);
        }
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${confirmed.length} Artikel hinzugefügt')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  void _showTransferSheet(BuildContext context, List<ShoppingListItem> checked) {
    final selectedList = ref.read(selectedShoppingListProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TransferToInventorySheet(
        checkedItems: checked,
        sourceList: selectedList,
      ),
    );
  }

  void _showCreateListDialog() {
    final household = ref.read(householdProvider).valueOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreateListSheet(
        hasHousehold: household != null,
        householdName: household?.name,
        onConfirm: (name, shareWithHousehold) async {
          try {
            if (shareWithHousehold) {
              await ref
                  .read(shoppingListsProvider.notifier)
                  .createSharedList(name);
            } else {
              await ref
                  .read(shoppingListsProvider.notifier)
                  .createList(name);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fehler beim Erstellen: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showRenameDialog(ShoppingList list) {
    final nameController = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liste umbenennen'),
        content: TextField(
          controller: nameController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(shoppingListsProvider.notifier)
                    .renameList(list.id, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ShoppingList list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liste löschen?'),
        content: Text('"${list.name}" und alle Artikel darin werden gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(shoppingListsProvider.notifier).deleteList(list.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(List<ShoppingListItem> items) {
    // Items nach Kategorie gruppieren
    final grouped = <ShoppingCategory, List<ShoppingListItem>>{};
    for (final item in items) {
      final cat = ShoppingCategory.categorize(item.name);
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    // Nach Sortierreihenfolge sortieren
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => a.key.sortOrder.compareTo(b.key.sortOrder));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: sortedEntries.length,
      itemBuilder: (context, sectionIndex) {
        final entry = sortedEntries[sectionIndex];
        final category = entry.key;
        final categoryItems = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${categoryItems.length})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            ...categoryItems.map(
              (item) => _ShoppingItem(
                key: Key(item.id),
                item: item,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStapleItemsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _StapleItemsSheet(),
    );
  }

  void _showSaveTemplateDialog() {
    final items = ref.read(shoppingListProvider).valueOrNull ?? [];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste ist leer – nichts zu speichern.')),
      );
      return;
    }
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Als Vorlage speichern'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'z.B. Wocheneinkauf Basis',
            prefixIcon: Icon(Icons.label_outline),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final itemNames = items.map((i) => i.name).toList();
              ref
                  .read(shoppingTemplatesProvider.notifier)
                  .saveTemplate(name, itemNames);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Vorlage "$name" gespeichert ✅')),
              );
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  void _showLoadTemplateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _TemplateLoadSheet(),
    );
  }

  Future<void> _completeList(List<ShoppingListItem> items) async {
    final checked = items.where((e) => e.isChecked).toList();
    final unchecked = items.where((e) => !e.isChecked).toList();

    final result = await showModalBottomSheet<_CompleteAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CompleteListSheet(
        totalItems: items.length,
        checkedCount: checked.length,
        uncheckedCount: unchecked.length,
      ),
    );

    if (result == null || !mounted) return;

    if (result == _CompleteAction.transferAndClear) {
      // Direkt ins Inventar übernehmen – KEIN zweites Sheet öffnen
      if (checked.isNotEmpty) {
        await _transferToInventoryDirect(checked);
      }
      // Gesamte Liste leeren
      await ref.read(shoppingListProvider.notifier).clearAll();
      if (mounted) setState(() => _shoppingMode = false);
      return;
    }

    if (result == _CompleteAction.transfer) {
      // Sheet öffnen (user will selbst wählen was übernommen wird)
      if (checked.isNotEmpty && mounted) {
        _showTransferSheet(context, checked);
      }
      if (mounted) setState(() => _shoppingMode = false);
      return;
    }

    if (result == _CompleteAction.clearAll) {
      await ref.read(shoppingListProvider.notifier).clearAll();
      if (mounted) setState(() => _shoppingMode = false);
    }
  }

  /// Überträgt Items direkt ins Inventar ohne zweites Sheet.
  Future<void> _transferToInventoryDirect(List<ShoppingListItem> items) async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final household = ref.read(householdProvider).valueOrNull;
    final selectedList = ref.read(selectedShoppingListProvider);

    // householdId: Haushaltsliste → Haushalt-Vorrat; User in Haushalt → Haushalt-Vorrat
    String? householdId;
    if (selectedList?.householdId != null) {
      householdId = selectedList!.householdId;
    } else if (household != null) {
      householdId = household.id;
    }

    for (final shopItem in items) {
      final inventoryItem = InventoryItem(
        id: '',
        userId: userId,
        householdId: householdId,
        ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
        ingredientName: shopItem.name,
        quantity: _parseQuantityValue(shopItem.quantity),
        unit: _parseQuantityUnit(shopItem.quantity),
        createdAt: DateTime.now(),
      );
      await ref.read(inventoryProvider.notifier).addItem(inventoryItem);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${items.length} Artikel ins ${householdId != null ? 'Haushalt-' : ''}Inventar übernommen ✅',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Parst "100 g" → 100.0, "2 Stück" → 2.0, "100 gramm" → 100.0
  double? _parseQuantityValue(String? qty) {
    if (qty == null || qty.isEmpty) return null;
    final match = RegExp(r'^\s*([\d.,]+)').firstMatch(qty);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  /// Parst "100 g" → "g", "2 Stück" → "Stück", "100" → null
  String? _parseQuantityUnit(String? qty) {
    if (qty == null || qty.isEmpty) return null;
    final match = RegExp(r'^\s*[\d.,]+\s*(.*)$').firstMatch(qty);
    final unit = match?.group(1)?.trim();
    return (unit != null && unit.isNotEmpty) ? unit : null;
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(shoppingListsProvider);
    final selectedList = ref.watch(selectedShoppingListProvider);
    final itemsAsync = ref.watch(shoppingListProvider);
    final theme = Theme.of(context);

    // Grüner Pulse wenn alle Items abgehakt
    ref.listen(shoppingListProvider, (prev, next) {
      final prevItems = prev?.valueOrNull;
      final nextItems = next.valueOrNull;
      if (nextItems != null &&
          nextItems.isNotEmpty &&
          nextItems.every((i) => i.isChecked) &&
          prevItems != null &&
          !prevItems.every((i) => i.isChecked)) {
        HapticFeedback.heavyImpact();
        setState(() => _showSuccessPulse = true);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _showSuccessPulse = false);
        });
      }
    });

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: _shoppingMode
            ? Row(children: [
                const Icon(Icons.shopping_cart_rounded, size: 20),
                const SizedBox(width: 8),
                const Text('Einkaufsmodus'),
              ])
            : const Text('Einkaufsliste'),
        backgroundColor:
            _shoppingMode ? Theme.of(context).colorScheme.primaryContainer : null,
        bottom: _shoppingMode
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(kTextTabBarHeight),
                child: ValueListenableBuilder<int>(
                  valueListenable: pantryTabNotifier,
                  builder: (_, tab, __) => PantryTabBar(currentTab: tab),
                ),
              ),
        actions: [
          // Einkaufsmodus Toggle
          IconButton(
            icon: Icon(_shoppingMode
                ? Icons.close_rounded
                : Icons.shopping_cart_checkout_rounded),
            tooltip: _shoppingMode ? 'Einkaufsmodus beenden' : 'Einkaufsmodus',
            onPressed: () => setState(() => _shoppingMode = !_shoppingMode),
          ),
          if (!_shoppingMode) ...[
            // Erledigte ein-/ausblenden (bleibt direkt sichtbar – oft benötigt)
            itemsAsync.whenOrNull(
                  data: (items) => items.any((e) => e.isChecked)
                      ? IconButton(
                          icon: Icon(_hideChecked
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          tooltip: _hideChecked
                              ? 'Erledigte anzeigen'
                              : 'Erledigte ausblenden',
                          onPressed: () =>
                              setState(() => _hideChecked = !_hideChecked),
                        )
                      : null,
                ) ??
                const SizedBox.shrink(),
            // Gruppenansicht
            IconButton(
              icon: Icon(_groupedView
                  ? Icons.view_list_rounded
                  : Icons.category_rounded),
              tooltip: _groupedView ? 'Normale Ansicht' : 'Nach Kategorie',
              onPressed: () => setState(() => _groupedView = !_groupedView),
            ),
            // Neue Liste erstellen
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Neue Liste',
              onPressed: _showCreateListDialog,
            ),
            // Alles weitere ins Dot-Menü
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                switch (action) {
                  case 'share':
                    itemsAsync.whenData((items) => _shareList(items));
                  case 'transfer':
                    itemsAsync.whenData((items) {
                      final checked = items.where((e) => e.isChecked).toList();
                      if (checked.isNotEmpty) _showTransferSheet(context, checked);
                    });
                  case 'clear_checked':
                    ref.read(shoppingListProvider.notifier).clearChecked();
                  case 'template_save':
                    _showSaveTemplateDialog();
                  case 'template_load':
                    _showLoadTemplateSheet();
                  case 'stats':
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => const ShoppingStatsSheet(),
                    );
                }
              },
              itemBuilder: (_) {
                final items = itemsAsync.valueOrNull ?? [];
                final hasChecked = items.any((e) => e.isChecked);
                return [
                  PopupMenuItem(
                    value: 'share',
                    enabled: items.isNotEmpty,
                    child: const ListTile(
                      leading: Icon(Icons.share_rounded),
                      title: Text('Liste teilen'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'transfer',
                    enabled: hasChecked,
                    child: ListTile(
                      leading: Icon(Icons.move_to_inbox_rounded,
                          color: hasChecked ? null : Colors.grey),
                      title: Text('Ins Inventar übernehmen',
                          style: TextStyle(color: hasChecked ? null : Colors.grey)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_checked',
                    enabled: hasChecked,
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep,
                          color: hasChecked ? Colors.red : Colors.grey),
                      title: Text('Erledigte löschen',
                          style: TextStyle(
                              color: hasChecked ? Colors.red : Colors.grey)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'template_save',
                    child: ListTile(
                      leading: Icon(Icons.save_outlined),
                      title: Text('Als Vorlage speichern'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'template_load',
                    child: ListTile(
                      leading: Icon(Icons.file_open_outlined),
                      title: Text('Vorlage laden'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'stats',
                    child: ListTile(
                      leading: Icon(Icons.bar_chart_rounded),
                      title: Text('Statistiken'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ];
              },
            ),
            const AppBarMoreButton(),
          ], // Ende !_shoppingMode
        ],
      ),
      body: _shoppingMode
          ? _ShoppingModeBody(
              itemsAsync: itemsAsync,
              onComplete: () => itemsAsync.whenData(
                  (items) => _completeList(items)),
            )
          : Column(
        children: [
          // Listen-Tabs
          listsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (lists) => lists.isEmpty
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    child: Row(
                      children: lists.map((list) {
                        final isSelected = selectedList?.id == list.id;
                        final isOwn = list.userId ==
                            ref.read(currentUserProvider)?.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onLongPress: () => _showListOptions(list),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(list.name),
                                  if (list.isShared) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.group,
                                      size: 13,
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                    ),
                                  ],
                                  if (!isOwn) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.person_outline,
                                      size: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ],
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) => ref
                                  .read(
                                      selectedShoppingListProvider.notifier)
                                  .state = list,
                              avatar: isSelected
                                  ? null
                                  : Icon(_iconForList(list.icon),
                                      size: 16),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          // 🤖 Intelligente Einkaufsvorschläge
          Consumer(
            builder: (context, ref, _) {
              final currentItems = ref.watch(shoppingListProvider).valueOrNull ?? [];
              final currentNames = currentItems.map((i) => i.name).toList();
              final suggestionsAsync = ref.watch(smartSuggestionsProvider(currentNames));
              return suggestionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (suggestions) {
                  if (suggestions.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 14,
                                color: Theme.of(context).colorScheme.tertiary),
                            const SizedBox(width: 4),
                            Text(
                              'Vorschläge',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: suggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Tooltip(
                              message: s.reason,
                              child: ActionChip(
                                avatar: const Icon(Icons.add, size: 14),
                                label: Text(s.name),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer
                                    .withOpacity(0.5),
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  final isNew = await ref
                                      .read(shoppingListProvider.notifier)
                                      .addItem(s.name);
                                  SmartSuggestionsService.recordPurchase(s.name);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..clearSnackBars()
                                      ..showSnackBar(SnackBar(
                                        content: Text(isNew
                                            ? '✅ ${s.name} hinzugefügt'
                                            : '➕ ${s.name} – Menge erhöht'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                  }
                                },
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  );
                },
              );
            },
          ),
          // Eingabe-Feld
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final inventoryNames = (ref.watch(inventoryProvider).valueOrNull ?? [])
                          .map((i) => i.ingredientName)
                          .toSet();
                      final stapleNames = ref.watch(stapleItemsProvider)
                          .map((s) => s)
                          .toSet();
                      final allSuggestions = {...inventoryNames, ...stapleNames}.toList()
                        ..sort();

                      return Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.length < 2) return [];
                          final query = textEditingValue.text.toLowerCase();
                          // Vorrat + Stammartikel zuerst
                          final localMatches = allSuggestions
                              .where((s) => s.toLowerCase().contains(query))
                              .take(4)
                              .toList();
                          // Katalog-Ergänzungen
                          final catalogMatches = IngredientCatalog.search(query, maxResults: 6)
                              .map((e) => e.name)
                              .where((n) => !localMatches.map((s) => s.toLowerCase()).contains(n.toLowerCase()))
                              .take(6 - localMatches.length)
                              .toList();
                          return [...localMatches, ...catalogMatches];
                        },
                        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                          _controller.addListener(() {
                            if (controller.text != _controller.text) {
                              controller.text = _controller.text;
                            }
                          });
                          controller.addListener(() {
                            if (_controller.text != controller.text) {
                              _controller.text = controller.text;
                            }
                          });
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Artikel hinzufügen...',
                              prefixIcon: const Icon(Icons.add_shopping_cart),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.star_outline, size: 20),
                                tooltip: 'Stammartikel verwalten',
                                onPressed: () => _showStapleItemsSheet(context),
                              ),
                            ),
                            onSubmitted: (_) {
                              _addItem();
                              controller.clear();
                            },
                            textInputAction: TextInputAction.done,
                          );
                        },
                        onSelected: (selection) {
                          _controller.text = selection;
                          _addItem();
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    final isLocal = inventoryNames.contains(option) || stapleNames.contains(option);
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        isLocal
                                            ? (inventoryNames.contains(option) ? Icons.kitchen : Icons.star_outline)
                                            : Icons.search,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      title: Text(option, style: const TextStyle(fontSize: 14)),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                // Barcode-Scan
                IconButton.filled(
                  onPressed: _scanAndAddItem,
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  tooltip: 'Barcode scannen',
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                // Foto-Scan
                IconButton.filledTonal(
                  onPressed: _scanPhotoToList,
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                  tooltip: 'Zettel fotografieren',
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                // Hinzufügen
                IconButton.filled(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Hinzufügen',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: itemsAsync.when(
              loading: () => SkeletonList(
                count: 4,
                builder: () => const ShoppingSkeletonCard(),
              ),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (items) {
                final visibleItems = _hideChecked
                    ? items.where((i) => !i.isChecked).toList()
                    : items;
                if (visibleItems.isEmpty) return const _EmptyShoppingList();

                // Gruppierte Ansicht
                if (_groupedView) {
                  return _buildGroupedList(visibleItems);
                }

                return ReorderableListView.builder(
                  itemCount: visibleItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      ),
                      child: child,
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    HapticFeedback.selectionClick();
                    // ReorderableListView gibt newIndex nach dem Entfernen
                    if (newIndex > oldIndex) newIndex--;
                    ref
                        .read(shoppingListProvider.notifier)
                        .reorderItems(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) => _ShoppingItem(
                    key: Key(visibleItems[index].id),
                    item: visibleItems[index],
                  ),
                );
              },
            ),
          ),
          // ── Prominenter "In Vorrat übernehmen"-Banner ──────────────────
          itemsAsync.whenOrNull(
            data: (items) {
              final checked = items.where((e) => e.isChecked).toList();
              if (checked.isEmpty) return null;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: const ValueKey('transfer_banner'),
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.95),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: SafeArea(
                    top: false,
                    child: FilledButton.icon(
                      onPressed: () => _showTransferSheet(context, checked),
                      icon: const Icon(Icons.move_to_inbox_rounded),
                      label: Text(
                        '${checked.length} ${checked.length == 1 ? 'Artikel' : 'Artikel'} in Vorrat übernehmen',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),
          // Gesamtpreis-Leiste
          Consumer(
            builder: (context, ref, _) {
              final prices = ref.watch(itemPricesProvider);
              final currentItems = ref.watch(shoppingListProvider).valueOrNull ?? [];
              // Nur anzeigen wenn Liste Items hat UND Preise für diese Items gespeichert sind
              if (prices.isEmpty || currentItems.isEmpty) return const SizedBox.shrink();
              // Nur Preise der aktuellen Items
              final currentNames = currentItems.map((i) => i.name).toSet();
              final relevantPrices = {
                for (final e in prices.entries)
                  if (currentNames.contains(e.key)) e.key: e.value
              };
              if (relevantPrices.isEmpty) return const SizedBox.shrink();
              final total = relevantPrices.values.fold(0.0, (s, p) => s + p);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Geschätzt (${relevantPrices.length} Artikel)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '~ ${total.toStringAsFixed(2)} €',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ), // Ende Column (normal mode)
    ),
        // Grüner Erfolgs-Pulse
        if (_showSuccessPulse)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showSuccessPulse ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.green.withValues(alpha: 0.15),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 72),
                      SizedBox(height: 12),
                      Text(
                        'Einkauf abgeschlossen! 🎉',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showListOptions(ShoppingList list) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final household = ref.read(householdProvider).valueOrNull;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Haushalt-Sharing-Status
              if (list.isShared)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group, size: 16,
                          color: Theme.of(context).colorScheme.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Mit Haushalt geteilt',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Umbenennen'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameDialog(list);
                },
              ),
              // Teilen / Nicht teilen
              if (household != null) ...[
                if (!list.isShared)
                  ListTile(
                    leading: Icon(Icons.group_add,
                        color: Theme.of(context).colorScheme.primary),
                    title: const Text('Mit Haushalt teilen'),
                    subtitle: Text('Alle in „${household.name}" können diese Liste sehen'),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref
                          .read(shoppingListsProvider.notifier)
                          .shareWithHousehold(list.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.group, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('„${list.name}" wird mit deinem Haushalt geteilt'),
                          ]),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      );
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.group_remove),
                    title: const Text('Nicht mehr teilen'),
                    subtitle: const Text('Liste wird wieder privat'),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref
                          .read(shoppingListsProvider.notifier)
                          .unshare(list.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Liste ist jetzt wieder privat')),
                      );
                    },
                  ),
              ],
              // Löschen nur wenn eigene Liste
              if (list.userId == ref.read(currentUserProvider)?.id)
                ListTile(
                  leading: Icon(Icons.delete,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('Löschen',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirmation(list);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForList(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'store':
        return Icons.store;
      case 'hardware':
        return Icons.hardware;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.list_alt;
    }
  }
}

class _EmptyShoppingList extends StatelessWidget {
  const _EmptyShoppingList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Einkaufsliste ist leer',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Füge oben Artikel hinzu!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingItem extends ConsumerStatefulWidget {
  final ShoppingListItem item;
  const _ShoppingItem({super.key, required this.item});

  @override
  ConsumerState<_ShoppingItem> createState() => _ShoppingItemState();
}

class _ShoppingItemState extends ConsumerState<_ShoppingItem> {
  ShoppingListItem get item => widget.item;

  // Nur für Preis-Dialog noch benötigt
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prices = ref.watch(itemPricesProvider);
    final price = prices[item.id];
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(shoppingListProvider.notifier).deleteItem(item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () => _showEditDialog(context),
          child: CheckboxListTile(
            title: Text(
              item.name,
              style: TextStyle(
                decoration:
                    item.isChecked ? TextDecoration.lineThrough : null,
                color: item.isChecked
                    ? theme.colorScheme.outline
                    : null,
              ),
            ),
            // Wrap statt Row verhindert overflow
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  // Menge-Badge
                  GestureDetector(
                    onTap: () => _showEditDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.quantity != null
                            ? theme.colorScheme.secondaryContainer
                                .withValues(alpha: 0.7)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.scale_outlined,
                            size: 11,
                            color: item.quantity != null
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.quantity ?? '+ Menge',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: item.quantity != null
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: item.quantity != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Preis-Badge
                  GestureDetector(
                    onTap: () => _showPriceDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: price != null
                            ? theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.5)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.euro_rounded,
                            size: 11,
                            color: price != null
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            price != null
                                ? price.toStringAsFixed(2)
                                : 'Preis',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: price != null
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            value: item.isChecked,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              ref
                  .read(shoppingListProvider.notifier)
                  .toggleChecked(item.id, val ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => _EditItemDialog(
        item: item,
        onSave: (updatedItem) {
          ref.read(shoppingListProvider.notifier).updateItem(updatedItem);
        },
      ),
    );
  }

  void _showPriceDialog(BuildContext context) {
    final currentPrice = ref.read(itemPricesProvider)[item.id];
    _priceCtrl.text = currentPrice?.toStringAsFixed(2) ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Preis für ${item.name}'),
        content: TextField(
          controller: _priceCtrl,
          decoration: const InputDecoration(
            hintText: '0.00',
            suffixText: '€',
            prefixIcon: Icon(Icons.euro),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          onSubmitted: (val) {
            final price = double.tryParse(val.replaceAll(',', '.'));
            ref.read(itemPricesProvider.notifier).setPrice(item.id, price);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          if (currentPrice != null)
            TextButton(
              onPressed: () {
                ref.read(itemPricesProvider.notifier).setPrice(item.id, null);
                Navigator.pop(ctx);
              },
              child: const Text('Entfernen'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(
                  _priceCtrl.text.replaceAll(',', '.'));
              ref.read(itemPricesProvider.notifier).setPrice(item.id, price);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Dialog zum Bearbeiten eines Einkaufslisten-Items:
/// Name-Feld + Zahlen-Mengenfeld + Einheiten-Dropdown
class _EditItemDialog extends StatefulWidget {
  final ShoppingListItem item;
  final void Function(ShoppingListItem updated) onSave;
  const _EditItemDialog({required this.item, required this.onSave});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  static const _units = ['Stück', 'g', 'kg', 'ml', 'l', 'EL', 'TL', 'Pck.', 'Dose', 'Flasche'];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    // Menge in Zahl + Einheit aufteilen
    final qty = widget.item.quantity ?? '';
    final parts = qty.trim().split(RegExp(r'\s+'));
    final num = parts.isNotEmpty ? parts.first : '';
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : 'Stück';
    _amountCtrl = TextEditingController(text: num);
    _selectedUnit = _units.contains(unit) ? unit : 'Stück';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Artikel bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Zahlen-Mengenfeld
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Menge',
                    prefixIcon: Icon(Icons.numbers_rounded),
                    hintText: '1',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
              ),
              const SizedBox(width: 8),
              // Einheiten-Dropdown
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Einheit',
                    prefixIcon: Icon(Icons.straighten_rounded),
                  ),
                  items: _units.map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v ?? 'Stück'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final amount = _amountCtrl.text.trim();
            final qty = amount.isEmpty
                ? null
                : '$amount $_selectedUnit'.trim();
            widget.onSave(widget.item.copyWith(name: name, quantity: qty));
            Navigator.pop(context);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

class _ScanToShoppingSheet extends ConsumerStatefulWidget {
  const _ScanToShoppingSheet();

  @override
  ConsumerState<_ScanToShoppingSheet> createState() =>
      _ScanToShoppingSheetState();
}

class _ScanToShoppingSheetState extends ConsumerState<_ScanToShoppingSheet> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _processing = false;
  String? _lastBarcode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || _processing || barcode == _lastBarcode) return;

    setState(() {
      _processing = true;
      _lastBarcode = barcode;
    });

    // Barcode über Scanner-Provider nachschlagen
    await ref.read(scannerProvider.notifier).scanBarcode(barcode);
    final state = ref.read(scannerProvider);

    if (state.ingredient != null) {
      // Produkt gefunden → Name zurückgeben und schließen
      if (mounted) {
        Navigator.of(context).pop(state.ingredient!.name);
      }
    } else {
      // Nicht gefunden → Barcode-String als Fallback anbieten
      if (mounted) {
        final useBarcode = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Produkt nicht gefunden'),
            content: Text(
              'Der Barcode „$barcode" wurde nicht erkannt.\nMöchtest du den Barcode als Artikelname verwenden?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Erneut scannen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Übernehmen'),
              ),
            ],
          ),
        );
        if (useBarcode == true && mounted) {
          Navigator.of(context).pop(barcode);
        } else {
          setState(() {
            _processing = false;
            _lastBarcode = null;
          });
        }
      }
    }

    ref.read(scannerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Artikel per Barcode hinzufügen',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                ),
                // Scan-Rahmen
                Center(
                  child: Container(
                    width: 260,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Loading
                if (_processing)
                  Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                // Hinweis unten
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Barcode in den Rahmen halten',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Abbrechen'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet zum Verwalten der Stammartikel.
class _StapleItemsSheet extends ConsumerStatefulWidget {
  const _StapleItemsSheet();

  @override
  ConsumerState<_StapleItemsSheet> createState() => _StapleItemsSheetState();
}

class _StapleItemsSheetState extends ConsumerState<_StapleItemsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addStaple() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    ref.read(stapleItemsProvider.notifier).addItem(name);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staples = ref.watch(stapleItemsProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Stammartikel',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Artikel die du regelmäßig kaufst. Tippe auf einen Chip um ihn schnell zur Liste hinzuzufügen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Eingabe
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Neuer Stammartikel...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addStaple(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addStaple,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Liste
            Flexible(
              child: staples.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Noch keine Stammartikel.\nFüge z.B. Milch, Brot oder Eier hinzu!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: staples.length,
                      itemBuilder: (context, index) {
                        final name = staples[index];
                        return ListTile(
                          leading: const Icon(Icons.star_outline, size: 20),
                          title: Text(name),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 20,
                                color: theme.colorScheme.error),
                            onPressed: () => ref
                                .read(stapleItemsProvider.notifier)
                                .removeItem(name),
                          ),
                          dense: true,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom Sheet zum Laden von Einkaufslisten-Vorlagen.
class _TemplateLoadSheet extends ConsumerWidget {
  const _TemplateLoadSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(shoppingTemplatesProvider);
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.file_copy_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Vorlagen',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Wähle eine Vorlage um alle Artikel auf die aktive Liste zu setzen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: templates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Noch keine Vorlagen gespeichert.\n\nSpeichere deine aktuelle Liste als Vorlage über das Menü oben.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(Icons.list_alt,
                                  color: theme.colorScheme.onPrimaryContainer),
                            ),
                            title: Text(template.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${template.items.length} Artikel: ${template.items.take(3).join(", ")}${template.items.length > 3 ? "…" : ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20,
                                  color: theme.colorScheme.error),
                              onPressed: () {
                                ref
                                    .read(shoppingTemplatesProvider.notifier)
                                    .deleteTemplate(template.id);
                              },
                            ),
                            onTap: () {
                              // Alle Artikel der Vorlage hinzufügen
                              for (final item in template.items) {
                                ref
                                    .read(shoppingListProvider.notifier)
                                    .addItem(item);
                              }
                              Navigator.of(context).pop();
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${template.items.length} Artikel aus "${template.name}" hinzugefügt ✅',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Sheet: Neue Einkaufsliste erstellen
// ─────────────────────────────────────────────
class _CreateListSheet extends StatefulWidget {
  final bool hasHousehold;
  final String? householdName;
  final void Function(String name, bool shareWithHousehold) onConfirm;

  const _CreateListSheet({
    required this.hasHousehold,
    required this.householdName,
    required this.onConfirm,
  });

  @override
  State<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends State<_CreateListSheet> {
  final _controller = TextEditingController();
  late bool _shareWithHousehold;
  String? _selectedMarket;

  @override
  void initState() {
    super.initState();
    // Wenn User in Haushalt ist → Switch standardmäßig an
    _shareWithHousehold = widget.hasHousehold;
  }

  static const _markets = [
    '🟢 Rewe', '🔵 Edeka', '🟡 Lidl', '🟠 Aldi',
    '🔴 Penny', '🟣 Kaufland', '⚪ dm', '🟤 Rossmann',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Neue Einkaufsliste',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name der Liste',
              hintText: 'z.B. Kaufland, Wocheneinkauf...',
              prefixIcon: Icon(Icons.list_alt),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          Text('Supermarkt (optional)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _markets.map((market) {
              final isSelected = _selectedMarket == market;
              return ChoiceChip(
                label: Text(market, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                visualDensity: VisualDensity.compact,
                onSelected: (selected) {
                  setState(() {
                    _selectedMarket = selected ? market : null;
                    if (selected && _controller.text.isEmpty) {
                      // Auto-fill name with market name
                      _controller.text = market.replaceAll(RegExp(r'[^\w\sÀ-ÿ]'), '').trim();
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (widget.hasHousehold) ...[
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _shareWithHousehold
                    ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.6)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _shareWithHousehold
                      ? theme.colorScheme.secondary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: SwitchListTile(
                value: _shareWithHousehold,
                onChanged: (v) => setState(() => _shareWithHousehold = v),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                secondary: Icon(
                  _shareWithHousehold ? Icons.group : Icons.lock_outline,
                  color: _shareWithHousehold
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  _shareWithHousehold ? 'Mit Haushalt geteilt' : 'Nur für mich (privat)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _shareWithHousehold
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  _shareWithHousehold
                      ? 'Alle in „${widget.householdName}" können diese Liste sehen und bearbeiten'
                      : 'Nur du siehst diese Liste',
                  style: TextStyle(
                    fontSize: 12,
                    color: _shareWithHousehold
                        ? theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    final name = _controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(context);
                    widget.onConfirm(name, _shareWithHousehold);
                  },
                  icon: Icon(_shareWithHousehold ? Icons.group_add : Icons.add),
                  label: Text(_shareWithHousehold
                      ? 'Geteilte Liste erstellen'
                      : 'Liste erstellen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sheet zur Bestätigung der per Foto erkannten Einkaufsartikel.
class _PhotoOcrResultSheet extends StatefulWidget {
  final List<String> detectedItems;
  const _PhotoOcrResultSheet({required this.detectedItems});

  @override
  State<_PhotoOcrResultSheet> createState() => _PhotoOcrResultSheetState();
}

class _PhotoOcrResultSheetState extends State<_PhotoOcrResultSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.detectedItems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📸 Erkannte Artikel',
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                      Text(
                        '${_selected.length} von ${widget.detectedItems.length} ausgewählt',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    if (_selected.length == widget.detectedItems.length) {
                      _selected.clear();
                    } else {
                      _selected.addAll(widget.detectedItems);
                    }
                  }),
                  child: Text(
                    _selected.length == widget.detectedItems.length
                        ? 'Keine' : 'Alle',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.detectedItems.length,
                itemBuilder: (context, index) {
                  final item = widget.detectedItems[index];
                  final isSelected = _selected.contains(item);
                  return CheckboxListTile(
                    dense: true,
                    value: isSelected,
                    title: Text(item, style: const TextStyle(fontSize: 14)),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) => setState(() {
                      if (val == true) {
                        _selected.add(item);
                      } else {
                        _selected.remove(item);
                      }
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, _selected.toList()),
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('${_selected.length} Artikel hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Einkaufsmodus-Body ───────────────────────────────────────────────────────

enum _CompleteAction { transfer, clearAll, transferAndClear }

class _ShoppingModeBody extends ConsumerStatefulWidget {
  final AsyncValue itemsAsync;
  final VoidCallback onComplete;

  const _ShoppingModeBody({
    required this.itemsAsync,
    required this.onComplete,
  });

  @override
  ConsumerState<_ShoppingModeBody> createState() => _ShoppingModeBodyState();
}

class _ShoppingModeBodyState extends ConsumerState<_ShoppingModeBody> {
  bool _grouped = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return widget.itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (rawItems) {
        final items = rawItems as List<ShoppingListItem>;
        final unchecked = items.where((i) => !i.isChecked).toList();
        final checked = items.where((i) => i.isChecked).toList();
        final progress = items.isEmpty ? 0.0 : checked.length / items.length;

        return Column(
          children: [
            // Fortschrittsleiste
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${checked.length} von ${items.length} erledigt',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Kategorie-Toggle
                          IconButton(
                            icon: Icon(
                              _grouped
                                  ? Icons.view_list_rounded
                                  : Icons.category_rounded,
                              size: 20,
                            ),
                            tooltip: _grouped
                                ? 'Normale Ansicht'
                                : 'Nach Kategorie',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _grouped = !_grouped),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            // Liste
            Expanded(
              child: _grouped
                  ? _buildGroupedShoppingMode(context, theme, unchecked, checked)
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      children: [
                        if (unchecked.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                            child: Text(
                              'Noch zu kaufen (${unchecked.length})',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ...unchecked.map(
                              (item) => _ShoppingModeItem(item: item)),
                        ],
                        if (checked.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 16,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Im Korb (${checked.length})',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...checked
                              .map((item) => _ShoppingModeItem(item: item)),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
            // Bottom-Bar: Abschließen
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    onPressed: items.isNotEmpty ? widget.onComplete : null,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'Einkauf abschließen',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupedShoppingMode(
    BuildContext context,
    ThemeData theme,
    List<ShoppingListItem> unchecked,
    List<ShoppingListItem> checked,
  ) {
    // Kategorie-Zuordnung aus shopping_category.dart nutzen
    final Map<String, List<ShoppingListItem>> groups = {};
    for (final item in unchecked) {
      final cat = ShoppingCategory.categorize(item.name).name;
      groups.putIfAbsent(cat, () => []).add(item);
    }
    final sortedCats = groups.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        ...sortedCats.map((cat) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                  child: Text(
                    cat,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...groups[cat]!.map((item) => _ShoppingModeItem(item: item)),
              ],
            )),
        if (checked.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Im Korb (${checked.length})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...checked.map((item) => _ShoppingModeItem(item: item)),
        ],
        const SizedBox(height: 100),
      ],
    );
  }
}

class _ShoppingModeItem extends ConsumerWidget {
  final ShoppingListItem item;

  const _ShoppingModeItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isChecked = item.isChecked;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isChecked
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isChecked
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          ref
              .read(shoppingListProvider.notifier)
              .toggleChecked(item.id, !isChecked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  border: isChecked
                      ? null
                      : Border.all(
                          color: theme.colorScheme.outline,
                          width: 2,
                        ),
                ),
                child: isChecked
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        color: isChecked
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    if (item.quantity != null && item.quantity!.isNotEmpty)
                      Text(
                        item.quantity!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (isChecked)
                Icon(Icons.shopping_cart_rounded,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteListSheet extends StatelessWidget {
  final int totalItems;
  final int checkedCount;
  final int uncheckedCount;

  const _CompleteListSheet({
    required this.totalItems,
    required this.checkedCount,
    required this.uncheckedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDone = uncheckedCount == 0;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              allDone
                  ? Icons.celebration_rounded
                  : Icons.shopping_cart_checkout_rounded,
              size: 48,
              color: allDone ? Colors.amber : theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              allDone ? 'Alles erledigt! 🎉' : 'Einkauf abschließen',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              allDone
                  ? '$checkedCount Artikel im Korb. Möchtest du sie in deinen Vorrat übernehmen?'
                  : '$checkedCount von $totalItems Artikeln erledigt.\nNoch $uncheckedCount offen.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (checkedCount > 0) ...[
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _CompleteAction.transferAndClear),
                icon: const Icon(Icons.move_to_inbox_rounded),
                label: Text(
                    'In Vorrat übernehmen & leeren ($checkedCount)'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _CompleteAction.transfer),
                icon: const Icon(Icons.move_to_inbox_outlined),
                label: Text('Nur in Vorrat übernehmen ($checkedCount)'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pop(context, _CompleteAction.clearAll),
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.red),
              label: const Text('Liste komplett leeren',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      ),
    );
  }
}
