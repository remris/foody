import 'package:kokomi/models/recipe.dart';

class CommunityRecipe {
  final String id;
  final String userId;
  final String authorName;
  final String title;
  final String description;
  final Map<String, dynamic> recipeJson;
  final String? imageUrl;
  final List<String> tags;
  final String? category;
  final String difficulty;
  final int cookingTimeMinutes;
  final int servings;
  final bool isPublished;
  final String source;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed / joined fields
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;
  final double? avgRating;
  final int ratingCount;
  final int? myRating;

  const CommunityRecipe({
    required this.id,
    required this.userId,
    this.authorName = 'Anonym',
    required this.title,
    this.description = '',
    required this.recipeJson,
    this.imageUrl,
    this.tags = const [],
    this.category,
    this.difficulty = 'Mittel',
    this.cookingTimeMinutes = 30,
    this.servings = 2,
    this.isPublished = true,
    this.source = 'community',
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
    this.avgRating,
    this.ratingCount = 0,
    this.myRating,
  });

  factory CommunityRecipe.fromJson(Map<String, dynamic> json) {
    return CommunityRecipe(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      authorName: (json['author_name'] as String?) ?? 'Kokomi-User',
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      recipeJson: (json['recipe_json'] as Map<String, dynamic>?) ?? {},
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      category: json['category'] as String?,
      difficulty: (json['difficulty'] as String?) ?? 'Mittel',
      cookingTimeMinutes: (json['cooking_time_minutes'] as int?) ?? 30,
      servings: (json['servings'] as int?) ?? 2,
      isPublished: (json['is_published'] as bool?) ?? true,
      source: (json['source'] as String?) ?? 'community',
      viewCount: (json['view_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
          (json['updated_at'] as String?) ?? json['created_at'] as String),
      likeCount: (json['like_count'] as int?) ?? 0,
      commentCount: (json['comment_count'] as int?) ?? 0,
      isLikedByMe: (json['is_liked_by_me'] as bool?) ?? false,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as int?) ?? 0,
      myRating: json['my_rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'author_name': authorName,
        'title': title,
        'description': description,
        'recipe_json': recipeJson,
        'image_url': imageUrl,
        'tags': tags,
        'category': category,
        'difficulty': difficulty,
        'cooking_time_minutes': cookingTimeMinutes,
        'servings': servings,
        'is_published': isPublished,
        'source': source,
      };

  /// Aus einem gespeicherten KI-/manuellen Rezept eine Community-Version erstellen
  factory CommunityRecipe.fromFoodRecipe(
    FoodRecipe recipe, {
    required String userId,
    required String authorName,
  }) {
    return CommunityRecipe(
      id: '',
      userId: userId,
      authorName: authorName,
      title: recipe.title,
      description: recipe.description,
      recipeJson: recipe.toJson(),
      tags: [],
      difficulty: recipe.difficulty,
      cookingTimeMinutes: recipe.cookingTimeMinutes,
      servings: recipe.servings,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  CommunityRecipe copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? title,
    String? description,
    Map<String, dynamic>? recipeJson,
    String? imageUrl,
    List<String>? tags,
    String? category,
    String? difficulty,
    int? cookingTimeMinutes,
    int? servings,
    bool? isPublished,
    String? source,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
    double? avgRating,
    int? ratingCount,
    int? myRating,
  }) =>
      CommunityRecipe(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        authorName: authorName ?? this.authorName,
        title: title ?? this.title,
        description: description ?? this.description,
        recipeJson: recipeJson ?? this.recipeJson,
        imageUrl: imageUrl ?? this.imageUrl,
        tags: tags ?? this.tags,
        category: category ?? this.category,
        difficulty: difficulty ?? this.difficulty,
        cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
        servings: servings ?? this.servings,
        isPublished: isPublished ?? this.isPublished,
        source: source ?? this.source,
        viewCount: viewCount ?? this.viewCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        isLikedByMe: isLikedByMe ?? this.isLikedByMe,
        avgRating: avgRating ?? this.avgRating,
        ratingCount: ratingCount ?? this.ratingCount,
        myRating: myRating ?? this.myRating,
      );

  /// Zugehöriges FoodRecipe-Objekt aus recipeJson rekonstruieren
  FoodRecipe toFoodRecipe() {
    try {
      final r = FoodRecipe.fromJson(recipeJson);
      // imageUrl aus community_recipe bevorzugen, dann aus recipeJson
      return r.copyWith(imageUrl: imageUrl ?? r.imageUrl);
    } catch (_) {
      return FoodRecipe(
        id: id,
        title: title,
        description: description,
        ingredients: const [],
        steps: const [],
        cookingTimeMinutes: cookingTimeMinutes,
        difficulty: difficulty,
        servings: servings,
        imageUrl: imageUrl,
      );
    }
  }
}

class RecipeComment {
  final String id;
  final String recipeId;
  final String userId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const RecipeComment({
    required this.id,
    required this.recipeId,
    required this.userId,
    this.authorName = 'Kokomi-User',
    required this.content,
    required this.createdAt,
  });

  factory RecipeComment.fromJson(Map<String, dynamic> json) {
    return RecipeComment(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      userId: json['user_id'] as String,
      authorName: (json['author_name'] as String?) ?? 'Kokomi-User',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'recipe_id': recipeId,
        'user_id': userId,
        'author_name': authorName,
        'content': content,
      };
}

