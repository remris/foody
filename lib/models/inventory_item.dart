class Ingredient {
  final String id;
  final String name;
  final String? barcode;
  final String? category;
  final String? imageUrl;
  final String? nutriScore;

  const Ingredient({
    required this.id,
    required this.name,
    this.barcode,
    this.category,
    this.imageUrl,
    this.nutriScore,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String?,
        category: json['category'] as String?,
        imageUrl: json['image_url'] as String?,
        nutriScore: json['nutri_score'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'category': category,
        'image_url': imageUrl,
        'nutri_score': nutriScore,
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
  });

  /// Ist dieses Item ein Haushalt-Item?
  bool get isHousehold => householdId != null;

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
      );
}

// Sentinel für copyWith um null explizit setzen zu können
const _unset = Object();

