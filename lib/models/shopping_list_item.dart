class ShoppingListItem {
  final String id;
  final String listId;
  final String userId;
  final String name;
  final String? quantity;
  final bool isChecked;
  final DateTime createdAt;

  const ShoppingListItem({
    required this.id,
    required this.listId,
    required this.userId,
    required this.name,
    this.quantity,
    required this.isChecked,
    required this.createdAt,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) =>
      ShoppingListItem(
        id: json['id'] as String,
        listId: json['list_id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        quantity: json['quantity'] as String?,
        isChecked: json['is_checked'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'list_id': listId,
        'user_id': userId,
        'name': name,
        'quantity': quantity,
        'is_checked': isChecked,
        'created_at': createdAt.toIso8601String(),
      };

  ShoppingListItem copyWith({
    String? id,
    String? listId,
    String? userId,
    String? name,
    String? quantity,
    bool? isChecked,
    DateTime? createdAt,
  }) =>
      ShoppingListItem(
        id: id ?? this.id,
        listId: listId ?? this.listId,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        isChecked: isChecked ?? this.isChecked,
        createdAt: createdAt ?? this.createdAt,
      );
}

