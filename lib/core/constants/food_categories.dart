import 'package:flutter/material.dart';

/// Vordefinierte Lebensmittel-Kategorien mit Icon und Farbe.
enum FoodCategory {
  obst('Obst', Icons.apple, Color(0xFF66BB6A)),
  gemuese('Gemüse', Icons.grass, Color(0xFF558B2F)),
  obstGemuese('Obst & Gemüse', Icons.local_florist, Color(0xFF66BB6A)),
  fleischFisch('Fleisch & Fisch', Icons.set_meal, Color(0xFFEF5350)),
  wurst('Wurst & Aufschnitt', Icons.lunch_dining, Color(0xFFE57373)),
  milchprodukte('Milchprodukte', Icons.water_drop, Color(0xFF5C93C5)),
  getraenke('Getränke', Icons.local_cafe, Color(0xFF4DB6AC)),
  snacks('Snacks', Icons.cookie, Color(0xFFFF8A65)),
  suesswarenSnacks('Süßwaren & Snacks', Icons.cookie, Color(0xFFFF8A65)),
  backwaren('Backwaren', Icons.bakery_dining, Color(0xFFB07D4F)),
  brotBackwaren('Brot & Backwaren', Icons.bakery_dining, Color(0xFFB07D4F)),
  tiefkuehl('Tiefkühl', Icons.ac_unit, Color(0xFF5B9BD5)),
  fertigprodukte('Fertigprodukte', Icons.lunch_dining, Color(0xFF7986CB)),
  konserven('Konserven', Icons.inventory_2, Color(0xFF78909C)),
  vorrat('Vorrat', Icons.storage, Color(0xFF8D6E63)),
  gewuerze('Gewürze & Kräuter', Icons.spa, Color(0xFF7CB342)),
  oeleSossen('Öle & Soßen', Icons.opacity, Color(0xFFE6A817)),
  oeleEssig('Öle & Essig', Icons.opacity, Color(0xFFE6A817)),
  getreideNudeln('Getreide & Nudeln', Icons.grain, Color(0xFFA1887F)),
  nudelnGetreide('Nudeln & Getreide', Icons.grain, Color(0xFFA1887F)),
  nuesse('Nüsse & Samen', Icons.eco, Color(0xFF795548)),
  suessigkeiten('Süßigkeiten', Icons.cake, Color(0xFFD45F8A)),
  suesseAufstriche('Süßes & Aufstriche', Icons.cake, Color(0xFFD45F8A)),
  pflanzlicheProteine('Pflanzliche Proteine', Icons.eco, Color(0xFF558B2F)),
  backen('Backen', Icons.bakery_dining, Color(0xFFB07D4F)),
  fruehstueck('Frühstück', Icons.free_breakfast, Color(0xFFE6A817)),
  haushalt('Haushalt & Reinigung', Icons.cleaning_services, Color(0xFF607D8B)),
  hygiene('Hygiene & Pflege', Icons.soap, Color(0xFF4DB6AC)),
  koerperpflege('Körperpflege', Icons.soap, Color(0xFF4DB6AC)),
  baby('Baby & Kind', Icons.child_care, Color(0xFFE8806A)),
  tierfutter('Tierfutter', Icons.pets, Color(0xFF8D6E63)),
  gesundheit('Gesundheit', Icons.health_and_safety, Color(0xFF4DB6AC)),
  sportFitness('Sport & Fitness', Icons.fitness_center, Color(0xFF5C93C5)),
  fermentiert('Fermentiert', Icons.science, Color(0xFF7CB342)),
  alkohol('Alkohol', Icons.local_bar, Color(0xFF8E6BB5)),
  asiatisch('Asiatisch', Icons.restaurant, Color(0xFFEF5350)),
  mediterran('Mediterran', Icons.restaurant, Color(0xFF5C93C5)),
  mexikanisch('Mexikanisch', Icons.restaurant, Color(0xFF7CB342)),
  glutenfrei('Glutenfrei', Icons.do_not_disturb_alt, Color(0xFFE6A817)),
  sonstiges('Sonstiges', Icons.more_horiz, Color(0xFF9E9E9E)),
  ;

  const FoodCategory(this.label, [this.icon = Icons.more_horiz, this.color = const Color(0xFF9E9E9E)]);

  final String label;
  final IconData icon;
  final Color color;

  /// Findet eine FoodCategory anhand ihres Labels – inkl. Katalog-Strings.
  static FoodCategory? fromLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    final lower = label.toLowerCase().trim();

    // Exaktes Match zuerst
    for (final c in FoodCategory.values) {
      if (c.label.toLowerCase() == lower) return c;
    }

    // Fuzzy-Mapping für alle Katalog-Kategorien
    const aliases = <String, FoodCategory>{
      // Tiefkühl-Varianten
      'tiefkühl': FoodCategory.tiefkuehl,
      'tiefkuehl': FoodCategory.tiefkuehl,
      'tiefkühlprodukte': FoodCategory.tiefkuehl,
      'tk': FoodCategory.tiefkuehl,
      'frozen': FoodCategory.tiefkuehl,
      // Fertigprodukte
      'fertigprodukte': FoodCategory.fertigprodukte,
      'convenience': FoodCategory.fertigprodukte,
      'fertiggericht': FoodCategory.fertigprodukte,
      // Obst & Gemüse
      'obst & gemüse': FoodCategory.obstGemuese,
      'obst & gemuese': FoodCategory.obstGemuese,
      'obst und gemüse': FoodCategory.obstGemuese,
      'obst': FoodCategory.obst,
      'gemüse': FoodCategory.gemuese,
      'gemuese': FoodCategory.gemuese,
      // Fleisch
      'fleisch & fisch': FoodCategory.fleischFisch,
      'fleisch und fisch': FoodCategory.fleischFisch,
      'fleisch': FoodCategory.fleischFisch,
      'fisch': FoodCategory.fleischFisch,
      'meeresfrüchte': FoodCategory.fleischFisch,
      // Wurst
      'wurst & aufschnitt': FoodCategory.wurst,
      'wurst': FoodCategory.wurst,
      'aufschnitt': FoodCategory.wurst,
      // Milch
      'milchprodukte': FoodCategory.milchprodukte,
      'molkereiprodukte': FoodCategory.milchprodukte,
      'käse': FoodCategory.milchprodukte,
      // Getränke
      'getränke': FoodCategory.getraenke,
      'getraenke': FoodCategory.getraenke,
      // Snacks
      'süßwaren & snacks': FoodCategory.suesswarenSnacks,
      'suesswarensnacks': FoodCategory.suesswarenSnacks,
      'snacks': FoodCategory.snacks,
      // Backwaren
      'brot & backwaren': FoodCategory.brotBackwaren,
      'backwaren': FoodCategory.backwaren,
      'brot': FoodCategory.brotBackwaren,
      'backen': FoodCategory.backen,
      // Konserven
      'konserven': FoodCategory.konserven,
      'vorrat': FoodCategory.vorrat,
      // Gewürze
      'gewürze & soßen': FoodCategory.gewuerze,
      'gewürze & kräuter': FoodCategory.gewuerze,
      'gewuerze': FoodCategory.gewuerze,
      'gewürze': FoodCategory.gewuerze,
      'kräuter': FoodCategory.gewuerze,
      // Öle
      'öle & soßen': FoodCategory.oeleSossen,
      'öle & essig': FoodCategory.oeleEssig,
      'ole & essig': FoodCategory.oeleEssig,
      // Nudeln / Getreide
      'nudeln & getreide': FoodCategory.nudelnGetreide,
      'getreide & nudeln': FoodCategory.getreideNudeln,
      'nudeln': FoodCategory.nudelnGetreide,
      'getreide': FoodCategory.getreideNudeln,
      'reis': FoodCategory.getreideNudeln,
      // Nüsse
      'nüsse & samen': FoodCategory.nuesse,
      'nuesse & samen': FoodCategory.nuesse,
      'nüsse': FoodCategory.nuesse,
      // Süßes
      'süßigkeiten': FoodCategory.suessigkeiten,
      'süßes & aufstriche': FoodCategory.suesseAufstriche,
      'suesses & aufstriche': FoodCategory.suesseAufstriche,
      'schokolade': FoodCategory.suessigkeiten,
      // Frühstück
      'frühstück': FoodCategory.fruehstueck,
      'fruhstuck': FoodCategory.fruehstueck,
      // Haushalt
      'haushalt & reinigung': FoodCategory.haushalt,
      'haushalt': FoodCategory.haushalt,
      'reinigung': FoodCategory.haushalt,
      // Hygiene
      'hygiene & pflege': FoodCategory.hygiene,
      'körperpflege': FoodCategory.koerperpflege,
      'korperpflege': FoodCategory.koerperpflege,
      // Baby
      'baby & kind': FoodCategory.baby,
      'baby': FoodCategory.baby,
      // Tierfutter
      'tierfutter': FoodCategory.tierfutter,
      'tiernahrung': FoodCategory.tierfutter,
      // Gesundheit
      'gesundheit': FoodCategory.gesundheit,
      // Sport
      'sport & fitness': FoodCategory.sportFitness,
      // Pflanzlich
      'pflanzliche proteine': FoodCategory.pflanzlicheProteine,
      'vegan': FoodCategory.pflanzlicheProteine,
      // Fermentiert
      'fermentiert': FoodCategory.fermentiert,
      // Alkohol
      'alkohol': FoodCategory.alkohol,
      // Küchen-Stile
      'asiatisch': FoodCategory.asiatisch,
      'mediterran': FoodCategory.mediterran,
      'mexikanisch': FoodCategory.mexikanisch,
      // Glutenfrei
      'glutenfrei': FoodCategory.glutenfrei,
    };

    return aliases[lower] ?? FoodCategory.sonstiges;
  }

  /// Versucht eine OpenFoodFacts-Kategorie auf eine FoodCategory zu mappen.
  static FoodCategory? fromOpenFoodFacts(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();

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

    for (final entry in mapping.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}

