import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// Community (lokale Nachbarschafts-Community)
// ─────────────────────────────────────────────────────────────────────────────
class Community {
  final String id;
  final String name;
  final String? description;
  final String? plz;
  final String? city;
  final String inviteCode;
  final String adminId;
  final int maxMembers;
  final bool isPublic;
  final DateTime createdAt;

  // Optionale Felder die per Join geladen werden können
  final int? memberCount;
  final String? myStatus; // 'active' | 'pending' | 'rejected' | null

  const Community({
    required this.id,
    required this.name,
    this.description,
    this.plz,
    this.city,
    required this.inviteCode,
    required this.adminId,
    this.maxMembers = 50,
    this.isPublic = true,
    required this.createdAt,
    this.memberCount,
    this.myStatus,
  });

  factory Community.fromJson(Map<String, dynamic> json) => Community(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        plz: json['plz'] as String?,
        city: json['city'] as String?,
        inviteCode: json['invite_code'] as String,
        adminId: json['admin_id'] as String,
        maxMembers: (json['max_members'] as int?) ?? 50,
        isPublic: (json['is_public'] as bool?) ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        memberCount: json['member_count'] as int?,
        myStatus: json['my_status'] as String?,
      );

  bool get isFull => memberCount != null && memberCount! >= maxMembers;

  Community copyWith({
    String? name,
    String? description,
    String? plz,
    String? city,
    String? inviteCode,
    int? memberCount,
    String? myStatus,
  }) =>
      Community(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        plz: plz ?? this.plz,
        city: city ?? this.city,
        inviteCode: inviteCode ?? this.inviteCode,
        adminId: adminId,
        maxMembers: maxMembers,
        isPublic: isPublic,
        createdAt: createdAt,
        memberCount: memberCount ?? this.memberCount,
        myStatus: myStatus ?? this.myStatus,
      );

  /// Generiert einen zufälligen 6-stelligen Einladungscode.
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CommunityMember
// ─────────────────────────────────────────────────────────────────────────────
class CommunityMember {
  final String id;
  final String communityId;
  final String userId;
  final String? displayName;
  final String status; // 'pending' | 'active' | 'rejected'
  final DateTime? joinedAt;
  final DateTime createdAt;

  const CommunityMember({
    required this.id,
    required this.communityId,
    required this.userId,
    this.displayName,
    required this.status,
    this.joinedAt,
    required this.createdAt,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) =>
      CommunityMember(
        id: json['id'] as String,
        communityId: json['community_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String?,
        status: json['status'] as String,
        joinedAt: json['joined_at'] != null
            ? DateTime.parse(json['joined_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
}

// ─────────────────────────────────────────────────────────────────────────────
// CommunityPost
// ─────────────────────────────────────────────────────────────────────────────
class CommunityPost {
  final String id;
  final String communityId;
  final String userId;
  final String? authorName;
  final String? authorAvatar;
  final String content;
  final String? recipeId;
  final String? mealPlanId;
  final String? recipeTitle;
  final String? mealPlanTitle;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.userId,
    this.authorName,
    this.authorAvatar,
    required this.content,
    this.recipeId,
    this.mealPlanId,
    this.recipeTitle,
    this.mealPlanTitle,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String,
        communityId: json['community_id'] as String,
        userId: json['user_id'] as String,
        authorName: json['author_name'] as String?,
        authorAvatar: json['author_avatar'] as String?,
        content: json['content'] as String,
        recipeId: json['recipe_id'] as String?,
        mealPlanId: json['meal_plan_id'] as String?,
        recipeTitle: json['recipe_title'] as String?,
        mealPlanTitle: json['meal_plan_title'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CommunityShare (Reste / Vorrat verschenken)
// ─────────────────────────────────────────────────────────────────────────────
class CommunityShare {
  final String id;
  final String communityId;
  final String offeredBy;
  final String? offeredByName;
  final String itemName;
  final String? quantity;
  final String? note;
  final String status; // 'available' | 'claimed' (claimed → sofort gelöscht)
  final DateTime createdAt;

  const CommunityShare({
    required this.id,
    required this.communityId,
    required this.offeredBy,
    this.offeredByName,
    required this.itemName,
    this.quantity,
    this.note,
    this.status = 'available',
    required this.createdAt,
  });

  factory CommunityShare.fromJson(Map<String, dynamic> json) => CommunityShare(
        id: json['id'] as String,
        communityId: json['community_id'] as String,
        offeredBy: json['offered_by'] as String,
        offeredByName: json['offered_by_name'] as String?,
        itemName: json['item_name'] as String,
        quantity: json['quantity'] as String?,
        note: json['note'] as String?,
        status: json['status'] as String? ?? 'available',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CommunityShareRequest (Abholungsanfrage für ein Angebot)
// ─────────────────────────────────────────────────────────────────────────────
class CommunityShareRequest {
  final String id;
  final String shareId;
  final String communityId;
  final String userId;
  final String? displayName;
  final String? message;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;

  const CommunityShareRequest({
    required this.id,
    required this.shareId,
    required this.communityId,
    required this.userId,
    this.displayName,
    this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  factory CommunityShareRequest.fromJson(Map<String, dynamic> json) =>
      CommunityShareRequest(
        id: json['id'] as String,
        shareId: json['share_id'] as String,
        communityId: json['community_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String?,
        message: json['message'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

// ─────────────────────────────────────────────────────────────────────────────
// CommunityHelpRequest (Suchanfrage: "ich brauche X")
// ─────────────────────────────────────────────────────────────────────────────
class CommunityHelpRequest {
  final String id;
  final String communityId;
  final String userId;
  final String? displayName;
  final String itemName;
  final String? quantity;
  final String? note;
  final String status; // 'open' | 'closed'
  final DateTime createdAt;

  // Optional: Anzahl ausstehender Angebote (für Badge)
  final int? offerCount;

  const CommunityHelpRequest({
    required this.id,
    required this.communityId,
    required this.userId,
    this.displayName,
    required this.itemName,
    this.quantity,
    this.note,
    this.status = 'open',
    required this.createdAt,
    this.offerCount,
  });

  factory CommunityHelpRequest.fromJson(Map<String, dynamic> json) =>
      CommunityHelpRequest(
        id: json['id'] as String,
        communityId: json['community_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String?,
        itemName: json['item_name'] as String,
        quantity: json['quantity'] as String?,
        note: json['note'] as String?,
        status: json['status'] as String? ?? 'open',
        createdAt: DateTime.parse(json['created_at'] as String),
        offerCount: json['offer_count'] as int?,
      );

  bool get isOpen => status == 'open';
}

// ─────────────────────────────────────────────────────────────────────────────
// CommunityHelpOffer (Aushelfen-Angebot auf eine Suchanfrage)
// ─────────────────────────────────────────────────────────────────────────────
class CommunityHelpOffer {
  final String id;
  final String requestId;
  final String communityId;
  final String userId;
  final String? displayName;
  final String? message;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;

  const CommunityHelpOffer({
    required this.id,
    required this.requestId,
    required this.communityId,
    required this.userId,
    this.displayName,
    this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  factory CommunityHelpOffer.fromJson(Map<String, dynamic> json) =>
      CommunityHelpOffer(
        id: json['id'] as String,
        requestId: json['request_id'] as String,
        communityId: json['community_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String?,
        message: json['message'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}

// ─────────────────────────────────────────────────────────────────────────────
// CommunityMessage (Mini-Chat für Share & Help)
// ─────────────────────────────────────────────────────────────────────────────
class CommunityMessage {
  final String id;
  final String contextType; // 'share' | 'help'
  final String contextId;   // share_request.id oder help_request.id
  final String communityId;
  final String senderId;
  final String? senderName;
  final String recipientId;
  final String text;
  final DateTime? readAt;
  final DateTime createdAt;

  const CommunityMessage({
    required this.id,
    required this.contextType,
    required this.contextId,
    required this.communityId,
    required this.senderId,
    this.senderName,
    required this.recipientId,
    required this.text,
    this.readAt,
    required this.createdAt,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) =>
      CommunityMessage(
        id: json['id'] as String,
        contextType: json['context_type'] as String,
        contextId: json['context_id'] as String,
        communityId: json['community_id'] as String,
        senderId: json['sender_id'] as String,
        senderName: json['sender_name'] as String?,
        recipientId: json['recipient_id'] as String,
        text: json['text'] as String,
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isRead => readAt != null;
}

