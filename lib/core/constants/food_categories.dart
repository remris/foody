import 'package:flutter/material.dart';

/// Vordefinierte Lebensmittel-Kategorien mit Icon und Farbe.
enum FoodCategory {
  obst('Obst', Icons.apple, Color(0xFF4CAF50)),
  gemuese('Gemüse', Icons.grass, Color(0xFF66BB6A)),
  fleischFisch('Fleisch & Fisch', Icons.set_meal, Color(0xFFEF5350)),
  milchprodukte('Milchprodukte', Icons.water_drop, Color(0xFF42A5F5)),
  getraenke('Getränke', Icons.local_cafe, Color(0xFF26C6DA)),
  snacks('Snacks', Icons.cookie, Color(0xFFFF7043)),
  backwaren('Backwaren', Icons.bakery_dining, Color(0xFFD4A373)),
  tiefkuehl('Tiefkühl', Icons.ac_unit, Color(0xFF90CAF9)),
  konserven('Konserven', Icons.inventory_2, Color(0xFF78909C)),
  gewuerze('Gewürze & Kräuter', Icons.spa, Color(0xFF8BC34A)),
  oeleSossen('Öle & Soßen', Icons.opacity, Color(0xFFFFCA28)),
  getreideNudeln('Getreide & Nudeln', Icons.grain, Color(0xFFBCAAA4)),
  suessigkeiten('Süßigkeiten', Icons.cake, Color(0xFFE91E63)),
  haushalt('Haushalt & Reinigung', Icons.cleaning_services, Color(0xFF607D8B)),
  hygiene('Hygiene & Pflege', Icons.soap, Color(0xFF26A69A)),
  baby('Baby & Kind', Icons.child_care, Color(0xFFFF8A80)),
  sonstiges('Sonstiges', Icons.more_horiz, Color(0xFF9E9E9E)),
  ;

  const FoodCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Versucht eine OpenFoodFacts-Kategorie auf eine FoodCategory zu mappen.
  static FoodCategory? fromOpenFoodFacts(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();

    // Mapping von typischen OpenFoodFacts-Tags
    const mapping = <String, FoodCategory>{
      'fruit': FoodCategory.obst,
      'fruits': FoodCategory.obst,
      'vegetable': FoodCategory.gemuese,
      'vegetables': FoodCategory.gemuese,
      'legume': FoodCategory.gemuese,
      'meat': FoodCategory.fleischFisch,
      'meats': FoodCategory.fleischFisch,
      'fish': FoodCategory.fleischFisch,
      'seafood': FoodCategory.fleischFisch,
      'poultry': FoodCategory.fleischFisch,
      'dairy': FoodCategory.milchprodukte,
      'dairies': FoodCategory.milchprodukte,
      'milk': FoodCategory.milchprodukte,
      'cheese': FoodCategory.milchprodukte,
      'yogurt': FoodCategory.milchprodukte,
      'beverage': FoodCategory.getraenke,
      'beverages': FoodCategory.getraenke,
      'drink': FoodCategory.getraenke,
      'drinks': FoodCategory.getraenke,
      'water': FoodCategory.getraenke,
      'juice': FoodCategory.getraenke,
      'soda': FoodCategory.getraenke,
      'snack': FoodCategory.snacks,
      'snacks': FoodCategory.snacks,
      'chip': FoodCategory.snacks,
      'chips': FoodCategory.snacks,
      'cracker': FoodCategory.snacks,
      'bread': FoodCategory.backwaren,
      'breads': FoodCategory.backwaren,
      'pastry': FoodCategory.backwaren,
      'pastries': FoodCategory.backwaren,
      'baked': FoodCategory.backwaren,
      'frozen': FoodCategory.tiefkuehl,
      'ice-cream': FoodCategory.tiefkuehl,
      'canned': FoodCategory.konserven,
      'preserved': FoodCategory.konserven,
      'conserve': FoodCategory.konserven,
      'spice': FoodCategory.gewuerze,
      'spices': FoodCategory.gewuerze,
      'herb': FoodCategory.gewuerze,
      'herbs': FoodCategory.gewuerze,
      'seasoning': FoodCategory.gewuerze,
      'oil': FoodCategory.oeleSossen,
      'oils': FoodCategory.oeleSossen,
      'sauce': FoodCategory.oeleSossen,
      'sauces': FoodCategory.oeleSossen,
      'condiment': FoodCategory.oeleSossen,
      'ketchup': FoodCategory.oeleSossen,
      'mustard': FoodCategory.oeleSossen,
      'cereal': FoodCategory.getreideNudeln,
      'cereals': FoodCategory.getreideNudeln,
      'pasta': FoodCategory.getreideNudeln,
      'noodle': FoodCategory.getreideNudeln,
      'rice': FoodCategory.getreideNudeln,
      'grain': FoodCategory.getreideNudeln,
      'flour': FoodCategory.getreideNudeln,
      'candy': FoodCategory.suessigkeiten,
      'candies': FoodCategory.suessigkeiten,
      'chocolate': FoodCategory.suessigkeiten,
      'sweet': FoodCategory.suessigkeiten,
      'sweets': FoodCategory.suessigkeiten,
      'confectionery': FoodCategory.suessigkeiten,
      'sugar': FoodCategory.suessigkeiten,
      // Non-Food
      'cleaning': FoodCategory.haushalt,
      'cleaner': FoodCategory.haushalt,
      'detergent': FoodCategory.haushalt,
      'sponge': FoodCategory.haushalt,
      'trash': FoodCategory.haushalt,
      'foil': FoodCategory.haushalt,
      'tape': FoodCategory.haushalt,
      'paper': FoodCategory.haushalt,
      'tissue': FoodCategory.haushalt,
      'laundry': FoodCategory.haushalt,
      'shampoo': FoodCategory.hygiene,
      'shower': FoodCategory.hygiene,
      'soap': FoodCategory.hygiene,
      'toothpaste': FoodCategory.hygiene,
      'deodorant': FoodCategory.hygiene,
      'cosmetic': FoodCategory.hygiene,
      'cream': FoodCategory.hygiene,
      'lotion': FoodCategory.hygiene,
      'diaper': FoodCategory.baby,
      'diapers': FoodCategory.baby,
      'windel': FoodCategory.baby,
      'windeln': FoodCategory.baby,
      'baby': FoodCategory.baby,
      'pacifier': FoodCategory.baby,
    };

    // Exaktes Matching
    for (final entry in mapping.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Findet eine FoodCategory anhand ihres Labels.
  static FoodCategory? fromLabel(String? label) {
    if (label == null) return null;
    try {
      return FoodCategory.values.firstWhere(
        (c) => c.label.toLowerCase() == label.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

