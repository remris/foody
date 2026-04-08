class RecipeIngredient {
  final String name;
  final String amount;

  const RecipeIngredient({required this.name, required this.amount});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'] as String,
        amount: json['amount'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
      };
}

class FoodRecipe {
  final String id;
  final String title;
  final String description;
  final int cookingTimeMinutes;
  final String difficulty;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final NutritionInfo? nutrition;
  final String? imageUrl;
  /// Tags z.B. ['Vegan', 'Airfryer', 'OnePot']
  final List<String> tags;
  /// 'own' = selbst erstellt, 'community' = von Community gespeichert, 'ai' = KI-generiert
  /// 'manual' ist ein Legacy-Wert und wird zu 'own' normalisiert
  final String? _source;
  String get source {
    final s = _source ?? 'ai';
    return s == 'manual' ? 'own' : s;
  }
  /// Die DB-ID des saved_recipes Eintrags (für Löschoperationen)
  final String? savedRecipeId;

  const FoodRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.cookingTimeMinutes,
    required this.difficulty,
    this.servings = 2,
    required this.ingredients,
    required this.steps,
    this.nutrition,
    this.imageUrl,
    this.tags = const [],
    String source = 'ai',
    this.savedRecipeId,
  }) : _source = source;

  factory FoodRecipe.fromJson(Map<String, dynamic> json) => FoodRecipe(
        id: json['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String,
        description: json['description'] as String,
        cookingTimeMinutes: json['cookingTimeMinutes'] as int? ?? 30,
        difficulty: json['difficulty'] as String? ?? 'Mittel',
        servings: json['servings'] as int? ?? 2,
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.map((e) =>
                    RecipeIngredient.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        steps: (json['steps'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        nutrition: json['nutrition'] != null
            ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
            : null,
        imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        source: (json['source'] as String?) ?? 'ai',
        savedRecipeId: (json['savedRecipeId'] as String?) ?? (json['saved_recipe_id'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'cookingTimeMinutes': cookingTimeMinutes,
        'difficulty': difficulty,
        'servings': servings,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps,
        'nutrition': nutrition?.toJson(),
        'imageUrl': imageUrl,
        'tags': tags,
        'source': source,
        'savedRecipeId': savedRecipeId,
      };

  FoodRecipe copyWith({
    String? id,
    String? title,
    String? description,
    int? cookingTimeMinutes,
    String? difficulty,
    int? servings,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    NutritionInfo? nutrition,
    String? imageUrl,
    List<String>? tags,
    String? source,
    String? savedRecipeId,
  }) =>
      FoodRecipe(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
        difficulty: difficulty ?? this.difficulty,
        servings: servings ?? this.servings,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        nutrition: nutrition ?? this.nutrition,
        imageUrl: imageUrl ?? this.imageUrl,
        tags: tags ?? this.tags,
        source: source ?? this.source,
        savedRecipeId: savedRecipeId ?? this.savedRecipeId,
      );
}
