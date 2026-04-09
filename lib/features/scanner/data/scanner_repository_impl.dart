import 'package:dio/dio.dart';
import 'package:kokomu/core/constants/app_constants.dart';
import 'package:kokomu/core/constants/food_categories.dart';
import 'package:kokomu/features/scanner/domain/scanner_repository.dart';
import 'package:kokomu/models/inventory_item.dart';
import 'package:kokomu/models/product_details.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  final _dio = Dio();

  @override
  Future<Ingredient?> lookupBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        '${AppConstants.openFoodFactsBaseUrl}/$barcode.json',
      );

      if (response.statusCode != 200) return null;

      final status = response.data['status'];
      if (status != 1) return null;

      final product = response.data['product'] as Map<String, dynamic>;
      final name =
          (product['product_name_de'] as String?)?.isNotEmpty == true
              ? product['product_name_de'] as String
              : (product['product_name'] as String?) ?? 'Unbekanntes Produkt';

      final tags = product['categories_tags'] as List<dynamic>?;
      String? category;
      if (tags != null && tags.isNotEmpty) {
        // Versuche OpenFoodFacts-Tags auf vordefinierte Kategorien zu mappen
        for (final tag in tags) {
          final mapped = FoodCategory.fromOpenFoodFacts(tag as String);
          if (mapped != null) {
            category = mapped.label;
            break;
          }
        }
        // Fallback: ersten Tag bereinigen
        category ??= _cleanCategory(tags.first as String);
      }

      final imageUrl = product['image_url'] as String?;
      final nutriScore = (product['nutriscore_grade'] as String?)?.toLowerCase();

      return Ingredient(
        id: barcode,
        name: name,
        barcode: barcode,
        category: category,
        imageUrl: imageUrl,
        nutriScore: nutriScore,
      );
    } catch (_) {
      return null;
    }
  }

  String _cleanCategory(String raw) {
    // "en:beverages" → "Beverages"
    final parts = raw.split(':');
    final last = parts.last.replaceAll('-', ' ');
    return last.isNotEmpty
        ? '${last[0].toUpperCase()}${last.substring(1)}'
        : raw;
  }

  @override
  Future<ProductDetails?> lookupProductDetails(String barcode) async {
    try {
      final response = await _dio.get(
        '${AppConstants.openFoodFactsBaseUrl}/$barcode.json',
      );

      if (response.statusCode != 200) return null;
      final status = response.data['status'];
      if (status != 1) return null;

      final product = response.data['product'] as Map<String, dynamic>;
      final name =
          (product['product_name_de'] as String?)?.isNotEmpty == true
              ? product['product_name_de'] as String
              : (product['product_name'] as String?) ?? 'Unbekanntes Produkt';

      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      final allergens = (product['allergens_tags'] as List<dynamic>?)
              ?.map((e) => _cleanCategory(e as String))
              .toList() ??
          [];
      final labels = (product['labels_tags'] as List<dynamic>?)
              ?.map((e) => _cleanCategory(e as String))
              .toList() ??
          [];

      return ProductDetails(
        barcode: barcode,
        name: name,
        brands: product['brands'] as String?,
        packagingQuantity: product['quantity'] as String?,
        imageUrl: product['image_url'] as String?,
        nutriscoreGrade: product['nutriscore_grade'] as String?,
        allergensTags: allergens,
        labelsTags: labels,
        nutriments: nutriments != null
            ? NutrientInfo.fromOpenFoodFacts(nutriments)
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}
