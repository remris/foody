class ShoppingList {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final DateTime createdAt;
  final String? householdId; // null = privat, gesetzt = Haushalt geteilt

  const ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    this.icon = 'shopping_cart',
    required this.createdAt,
    this.householdId,
  });

  bool get isShared => householdId != null;

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'shopping_cart',
        createdAt: DateTime.parse(json['created_at'] as String),
        householdId: json['household_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'icon': icon,
        'created_at': createdAt.toIso8601String(),
        if (householdId != null) 'household_id': householdId,
      };

  ShoppingList copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    DateTime? createdAt,
    String? householdId,
    bool clearHousehold = false,
  }) =>
      ShoppingList(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        createdAt: createdAt ?? this.createdAt,
        householdId: clearHousehold ? null : (householdId ?? this.householdId),
      );
}
