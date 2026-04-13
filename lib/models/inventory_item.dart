/// Nährwerte pro 100g – werden beim Barcode-Scan von OpenFoodFacts befüllt.
class IngredientNutrients {
  final double? kcalPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? saturatedFatPer100g;
  final double? carbsPer100g;
  final double? sugarPer100g;
  final double? fiberPer100g;
  final double? saltPer100g;

  const IngredientNutrients({
    this.kcalPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.saturatedFatPer100g,
    this.carbsPer100g,
    this.sugarPer100g,
    this.fiberPer100g,
    this.saltPer100g,
  });

  bool get hasData =>
      kcalPer100g != null ||
      proteinPer100g != null ||
      fatPer100g != null ||
      carbsPer100g != null;

  factory IngredientNutrients.fromJson(Map<String, dynamic> json) =>
      IngredientNutrients(
        kcalPer100g: (json['kcal_100g'] as num?)?.toDouble(),
        proteinPer100g: (json['protein_100g'] as num?)?.toDouble(),
        fatPer100g: (json['fat_100g'] as num?)?.toDouble(),
        saturatedFatPer100g: (json['saturated_fat_100g'] as num?)?.toDouble(),
        carbsPer100g: (json['carbs_100g'] as num?)?.toDouble(),
        sugarPer100g: (json['sugar_100g'] as num?)?.toDouble(),
        fiberPer100g: (json['fiber_100g'] as num?)?.toDouble(),
        saltPer100g: (json['salt_100g'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'kcal_100g': kcalPer100g,
        'protein_100g': proteinPer100g,
        'fat_100g': fatPer100g,
        'saturated_fat_100g': saturatedFatPer100g,
        'carbs_100g': carbsPer100g,
        'sugar_100g': sugarPer100g,
        'fiber_100g': fiberPer100g,
        'salt_100g': saltPer100g,
      };

  /// Berechnet die Nährwerte für eine gegebene Menge in Gramm.
  IngredientNutrients forGrams(double grams) {
    final factor = grams / 100.0;
    return IngredientNutrients(
      kcalPer100g: kcalPer100g != null ? kcalPer100g! * factor : null,
      proteinPer100g: proteinPer100g != null ? proteinPer100g! * factor : null,
      fatPer100g: fatPer100g != null ? fatPer100g! * factor : null,
      saturatedFatPer100g: saturatedFatPer100g != null ? saturatedFatPer100g! * factor : null,
      carbsPer100g: carbsPer100g != null ? carbsPer100g! * factor : null,
      sugarPer100g: sugarPer100g != null ? sugarPer100g! * factor : null,
      fiberPer100g: fiberPer100g != null ? fiberPer100g! * factor : null,
      saltPer100g: saltPer100g != null ? saltPer100g! * factor : null,
    );
  }
}

class Ingredient {
  final String id;
  final String name;
  final String? barcode;
  final String? category;
  final String? imageUrl;
  final String? nutriScore;
  final IngredientNutrients? nutrients;

  const Ingredient({
    required this.id,
    required this.name,
    this.barcode,
    this.category,
    this.imageUrl,
    this.nutriScore,
    this.nutrients,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String?,
        category: json['category'] as String?,
        imageUrl: json['image_url'] as String?,
        nutriScore: json['nutri_score'] as String?,
        nutrients: json['nutrients'] != null
            ? IngredientNutrients.fromJson(
                json['nutrients'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'category': category,
        'image_url': imageUrl,
        'nutri_score': nutriScore,
        'nutrients': nutrients?.toJson(),
      };
}

class InventoryItem {
  final String id;
  final String userId;
  final String ingredientId;
  final String ingredientName;
  final String? ingredientCategory;
  final String? ingredientImageUrl;
  final double? quantity;
  final String? unit;
  final DateTime? expiryDate;
  final double minThreshold;
  final String? barcode;
  final List<String> tags;
  final String? nutriScore; // 'a','b','c','d','e' von OpenFoodFacts
  final String? householdId;
  final DateTime createdAt;
  final DateTime? openedAt; // neu: Geöffnet-Datum
  /// Nährwerte pro 100g – nur bei gescannten Produkten vorhanden
  final IngredientNutrients? nutrientInfo;

  const InventoryItem({
    required this.id,
    required this.userId,
    required this.ingredientId,
    required this.ingredientName,
    this.ingredientCategory,
    this.ingredientImageUrl,
    this.quantity,
    this.unit,
    this.expiryDate,
    this.minThreshold = 0,
    this.barcode,
    this.tags = const [],
    this.nutriScore,
    this.householdId,
    required this.createdAt,
    this.openedAt,
    this.nutrientInfo,
  });

  /// Ist dieses Item ein Haushalt-Item?
  bool get isHousehold => householdId != null;
  bool get isOpened => openedAt != null;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        ingredientId: json['ingredient_id'] as String,
        ingredientName: json['ingredient_name'] as String,
        ingredientCategory: json['ingredient_category'] as String?,
        ingredientImageUrl: json['ingredient_image_url'] as String?,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        expiryDate: json['expiry_date'] != null
            ? DateTime.parse(json['expiry_date'] as String)
            : null,
        minThreshold: (json['min_threshold'] as num?)?.toDouble() ?? 0,
        barcode: json['barcode'] as String?,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        nutriScore: json['nutri_score'] as String?,
        householdId: json['household_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        openedAt: json['opened_at'] != null
            ? DateTime.parse(json['opened_at'] as String)
            : null,
        nutrientInfo: json['nutrient_info'] != null
            ? IngredientNutrients.fromJson(
                json['nutrient_info'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'ingredient_id': ingredientId,
        'ingredient_name': ingredientName,
        'ingredient_category': ingredientCategory,
        'ingredient_image_url': ingredientImageUrl,
        'quantity': quantity,
        'unit': unit,
        'expiry_date': expiryDate?.toIso8601String(),
        'min_threshold': minThreshold,
        'barcode': barcode,
        'tags': tags,
        'nutri_score': nutriScore,
        'household_id': householdId,
        'created_at': createdAt.toIso8601String(),
        'opened_at': openedAt?.toIso8601String(),
        if (nutrientInfo != null) 'nutrient_info': nutrientInfo!.toJson(),
      };

  InventoryItem copyWith({
    String? id,
    String? userId,
    String? ingredientId,
    String? ingredientName,
    String? ingredientCategory,
    String? ingredientImageUrl,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    double? minThreshold,
    String? barcode,
    List<String>? tags,
    String? nutriScore,
    Object? householdId = _unset,
    DateTime? createdAt,
    Object? openedAt = _unset,
    Object? nutrientInfo = _unset,
  }) =>
      InventoryItem(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        ingredientId: ingredientId ?? this.ingredientId,
        ingredientName: ingredientName ?? this.ingredientName,
        ingredientCategory: ingredientCategory ?? this.ingredientCategory,
        ingredientImageUrl: ingredientImageUrl ?? this.ingredientImageUrl,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        expiryDate: expiryDate ?? this.expiryDate,
        minThreshold: minThreshold ?? this.minThreshold,
        barcode: barcode ?? this.barcode,
        tags: tags ?? this.tags,
        nutriScore: nutriScore ?? this.nutriScore,
        householdId: householdId == _unset
            ? this.householdId
            : householdId as String?,
        createdAt: createdAt ?? this.createdAt,
        openedAt: openedAt == _unset ? this.openedAt : openedAt as DateTime?,
        nutrientInfo: nutrientInfo == _unset
            ? this.nutrientInfo
            : nutrientInfo as IngredientNutrients?,
      );
}

// Sentinel für copyWith um null explizit setzen zu können
const _unset = Object();
