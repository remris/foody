import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kokomu/core/constants/food_categories.dart';
import 'package:kokomu/core/services/fridge_scan_service.dart';
import 'package:kokomu/features/auth/presentation/auth_provider.dart';
import 'package:kokomu/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomu/models/inventory_item.dart';

/// Bottom Sheet für KI-gestützte Kühlschrank-/Vorratsfoto-Analyse.
class FridgeScanSheet extends ConsumerStatefulWidget {
  const FridgeScanSheet({super.key});

  @override
  ConsumerState<FridgeScanSheet> createState() => _FridgeScanSheetState();
}

class _FridgeScanSheetState extends ConsumerState<FridgeScanSheet> {
  bool _isScanning = false;
  bool _isAdding = false;
  List<FridgeScanItem> _detectedItems = [];
  final Set<int> _selectedIndices = {};
  String? _imagePath;
  String? _error;

  String _buildSubtitle(FridgeScanItem item) {
    final parts = <String>[];
    if (item.category != null) parts.add(item.category!);
    if (item.quantity != null && item.unit != null) {
      parts.add('${item.quantity} ${item.unit}');
    } else if (item.quantity != null) {
      parts.add(item.quantity!);
    }
    return parts.join(' · ');
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _isScanning = true;
      _error = null;
      _detectedItems = [];
      _selectedIndices.clear();
    });

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (photo == null) {
        setState(() => _isScanning = false);
        return;
      }
      _imagePath = photo.path;
      final items = await FridgeScanService.analyzeImageFile(File(photo.path));

      setState(() {
        _detectedItems = items;
        _selectedIndices.addAll(List.generate(items.length, (i) => i));
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _addSelected() async {
    if (_selectedIndices.isEmpty) return;
    setState(() => _isAdding = true);

    final userId = ref.read(currentUserProvider)?.id ?? '';
    final notifier = ref.read(inventoryProvider.notifier);
    int added = 0;

    for (final idx in _selectedIndices) {
      final item = _detectedItems[idx];
      final category = FoodCategory.fromLabel(item.category);
      final inventoryItem = InventoryItem(
        id: '',
        userId: userId,
        ingredientId:
            DateTime.now().millisecondsSinceEpoch.toString() + idx.toString(),
        ingredientName: item.name,
        ingredientCategory: category?.label ?? item.category,
        quantity: double.tryParse(item.quantity ?? ''),
        unit: item.unit,
        createdAt: DateTime.now(),
      );
      await notifier.addItem(inventoryItem);
      added++;
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $added Produkte zum Vorrat hinzugefügt'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.camera_enhance_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Kühlschrank scannen 🧊',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Fotografiere deinen Kühlschrank oder Vorrat –\ndie KI erkennt automatisch alle Produkte.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Inhalt ──
          Expanded(
            child: _isScanning
                ? _buildLoadingState(theme)
                : _detectedItems.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildResultList(theme, scrollController),
          ),

          // ── Aktions-Buttons ──
          if (!_isScanning && _detectedItems.isNotEmpty)
            _buildActionBar(theme),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('🤖 KI analysiert das Foto...', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Produkte werden erkannt und zugeordnet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fehler: $_error',
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_imagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text('Keine Produkte erkannt', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Versuche ein deutlicheres Foto mit besserem Licht aufzunehmen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 32),
            Icon(
              Icons.camera_enhance_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Foto aufnehmen',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Fotografiere Kühlschrank, Vorratskammer oder einzelne Produkte – die KI erkennt automatisch was du hast.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],

          // Scan-Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _scan(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Kamera'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scan(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Galerie'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 20,
                    color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tipp: Gutes Licht und eine ruhige Hand helfen der KI Produkte besser zu erkennen.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(ThemeData theme, ScrollController scrollController) {
    return Column(
      children: [
        if (_imagePath != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_imagePath!),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                '${_detectedItems.length} Produkte erkannt',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedIndices.length == _detectedItems.length) {
                      _selectedIndices.clear();
                    } else {
                      _selectedIndices
                          .addAll(List.generate(_detectedItems.length, (i) => i));
                    }
                  });
                },
                child: Text(
                  _selectedIndices.length == _detectedItems.length
                      ? 'Alle abwählen'
                      : 'Alle wählen',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _detectedItems.length,
            itemBuilder: (context, index) {
              final item = _detectedItems[index];
              final isSelected = _selectedIndices.contains(index);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    child: const Text('🛒', style: TextStyle(fontSize: 18)),
                  ),
                  title: Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: item.category != null || item.quantity != null
                      ? Text(
                          _buildSubtitle(item),
                          style: theme.textTheme.bodySmall,
                        )
                      : null,
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (_) => setState(() {
                      if (isSelected) {
                        _selectedIndices.remove(index);
                      } else {
                        _selectedIndices.add(index);
                      }
                    }),
                  ),
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedIndices.remove(index);
                    } else {
                      _selectedIndices.add(index);
                    }
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _scan(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Neues Foto'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isAdding || _selectedIndices.isEmpty
                    ? null
                    : _addSelected,
                icon: _isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  _selectedIndices.isEmpty
                      ? 'Nichts ausgewählt'
                      : '${_selectedIndices.length} zum Vorrat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

