import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rezept-Collections: Eigene Ordner für gespeicherte Rezepte.
/// z.B. "Schnelle Gerichte", "Meal Prep", "Party-Food"

class RecipeCollection {
  final String id;
  final String name;
  final String emoji;
  final List<String> recipeTitles; // Rezept-Titel als Keys

  const RecipeCollection({
    required this.id,
    required this.name,
    this.emoji = '📁',
    this.recipeTitles = const [],
  });

  RecipeCollection copyWith({
    String? name,
    String? emoji,
    List<String>? recipeTitles,
  }) =>
      RecipeCollection(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        recipeTitles: recipeTitles ?? this.recipeTitles,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'recipeTitles': recipeTitles,
      };

  factory RecipeCollection.fromJson(Map<String, dynamic> json) =>
      RecipeCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '📁',
        recipeTitles: (json['recipeTitles'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
      );
}

class RecipeCollectionsNotifier extends Notifier<List<RecipeCollection>> {
  static const _key = 'recipe_collections';

  @override
  List<RecipeCollection> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return;
    try {
      final list = (jsonDecode(json) as List)
          .map((e) => RecipeCollection.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> createCollection(String name, {String emoji = '📁'}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    state = [...state, RecipeCollection(id: id, name: name, emoji: emoji)];
    await _save();
  }

  Future<void> deleteCollection(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _save();
  }

  Future<void> renameCollection(String id, String newName) async {
    state = state
        .map((c) => c.id == id ? c.copyWith(name: newName) : c)
        .toList();
    await _save();
  }

  Future<void> addRecipeToCollection(
      String collectionId, String recipeTitle) async {
    state = state.map((c) {
      if (c.id != collectionId) return c;
      if (c.recipeTitles.contains(recipeTitle)) return c;
      return c.copyWith(recipeTitles: [...c.recipeTitles, recipeTitle]);
    }).toList();
    await _save();
  }

  Future<void> removeRecipeFromCollection(
      String collectionId, String recipeTitle) async {
    state = state.map((c) {
      if (c.id != collectionId) return c;
      return c.copyWith(
        recipeTitles: c.recipeTitles.where((t) => t != recipeTitle).toList(),
      );
    }).toList();
    await _save();
  }

  /// Alle Collections die ein bestimmtes Rezept enthalten.
  List<RecipeCollection> collectionsForRecipe(String recipeTitle) {
    return state.where((c) => c.recipeTitles.contains(recipeTitle)).toList();
  }
}

final recipeCollectionsProvider =
    NotifierProvider<RecipeCollectionsNotifier, List<RecipeCollection>>(
  RecipeCollectionsNotifier.new,
);

