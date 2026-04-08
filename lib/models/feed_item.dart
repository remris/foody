import 'package:kokomi/models/community_recipe.dart';
import 'package:kokomi/models/community_meal_plan.dart';

// ─── SocialPost ───────────────────────────────────────────────────────────────

class SocialPost {
  final String id;
  final String userId;
  final String authorName;
  final String? avatarUrl;
  final String text;
  final String? attachedRecipeId;
  final String? attachedPlanId;
  final CommunityRecipe? attachedRecipe;
  final CommunityMealPlan? attachedPlan;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;
  final DateTime createdAt;

  const SocialPost({
    required this.id,
    required this.userId,
    this.authorName = 'Kokomi-User',
    this.avatarUrl,
    required this.text,
    this.attachedRecipeId,
    this.attachedPlanId,
    this.attachedRecipe,
    this.attachedPlan,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
    required this.createdAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        authorName: (json['author_name'] as String?) ?? 'Kokomi-User',
        avatarUrl: json['avatar_url'] as String?,
        text: json['text'] as String,
        attachedRecipeId: json['attached_recipe_id'] as String?,
        attachedPlanId: json['attached_plan_id'] as String?,
        likeCount: (json['like_count'] as int?) ?? 0,
        commentCount: (json['comment_count'] as int?) ?? 0,
        isLikedByMe: (json['is_liked_by_me'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  SocialPost copyWith({int? likeCount, int? commentCount, bool? isLikedByMe}) =>
      SocialPost(
        id: id, userId: userId, authorName: authorName, avatarUrl: avatarUrl,
        text: text, attachedRecipeId: attachedRecipeId, attachedPlanId: attachedPlanId,
        attachedRecipe: attachedRecipe, attachedPlan: attachedPlan,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        isLikedByMe: isLikedByMe ?? this.isLikedByMe,
        createdAt: createdAt,
      );
}

// ─── SocialPostComment ────────────────────────────────────────────────────────

class SocialPostComment {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String text;
  final DateTime createdAt;

  const SocialPostComment({
    required this.id, required this.postId, required this.userId,
    this.authorName = 'Kokomi-User', required this.text, required this.createdAt,
  });

  factory SocialPostComment.fromJson(Map<String, dynamic> json) => SocialPostComment(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        userId: json['user_id'] as String,
        authorName: (json['author_name'] as String?) ?? 'Kokomi-User',
        text: json['text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

// ─── FeedItem ─────────────────────────────────────────────────────────────────

enum FeedItemType { recipe, plan, post }

/// Unified Feed-Item für Rezepte und Wochenpläne.
class FeedItem {
  final FeedItemType type;
  final CommunityRecipe? recipe;
  final CommunityMealPlan? plan;
  final SocialPost? post;

  const FeedItem._({required this.type, this.recipe, this.plan, this.post});

  factory FeedItem.recipe(CommunityRecipe r) =>
      FeedItem._(type: FeedItemType.recipe, recipe: r);
  factory FeedItem.plan(CommunityMealPlan p) =>
      FeedItem._(type: FeedItemType.plan, plan: p);
  factory FeedItem.post(SocialPost p) =>
      FeedItem._(type: FeedItemType.post, post: p);

  String get id => recipe?.id ?? plan?.id ?? post!.id;
  String get userId => recipe?.userId ?? plan?.userId ?? post!.userId;
  String get authorName => recipe?.authorName ?? plan?.authorName ?? post!.authorName;
  String get title => recipe?.title ?? plan?.title ?? post!.text;
  String get description => recipe?.description ?? plan?.description ?? post!.text;
  List<String> get tags => recipe?.tags ?? plan?.tags ?? const [];
  DateTime get createdAt => recipe?.createdAt ?? plan?.createdAt ?? post!.createdAt;
  int get likeCount => recipe?.likeCount ?? plan?.likeCount ?? post!.likeCount;
  bool get isLikedByMe => recipe?.isLikedByMe ?? plan?.isLikedByMe ?? post!.isLikedByMe;
}
