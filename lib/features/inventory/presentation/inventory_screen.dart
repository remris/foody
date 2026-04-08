import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kokomi/core/utils/extensions.dart';
import 'package:kokomi/core/constants/food_categories.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/features/household/presentation/household_provider.dart';
import 'package:kokomi/features/inventory/presentation/add_inventory_item_sheet.dart';
import 'package:kokomi/features/inventory/presentation/fridge_scan_sheet.dart';
import 'package:kokomi/features/recipes/presentation/ingredient_selection_sheet.dart';
import 'package:kokomi/features/inventory/presentation/inventory_stats_card.dart';
import 'package:kokomi/models/inventory_item.dart';
import 'package:kokomi/widgets/skeleton_loader.dart';
import 'package:kokomi/widgets/nutri_score_badge.dart';
import 'package:kokomi/widgets/main_shell.dart' show AppBarMoreButton;
import 'package:kokomi/features/pantry/presentation/pantry_shopping_screen.dart' show PantryTabBar, pantryTabNotifier;

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Sheet öffnen → Zutaten auswählen → zum Rezepte-Tab navigieren
  Future<void> _openRecipeGenerator() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const IngredientSelectionSheet(),
    );
    if (result != null && mounted) {
      final ingredients = result['ingredients'] as List<String>;
      context.push('/ai-recipes', extra: ingredients);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final items = ref.watch(sortedInventoryProvider);
    final allItems = ref.watch(inventoryProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider);
    final selectedCategories = ref.watch(selectedCategoriesProvider);
    final sortMode = ref.watch(inventorySortModeProvider);
    final selectedZone = ref.watch(storageZoneProvider);
    final showLeftovers = ref.watch(inventoryShowLeftoversProvider);
    // Scope direkt watchen damit der Screen bei Änderung rebuildet
    ref.watch(inventoryScopeProvider);
    final theme = Theme.of(context);

    // Artikel mit MHD (für bedingte StatsCard-Anzeige)
    final itemsWithExpiry = allItems.where((i) => i.expiryDate != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Vorrat durchsuchen...',
                  border: InputBorder.none,
                ),
                onChanged: (val) =>
                    ref.read(inventorySearchProvider.notifier).state = val,
              )
            : const Text('Mein Vorrat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: ValueListenableBuilder<int>(
            valueListenable: pantryTabNotifier,
            builder: (_, tab, __) => PantryTabBar(currentTab: tab),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                ref.read(inventorySearchProvider.notifier).state = '';
              }
            },
          ),
          IconButton(
            icon: Icon(
              sortMode == InventorySortMode.category
                  ? Icons.view_list_rounded
                  : Icons.category_rounded,
              color: sortMode == InventorySortMode.category
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: sortMode == InventorySortMode.category
                ? 'Normale Ansicht'
                : 'Nach Kategorie gruppieren',
            onPressed: () {
              ref.read(inventorySortModeProvider.notifier).state =
                  sortMode == InventorySortMode.category
                      ? InventorySortMode.nameAZ
                      : InventorySortMode.category;
            },
          ),
          // Sortier-Button
          PopupMenuButton<InventorySortMode>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sortieren',
            initialValue: sortMode,
            onSelected: (mode) =>
                ref.read(inventorySortModeProvider.notifier).state = mode,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: InventorySortMode.expiryDate,
                child: Text('Ablaufdatum (nächstes zuerst)'),
              ),
              PopupMenuItem(
                value: InventorySortMode.nameAZ,
                child: Text('Name A → Z'),
              ),
              PopupMenuItem(
                value: InventorySortMode.nameZA,
                child: Text('Name Z → A'),
              ),
              PopupMenuItem(
                value: InventorySortMode.newestFirst,
                child: Text('Zuletzt hinzugefügt'),
              ),
              PopupMenuItem(
                value: InventorySortMode.category,
                child: Text('Kategorie'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
          ),
          const AppBarMoreButton(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'fab_scan',
              onPressed: () => context.push('/scanner'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              tooltip: 'Barcode scannen',
              child: const Icon(Icons.qr_code_scanner_rounded),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              heroTag: 'fab_add',
              onPressed: () => _showAddSheet(context),
              tooltip: 'Manuell hinzufügen',
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Kompakte Ablauf-Zeile (nur wenn Artikel mit MHD vorhanden) ──
          if (itemsWithExpiry.isNotEmpty)
            const InventoryStatsCard(),

          // ── Scope-Zeile: Privat / Haushalt (nur bei Haushalt) ──
          Consumer(
            builder: (context, ref, _) {
              final household = ref.watch(householdProvider).valueOrNull;
              if (household == null) return const SizedBox.shrink();
              final scope = ref.watch(inventoryScopeProvider);
              final theme = Theme.of(context);
              final toHousehold = scope != InventoryScope.household;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<InventoryScope>(
                        segments: const [
                          ButtonSegment(
                            value: InventoryScope.all,
                            label: Text('Alle', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment(
                            value: InventoryScope.household,
                            icon: Icon(Icons.home_outlined, size: 14),
                            label: Text('Haushalt', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment(
                            value: InventoryScope.personal,
                            icon: Icon(Icons.person_outline, size: 14),
                            label: Text('Privat', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        selected: {scope},
                        onSelectionChanged: (s) {
                          ref.read(inventoryScopeProvider.notifier).state = s.first;
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: toHousehold
                          ? 'Zum Haushalt verschieben'
                          : 'Zu Privat verschieben',
                      child: IconButton(
                        icon: Icon(
                          toHousehold ? Icons.home_rounded : Icons.person_rounded,
                          color: theme.colorScheme.tertiary,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.tertiaryContainer
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final allItems =
                              ref.read(inventoryProvider).valueOrNull ?? [];
                          final sourceItems = toHousehold
                              ? allItems.where((i) => !i.isHousehold).toList()
                              : allItems.where((i) => i.isHousehold).toList();
                          if (sourceItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(toHousehold
                                    ? 'Keine privaten Artikel vorhanden'
                                    : 'Keine Haushalt-Artikel vorhanden'),
                              ),
                            );
                            return;
                          }
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (_) => _TransferItemsSheet(
                              items: sourceItems,
                              toHousehold: toHousehold,
                              householdName: household.name,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Filter-Zeile: Zone + Kategorie-Button ──────────────────────
          _InventoryFilterRow(
            categories: categories,
            selectedCategories: selectedCategories,
            selectedZone: selectedZone,
          ),

          // ── Anzahl + Rezepte-Button ──
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${items.length} Artikel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (allItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: _openRecipeGenerator,
                      icon: const Icon(Icons.auto_awesome, size: 13),
                      label: const Text('Rezepte'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

          // ── Artikel-Liste ──
          Expanded(
            child: inventoryAsync.when(
              loading: () => SkeletonList(
                builder: () => const InventorySkeletonCard(),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Verbindungsfehler',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('$e',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.read(inventoryProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (_) {
                if (items.isEmpty) {
                  if (showLeftovers && allItems.isNotEmpty) {
                    return _EmptyFilterResult(
                      icon: Icons.kitchen_rounded,
                      title: 'Keine Reste gefunden',
                      subtitle:
                          'Als Reste gelten Artikel mit dem Tag „reste", der Kategorie „Gekochtes" oder einer Menge ≤ 1.',
                      onClear: () => ref
                          .read(inventoryShowLeftoversProvider.notifier)
                          .state = false,
                    );
                  }
                  return const _EmptyInventory();
                }

                // ── Kategorie-Gruppenansicht ──────────────────────────────
                if (sortMode == InventorySortMode.category) {
                  return _buildCategoryGrouped(context, items);
                }

                // ── Normale flache Liste ──────────────────────────────────
                return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return TweenAnimationBuilder<double>(
                          key: ValueKey(items[index].id),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(
                              milliseconds: 250 + (index.clamp(0, 10) * 30)),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _InventoryItemCard(item: items[index]),
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Baut eine nach Kategorien gruppierte Ansicht mit Überschriften.
  Widget _buildCategoryGrouped(BuildContext context, List<InventoryItem> items) {
    final theme = Theme.of(context);

    // Gruppen aufbauen: Kategorie → Items
    final Map<String, List<InventoryItem>> groups = {};
    for (final item in items) {
      final cat = item.ingredientCategory?.isNotEmpty == true
          ? item.ingredientCategory!
          : 'Sonstiges';
      groups.putIfAbsent(cat, () => []).add(item);
    }
    // Alphabetisch sortiert, "Sonstiges" immer ans Ende
    final sorted = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'Sonstiges') return 1;
        if (b == 'Sonstiges') return -1;
        return a.compareTo(b);
      });

    // Flache Widget-Liste aus Überschriften + Items aufbauen
    final widgets = <Widget>[];
    for (final cat in sorted) {
      final catItems = groups[cat]!;
      final foodCat = FoodCategory.fromLabel(cat);

      // Kategorie-Überschrift
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (foodCat?.color ?? theme.colorScheme.surfaceContainerHighest)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  foodCat?.icon ?? Icons.category_outlined,
                  size: 16,
                  color: foodCat?.color ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cat,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${catItems.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );

      // Items der Kategorie
      for (var i = 0; i < catItems.length; i++) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _InventoryItemCard(item: catItems[i]),
          ),
        );
      }
    }
    widgets.add(const SizedBox(height: 88));

    return ListView(
      padding: EdgeInsets.zero,
      children: widgets,
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddInventoryItemSheet(),
    );
  }
}



/// Sheet: Items auswählen und transferieren (Privat ↔ Haushalt)
class _TransferItemsSheet extends ConsumerStatefulWidget {
  final List<InventoryItem> items;
  final bool toHousehold;
  final String householdName;

  const _TransferItemsSheet({
    required this.items,
    required this.toHousehold,
    required this.householdName,
  });

  @override
  ConsumerState<_TransferItemsSheet> createState() =>
      _TransferItemsSheetState();
}

class _TransferItemsSheetState extends ConsumerState<_TransferItemsSheet> {
  late Set<String> _selected;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Standardmäßig alle ausgewählt
    _selected = widget.items.map((i) => i.id).toSet();
  }

  bool get _allSelected => _selected.length == widget.items.length;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected = widget.items.map((i) => i.id).toSet();
      }
    });
  }

  Future<void> _transfer() async {
    if (_selected.isEmpty) return;
    setState(() => _isLoading = true);

    await ref.read(inventoryProvider.notifier).transferItems(
          _selected.toList(),
          toHousehold: widget.toHousehold,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.toHousehold
                ? '✅ ${_selected.length} Artikel zum Haushalt verschoben'
                : '✅ ${_selected.length} Artikel zu Privat verschoben',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = widget.toHousehold
        ? 'Privat → Haushalt „${widget.householdName}"'
        : 'Haushalt „${widget.householdName}" → Privat';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.toHousehold
                          ? Icons.home_rounded
                          : Icons.person_rounded,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Artikel verschieben',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  direction,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Alle auswählen / abwählen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CheckboxListTile(
              title: Text(
                _allSelected
                    ? 'Alle abwählen (${widget.items.length})'
                    : 'Alle auswählen (${widget.items.length})',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              value: _allSelected,
              onChanged: (_) => _toggleAll(),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ),
          const Divider(height: 1),
          // Item-Liste
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isChecked = _selected.contains(item.id);
                return CheckboxListTile(
                  value: isChecked,
                  onChanged: (_) {
                    setState(() {
                      if (isChecked) {
                        _selected.remove(item.id);
                      } else {
                        _selected.add(item.id);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: Text(item.ingredientName),
                  subtitle: item.ingredientCategory != null
                      ? Text(item.ingredientCategory!,
                          style: theme.textTheme.bodySmall)
                      : null,
                  secondary: item.quantity != null
                      ? Text(
                          '${item.quantity!.toStringAsFixed(item.quantity! == item.quantity!.roundToDouble() ? 0 : 1)} ${item.unit ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          // Transfer-Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: FilledButton.icon(
              onPressed: _selected.isEmpty || _isLoading ? null : _transfer,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(widget.toHousehold
                      ? Icons.home_rounded
                      : Icons.person_rounded),
              label: Text(
                _selected.isEmpty
                    ? 'Auswählen'
                    : '${_selected.length} Artikel verschieben',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kompakte Filter-Zeile die Zone-Chips + einen "Mehr"-Button kombiniert.
/// Der "Mehr"-Button öffnet ein BottomSheet mit Kategorie-Mehrfachauswahl.
class _InventoryFilterRow extends ConsumerWidget {
  final List<dynamic> categories;
  final Set<String> selectedCategories;
  final dynamic selectedZone;

  const _InventoryFilterRow({
    required this.categories,
    required this.selectedCategories,
    required this.selectedZone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasActiveCategories = selectedCategories.isNotEmpty;
    final showLeftovers = ref.watch(inventoryShowLeftoversProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Reste-Chip
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                avatar: Icon(
                  Icons.kitchen_rounded,
                  size: 14,
                  color: showLeftovers
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                label: const Text('Reste', style: TextStyle(fontSize: 12)),
                selected: showLeftovers,
                selectedColor: theme.colorScheme.tertiaryContainer,
                labelStyle: TextStyle(
                  color: showLeftovers
                      ? theme.colorScheme.onTertiaryContainer
                      : null,
                  fontWeight: showLeftovers ? FontWeight.bold : null,
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                tooltip: 'Artikel mit Reste-Tag, niedriger Menge (≤1) oder unter Mindestbestand',
                onSelected: (val) {
                  ref.read(inventoryShowLeftoversProvider.notifier).state = val;
                },
              ),
            ),
            Container(
              height: 20,
              width: 1,
              color: theme.colorScheme.outlineVariant,
              margin: const EdgeInsets.only(right: 6),
            ),
            // Zone-Chips
            ...StorageZone.values.map((zone) {
              final isSelected = selectedZone == zone;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text('${zone.emoji} ${zone.label}'),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : null,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    ref.read(storageZoneProvider.notifier).state = zone;
                    ref.read(selectedCategoriesProvider.notifier).state = {};
                  },
                ),
              );
            }),
            // Trennlinie
            if (categories.isNotEmpty) ...[
              Container(
                height: 20,
                width: 1,
                color: theme.colorScheme.outlineVariant,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
              // Kategorie-Button (zeigt Anzahl aktiver Filter)
              FilterChip(
                avatar: Icon(
                  Icons.filter_list_rounded,
                  size: 14,
                  color: hasActiveCategories
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  hasActiveCategories
                      ? 'Kategorien (${selectedCategories.length})'
                      : 'Kategorien',
                  style: const TextStyle(fontSize: 12),
                ),
                selected: hasActiveCategories,
                selectedColor: theme.colorScheme.secondaryContainer,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => _showCategorySheet(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CategoryFilterSheet(
        categories: categories,
        selected: selectedCategories,
        onChanged: (newSet) {
          ref.read(selectedCategoriesProvider.notifier).state = newSet;
        },
      ),
    );
  }
}

/// BottomSheet für Mehrfachauswahl der Kategorien
class _CategoryFilterSheet extends StatefulWidget {
  final List<dynamic> categories;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _CategoryFilterSheet({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Kategorien filtern',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_selected.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _selected.clear());
                    widget.onChanged({});
                  },
                  child: const Text('Alle zurücksetzen'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((cat) {
              final isSelected = _selected.contains(cat.label as String);
              return FilterChip(
                avatar: Icon(cat.icon as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : cat.color as Color),
                label: Text(cat.label as String),
                selected: isSelected,
                selectedColor: cat.color as Color,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
                showCheckmark: false,
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selected.add(cat.label as String);
                    } else {
                      _selected.remove(cat.label as String);
                    }
                  });
                  widget.onChanged(Set<String>.from(_selected));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_selected.isEmpty
                  ? 'Alle anzeigen'
                  : '${_selected.length} Filter anwenden'),
            ),
          ),
        ],
      ),
    );
  }
}


class _EmptyFilterResult extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onClear;

  const _EmptyFilterResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onClear,
  });

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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.colorScheme.tertiary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Filter zurücksetzen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
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
              child: Icon(Icons.kitchen_rounded,
                  size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Willkommen bei Kokomi! 👋',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Dein digitaler Kühlschrank wartet darauf gefüllt zu werden.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Schritte
            _OnboardingStep(
              icon: Icons.qr_code_scanner_rounded,
              color: theme.colorScheme.primary,
              title: 'Barcode scannen',
              subtitle: 'Produkte einfach per Kamera hinzufügen',
            ),
            const SizedBox(height: 8),
            _OnboardingStep(
              icon: Icons.add_rounded,
              color: Colors.green,
              title: 'Manuell hinzufügen',
              subtitle: 'Tippe auf „Hinzufügen" unten rechts',
            ),
            const SizedBox(height: 8),
            _OnboardingStep(
              icon: Icons.auto_awesome_rounded,
              color: Colors.purple,
              title: 'Rezepte generieren',
              subtitle: 'KI schlägt Rezepte aus deinem Vorrat vor',
            ),
          ],
        ),
      );
  }
}

class _OnboardingStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardingStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryItemCard extends ConsumerWidget {
  final InventoryItem item;
  const _InventoryItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = expiryColor(item.expiryDate);
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.horizontal,
      // Hintergrund für Rechts-Swipe (→ Löschen)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 24),
            SizedBox(width: 6),
            Text('Bearbeiten',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      // Hintergrund für Links-Swipe (← Löschen)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // → Bearbeiten (Sheet öffnen)
          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => AddInventoryItemSheet(existingItem: item),
            );
          }
          return false; // Nicht entfernen
        }
        // ← Löschen
        return true;
      },
      onDismissed: (_) =>
          ref.read(inventoryProvider.notifier).deleteItem(item.id),
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => AddInventoryItemSheet(existingItem: item),
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Avatar / Bild
                Hero(
                  tag: 'inventory_${item.id}',
                  child: item.ingredientImageUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.ingredientImageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildInitialAvatar(color),
                      ),
                    )
                  : _buildInitialAvatar(color),
                ),
              const SizedBox(width: 10),
              // Name & Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.isHousehold)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.home_rounded, size: 14,
                                color: theme.colorScheme.tertiary),
                          ),
                        Expanded(
                          child: Text(
                            item.ingredientName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.ingredientCategory != null) ...[
                          Icon(Icons.label_outline, size: 13,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              item.ingredientCategory!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (item.quantity != null) ...[
                          if (item.ingredientCategory != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('·', style: theme.textTheme.bodySmall),
                            ),
                          Text(
                            '${item.quantity} ${item.unit ?? ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Mengen-Schnellbearbeitung
              if (item.quantity != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        icon: const Icon(Icons.remove, size: 14),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: item.quantity! > 0
                            ? () {
                                HapticFeedback.selectionClick();
                                final updated = item.copyWith(
                                  quantity: (item.quantity! - 1).clamp(0, 9999),
                                );
                                ref.read(inventoryProvider.notifier).updateItem(updated);
                              }
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        item.quantity!.toStringAsFixed(item.quantity! == item.quantity!.roundToDouble() ? 0 : 1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        icon: const Icon(Icons.add, size: 14),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          final updated = item.copyWith(
                            quantity: item.quantity! + 1,
                          );
                          ref.read(inventoryProvider.notifier).updateItem(updated);
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 6),
              // Nutri-Score Badge
              if (item.nutriScore != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: NutriScoreBadge(score: item.nutriScore!, size: 22),
                ),
              // Ablaufdatum
              if (item.expiryDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.expiryDate!.formattedDate,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      if (item.expiryDate!.isExpired)
                        Text('Abgelaufen',
                            style: TextStyle(
                                color: color, fontSize: 9, fontWeight: FontWeight.w700))
                      else if (item.expiryDate!.isExpiringSoon)
                        Text('Bald',
                            style: TextStyle(
                                color: color, fontSize: 9, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInitialAvatar(Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          item.ingredientName.isNotEmpty
              ? item.ingredientName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

