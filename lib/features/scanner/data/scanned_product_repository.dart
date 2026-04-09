import 'package:kokomu/core/constants/app_constants.dart';
import 'package:kokomu/core/services/supabase_service.dart';
import 'package:kokomu/models/scanned_product.dart';

class ScannedProductRepository {
  final _client = SupabaseService.client;

  Future<List<ScannedProduct>> getScannedProducts(String userId) async {
    final data = await _client
        .from(AppConstants.tableScannedProducts)
        .select()
        .eq('user_id', userId)
        .order('last_scanned_at', ascending: false);
    return (data as List).map((e) => ScannedProduct.fromJson(e)).toList();
  }

  Future<void> recordScan({
    required String userId,
    required String barcode,
    required String productName,
    Map<String, dynamic>? productData,
  }) async {
    final existing = await _client
        .from(AppConstants.tableScannedProducts)
        .select()
        .eq('user_id', userId)
        .eq('barcode', barcode)
        .maybeSingle();

    if (existing != null) {
      await _client.from(AppConstants.tableScannedProducts).update({
        'scan_count': (existing['scan_count'] as int? ?? 0) + 1,
        'last_scanned_at': DateTime.now().toIso8601String(),
        if (productData != null) 'product_data': productData,
      }).eq('id', existing['id'] as String);
    } else {
      await _client.from(AppConstants.tableScannedProducts).insert({
        'user_id': userId,
        'barcode': barcode,
        'product_name': productName,
        if (productData != null) 'product_data': productData,
        'scan_count': 1,
        'is_favorite': false,
        'last_scanned_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _client
        .from(AppConstants.tableScannedProducts)
        .update({'is_favorite': isFavorite}).eq('id', id);
  }
}

