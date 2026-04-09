import 'package:kokomu/features/meal_plan/presentation/meal_plan_provider.dart';

/// Ein Community-Wochenplan der geteilt, bewertet und übernommen werden kann.
class CommunityMealPlan {
  final String id;
  final String userId;
  final String authorName;
  final String title;
  final String description;
  final List<dynamic> planJson; // Raw JSON der MealPlanEntry-Liste
  final List<String> tags;
  final bool isPublished;
  final int viewCount;
  final DateTime createdAt;

  // Computed / joined fields
  final int likeCount;
  final bool isLikedByMe;
  final bool isSavedByMe;
  final double? avgRating;
  final int ratingCount;

  const CommunityMealPlan({
    required this.id,
    required this.userId,
    this.authorName = 'Anonym',
    required this.title,
    this.description = '',
    required this.planJson,
    this.tags = const [],
    this.isPublished = true,
    this.viewCount = 0,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.isSavedByMe = false,
    this.avgRating,
    this.ratingCount = 0,
  });

  factory CommunityMealPlan.fromJson(Map<String, dynamic> json) {
    return CommunityMealPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      authorName: (json['author_name'] as String?) ?? 'kokomu-User',
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      planJson: (json['plan_json'] as List<dynamic>?) ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPublished: (json['is_published'] as bool?) ?? true,
      viewCount: (json['view_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: (json['like_count'] as int?) ?? 0,
      isLikedByMe: (json['is_liked_by_me'] as bool?) ?? false,
      isSavedByMe: (json['is_saved_by_me'] as bool?) ?? false,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'author_name': authorName,
        'title': title,
        'description': description,
        'plan_json': planJson,
        'tags': tags,
        'is_published': isPublished,
      };

  /// Konvertiert planJson in MealPlanEntry-Liste.
  List<MealPlanEntry> get entries {
    try {
      return planJson
          .map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Alle Rezept-Titel des Plans
  List<String> get recipeTitles {
    final e = entries;
    return e.map((entry) => entry.recipe.title).toSet().toList();
  }

  /// Wochentag-Namen mit ihren Rezepten (für Vorschau)
  Map<String, List<String>> get weekPreview {
    const dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final result = <String, List<String>>{};
    for (final entry in entries) {
      final day = dayNames[entry.dayIndex.clamp(0, 6)];
      result.putIfAbsent(day, () => []);
      result[day]!.add(entry.recipe.title);
    }
    return result;
  }

  /// Durchschnittliche Kalorien pro Tag
  int get avgDailyCalories {
    final e = entries;
    if (e.isEmpty) return 0;
    final total = e.fold(0, (sum, entry) => sum + (entry.recipe.nutrition?.calories ?? 0));
    final days = e.map((entry) => entry.dayIndex).toSet().length;
    return days > 0 ? total ~/ days : 0;
  }

  CommunityMealPlan copyWith({
    bool? isLikedByMe,
    int? likeCount,
    bool? isSavedByMe,
    double? avgRating,
    int? ratingCount,
  }) {
    return CommunityMealPlan(
      id: id,
      userId: userId,
      authorName: authorName,
      title: title,
      description: description,
      planJson: planJson,
      tags: tags,
      isPublished: isPublished,
      viewCount: viewCount,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}

