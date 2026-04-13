import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomu/features/household/presentation/household_provider.dart';
import 'package:kokomu/features/scanner/presentation/scanner_provider.dart';
import 'package:kokomu/features/scanner/presentation/scanned_products_provider.dart';
import 'package:kokomu/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomu/models/inventory_item.dart';
import 'package:kokomu/widgets/nutri_score_badge.dart';
import 'package:kokomu/widgets/main_shell.dart' show AppBarMoreButton;

const _kScannerUnits = [
  'g', 'kg', 'ml', 'L', 'cl',
  'EL', 'TL', 'Tasse',
  'Stück', 'Packung', 'Pkg.', 'Dose', 'Glas',
  'Scheibe', 'Scheiben', 'Bund',
  'Prise', 'Schuss', 'nach Geschmack',
];

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _dialogShown = false;
  bool _bulkScanMode = false;
  int _bulkScanCount = 0;
  bool _torchEnabled = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScannerState>(scannerProvider, (prev, next) {
      if (_dialogShown) return;
      if (next.ingredient != null) {
        _dialogShown = true;
        HapticFeedback.mediumImpact(); // Haptisches Feedback bei Erfolg
        _showResultSheet(context, next.ingredient!);
      } else if (next.error != null && !next.isLoading) {
        _dialogShown = true;
        HapticFeedback.lightImpact(); // Leichtes Feedback bei Fehler
        // Produkt nicht gefunden → manuelle Eingabe anbieten
        _showManualEntrySheet(context, next.lastBarcode ?? '');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: _bulkScanMode
            ? Text('Bulk-Scan ($_bulkScanCount)')
            : const Text('Scanner'),
        actions: [
          // Bulk-Scan Modus Toggle
          IconButton(
            icon: Icon(
              _bulkScanMode
                  ? Icons.repeat_on_rounded
                  : Icons.repeat_rounded,
              color: _bulkScanMode ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: _bulkScanMode
                ? 'Bulk-Scan beenden'
                : 'Mehrere Artikel scannen',
            onPressed: () => setState(() {
              _bulkScanMode = !_bulkScanMode;
              if (!_bulkScanMode) _bulkScanCount = 0;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Kassenbon scannen',
            onPressed: () => context.push('/scanner/receipt'),
          ),
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: _torchEnabled ? Colors.amber : null,
            ),
            tooltip: 'Taschenlampe',
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchEnabled = !_torchEnabled);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
          const AppBarMoreButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner, size: 18), text: 'Scannen'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'Verlauf'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Scanner
          _buildScannerView(context),
          // Tab 2: Scan-History
          const _ScanHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildScannerView(BuildContext context) {
    return Stack(
      children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull?.rawValue;
              if (barcode != null) {
                HapticFeedback.selectionClick();
                ref.read(scannerProvider.notifier).scanBarcode(barcode);
              }
            },
          ),
          // Overlay
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Loading-Indikator
          Consumer(
            builder: (context, ref, _) {
              final isLoading = ref.watch(
                scannerProvider.select((s) => s.isLoading),
              );
              if (!isLoading) return const SizedBox.shrink();
              return Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Barcode in den Rahmen halten',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showManualBarcodeInput,
                  icon: const Icon(Icons.keyboard, color: Colors.white70),
                  label: const Text(
                    'Barcode manuell eingeben',
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
  }

  void _showManualBarcodeInput() {
    final barcodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Barcode eingeben'),
        content: TextField(
          controller: barcodeController,
          decoration: const InputDecoration(
            hintText: 'z.B. 4006381333931',
            prefixIcon: Icon(Icons.qr_code),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              Navigator.pop(ctx);
              ref.read(scannerProvider.notifier).scanBarcode(val.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final val = barcodeController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                ref.read(scannerProvider.notifier).scanBarcode(val);
              }
            },
            child: const Text('Suchen'),
          ),
        ],
      ),
    ).then((_) => barcodeController.dispose());
  }

  void _showManualEntrySheet(BuildContext context, String barcode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ManualEntrySheet(barcode: barcode),
    ).whenComplete(() {
      ref.read(scannerProvider.notifier).reset();
      _dialogShown = false;
    });
  }

  void _showResultSheet(BuildContext context, Ingredient ingredient) {
    // Scan in History aufzeichnen
    ref.read(scannedProductsProvider.notifier).recordScan(
          barcode: ingredient.barcode ?? ingredient.id,
          productName: ingredient.name,
        );

    if (_bulkScanMode) {
      // Bulk-Modus: Direkt zum Vorrat hinzufügen, kein Sheet
      _bulkAddToInventory(ingredient);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScanResultSheet(ingredient: ingredient),
    ).whenComplete(() {
      ref.read(scannerProvider.notifier).reset();
      _dialogShown = false;
    });
  }

  Future<void> _bulkAddToInventory(Ingredient ingredient) async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final householdId = ref.read(householdProvider).valueOrNull?.id;
    final item = InventoryItem(
      id: '',
      userId: userId,
      ingredientId: ingredient.id,
      ingredientName: ingredient.name,
      ingredientCategory: ingredient.category,
      ingredientImageUrl: ingredient.imageUrl,
      quantity: 1,
      unit: 'Stück',
      expiryDate: null,
      nutriScore: ingredient.nutriScore,
      householdId: householdId,
      createdAt: DateTime.now(),
    );
    await ref.read(inventoryProvider.notifier).addItem(item);
    setState(() => _bulkScanCount++);
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${ingredient.name} hinzugefügt (#$_bulkScanCount)'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
    // Sofort weiter scannen
    ref.read(scannerProvider.notifier).reset();
    _dialogShown = false;
  }
}

class _ScanResultSheet extends ConsumerStatefulWidget {
  final Ingredient ingredient;
  const _ScanResultSheet({required this.ingredient});

  @override
  ConsumerState<_ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends ConsumerState<_ScanResultSheet> {
  final _quantityController = TextEditingController();
  String _selectedUnit = 'Stück';
  DateTime? _expiryDate;
  bool _isLoading = false;
  bool _isHousehold = false;
  bool _defaultApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultApplied) {
      final household = ref.read(householdProvider).valueOrNull;
      if (household != null) _isHousehold = true;
      _defaultApplied = true;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) setState(() => _expiryDate = date);
  }

  Future<void> _addToInventory() async {
    setState(() => _isLoading = true);
    final userId = ref.read(currentUserProvider)?.id ?? '';
    final householdId = _isHousehold
        ? ref.read(householdProvider).valueOrNull?.id
        : null;
    final item = InventoryItem(
      id: '',
      userId: userId,
      ingredientId: widget.ingredient.id,
      ingredientName: widget.ingredient.name,
      ingredientCategory: widget.ingredient.category,
      ingredientImageUrl: widget.ingredient.imageUrl,
      quantity: double.tryParse(_quantityController.text),
      unit: _selectedUnit == 'nach Geschmack' ? null : _selectedUnit,
      expiryDate: _expiryDate,
      nutriScore: widget.ingredient.nutriScore,
      nutrientInfo: widget.ingredient.nutrients,
      householdId: householdId,
      createdAt: DateTime.now(),
    );
    await ref.read(inventoryProvider.notifier).addItem(item);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.ingredient.name} zum '
            '${_isHousehold ? 'Haushalts-' : 'privaten '}Vorrat hinzugefügt!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addToShoppingList() async {
    final qty = _quantityController.text.trim();
    final unit = _selectedUnit == 'nach Geschmack' ? '' : _selectedUnit;
    final quantity = qty.isNotEmpty ? '$qty $unit'.trim() : null;
    await ref.read(shoppingListProvider.notifier).addItem(
          widget.ingredient.name,
          quantity: quantity,
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.ingredient.name} zur Einkaufsliste hinzugefügt!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (widget.ingredient.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.ingredient.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restaurant_rounded, size: 32,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.restaurant_rounded, size: 32,
                      color: Theme.of(context).colorScheme.primary),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ingredient.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (widget.ingredient.category != null)
                      Text(
                        widget.ingredient.category!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (widget.ingredient.nutriScore != null) ...[
                      const SizedBox(height: 6),
                      NutriScoreScale(score: widget.ingredient.nutriScore!),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Menge',
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScannerUnitDropdown(
                  value: _selectedUnit,
                  onChanged: (u) => setState(() => _selectedUnit = u),
                ),
              ),
            ],
          ),
          // ── Nährwerte anzeigen wenn vorhanden ──
          if (widget.ingredient.nutrients != null &&
              widget.ingredient.nutrients!.hasData) ...[
            const SizedBox(height: 16),
            _ScanNutrientRow(nutrients: widget.ingredient.nutrients!),
          ],
          const SizedBox(height: 12),
          // ── Haushalt / Privat Toggle ──
          Consumer(builder: (context, ref, _) {
            final household = ref.watch(householdProvider).valueOrNull;
            if (household == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.home_outlined, size: 16),
                    label: Text('Haushalt'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.person_outline, size: 16),
                    label: Text('Privat'),
                  ),
                ],
                selected: {_isHousehold},
                onSelectionChanged: (s) =>
                    setState(() => _isHousehold = s.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _expiryDate == null
                  ? 'Ablaufdatum wählen'
                  : 'Ablaufdatum: ${_expiryDate!.day}.${_expiryDate!.month}.${_expiryDate!.year}',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isLoading ? null : _addToInventory,
            icon: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.kitchen_rounded),
            label: const Text('Zum Vorrat hinzufügen'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _addToShoppingList,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Zur Einkaufsliste'),
          ),
        ],
      ),
    );
  }
}

class _ManualEntrySheet extends ConsumerStatefulWidget {
  final String barcode;
  const _ManualEntrySheet({required this.barcode});

  @override
  ConsumerState<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<_ManualEntrySheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'Stück');
  bool _addToInventory = true;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (_addToInventory) {
      final userId = ref.read(currentUserProvider)?.id ?? '';
      final item = InventoryItem(
        id: '',
        userId: userId,
        ingredientId: widget.barcode,
        ingredientName: name,
        quantity: double.tryParse(_quantityController.text),
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(inventoryProvider.notifier).addItem(item);
    } else {
      final qty = _quantityController.text.trim();
      final unit = _unitController.text.trim();
      await ref.read(shoppingListProvider.notifier).addItem(
            name,
            quantity: qty.isNotEmpty ? '$qty $unit'.trim() : null,
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name ${_addToInventory ? 'zum Vorrat' : 'zur Einkaufsliste'} hinzugefügt!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.qr_code_rounded,
                    color: theme.colorScheme.error, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Produkt nicht gefunden',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Barcode: ${widget.barcode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Produktname eingeben',
              style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'z.B. Vollmilch, Brot, Joghurt...',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Menge',
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: 'Einheit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ziel wählen
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Zum Vorrat'),
                  avatar: const Icon(Icons.kitchen_rounded, size: 16),
                  selected: _addToInventory,
                  onSelected: (_) => setState(() => _addToInventory = true),
                  showCheckmark: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Einkaufsliste'),
                  avatar: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  selected: !_addToInventory,
                  onSelected: (_) => setState(() => _addToInventory = false),
                  showCheckmark: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _confirm,
            icon: Icon(_addToInventory
                ? Icons.kitchen_rounded
                : Icons.add_shopping_cart_rounded),
            label: Text(
                _addToInventory ? 'Zum Vorrat hinzufügen' : 'Zur Einkaufsliste'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }
}

class _ScanHistoryTab extends ConsumerWidget {
  const _ScanHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(scannedProductsProvider);
    final theme = Theme.of(context);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (products) => products.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 64, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('Noch keine Scans',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Scanne Barcodes um deine History aufzubauen',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: Text(
                        product.productName.isNotEmpty
                            ? product.productName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${product.scanCount}x gescannt · ${_formatDate(product.lastScannedAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        product.isFavorite
                            ? Icons.star
                            : Icons.star_border,
                        color: product.isFavorite
                            ? Colors.amber
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => ref
                          .read(scannedProductsProvider.notifier)
                          .toggleFavorite(
                              product.id, !product.isFavorite),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return '${date.day}.${date.month}.${date.year}';
  }
}

// ── Einheiten-Dropdown für Scanner ───────────────────────────────────────────
class _ScannerUnitDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _ScannerUnitDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final units = _kScannerUnits.contains(value)
        ? _kScannerUnits
        : [value, ..._kScannerUnits];
    return DropdownButtonFormField<String>(
      value: units.contains(value) ? value : units.first,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Einheit',
        prefixIcon: Icon(Icons.straighten, size: 18),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: units
          .map((u) => DropdownMenuItem(
                value: u,
                child: Text(u,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ── Nährwert-Zeile im Scan-Sheet ──────────────────────────────────────────────
class _ScanNutrientRow extends StatelessWidget {
  final IngredientNutrients nutrients;
  const _ScanNutrientRow({required this.nutrients});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nährwerte pro 100g',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (nutrients.kcalPer100g != null)
                _NutrientChip(
                  label: 'Kcal',
                  value: nutrients.kcalPer100g!.toInt().toString(),
                  color: Colors.orange,
                ),
              if (nutrients.proteinPer100g != null)
                _NutrientChip(
                  label: 'Protein',
                  value: '${nutrients.proteinPer100g!.toStringAsFixed(1)}g',
                  color: Colors.purple,
                ),
              if (nutrients.carbsPer100g != null)
                _NutrientChip(
                  label: 'Kohlenhydr.',
                  value: '${nutrients.carbsPer100g!.toStringAsFixed(1)}g',
                  color: Colors.blue,
                ),
              if (nutrients.fatPer100g != null)
                _NutrientChip(
                  label: 'Fett',
                  value: '${nutrients.fatPer100g!.toStringAsFixed(1)}g',
                  color: Colors.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NutrientChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

