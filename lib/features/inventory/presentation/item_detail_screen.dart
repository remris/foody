import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/core/constants/food_categories.dart';
import 'package:kokomu/features/inventory/presentation/add_inventory_item_sheet.dart';
import 'package:kokomu/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomu/features/scanner/data/scanner_repository_impl.dart';
import 'package:kokomu/features/scanner/domain/scanner_repository.dart';
import 'package:kokomu/models/inventory_item.dart';
import 'package:kokomu/models/product_details.dart';

final scannerRepoProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepositoryImpl();
});

final productDetailsProvider =
    FutureProvider.family<ProductDetails?, String>((ref, barcode) async {
  if (barcode.isEmpty) return null;
  return ref.read(scannerRepoProvider).lookupProductDetails(barcode);
});

// ─── Detail-Screen ────────────────────────────────────────────────────────────

class ItemDetailScreen extends ConsumerStatefulWidget {
  final InventoryItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late InventoryItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _toggleOpened() async {
    if (_item.isOpened) {
      // Bereits geöffnet → schließen
      final updated = _item.copyWith(openedAt: null);
      await ref.read(inventoryProvider.notifier).updateItem(updated);
      if (mounted) setState(() => _item = updated);
    } else {
      // Noch nicht geöffnet → Dialog mit %-Verbrauch
      final result = await _showOpenedDialog(context);
      if (result == null || !mounted) return;
      final percent = result;
      // Neue Menge berechnen (abzüglich verbrauchter %)
      double? newQty = _item.quantity;
      if (newQty != null && percent > 0) {
        newQty = newQty * (1 - percent / 100);
        if (newQty < 0) newQty = 0;
      }
      final updated = _item.copyWith(
        openedAt: DateTime.now(),
        quantity: newQty,
      );
      await ref.read(inventoryProvider.notifier).updateItem(updated);
      if (mounted) setState(() => _item = updated);
    }
  }

  /// Zeigt Dialog: "Bereits wieviel % verbraucht?"
  Future<double?> _showOpenedDialog(BuildContext context) async {
    double sliderValue = 0;
    return showDialog<double>(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (c, setDialogState) {
            final theme = Theme.of(c);
            return AlertDialog(
              title: const Text('Als geöffnet markieren'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wie viel ist bereits verbraucht?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Die Menge wird entsprechend angepasst.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  // Großes Prozent-Display
                  Center(
                    child: Text(
                      '${sliderValue.round()} %',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _percentColor(sliderValue, theme),
                      ),
                    ),
                  ),
                  // Beschriftung der verbleibenden Menge
                  if (_item.quantity != null) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Verbleibend: ${(_item.quantity! * (1 - sliderValue / 100)).toStringAsFixed(1)} ${_item.unit ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Slider(
                    value: sliderValue,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${sliderValue.round()} %',
                    activeColor: _percentColor(sliderValue, theme),
                    onChanged: (v) => setDialogState(() => sliderValue = v),
                  ),
                  // Schnell-Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [0, 25, 50, 75].map((p) {
                      final isSelected = sliderValue.round() == p;
                      return GestureDetector(
                        onTap: () => setDialogState(() => sliderValue = p.toDouble()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _percentColor(p.toDouble(), theme).withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? _percentColor(p.toDouble(), theme)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '$p %',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? _percentColor(p.toDouble(), theme)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, sliderValue),
                  child: const Text('Bestätigen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _percentColor(double percent, ThemeData theme) {
    if (percent >= 75) return theme.colorScheme.error;
    if (percent >= 50) return Colors.orange.shade700;
    if (percent >= 25) return Colors.amber.shade700;
    return Colors.green.shade700;
  }

  /// Verbrauch nachträglich anpassen (wenn bereits geöffnet)
  Future<void> _adjustConsumption() async {
    final result = await _showOpenedDialog(context);
    if (result == null || !mounted) return;
    final percent = result;
    if (percent <= 0) return;
    double? newQty = _item.quantity;
    if (newQty != null) {
      newQty = newQty * (1 - percent / 100);
      if (newQty < 0) newQty = 0;
    }
    final updated = _item.copyWith(quantity: newQty);
    await ref.read(inventoryProvider.notifier).updateItem(updated);
    if (mounted) setState(() => _item = updated);
  }

  Future<void> _markConsumed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Verbraucht?'),
        content: Text('"${_item.ingredientName}" aus dem Vorrat entfernen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Verbraucht')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(inventoryProvider.notifier).deleteItem(_item.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _markDisposed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Entsorgt?'),
        content: Text('"${_item.ingredientName}" als entsorgt markieren und entfernen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error),
            child: const Text('Entsorgen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(inventoryProvider.notifier).deleteItem(_item.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openEdit() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddInventoryItemSheet(existingItem: _item),
    );
    final items = ref.read(inventoryProvider).valueOrNull ?? [];
    final fresh = items.firstWhere((i) => i.id == _item.id, orElse: () => _item);
    if (mounted) setState(() => _item = fresh);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = FoodCategory.fromLabel(_item.ingredientCategory);
    final barcode = _item.barcode ?? _item.ingredientId;
    final detailsAsync = ref.watch(productDetailsProvider(barcode));

    return Scaffold(
      appBar: AppBar(
        title: Text(_item.ingredientName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Bearbeiten',
            onPressed: _openEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductHeader(item: _item, category: category),
            const SizedBox(height: 16),
            _OpenedStatusCard(
              item: _item,
              onToggle: _toggleOpened,
              onAdjustConsumption: _item.isOpened ? _adjustConsumption : null,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _InventoryInfoCard(item: _item, theme: theme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markConsumed,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Verbraucht'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markDisposed,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Entsorgt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            detailsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (_, __) => _NoFoodFacts(theme: theme),
              data: (details) {
                if (details == null) return _NoFoodFacts(theme: theme);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (details.nutriscoreGrade != null) ...[
                      _NutriScoreBadge(grade: details.nutriscoreGrade!),
                      const SizedBox(height: 16),
                    ],
                    if (details.brands != null || details.packagingQuantity != null)
                      _BrandInfoCard(details: details, theme: theme),
                    if (details.nutriments != null) ...[
                      const SizedBox(height: 16),
                      _NutritionTable(nutriments: details.nutriments!, theme: theme),
                    ],
                    if (details.allergensTags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _TagSection(title: 'Allergene', tags: details.allergensTags,
                          color: theme.colorScheme.error, icon: Icons.warning_amber_rounded, theme: theme),
                    ],
                    if (details.labelsTags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _TagSection(title: 'Labels', tags: details.labelsTags,
                          color: theme.colorScheme.primary, icon: Icons.verified_outlined, theme: theme),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Geöffnet-Status-Card ──────────────────────────────────────────────────────

class _OpenedStatusCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onToggle;
  final VoidCallback? onAdjustConsumption;
  final ThemeData theme;
  const _OpenedStatusCard({
    required this.item,
    required this.onToggle,
    required this.theme,
    this.onAdjustConsumption,
  });

  @override
  Widget build(BuildContext context) {
    final isOpened = item.isOpened;
    final openedAt = item.openedAt;
    final daysSince = openedAt != null ? DateTime.now().difference(openedAt).inDays : 0;

    // Füllstand-Anzeige (nur wenn Menge bekannt)
    final hasQty = item.quantity != null;

    return Card(
      color: isOpened ? Colors.orange.withValues(alpha: 0.08) : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOpened ? Colors.orange.shade300 : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOpened ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  color: isOpened ? Colors.orange.shade700 : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpened ? '🟠 Geöffnet' : 'Ungeöffnet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isOpened ? Colors.orange.shade800 : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isOpened && openedAt != null)
                        Text(
                          'Seit ${openedAt.day}.${openedAt.month}.${openedAt.year} · $daysSince Tag${daysSince != 1 ? 'e' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onToggle,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(isOpened ? 'Schließen' : 'Als geöffnet markieren'),
                ),
              ],
            ),
            // Verbrauch-Anpassen Button (nur wenn geöffnet)
            if (isOpened) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verbrauch anpassen',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (hasQty)
                          Text(
                            'Aktuell: ${item.quantity!.toStringAsFixed(1)} ${item.unit ?? ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAdjustConsumption,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('% verbraucht'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bestand-Info-Card ─────────────────────────────────────────────────────────

class _InventoryInfoCard extends StatelessWidget {
  final InventoryItem item;
  final ThemeData theme;
  const _InventoryInfoCard({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bestand', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoTile(
                  icon: Icons.scale,
                  label: 'Menge',
                  value: item.quantity != null ? '${item.quantity} ${item.unit ?? ''}'.trim() : '–',
                  theme: theme,
                ),
                const SizedBox(width: 16),
                _InfoTile(
                  icon: Icons.calendar_today,
                  label: 'Ablaufdatum',
                  value: item.expiryDate != null
                      ? '${item.expiryDate!.day}.${item.expiryDate!.month}.${item.expiryDate!.year}'
                      : '–',
                  theme: theme,
                ),
                if (item.minThreshold > 0) ...[
                  const SizedBox(width: 16),
                  _InfoTile(icon: Icons.low_priority, label: 'Min. Bestand', value: '${item.minThreshold}', theme: theme),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  const _InfoTile({required this.icon, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Produkt-Header ────────────────────────────────────────────────────────────

class _ProductHeader extends StatelessWidget {
  final InventoryItem item;
  final FoodCategory? category;
  const _ProductHeader({required this.item, this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'inventory_${item.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: item.ingredientImageUrl != null
                ? Image.network(item.ingredientImageUrl!, width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(theme))
                : _placeholder(theme),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.ingredientName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (category != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: category!.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category!.icon, size: 14, color: category!.color),
                      const SizedBox(width: 4),
                      Text(category!.label,
                          style: TextStyle(fontSize: 12, color: category!.color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              if (item.isHousehold) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.home_rounded, size: 13, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 4),
                    Text('Haushalt', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: (category?.color ?? theme.colorScheme.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(category?.icon ?? Icons.fastfood, size: 36,
            color: category?.color ?? theme.colorScheme.primary),
      );
}

// ── Nutri-Score Badge ─────────────────────────────────────────────────────────

class _NutriScoreBadge extends StatelessWidget {
  final String grade;
  const _NutriScoreBadge({required this.grade});

  Color _colorForGrade(String g) => switch (g.toLowerCase()) {
        'a' => const Color(0xFF1B8C3A),
        'b' => const Color(0xFF88C540),
        'c' => const Color(0xFFFFCB05),
        'd' => const Color(0xFFF29100),
        'e' => const Color(0xFFE63E11),
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Nutri-Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        ...['A', 'B', 'C', 'D', 'E'].map((g) {
          final isActive = g.toLowerCase() == grade.toLowerCase();
          final c = _colorForGrade(g);
          return Container(
            margin: const EdgeInsets.only(right: 3),
            width: isActive ? 36 : 28,
            height: isActive ? 36 : 28,
            decoration: BoxDecoration(
              color: isActive ? c : c.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text(g,
                style: TextStyle(color: isActive ? Colors.white : c,
                    fontWeight: FontWeight.bold, fontSize: isActive ? 16 : 12))),
          );
        }),
      ],
    );
  }
}

// ── Brand Info Card ───────────────────────────────────────────────────────────

class _BrandInfoCard extends StatelessWidget {
  final ProductDetails details;
  final ThemeData theme;
  const _BrandInfoCard({required this.details, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (details.brands != null) ...[
              Icon(Icons.business, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(details.brands!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
            if (details.brands != null && details.packagingQuantity != null) const Spacer(),
            if (details.packagingQuantity != null) ...[
              Icon(Icons.straighten, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(details.packagingQuantity!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Nutrition Table ───────────────────────────────────────────────────────────

class _NutritionTable extends StatelessWidget {
  final NutrientInfo nutriments;
  final ThemeData theme;
  const _NutritionTable({required this.nutriments, required this.theme});

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value, double ratio, Color color})>[
      if (nutriments.energyKcal != null)
        (label: 'Kalorien', value: '${nutriments.energyKcal!.round()} kcal',
            ratio: nutriments.energyKcal! / 2000, color: const Color(0xFFFF7043)),
      if (nutriments.fat != null)
        (label: 'Fett', value: '${nutriments.fat!.toStringAsFixed(1)} g',
            ratio: nutriments.fat! / 65, color: const Color(0xFFFFCA28)),
      if (nutriments.carbohydrates != null)
        (label: 'Kohlenhydrate', value: '${nutriments.carbohydrates!.toStringAsFixed(1)} g',
            ratio: nutriments.carbohydrates! / 300, color: const Color(0xFF42A5F5)),
      if (nutriments.proteins != null)
        (label: 'Eiweiß', value: '${nutriments.proteins!.toStringAsFixed(1)} g',
            ratio: nutriments.proteins! / 50, color: const Color(0xFFAB47BC)),
      if (nutriments.salt != null)
        (label: 'Salz', value: '${nutriments.salt!.toStringAsFixed(2)} g',
            ratio: nutriments.salt! / 6, color: const Color(0xFF78909C)),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nährwerte pro 100g',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(r.label, style: theme.textTheme.bodyMedium)),
                    Expanded(flex: 2, child: Text(r.value,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right)),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: r.ratio.clamp(0.0, 1.0),
                        backgroundColor: r.color.withValues(alpha: 0.15),
                        color: r.color, minHeight: 6,
                      ),
                    )),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tag Section ───────────────────────────────────────────────────────────────

class _TagSection extends StatelessWidget {
  final String title;
  final List<String> tags;
  final Color color;
  final IconData icon;
  final ThemeData theme;
  const _TagSection({required this.title, required this.tags, required this.color, required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: tags.map((t) => Chip(
            label: Text(t),
            backgroundColor: color.withValues(alpha: 0.1),
            labelStyle: TextStyle(fontSize: 12, color: color),
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }
}

// ── No Food Facts ─────────────────────────────────────────────────────────────

class _NoFoodFacts extends StatelessWidget {
  final ThemeData theme;
  const _NoFoodFacts({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 32, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('Keine Produktdetails verfügbar',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

