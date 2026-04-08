import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokomi/features/auth/presentation/auth_provider.dart';
import 'package:kokomi/features/scanner/data/scanned_product_repository.dart';
import 'package:kokomi/models/scanned_product.dart';

final scannedProductRepoProvider = Provider<ScannedProductRepository>((ref) {
  return ScannedProductRepository();
});

class ScannedProductsNotifier extends AsyncNotifier<List<ScannedProduct>> {
  @override
  Future<List<ScannedProduct>> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return [];
    return ref.read(scannedProductRepoProvider).getScannedProducts(userId);
  }

  Future<void> recordScan({
    required String barcode,
    required String productName,
    Map<String, dynamic>? productData,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await ref.read(scannedProductRepoProvider).recordScan(
          userId: userId,
          barcode: barcode,
          productName: productName,
          productData: productData,
        );
    state = AsyncData(
        await ref.read(scannedProductRepoProvider).getScannedProducts(userId));
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    // Optimistisches Update: sofort den lokalen State ändern
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((p) => p.id == id ? p.copyWith(isFavorite: isFavorite) : p).toList(),
    );
    // Dann in DB persistieren
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await ref.read(scannedProductRepoProvider).toggleFavorite(id, isFavorite);
    // Neu laden für Konsistenz
    state = AsyncData(
        await ref.read(scannedProductRepoProvider).getScannedProducts(userId));
  }
}

final scannedProductsProvider =
    AsyncNotifierProvider<ScannedProductsNotifier, List<ScannedProduct>>(
  ScannedProductsNotifier.new,
);

final favoritesProvider = Provider<List<ScannedProduct>>((ref) {
  final products = ref.watch(scannedProductsProvider).valueOrNull ?? [];
  return products.where((p) => p.isFavorite).toList();
});

final recentScansProvider = Provider<List<ScannedProduct>>((ref) {
  final products = ref.watch(scannedProductsProvider).valueOrNull ?? [];
  return products.take(10).toList();
});

