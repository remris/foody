import 'package:kokomu/models/recipe.dart';

/// Lokaler Rezept-Generator – funktioniert komplett offline ohne API.
/// Wird als Fallback verwendet wenn OpenAI nicht verfügbar ist.
class LocalRecipeService {
  /// Generiert Rezepte basierend auf vorhandenen Zutaten.
  List<FoodRecipe> generateFromIngredients(List<String> ingredients) {
    final lower = ingredients.map((e) => e.toLowerCase()).toSet();
    final matches = <_RecipeTemplate>[];

    for (final tpl in _templates) {
      final matchCount = tpl.keyIngredients
          .where((k) => lower.any((i) => i.contains(k)))
          .length;
      if (matchCount > 0) {
        matches.add(tpl);
      }
    }

    // Sortierung nach Übereinstimmungen, dann zufällig auffüllen
    matches.sort((a, b) {
      final aMatch = a.keyIngredients
          .where((k) => lower.any((i) => i.contains(k)))
          .length;
      final bMatch = b.keyIngredients
          .where((k) => lower.any((i) => i.contains(k)))
          .length;
      return bMatch.compareTo(aMatch);
    });

    // Mind. 3 Rezepte – rest mit allgemeinen Rezepten auffüllen
    final result = matches.take(3).toList();
    if (result.length < 3) {
      for (final tpl in _fallbackTemplates) {
        if (result.length >= 3) break;
        if (!result.contains(tpl)) result.add(tpl);
      }
    }

    return result.take(3).map((t) => t.toRecipe()).toList();
  }

  /// Generiert Rezepte basierend auf einem Freitext-Prompt.
  List<FoodRecipe> generateFromPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    final matches = <_RecipeTemplate>[];

    for (final tpl in _templates) {
      if (tpl.tags.any((tag) => lower.contains(tag))) {
        matches.add(tpl);
      }
    }

    if (matches.isEmpty) return _fallbackTemplates.take(3).map((t) => t.toRecipe()).toList();
    return matches.take(3).map((t) => t.toRecipe()).toList();
  }

  // ── Rezept-Vorlagen ──────────────────────────────────────────────────────

  static final List<_RecipeTemplate> _templates = [
    _RecipeTemplate(
      title: 'Spaghetti Bolognese',
      description: 'Nudeln · Klassisch Italienisch',
      keyIngredients: ['nudel', 'spaghetti', 'hackfleisch', 'tomate', 'rind'],
      tags: ['pasta', 'nudel', 'italienisch', 'hackfleisch', 'bolognese'],
      cookingTime: 35,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Spaghetti', amount: '400g'),
        RecipeIngredient(name: 'Hackfleisch', amount: '500g'),
        RecipeIngredient(name: 'Tomaten (Dose)', amount: '400g'),
        RecipeIngredient(name: 'Zwiebel', amount: '1 Stück'),
        RecipeIngredient(name: 'Knoblauch', amount: '2 Zehen'),
        RecipeIngredient(name: 'Olivenöl', amount: '2 EL'),
        RecipeIngredient(name: 'Salz & Pfeffer', amount: 'nach Geschmack'),
      ],
      steps: [
        'Zwiebel und Knoblauch fein hacken.',
        'Olivenöl in einer Pfanne erhitzen, Zwiebel und Knoblauch darin glasig dünsten.',
        'Hackfleisch hinzufügen und krümelig braten.',
        'Tomaten dazugeben, mit Salz und Pfeffer würzen, 20 Min. köcheln lassen.',
        'Spaghetti nach Packungsanleitung al dente kochen.',
        'Sauce über die Nudeln geben und servieren.',
      ],
    ),
    _RecipeTemplate(
      title: 'Rührei mit Gemüse',
      description: 'Frühstück · Schnell & Einfach',
      keyIngredients: ['ei', 'eier', 'paprika', 'tomate', 'zwiebel'],
      tags: ['ei', 'frühstück', 'rührei', 'schnell', 'vegetarisch'],
      cookingTime: 15,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Eier', amount: '4 Stück'),
        RecipeIngredient(name: 'Paprika', amount: '1 Stück'),
        RecipeIngredient(name: 'Tomate', amount: '1 Stück'),
        RecipeIngredient(name: 'Butter', amount: '1 EL'),
        RecipeIngredient(name: 'Salz & Pfeffer', amount: 'nach Geschmack'),
      ],
      steps: [
        'Paprika und Tomate in kleine Würfel schneiden.',
        'Butter in einer Pfanne bei mittlerer Hitze schmelzen.',
        'Gemüse 3 Min. anbraten.',
        'Eier verquirlen, salzen und pfeffern.',
        'Eier in die Pfanne geben und unter Rühren stocken lassen.',
        'Sofort servieren.',
      ],
    ),
    _RecipeTemplate(
      title: 'Hähnchen-Pfanne',
      description: 'Fleisch · Proteinreich',
      keyIngredients: ['hähnchen', 'hühnchen', 'huhn', 'chicken', 'paprika'],
      tags: ['hähnchen', 'hühnchen', 'huhn', 'fleisch', 'pfanne', 'chicken'],
      cookingTime: 25,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Hähnchenbrust', amount: '600g'),
        RecipeIngredient(name: 'Paprika (mix)', amount: '2 Stück'),
        RecipeIngredient(name: 'Zwiebel', amount: '1 Stück'),
        RecipeIngredient(name: 'Knoblauch', amount: '2 Zehen'),
        RecipeIngredient(name: 'Olivenöl', amount: '2 EL'),
        RecipeIngredient(name: 'Paprikapulver', amount: '1 TL'),
        RecipeIngredient(name: 'Salz & Pfeffer', amount: 'nach Geschmack'),
      ],
      steps: [
        'Hähnchenbrust in Streifen schneiden, würzen.',
        'Öl in Pfanne erhitzen, Hähnchen 5 Min. anbraten, herausnehmen.',
        'Zwiebel, Knoblauch und Paprika im gleichen Öl braten.',
        'Hähnchen zurück in die Pfanne geben.',
        'Mit Paprikapulver würzen und 5 Min. fertig garen.',
        'Mit Reis oder Brot servieren.',
      ],
    ),
    _RecipeTemplate(
      title: 'Kartoffelsuppe',
      description: 'Suppe · Herzhaft & Warm',
      keyIngredients: ['kartoffel', 'karotte', 'zwiebel', 'sellerie'],
      tags: ['suppe', 'kartoffel', 'warm', 'herzhaft', 'vegetarisch'],
      cookingTime: 40,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Kartoffeln', amount: '800g'),
        RecipeIngredient(name: 'Karotten', amount: '2 Stück'),
        RecipeIngredient(name: 'Zwiebel', amount: '1 Stück'),
        RecipeIngredient(name: 'Gemüsebrühe', amount: '1 Liter'),
        RecipeIngredient(name: 'Butter', amount: '1 EL'),
        RecipeIngredient(name: 'Petersilie', amount: 'etwas'),
        RecipeIngredient(name: 'Salz & Pfeffer', amount: 'nach Geschmack'),
      ],
      steps: [
        'Kartoffeln, Karotten und Zwiebel schälen und würfeln.',
        'Butter im Topf erhitzen, Zwiebel glasig dünsten.',
        'Kartoffeln und Karotten hinzugeben, kurz anbraten.',
        'Mit Brühe aufgießen und 25 Min. köcheln lassen.',
        'Mit einem Stabmixer pürieren oder stückig lassen.',
        'Mit Salz, Pfeffer und Petersilie abschmecken.',
      ],
    ),
    _RecipeTemplate(
      title: 'Tomatensuppe',
      description: 'Suppe · Klassisch',
      keyIngredients: ['tomate', 'tomaten'],
      tags: ['tomate', 'suppe', 'vegetarisch', 'schnell'],
      cookingTime: 25,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Tomaten', amount: '800g'),
        RecipeIngredient(name: 'Zwiebel', amount: '1 Stück'),
        RecipeIngredient(name: 'Knoblauch', amount: '2 Zehen'),
        RecipeIngredient(name: 'Gemüsebrühe', amount: '400ml'),
        RecipeIngredient(name: 'Olivenöl', amount: '2 EL'),
        RecipeIngredient(name: 'Basilikum', amount: 'etwas'),
      ],
      steps: [
        'Zwiebel und Knoblauch hacken, in Öl anbraten.',
        'Tomaten grob würfeln, dazugeben und 10 Min. köcheln.',
        'Brühe hinzufügen, weitere 10 Min. köcheln.',
        'Mit Stabmixer pürieren.',
        'Mit Basilikum, Salz und Pfeffer abschmecken.',
      ],
    ),
    _RecipeTemplate(
      title: 'Gebratener Reis',
      description: 'Asiatisch · Schnell',
      keyIngredients: ['reis', 'ei', 'eier', 'karotte'],
      tags: ['reis', 'asiatisch', 'schnell', 'gebratener reis'],
      cookingTime: 20,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Gekochter Reis (Vortag)', amount: '400g'),
        RecipeIngredient(name: 'Eier', amount: '2 Stück'),
        RecipeIngredient(name: 'Karotte', amount: '1 Stück'),
        RecipeIngredient(name: 'Frühlingszwiebeln', amount: '2 Stück'),
        RecipeIngredient(name: 'Sojasoße', amount: '3 EL'),
        RecipeIngredient(name: 'Sesamöl', amount: '1 EL'),
      ],
      steps: [
        'Öl im Wok bei hoher Hitze erhitzen.',
        'Karotten und Frühlingszwiebeln kurz anbraten.',
        'Reis hinzufügen und 3 Min. unter Rühren braten.',
        'Eier am Rand aufschlagen und rühren.',
        'Alles gut vermengen.',
        'Mit Sojasoße und Sesamöl abschmecken.',
      ],
    ),
    _RecipeTemplate(
      title: 'Pfannkuchen',
      description: 'Frühstück · Süß oder Herzhaft',
      keyIngredients: ['mehl', 'ei', 'eier', 'milch'],
      tags: ['pfannkuchen', 'frühstück', 'süß', 'backen', 'mehl'],
      cookingTime: 20,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Mehl', amount: '200g'),
        RecipeIngredient(name: 'Eier', amount: '2 Stück'),
        RecipeIngredient(name: 'Milch', amount: '300ml'),
        RecipeIngredient(name: 'Butter', amount: '2 EL'),
        RecipeIngredient(name: 'Salz', amount: '1 Prise'),
      ],
      steps: [
        'Mehl, Eier, Milch und Salz zu einem glatten Teig verrühren.',
        '30 Min. quellen lassen.',
        'Butter in Pfanne erhitzen.',
        'Jeweils eine Kelle Teig hineingeben und dünn verteilen.',
        'Jede Seite goldbraun backen.',
        'Mit Zucker, Marmelade oder herzhafter Füllung servieren.',
      ],
    ),
    _RecipeTemplate(
      title: 'Linsensuppe',
      description: 'Vegan · Proteinreich',
      keyIngredients: ['linsen', 'karotte', 'sellerie', 'zwiebel'],
      tags: ['linsen', 'vegan', 'suppe', 'vegetarisch', 'proteinreich'],
      cookingTime: 35,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Rote Linsen', amount: '250g'),
        RecipeIngredient(name: 'Karotten', amount: '2 Stück'),
        RecipeIngredient(name: 'Zwiebel', amount: '1 Stück'),
        RecipeIngredient(name: 'Gemüsebrühe', amount: '1 Liter'),
        RecipeIngredient(name: 'Kreuzkümmel', amount: '1 TL'),
        RecipeIngredient(name: 'Olivenöl', amount: '2 EL'),
      ],
      steps: [
        'Zwiebel und Karotten würfeln, in Öl anbraten.',
        'Linsen hinzufügen, mit Brühe aufgießen.',
        'Kreuzkümmel dazugeben.',
        '20 Min. bei mittlerer Hitze köcheln bis die Linsen weich sind.',
        'Nach Geschmack pürieren oder stückig lassen.',
        'Mit Salz, Pfeffer und Zitrone abschmecken.',
      ],
    ),
    _RecipeTemplate(
      title: 'Käse-Toast',
      description: 'Snack · Sehr schnell',
      keyIngredients: ['brot', 'toast', 'käse'],
      tags: ['toast', 'käse', 'snack', 'schnell', 'einfach'],
      cookingTime: 10,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Toastbrot', amount: '4 Scheiben'),
        RecipeIngredient(name: 'Käse (gerieben)', amount: '150g'),
        RecipeIngredient(name: 'Butter', amount: '1 EL'),
        RecipeIngredient(name: 'Oregano', amount: 'nach Geschmack'),
      ],
      steps: [
        'Toastbrot leicht buttern.',
        'Geriebenen Käse gleichmäßig verteilen.',
        'Oregano darüber streuen.',
        'Im Ofen bei 200°C für 8 Min. überbacken bis der Käse goldbraun ist.',
        'Heiß servieren.',
      ],
    ),
    _RecipeTemplate(
      title: 'Bunter Salat',
      description: 'Salat · Frisch & Leicht',
      keyIngredients: ['salat', 'tomate', 'gurke', 'paprika'],
      tags: ['salat', 'vegan', 'vegetarisch', 'leicht', 'frisch', 'gesund'],
      cookingTime: 10,
      difficulty: 'Einfach',
      ingredients: [
        RecipeIngredient(name: 'Salatblätter', amount: '150g'),
        RecipeIngredient(name: 'Tomaten', amount: '2 Stück'),
        RecipeIngredient(name: 'Gurke', amount: '1/2 Stück'),
        RecipeIngredient(name: 'Paprika', amount: '1 Stück'),
        RecipeIngredient(name: 'Olivenöl', amount: '3 EL'),
        RecipeIngredient(name: 'Essig', amount: '1 EL'),
        RecipeIngredient(name: 'Salz & Pfeffer', amount: 'nach Geschmack'),
      ],
      steps: [
        'Salat waschen und trocken schleudern.',
        'Gemüse in mundgerechte Stücke schneiden.',
        'Alles in einer Schüssel mischen.',
        'Aus Öl, Essig, Salz und Pfeffer ein Dressing rühren.',
        'Dressing über den Salat geben und sofort servieren.',
      ],
    ),
  ];

  static final List<_RecipeTemplate> _fallbackTemplates = [
    _templates[0], // Spaghetti Bolognese
    _templates[1], // Rührei
    _templates[3], // Kartoffelsuppe
  ];
}

class _RecipeTemplate {
  final String title;
  final String description;
  final List<String> keyIngredients;
  final List<String> tags;
  final int cookingTime;
  final String difficulty;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  const _RecipeTemplate({
    required this.title,
    required this.description,
    required this.keyIngredients,
    required this.tags,
    required this.cookingTime,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
  });

  FoodRecipe toRecipe() => FoodRecipe(
        id: title.hashCode.toString(),
        title: title,
        description: description,
        cookingTimeMinutes: cookingTime,
        difficulty: difficulty,
        servings: 4,
        ingredients: ingredients,
        steps: steps,
      );
}

