import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kokomi/core/services/receipt_ocr_service.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/models/inventory_item.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  final _ocrService = ReceiptOcrService();
  final _picker = ImagePicker();
  List<ReceiptItem>? _items;
  String? _rawText;
  bool _isLoading = false;
  bool _showRawText = false;
  final Set<int> _selectedIndices = {};

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 3000,
      imageQuality: 90,
    );
    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
      _items = null;
      _rawText = null;
    });

    try {
      final file = File(pickedFile.path);
      final items = await _ocrService.scanReceipt(file);
      final rawText = await _ocrService.getRawText(file);

      setState(() {
        _items = items;
        _rawText = rawText;
        _isLoading = false;
        // Alle vorauswählen
        _selectedIndices.addAll(
            List.generate(items.length, (i) => i));
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addToInventory() async {
    if (_items == null) return;
    final userId = ref.read(currentUserProvider)?.id ?? '';

    setState(() => _isLoading = true);

    for (final index in _selectedIndices) {
      final item = _items![index];
      final inventoryItem = InventoryItem(
        id: '',
        userId: userId,
        ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
        ingredientName: item.name,
        quantity: item.quantity != null
            ? double.tryParse(item.quantity!)
            : 1,
        createdAt: DateTime.now(),
      );
      await ref.read(inventoryProvider.notifier).addItem(inventoryItem);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_selectedIndices.length} Artikel ins Inventar übernommen'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kassenbon scannen'),
        actions: [
          if (_rawText != null)
            IconButton(
              icon: Icon(_showRawText
                  ? Icons.list_alt
                  : Icons.text_snippet_outlined),
              tooltip: _showRawText ? 'Erkannte Artikel' : 'Rohtext',
              onPressed: () =>
                  setState(() => _showRawText = !_showRawText),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Kassenbon wird analysiert...'),
                ],
              ),
            )
          : _items == null
              ? _buildStartView(theme)
              : _showRawText
                  ? _buildRawTextView(theme)
                  : _buildResultsView(theme),
    );
  }

  Widget _buildStartView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long,
                  size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('Kassenbon scannen',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Fotografiere deinen Kassenbon und die Artikel werden automatisch erkannt und ins Inventar übernommen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _scanReceipt(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Foto aufnehmen'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _scanReceipt(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Aus Galerie wählen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(ThemeData theme) {
    final items = _items!;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(Icons.receipt, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${items.length} Artikel erkannt',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedIndices.length == items.length) {
                      _selectedIndices.clear();
                    } else {
                      _selectedIndices.addAll(
                          List.generate(items.length, (i) => i));
                    }
                  });
                },
                child: Text(
                  _selectedIndices.length == items.length
                      ? 'Keine'
                      : 'Alle',
                ),
              ),
            ],
          ),
        ),
        // Items
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      const Text('Keine Artikel erkannt'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _scanReceipt(ImageSource.camera),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut scannen'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedIndices.contains(index);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIndices.add(index);
                            } else {
                              _selectedIndices.remove(index);
                            }
                          });
                        },
                        title: Text(item.name),
                        subtitle: Row(
                          children: [
                            if (item.price != null)
                              Text('${item.price} €',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  )),
                            if (item.quantity != null) ...[
                              if (item.price != null)
                                const Text(' · '),
                              Text('${item.quantity}x'),
                            ],
                          ],
                        ),
                        dense: true,
                        controlAffinity:
                            ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scanReceipt(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Neu scannen'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _selectedIndices.isEmpty
                      ? null
                      : _addToInventory,
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(
                    '${_selectedIndices.length} Artikel übernehmen',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRawTextView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Erkannter Rohtext',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _rawText ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

