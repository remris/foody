import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/inventory/presentation/inventory_provider.dart';
import 'package:kokomi/features/shopping_list/presentation/shopping_list_provider.dart';
import 'package:kokomi/models/inventory_item.dart';
import 'package:kokomi/models/shopping_list_item.dart';

/// Sheet zur Übernahme abgehakter Einkaufslisteneinträge ins Inventar.
class TransferToInventorySheet extends ConsumerStatefulWidget {
  final List<ShoppingListItem> checkedItems;
  const TransferToInventorySheet({super.key, required this.checkedItems});

  @override
  ConsumerState<TransferToInventorySheet> createState() =>
      _TransferToInventorySheetState();
}

class _TransferToInventorySheetState
    extends ConsumerState<TransferToInventorySheet> {
  bool _isLoading = false;
  bool _removeAfterTransfer = true;

  Future<void> _transferAll() async {
    setState(() => _isLoading = true);

    final userId = ref.read(currentUserProvider)?.id ?? '';
    final items = widget.checkedItems.map((shopItem) {
      return InventoryItem(
        id: '',
        userId: userId,
        ingredientId: DateTime.now().millisecondsSinceEpoch.toString(),
        ingredientName: shopItem.name,
        quantity: double.tryParse(shopItem.quantity ?? ''),
        createdAt: DateTime.now(),
      );
    }).toList();

    // Batch-Insert ins Inventar
    for (final item in items) {
      await ref.read(inventoryProvider.notifier).addItem(item);
    }

    // Abgehakte Items von Einkaufsliste entfernen
    if (_removeAfterTransfer) {
      await ref.read(shoppingListProvider.notifier).clearChecked();
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${items.length} Artikel ins Inventar übernommen',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
              Icon(Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Ins Inventar übernehmen',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.checkedItems.length} abgehakte Artikel werden ins Inventar übernommen. '
            'Details wie Menge und Ablaufdatum kannst du danach bearbeiten.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Artikel-Liste
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.checkedItems.length,
              itemBuilder: (context, index) {
                final item = widget.checkedItems[index];
                return ListTile(
                  leading: Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 20),
                  title: Text(item.name),
                  subtitle: item.quantity != null
                      ? Text(item.quantity!)
                      : null,
                  dense: true,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Option: nach Übernahme entfernen
          SwitchListTile(
            value: _removeAfterTransfer,
            onChanged: (val) =>
                setState(() => _removeAfterTransfer = val),
            title: const Text('Nach Übernahme von Liste entfernen'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : _transferAll,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.move_to_inbox),
            label: Text(
              _isLoading
                  ? 'Wird übernommen...'
                  : '${widget.checkedItems.length} Artikel übernehmen',
            ),
          ),
        ],
      ),
    );
  }
}

