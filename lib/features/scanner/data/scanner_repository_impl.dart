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
        for (final tag in tags) {
          final mapped = FoodCategory.fromOpenFoodFacts(tag as String);
          if (mapped != null) {
            category = mapped.label;
            break;
          }
        }
        category ??= _cleanCategory(tags.first as String);
      }

      final imageUrl = product['image_url'] as String?;
      final nutriScore = (product['nutriscore_grade'] as String?)?.toLowerCase();

      // Nährwerte aus OpenFoodFacts auslesen
      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      IngredientNutrients? nutrients;
      if (nutriments != null) {
        final kcal = (nutriments['energy-kcal_100g'] as num?)?.toDouble();
        final protein = (nutriments['proteins_100g'] as num?)?.toDouble();
        final fat = (nutriments['fat_100g'] as num?)?.toDouble();
        final saturatedFat = (nutriments['saturated-fat_100g'] as num?)?.toDouble();
        final carbs = (nutriments['carbohydrates_100g'] as num?)?.toDouble();
        final sugar = (nutriments['sugars_100g'] as num?)?.toDouble();
        final fiber = (nutriments['fiber_100g'] as num?)?.toDouble();
        final salt = (nutriments['salt_100g'] as num?)?.toDouble();

        if (kcal != null || protein != null || fat != null || carbs != null) {
          nutrients = IngredientNutrients(
            kcalPer100g: kcal,
            proteinPer100g: protein,
            fatPer100g: fat,
            saturatedFatPer100g: saturatedFat,
            carbsPer100g: carbs,
            sugarPer100g: sugar,
            fiberPer100g: fiber,
            saltPer100g: salt,
          );
        }
      }

      return Ingredient(
        id: barcode,
        name: name,
        barcode: barcode,
        category: category,
        imageUrl: imageUrl,
        nutriScore: nutriScore,
        nutrients: nutrients,
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
