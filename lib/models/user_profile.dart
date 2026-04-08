class SocialLinks {
  final String? instagram;
  final String? tiktok;
  final String? youtube;
  final String? website;

  const SocialLinks({
    this.instagram,
    this.tiktok,
    this.youtube,
    this.website,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) => SocialLinks(
        instagram: json['instagram'] as String?,
        tiktok: json['tiktok'] as String?,
        youtube: json['youtube'] as String?,
        website: json['website'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (instagram != null && instagram!.isNotEmpty) 'instagram': instagram,
        if (tiktok != null && tiktok!.isNotEmpty) 'tiktok': tiktok,
        if (youtube != null && youtube!.isNotEmpty) 'youtube': youtube,
        if (website != null && website!.isNotEmpty) 'website': website,
      };

  SocialLinks copyWith({
    String? instagram,
    String? tiktok,
    String? youtube,
    String? website,
  }) =>
      SocialLinks(
        instagram: instagram ?? this.instagram,
        tiktok: tiktok ?? this.tiktok,
        youtube: youtube ?? this.youtube,
        website: website ?? this.website,
      );

  bool get isEmpty =>
      (instagram == null || instagram!.isEmpty) &&
      (tiktok == null || tiktok!.isEmpty) &&
      (youtube == null || youtube!.isEmpty) &&
      (website == null || website!.isEmpty);
}

class UserProfile {
  final String id;
  final String displayName;
  /// Spitzname für den Haushalt (optional, nur intern sichtbar für Haushaltsmitglieder)
  final String? householdNickname;
  final String bio;
  final String? avatarUrl;
  final SocialLinks socialLinks;
  final int recipeCount;
  final int followerCount;
  final int followingCount;
  final bool isFollowedByMe;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.householdNickname,
    this.bio = '',
    this.avatarUrl,
    this.socialLinks = const SocialLinks(),
    this.recipeCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowedByMe = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final linksRaw = json['social_links'];
    final links = linksRaw is Map<String, dynamic>
        ? SocialLinks.fromJson(linksRaw)
        : const SocialLinks();

    return UserProfile(
      id: json['id'] as String,
      displayName: (json['display_name'] as String?) ?? '',
      householdNickname: json['household_nickname'] as String?,
      bio: (json['bio'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      socialLinks: links,
      recipeCount: (json['recipe_count'] as int?) ?? 0,
      followerCount: (json['follower_count'] as int?) ?? 0,
      followingCount: (json['following_count'] as int?) ?? 0,
      isFollowedByMe: (json['is_followed_by_me'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        if (householdNickname != null && householdNickname!.isNotEmpty)
          'household_nickname': householdNickname,
        'bio': bio,
        'avatar_url': avatarUrl,
        'social_links': socialLinks.toJson(),
      };

  UserProfile copyWith({
    String? displayName,
    String? householdNickname,
    bool clearHouseholdNickname = false,
    String? bio,
    String? avatarUrl,
    SocialLinks? socialLinks,
    int? recipeCount,
    int? followerCount,
    int? followingCount,
    bool? isFollowedByMe,
  }) =>
      UserProfile(
        id: id,
        displayName: displayName ?? this.displayName,
        householdNickname: clearHouseholdNickname
            ? null
            : (householdNickname ?? this.householdNickname),
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        socialLinks: socialLinks ?? this.socialLinks,
        recipeCount: recipeCount ?? this.recipeCount,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount ?? this.followingCount,
        isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      );

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty || displayName.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

