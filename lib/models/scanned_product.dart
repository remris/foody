
/// Ein gescanntes Produkt mit Scan-Zähler und Favoritenstatus.
class ScannedProduct {
  final String id;
  final String userId;
  final String barcode;
  final String productName;
  final Map<String, dynamic>? productData;
  final int scanCount;
  final bool isFavorite;
  final DateTime lastScannedAt;
  final DateTime createdAt;

  const ScannedProduct({
    required this.id,
    required this.userId,
    required this.barcode,
    required this.productName,
    this.productData,
    this.scanCount = 1,
    this.isFavorite = false,
    required this.lastScannedAt,
    required this.createdAt,
  });

  factory ScannedProduct.fromJson(Map<String, dynamic> json) => ScannedProduct(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        barcode: json['barcode'] as String,
        productName: json['product_name'] as String,
        productData: json['product_data'] as Map<String, dynamic>?,
        scanCount: json['scan_count'] as int? ?? 1,
        isFavorite: json['is_favorite'] as bool? ?? false,
        lastScannedAt: DateTime.parse(json['last_scanned_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'barcode': barcode,
        'product_name': productName,
        'product_data': productData,
        'scan_count': scanCount,
        'is_favorite': isFavorite,
        'last_scanned_at': lastScannedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  ScannedProduct copyWith({
    String? id,
    String? userId,
    String? barcode,
    String? productName,
    Map<String, dynamic>? productData,
    int? scanCount,
    bool? isFavorite,
    DateTime? lastScannedAt,
    DateTime? createdAt,
  }) =>
      ScannedProduct(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        barcode: barcode ?? this.barcode,
        productName: productName ?? this.productName,
        productData: productData ?? this.productData,
        scanCount: scanCount ?? this.scanCount,
        isFavorite: isFavorite ?? this.isFavorite,
        lastScannedAt: lastScannedAt ?? this.lastScannedAt,
        createdAt: createdAt ?? this.createdAt,
      );
}

