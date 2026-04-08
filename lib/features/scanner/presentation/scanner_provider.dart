import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/scanner/data/scanner_repository_impl.dart';
import 'package:kokomi/features/scanner/domain/scanner_repository.dart';
import 'package:kokomi/models/inventory_item.dart';

final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepositoryImpl();
});

// State: null = kein Scan, Ingredient = gefunden, String = Fehler
class ScannerState {
  final Ingredient? ingredient;
  final String? error;
  final bool isLoading;
  final String? lastBarcode;

  const ScannerState({
    this.ingredient,
    this.error,
    this.isLoading = false,
    this.lastBarcode,
  });

  ScannerState copyWith({
    Ingredient? ingredient,
    String? error,
    bool? isLoading,
    String? lastBarcode,
  }) =>
      ScannerState(
        ingredient: ingredient ?? this.ingredient,
        error: error ?? this.error,
        isLoading: isLoading ?? this.isLoading,
        lastBarcode: lastBarcode ?? this.lastBarcode,
      );

  ScannerState get cleared => const ScannerState();
}

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerState();

  Future<void> scanBarcode(String barcode) async {
    if (state.isLoading) return;
    if (state.lastBarcode == barcode) return; // Doppelscan verhindern

    state = ScannerState(isLoading: true, lastBarcode: barcode);

    final ingredient =
        await ref.read(scannerRepositoryProvider).lookupBarcode(barcode);

    if (ingredient == null) {
      state = ScannerState(
        error: 'Produkt nicht gefunden (Barcode: $barcode)',
        lastBarcode: barcode,
      );
    } else {
      state = ScannerState(ingredient: ingredient, lastBarcode: barcode);
    }
  }

  void reset() {
    state = const ScannerState();
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);

