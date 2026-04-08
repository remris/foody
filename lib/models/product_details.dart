/// Detaillierte Produktinformationen aus OpenFoodFacts.
class ProductDetails {
  final String barcode;
  final String name;
  final String? brands;
  final String? packagingQuantity;
  final String? imageUrl;
  final String? nutriscoreGrade;
  final List<String> allergensTags;
  final List<String> labelsTags;
  final NutrientInfo? nutriments;

  const ProductDetails({
    required this.barcode,
    required this.name,
    this.brands,
    this.packagingQuantity,
    this.imageUrl,
    this.nutriscoreGrade,
    this.allergensTags = const [],
    this.labelsTags = const [],
    this.nutriments,
  });
}

/// Nährwerte pro 100g.
class NutrientInfo {
  final double? energyKcal;
  final double? fat;
  final double? saturatedFat;
  final double? carbohydrates;
  final double? sugars;
  final double? proteins;
  final double? salt;
  final double? fiber;

  const NutrientInfo({
    this.energyKcal,
    this.fat,
    this.saturatedFat,
    this.carbohydrates,
    this.sugars,
    this.proteins,
    this.salt,
    this.fiber,
  });

  factory NutrientInfo.fromOpenFoodFacts(Map<String, dynamic> json) {
    return NutrientInfo(
      energyKcal: (json['energy-kcal_100g'] as num?)?.toDouble(),
      fat: (json['fat_100g'] as num?)?.toDouble(),
      saturatedFat: (json['saturated-fat_100g'] as num?)?.toDouble(),
      carbohydrates: (json['carbohydrates_100g'] as num?)?.toDouble(),
      sugars: (json['sugars_100g'] as num?)?.toDouble(),
      proteins: (json['proteins_100g'] as num?)?.toDouble(),
      salt: (json['salt_100g'] as num?)?.toDouble(),
      fiber: (json['fiber_100g'] as num?)?.toDouble(),
    );
  }
}

