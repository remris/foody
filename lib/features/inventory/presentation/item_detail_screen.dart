import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomu/core/constants/food_categories.dart';
import 'package:kokomu/features/scanner/data/scanner_repository_impl.dart';
import 'package:kokomu/features/scanner/domain/scanner_repository.dart';
import 'package:kokomu/models/inventory_item.dart';
import 'package:kokomu/models/product_details.dart';

final scannerRepoProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepositoryImpl();
});

/// Cache für Produkt-Details, um wiederholte API-Calls zu vermeiden.
final productDetailsProvider =
    FutureProvider.family<ProductDetails?, String>((ref, barcode) async {
  if (barcode.isEmpty) return null;
  return ref.read(scannerRepoProvider).lookupProductDetails(barcode);
});

class ItemDetailScreen extends ConsumerWidget {
  final InventoryItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final barcode = item.barcode ?? item.ingredientId;
    final detailsAsync = ref.watch(productDetailsProvider(barcode));
    final category = FoodCategory.fromLabel(item.ingredientCategory);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.ingredientName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Produktbild + Grundinfos
            _ProductHeader(item: item, category: category),
            const SizedBox(height: 20),

            // Inventar-Info
            _InventoryInfoCard(item: item, theme: theme),
            const SizedBox(height: 16),

            // Food Facts (aus API)
            detailsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => _NoFoodFacts(theme: theme),
              data: (details) {
                if (details == null) return _NoFoodFacts(theme: theme);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nutri-Score
                    if (details.nutriscoreGrade != null) ...[
                      _NutriScoreBadge(grade: details.nutriscoreGrade!),
                      const SizedBox(height: 16),
                    ],

                    // Marke & Packung
                    if (details.brands != null ||
                        details.packagingQuantity != null)
                      _BrandInfoCard(details: details, theme: theme),

                    // Nährwerte
                    if (details.nutriments != null) ...[
                      const SizedBox(height: 16),
                      _NutritionTable(
                          nutriments: details.nutriments!, theme: theme),
                    ],

                    // Allergene
                    if (details.allergensTags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _TagSection(
                        title: 'Allergene',
                        tags: details.allergensTags,
                        color: theme.colorScheme.error,
                        icon: Icons.warning_amber_rounded,
                        theme: theme,
                      ),
                    ],

                    // Labels
                    if (details.labelsTags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _TagSection(
                        title: 'Labels',
                        tags: details.labelsTags,
                        color: theme.colorScheme.primary,
                        icon: Icons.verified_outlined,
                        theme: theme,
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            // Barcode
            Center(
              child: Text(
                'Barcode: $barcode',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

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
        // Bild
        Hero(
          tag: 'inventory_${item.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: item.ingredientImageUrl != null
                ? Image.network(
                    item.ingredientImageUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildPlaceholder(theme, category),
                  )
                : _buildPlaceholder(theme, category),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.ingredientName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (category != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: category!.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category!.icon, size: 14, color: category!.color),
                      const SizedBox(width: 4),
                      Text(
                        category!.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: category!.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: item.tags
                      .map((t) => Chip(
                            label: Text(t),
                            visualDensity: VisualDensity.compact,
                            labelStyle: const TextStyle(fontSize: 10),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme, FoodCategory? cat) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: (cat?.color ?? theme.colorScheme.primary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        cat?.icon ?? Icons.fastfood,
        size: 40,
        color: cat?.color ?? theme.colorScheme.primary,
      ),
    );
  }
}

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
            Text('Bestand',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoTile(
                  icon: Icons.scale,
                  label: 'Menge',
                  value: item.quantity != null
                      ? '${item.quantity} ${item.unit ?? ''}'.trim()
                      : '–',
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
                  _InfoTile(
                    icon: Icons.low_priority,
                    label: 'Min. Bestand',
                    value: '${item.minThreshold}',
                    theme: theme,
                  ),
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

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _NutriScoreBadge extends StatelessWidget {
  final String grade;
  const _NutriScoreBadge({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Nutri-Score',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        ...['A', 'B', 'C', 'D', 'E'].map((g) {
          final isActive = g.toLowerCase() == grade.toLowerCase();
          final gColor = _colorForGrade(g);
          return Container(
            margin: const EdgeInsets.only(right: 3),
            width: isActive ? 36 : 28,
            height: isActive ? 36 : 28,
            decoration: BoxDecoration(
              color: isActive ? gColor : gColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                g,
                style: TextStyle(
                  color: isActive ? Colors.white : gColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isActive ? 16 : 12,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _colorForGrade(String g) {
    switch (g.toLowerCase()) {
      case 'a':
        return const Color(0xFF1B8C3A);
      case 'b':
        return const Color(0xFF88C540);
      case 'c':
        return const Color(0xFFFFCB05);
      case 'd':
        return const Color(0xFFF29100);
      case 'e':
        return const Color(0xFFE63E11);
      default:
        return Colors.grey;
    }
  }
}

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
              Text(details.brands!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
            if (details.brands != null && details.packagingQuantity != null)
              const Spacer(),
            if (details.packagingQuantity != null) ...[
              Icon(Icons.straighten, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(details.packagingQuantity!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NutritionTable extends StatelessWidget {
  final NutrientInfo nutriments;
  final ThemeData theme;

  const _NutritionTable({required this.nutriments, required this.theme});

  @override
  Widget build(BuildContext context) {
    final rows = <_NutritionRow>[
      if (nutriments.energyKcal != null)
        _NutritionRow('Kalorien', '${nutriments.energyKcal!.round()} kcal',
            nutriments.energyKcal! / 2000, const Color(0xFFFF7043)),
      if (nutriments.fat != null)
        _NutritionRow('Fett', '${nutriments.fat!.toStringAsFixed(1)} g',
            nutriments.fat! / 65, const Color(0xFFFFCA28)),
      if (nutriments.saturatedFat != null)
        _NutritionRow(
            '  davon gesättigt',
            '${nutriments.saturatedFat!.toStringAsFixed(1)} g',
            nutriments.saturatedFat! / 20,
            const Color(0xFFFFB74D)),
      if (nutriments.carbohydrates != null)
        _NutritionRow(
            'Kohlenhydrate',
            '${nutriments.carbohydrates!.toStringAsFixed(1)} g',
            nutriments.carbohydrates! / 300,
            const Color(0xFF42A5F5)),
      if (nutriments.sugars != null)
        _NutritionRow(
            '  davon Zucker',
            '${nutriments.sugars!.toStringAsFixed(1)} g',
            nutriments.sugars! / 50,
            const Color(0xFF66BB6A)),
      if (nutriments.proteins != null)
        _NutritionRow(
            'Eiweiß',
            '${nutriments.proteins!.toStringAsFixed(1)} g',
            nutriments.proteins! / 50,
            const Color(0xFFAB47BC)),
      if (nutriments.fiber != null)
        _NutritionRow(
            'Ballaststoffe',
            '${nutriments.fiber!.toStringAsFixed(1)} g',
            nutriments.fiber! / 25,
            const Color(0xFF8D6E63)),
      if (nutriments.salt != null)
        _NutritionRow('Salz', '${nutriments.salt!.toStringAsFixed(2)} g',
            nutriments.salt! / 6, const Color(0xFF78909C)),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nährwerte pro 100g',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(r.label,
                                  style: theme.textTheme.bodyMedium),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(r.value,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.right),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: r.ratio.clamp(0.0, 1.0),
                                  backgroundColor:
                                      r.color.withValues(alpha: 0.15),
                                  color: r.color,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _NutritionRow {
  final String label;
  final String value;
  final double ratio;
  final Color color;

  _NutritionRow(this.label, this.value, this.ratio, this.color);
}

class _TagSection extends StatelessWidget {
  final String title;
  final List<String> tags;
  final Color color;
  final IconData icon;
  final ThemeData theme;

  const _TagSection({
    required this.title,
    required this.tags,
    required this.color,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: tags
              .map((t) => Chip(
                    label: Text(t),
                    backgroundColor: color.withValues(alpha: 0.1),
                    labelStyle: TextStyle(fontSize: 12, color: color),
                    visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

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
            Icon(Icons.info_outline, size: 32,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'Keine Produktdetails verfügbar',
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

