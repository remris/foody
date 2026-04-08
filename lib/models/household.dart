class Household {
  final String id;
  final String name;
  final String createdBy;
  final String? inviteCode;
  final DateTime createdAt;
  // Admin-gesteuerte Feature-Flags (für alle Mitglieder gültig)
  final bool sharedInventory;
  final bool sharedShoppingList;
  final bool sharedMealPlan;

  const Household({
    required this.id,
    required this.name,
    required this.createdBy,
    this.inviteCode,
    required this.createdAt,
    this.sharedInventory = true,
    this.sharedShoppingList = true,
    this.sharedMealPlan = false,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      sharedInventory: _parseBool(json['shared_inventory'], defaultValue: true),
      sharedShoppingList: _parseBool(json['shared_shopping_list'], defaultValue: true),
      sharedMealPlan: _parseBool(json['shared_meal_plan'], defaultValue: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_by': createdBy,
        'invite_code': inviteCode,
        'created_at': createdAt.toIso8601String(),
        'shared_inventory': sharedInventory,
        'shared_shopping_list': sharedShoppingList,
        'shared_meal_plan': sharedMealPlan,
      };

  Household copyWith({
    String? name,
    String? inviteCode,
    bool? sharedInventory,
    bool? sharedShoppingList,
    bool? sharedMealPlan,
  }) =>
      Household(
        id: id,
        name: name ?? this.name,
        createdBy: createdBy,
        inviteCode: inviteCode ?? this.inviteCode,
        createdAt: createdAt,
        sharedInventory: sharedInventory ?? this.sharedInventory,
        sharedShoppingList: sharedShoppingList ?? this.sharedShoppingList,
        sharedMealPlan: sharedMealPlan ?? this.sharedMealPlan,
      );
}

class HouseholdMember {
  final String id;
  final String householdId;
  final String userId;
  final String role; // 'admin' oder 'member'
  final String? displayName;
  final DateTime joinedAt;

  const HouseholdMember({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.role,
    this.displayName,
    required this.joinedAt,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) =>
      HouseholdMember(
        id: json['id'] as String,
        householdId: json['household_id'] as String,
        userId: json['user_id'] as String,
        role: json['role'] as String? ?? 'member',
        displayName: json['display_name'] as String?,
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'household_id': householdId,
        'user_id': userId,
        'role': role,
        'display_name': displayName,
        'joined_at': joinedAt.toIso8601String(),
      };

  bool get isAdmin => role == 'admin';
}

class HouseholdJoinRequest {
  final String id;
  final String householdId;
  final String userId;
  final String? displayName;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  const HouseholdJoinRequest({
    required this.id,
    required this.householdId,
    required this.userId,
    this.displayName,
    required this.status,
    required this.createdAt,
  });

  factory HouseholdJoinRequest.fromJson(Map<String, dynamic> json) =>
      HouseholdJoinRequest(
        id: json['id'] as String,
        householdId: json['household_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Sicherer bool-Parser: funktioniert auch wenn die DB-Spalte noch nicht existiert (null).
bool _parseBool(dynamic value, {required bool defaultValue}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value == 'true' || value == '1';
  return defaultValue;
}
