/// Normalisierter Zutaten-Katalog für die kokomu-App.
/// Nur Gattungsbegriffe, keine Markennamen.
/// Varianten (TK, Dose, Glas, frisch) sind als eigene Einträge aufgeführt.
library ingredient_catalog;

class IngredientEntry {
  final String name;
  final String category;
  final String? defaultUnit;
  final List<String> aliases; // Alternative Schreibweisen für Suche
  final String canonicalId;

  const IngredientEntry({
    required this.name,
    required this.category,
    required this.canonicalId,
    this.defaultUnit,
    this.aliases = const [],
  });
}

class IngredientCatalog {
  static const List<IngredientEntry> all = [
    // ──────────────────────────────────────────────────────
    // MILCHPRODUKTE & EIER
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Vollmilch', category: 'Milchprodukte', canonicalId: 'milch_voll', defaultUnit: 'L', aliases: ['Milch', 'Kuhmilch']),
    IngredientEntry(name: 'Halbfettmilch', category: 'Milchprodukte', canonicalId: 'milch_halb', defaultUnit: 'L'),
    IngredientEntry(name: 'Laktosefreie Milch', category: 'Milchprodukte', canonicalId: 'milch_laktosefrei', defaultUnit: 'L'),
    IngredientEntry(name: 'Hafermilch', category: 'Milchprodukte', canonicalId: 'hafermilch', defaultUnit: 'L', aliases: ['Haferdrink']),
    IngredientEntry(name: 'Sojamilch', category: 'Milchprodukte', canonicalId: 'sojamilch', defaultUnit: 'L', aliases: ['Sojadrink']),
    IngredientEntry(name: 'Mandelmilch', category: 'Milchprodukte', canonicalId: 'mandelmilch', defaultUnit: 'L'),
    IngredientEntry(name: 'Butter', category: 'Milchprodukte', canonicalId: 'butter', defaultUnit: 'g'),
    IngredientEntry(name: 'Margarine', category: 'Milchprodukte', canonicalId: 'margarine', defaultUnit: 'g'),
    IngredientEntry(name: 'Sahne', category: 'Milchprodukte', canonicalId: 'sahne', defaultUnit: 'ml', aliases: ['Schlagsahne', 'Schlagobers']),
    IngredientEntry(name: 'Sauerrahm', category: 'Milchprodukte', canonicalId: 'sauerrahm', defaultUnit: 'g', aliases: ['Saure Sahne']),
    IngredientEntry(name: 'Schmand', category: 'Milchprodukte', canonicalId: 'schmand', defaultUnit: 'g'),
    IngredientEntry(name: 'Crème fraîche', category: 'Milchprodukte', canonicalId: 'creme_fraiche', defaultUnit: 'g', aliases: ['Creme Fraiche']),
    IngredientEntry(name: 'Joghurt (Natur)', category: 'Milchprodukte', canonicalId: 'joghurt_natur', defaultUnit: 'g', aliases: ['Naturjoghurt']),
    IngredientEntry(name: 'Joghurt (3,5%)', category: 'Milchprodukte', canonicalId: 'joghurt_voll', defaultUnit: 'g'),
    IngredientEntry(name: 'Griechischer Joghurt', category: 'Milchprodukte', canonicalId: 'joghurt_griech', defaultUnit: 'g'),
    IngredientEntry(name: 'Quark (Mager)', category: 'Milchprodukte', canonicalId: 'quark_mager', defaultUnit: 'g'),
    IngredientEntry(name: 'Quark (Vollfett)', category: 'Milchprodukte', canonicalId: 'quark_voll', defaultUnit: 'g'),
    IngredientEntry(name: 'Frischkäse', category: 'Milchprodukte', canonicalId: 'frischkaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Gouda', category: 'Milchprodukte', canonicalId: 'gouda', defaultUnit: 'g'),
    IngredientEntry(name: 'Edamer', category: 'Milchprodukte', canonicalId: 'edamer', defaultUnit: 'g'),
    IngredientEntry(name: 'Emmentaler', category: 'Milchprodukte', canonicalId: 'emmentaler', defaultUnit: 'g'),
    IngredientEntry(name: 'Parmesan', category: 'Milchprodukte', canonicalId: 'parmesan', defaultUnit: 'g'),
    IngredientEntry(name: 'Mozzarella', category: 'Milchprodukte', canonicalId: 'mozzarella', defaultUnit: 'g'),
    IngredientEntry(name: 'Mozzarella (gerieben)', category: 'Milchprodukte', canonicalId: 'mozzarella_gerieben', defaultUnit: 'g'),
    IngredientEntry(name: 'Feta', category: 'Milchprodukte', canonicalId: 'feta', defaultUnit: 'g', aliases: ['Schafskäse']),
    IngredientEntry(name: 'Ricotta', category: 'Milchprodukte', canonicalId: 'ricotta', defaultUnit: 'g'),
    IngredientEntry(name: 'Mascarpone', category: 'Milchprodukte', canonicalId: 'mascarpone', defaultUnit: 'g'),
    IngredientEntry(name: 'Eier', category: 'Milchprodukte', canonicalId: 'eier', defaultUnit: 'Stück', aliases: ['Ei', 'Hühnereier']),
    IngredientEntry(name: 'Eier (M)', category: 'Milchprodukte', canonicalId: 'eier_m', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Eier (L)', category: 'Milchprodukte', canonicalId: 'eier_l', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kondensmilch', category: 'Milchprodukte', canonicalId: 'kondensmilch', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // FLEISCH & GEFLÜGEL (FRISCH)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Hähnchenbrust', category: 'Fleisch & Fisch', canonicalId: 'haehnchen_brust', defaultUnit: 'g', aliases: ['Hühnerbrust', 'Chicken Breast']),
    IngredientEntry(name: 'Hähnchenschenkel', category: 'Fleisch & Fisch', canonicalId: 'haehnchen_schenkel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Hähnchen (TK)', category: 'Fleisch & Fisch', canonicalId: 'haehnchen_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Hähnchen (ganz)', category: 'Fleisch & Fisch', canonicalId: 'haehnchen_ganz', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Putenbrust', category: 'Fleisch & Fisch', canonicalId: 'puten_brust', defaultUnit: 'g'),
    IngredientEntry(name: 'Putengeschnetzeltes', category: 'Fleisch & Fisch', canonicalId: 'puten_geschnetzelt', defaultUnit: 'g'),
    IngredientEntry(name: 'Hackfleisch (gemischt)', category: 'Fleisch & Fisch', canonicalId: 'hack_gemischt', defaultUnit: 'g'),
    IngredientEntry(name: 'Hackfleisch (Rind)', category: 'Fleisch & Fisch', canonicalId: 'hack_rind', defaultUnit: 'g'),
    IngredientEntry(name: 'Hackfleisch (TK)', category: 'Fleisch & Fisch', canonicalId: 'hack_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Rindersteak', category: 'Fleisch & Fisch', canonicalId: 'rind_steak', defaultUnit: 'g'),
    IngredientEntry(name: 'Rindergulasch', category: 'Fleisch & Fisch', canonicalId: 'rind_gulasch', defaultUnit: 'g'),
    IngredientEntry(name: 'Schweinefilet', category: 'Fleisch & Fisch', canonicalId: 'schwein_filet', defaultUnit: 'g'),
    IngredientEntry(name: 'Schweinebauch', category: 'Fleisch & Fisch', canonicalId: 'schwein_bauch', defaultUnit: 'g'),
    IngredientEntry(name: 'Schweineschnitzel', category: 'Fleisch & Fisch', canonicalId: 'schwein_schnitzel', defaultUnit: 'g'),
    IngredientEntry(name: 'Kassler', category: 'Fleisch & Fisch', canonicalId: 'kassler', defaultUnit: 'g'),
    IngredientEntry(name: 'Speck', category: 'Fleisch & Fisch', canonicalId: 'speck', defaultUnit: 'g', aliases: ['Bacon', 'Bauchspeck']),
    IngredientEntry(name: 'Schinken (gekocht)', category: 'Fleisch & Fisch', canonicalId: 'schinken_gekocht', defaultUnit: 'g'),
    IngredientEntry(name: 'Schinken (roh)', category: 'Fleisch & Fisch', canonicalId: 'schinken_roh', defaultUnit: 'g'),
    IngredientEntry(name: 'Bratwurst', category: 'Fleisch & Fisch', canonicalId: 'bratwurst', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Wiener Würstchen', category: 'Fleisch & Fisch', canonicalId: 'wiener', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Salami', category: 'Fleisch & Fisch', canonicalId: 'salami', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // FISCH & MEERESFRÜCHTE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Lachsfilet', category: 'Fleisch & Fisch', canonicalId: 'lachs_filet', defaultUnit: 'g'),
    IngredientEntry(name: 'Lachs (TK)', category: 'Fleisch & Fisch', canonicalId: 'lachs_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Heilbutt (frisch)', category: 'Fleisch & Fisch', canonicalId: 'heilbutt_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Kabeljau', category: 'Fleisch & Fisch', canonicalId: 'kabeljau', defaultUnit: 'g'),
    IngredientEntry(name: 'Forelle', category: 'Fleisch & Fisch', canonicalId: 'forelle', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Thunfisch (Dose)', category: 'Fleisch & Fisch', canonicalId: 'thunfisch_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Fischstäbchen (TK)', category: 'Fleisch & Fisch', canonicalId: 'fischstaebchen_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Garnelen', category: 'Fleisch & Fisch', canonicalId: 'garnelen', defaultUnit: 'g', aliases: ['Shrimps', 'Crevetten']),
    IngredientEntry(name: 'Garnelen (TK)', category: 'Fleisch & Fisch', canonicalId: 'garnelen_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Meeresfrüchte (TK)', category: 'Fleisch & Fisch', canonicalId: 'meeresfruechte_tk', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // GEMÜSE (FRISCH)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Tomate', category: 'Obst & Gemüse', canonicalId: 'tomate', defaultUnit: 'Stück', aliases: ['Tomaten']),
    IngredientEntry(name: 'Cocktailtomaten', category: 'Obst & Gemüse', canonicalId: 'tomate_cocktail', defaultUnit: 'g', aliases: ['Kirschtomaten', 'Cherrytomaten']),
    IngredientEntry(name: 'Paprika (rot)', category: 'Obst & Gemüse', canonicalId: 'paprika_rot', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Paprika (gelb)', category: 'Obst & Gemüse', canonicalId: 'paprika_gelb', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Paprika (grün)', category: 'Obst & Gemüse', canonicalId: 'paprika_gruen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Gurke', category: 'Obst & Gemüse', canonicalId: 'gurke', defaultUnit: 'Stück', aliases: ['Salatgurke']),
    IngredientEntry(name: 'Karotte', category: 'Obst & Gemüse', canonicalId: 'karotte', defaultUnit: 'g', aliases: ['Karotten', 'Möhren', 'Möhre']),
    IngredientEntry(name: 'Zwiebel', category: 'Obst & Gemüse', canonicalId: 'zwiebel', defaultUnit: 'Stück', aliases: ['Zwiebeln']),
    IngredientEntry(name: 'Rote Zwiebel', category: 'Obst & Gemüse', canonicalId: 'zwiebel_rot', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Schalotte', category: 'Obst & Gemüse', canonicalId: 'schalotte', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Lauch', category: 'Obst & Gemüse', canonicalId: 'lauch', defaultUnit: 'Stück', aliases: ['Porree']),
    IngredientEntry(name: 'Brokkoli', category: 'Obst & Gemüse', canonicalId: 'brokkoli', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Brokkoli (TK)', category: 'Obst & Gemüse', canonicalId: 'brokkoli_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Blumenkohl', category: 'Obst & Gemüse', canonicalId: 'blumenkohl', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Blumenkohl (TK)', category: 'Obst & Gemüse', canonicalId: 'blumenkohl_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Weißkohl', category: 'Obst & Gemüse', canonicalId: 'weisskohl', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rotkohl', category: 'Obst & Gemüse', canonicalId: 'rotkohl', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rosenkohl', category: 'Obst & Gemüse', canonicalId: 'rosenkohl', defaultUnit: 'g'),
    IngredientEntry(name: 'Rosenkohl (TK)', category: 'Obst & Gemüse', canonicalId: 'rosenkohl_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Spinat (frisch)', category: 'Obst & Gemüse', canonicalId: 'spinat_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Spinat (TK)', category: 'Obst & Gemüse', canonicalId: 'spinat_tk', defaultUnit: 'g', aliases: ['Blattspinat (TK)']),
    IngredientEntry(name: 'Eisbergsalat', category: 'Obst & Gemüse', canonicalId: 'eisberg', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Feldsalat', category: 'Obst & Gemüse', canonicalId: 'feldsalat', defaultUnit: 'g', aliases: ['Rapunzel']),
    IngredientEntry(name: 'Rucola', category: 'Obst & Gemüse', canonicalId: 'rucola', defaultUnit: 'g'),
    IngredientEntry(name: 'Mischsalat', category: 'Obst & Gemüse', canonicalId: 'mischsalat', defaultUnit: 'g'),
    IngredientEntry(name: 'Zucchini', category: 'Obst & Gemüse', canonicalId: 'zucchini', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Aubergine', category: 'Obst & Gemüse', canonicalId: 'aubergine', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Champignons', category: 'Obst & Gemüse', canonicalId: 'champignons', defaultUnit: 'g', aliases: ['Pilze', 'Steinpilze']),
    IngredientEntry(name: 'Kartoffel', category: 'Obst & Gemüse', canonicalId: 'kartoffel', defaultUnit: 'kg', aliases: ['Kartoffeln']),
    IngredientEntry(name: 'Süßkartoffel', category: 'Obst & Gemüse', canonicalId: 'suesskartoffel', defaultUnit: 'Stück', aliases: ['Sweet Potato']),
    IngredientEntry(name: 'Knoblauch', category: 'Obst & Gemüse', canonicalId: 'knoblauch', defaultUnit: 'Zehe', aliases: ['Knoblauchzehe']),
    IngredientEntry(name: 'Ingwer', category: 'Obst & Gemüse', canonicalId: 'ingwer', defaultUnit: 'g'),
    IngredientEntry(name: 'Stangensellerie', category: 'Obst & Gemüse', canonicalId: 'sellerie_stange', defaultUnit: 'Stange'),
    IngredientEntry(name: 'Sellerie', category: 'Obst & Gemüse', canonicalId: 'sellerie', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fenchel', category: 'Obst & Gemüse', canonicalId: 'fenchel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kohlrabi', category: 'Obst & Gemüse', canonicalId: 'kohlrabi', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rote Bete', category: 'Obst & Gemüse', canonicalId: 'rote_bete', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Erbsen (frisch)', category: 'Obst & Gemüse', canonicalId: 'erbsen_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Erbsen (TK)', category: 'Obst & Gemüse', canonicalId: 'erbsen_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Mais (Dose)', category: 'Obst & Gemüse', canonicalId: 'mais_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Mais (TK)', category: 'Obst & Gemüse', canonicalId: 'mais_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Grüne Bohnen', category: 'Obst & Gemüse', canonicalId: 'bohnen_gruen', defaultUnit: 'g'),
    IngredientEntry(name: 'Grüne Bohnen (TK)', category: 'Obst & Gemüse', canonicalId: 'bohnen_gruen_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Spargel (weiß)', category: 'Obst & Gemüse', canonicalId: 'spargel_weiss', defaultUnit: 'g'),
    IngredientEntry(name: 'Spargel (grün)', category: 'Obst & Gemüse', canonicalId: 'spargel_gruen', defaultUnit: 'g'),
    IngredientEntry(name: 'Frühlingszwiebeln', category: 'Obst & Gemüse', canonicalId: 'fruehlingszwiebeln', defaultUnit: 'Bund'),
    IngredientEntry(name: 'Petersilie', category: 'Obst & Gemüse', canonicalId: 'petersilie', defaultUnit: 'Bund'),
    IngredientEntry(name: 'Basilikum', category: 'Obst & Gemüse', canonicalId: 'basilikum', defaultUnit: 'Bund'),
    IngredientEntry(name: 'Schnittlauch', category: 'Obst & Gemüse', canonicalId: 'schnittlauch', defaultUnit: 'Bund'),
    IngredientEntry(name: 'Dill', category: 'Obst & Gemüse', canonicalId: 'dill', defaultUnit: 'Bund'),
    IngredientEntry(name: 'Thymian (frisch)', category: 'Obst & Gemüse', canonicalId: 'thymian_frisch', defaultUnit: 'Zweig'),
    IngredientEntry(name: 'Rosmarin (frisch)', category: 'Obst & Gemüse', canonicalId: 'rosmarin_frisch', defaultUnit: 'Zweig'),
    IngredientEntry(name: 'Minze', category: 'Obst & Gemüse', canonicalId: 'minze', defaultUnit: 'Bund'),
    IngredientEntry(name: 'Avocado', category: 'Obst & Gemüse', canonicalId: 'avocado', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Zitrone', category: 'Obst & Gemüse', canonicalId: 'zitrone', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Limette', category: 'Obst & Gemüse', canonicalId: 'limette', defaultUnit: 'Stück'),

    // ──────────────────────────────────────────────────────
    // OBST
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Äpfel', category: 'Obst & Gemüse', canonicalId: 'apfel', defaultUnit: 'Stück', aliases: ['Apfel']),
    IngredientEntry(name: 'Birnen', category: 'Obst & Gemüse', canonicalId: 'birne', defaultUnit: 'Stück', aliases: ['Birne']),
    IngredientEntry(name: 'Bananen', category: 'Obst & Gemüse', canonicalId: 'banane', defaultUnit: 'Stück', aliases: ['Banane']),
    IngredientEntry(name: 'Orangen', category: 'Obst & Gemüse', canonicalId: 'orange', defaultUnit: 'Stück', aliases: ['Orange']),
    IngredientEntry(name: 'Mandarinen', category: 'Obst & Gemüse', canonicalId: 'mandarine', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Erdbeeren', category: 'Obst & Gemüse', canonicalId: 'erdbeere', defaultUnit: 'g', aliases: ['Erdbeere']),
    IngredientEntry(name: 'Erdbeeren (TK)', category: 'Obst & Gemüse', canonicalId: 'erdbeere_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Himbeeren', category: 'Obst & Gemüse', canonicalId: 'himbeere', defaultUnit: 'g'),
    IngredientEntry(name: 'Himbeeren (TK)', category: 'Obst & Gemüse', canonicalId: 'himbeere_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Blaubeeren', category: 'Obst & Gemüse', canonicalId: 'blaubeere', defaultUnit: 'g', aliases: ['Heidelbeeren']),
    IngredientEntry(name: 'Kirschen', category: 'Obst & Gemüse', canonicalId: 'kirsche', defaultUnit: 'g'),
    IngredientEntry(name: 'Weintrauben', category: 'Obst & Gemüse', canonicalId: 'traube', defaultUnit: 'g'),
    IngredientEntry(name: 'Kiwi', category: 'Obst & Gemüse', canonicalId: 'kiwi', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Mango', category: 'Obst & Gemüse', canonicalId: 'mango', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Ananas', category: 'Obst & Gemüse', canonicalId: 'ananas', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Ananas (Dose)', category: 'Obst & Gemüse', canonicalId: 'ananas_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Pfirsich', category: 'Obst & Gemüse', canonicalId: 'pfirsich', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Beeren-Mix (TK)', category: 'Obst & Gemüse', canonicalId: 'beeren_mix_tk', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // HÜLSENFRÜCHTE & GETREIDE (TROCKEN)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Kichererbsen (Dose)', category: 'Konserven', canonicalId: 'kichererbsen_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Kichererbsen (Glas)', category: 'Konserven', canonicalId: 'kichererbsen_glas', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Kichererbsen (trocken)', category: 'Vorrat', canonicalId: 'kichererbsen_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Linsen (rot)', category: 'Vorrat', canonicalId: 'linsen_rot', defaultUnit: 'g'),
    IngredientEntry(name: 'Linsen (grün)', category: 'Vorrat', canonicalId: 'linsen_gruen', defaultUnit: 'g'),
    IngredientEntry(name: 'Linsen (braun)', category: 'Vorrat', canonicalId: 'linsen_braun', defaultUnit: 'g'),
    IngredientEntry(name: 'Kidneybohnen (Dose)', category: 'Konserven', canonicalId: 'kidney_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Kidneybohnen (trocken)', category: 'Vorrat', canonicalId: 'kidney_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Weiße Bohnen (Dose)', category: 'Konserven', canonicalId: 'bohnen_weiss_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Schwarze Bohnen (Dose)', category: 'Konserven', canonicalId: 'bohnen_schwarz_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sojageschnetzeltes', category: 'Vorrat', canonicalId: 'soja_geschnetzelt', defaultUnit: 'g', aliases: ['Soja Granulat']),
    IngredientEntry(name: 'Tofu', category: 'Fleisch & Fisch', canonicalId: 'tofu', defaultUnit: 'g'),
    IngredientEntry(name: 'Räuchertofu', category: 'Fleisch & Fisch', canonicalId: 'tofu_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Tempeh', category: 'Fleisch & Fisch', canonicalId: 'tempeh', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // NUDELN & GETREIDE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Spaghetti', category: 'Nudeln & Getreide', canonicalId: 'spaghetti', defaultUnit: 'g'),
    IngredientEntry(name: 'Penne', category: 'Nudeln & Getreide', canonicalId: 'penne', defaultUnit: 'g'),
    IngredientEntry(name: 'Fusilli', category: 'Nudeln & Getreide', canonicalId: 'fusilli', defaultUnit: 'g'),
    IngredientEntry(name: 'Farfalle', category: 'Nudeln & Getreide', canonicalId: 'farfalle', defaultUnit: 'g'),
    IngredientEntry(name: 'Rigatoni', category: 'Nudeln & Getreide', canonicalId: 'rigatoni', defaultUnit: 'g'),
    IngredientEntry(name: 'Lasagneplatten', category: 'Nudeln & Getreide', canonicalId: 'lasagne', defaultUnit: 'g'),
    IngredientEntry(name: 'Tagliatelle', category: 'Nudeln & Getreide', canonicalId: 'tagliatelle', defaultUnit: 'g'),
    IngredientEntry(name: 'Vollkornnudeln', category: 'Nudeln & Getreide', canonicalId: 'nudeln_vollkorn', defaultUnit: 'g'),
    IngredientEntry(name: 'Reisnudeln', category: 'Nudeln & Getreide', canonicalId: 'reisnudeln', defaultUnit: 'g'),
    IngredientEntry(name: 'Basmatireis', category: 'Nudeln & Getreide', canonicalId: 'reis_basmati', defaultUnit: 'g', aliases: ['Basmati Reis']),
    IngredientEntry(name: 'Jasminreis', category: 'Nudeln & Getreide', canonicalId: 'reis_jasmin', defaultUnit: 'g'),
    IngredientEntry(name: 'Vollkornreis', category: 'Nudeln & Getreide', canonicalId: 'reis_vollkorn', defaultUnit: 'g'),
    IngredientEntry(name: 'Milchreis', category: 'Nudeln & Getreide', canonicalId: 'milchreis', defaultUnit: 'g'),
    IngredientEntry(name: 'Risotto-Reis', category: 'Nudeln & Getreide', canonicalId: 'risotto_reis', defaultUnit: 'g', aliases: ['Arborio']),
    IngredientEntry(name: 'Couscous', category: 'Nudeln & Getreide', canonicalId: 'couscous', defaultUnit: 'g'),
    IngredientEntry(name: 'Bulgur', category: 'Nudeln & Getreide', canonicalId: 'bulgur', defaultUnit: 'g'),
    IngredientEntry(name: 'Quinoa', category: 'Nudeln & Getreide', canonicalId: 'quinoa', defaultUnit: 'g'),
    IngredientEntry(name: 'Haferflocken', category: 'Frühstück', canonicalId: 'haferflocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Polenta', category: 'Nudeln & Getreide', canonicalId: 'polenta', defaultUnit: 'g'),
    IngredientEntry(name: 'Popcorn-Mais', category: 'Vorrat', canonicalId: 'popcorn_mais', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // BROT & BACKWAREN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Vollkornbrot', category: 'Brot & Backwaren', canonicalId: 'brot_vollkorn', defaultUnit: 'Scheibe', aliases: ['Brot']),
    IngredientEntry(name: 'Weißbrot', category: 'Brot & Backwaren', canonicalId: 'brot_weiss', defaultUnit: 'Scheibe'),
    IngredientEntry(name: 'Toastbrot', category: 'Brot & Backwaren', canonicalId: 'toast', defaultUnit: 'Scheibe'),
    IngredientEntry(name: 'Baguette', category: 'Brot & Backwaren', canonicalId: 'baguette', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Brötchen', category: 'Brot & Backwaren', canonicalId: 'broetchen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Laugenbrezel', category: 'Brot & Backwaren', canonicalId: 'brezel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tortillas (Weizen)', category: 'Brot & Backwaren', canonicalId: 'tortilla_weizen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tortillas (Mais)', category: 'Brot & Backwaren', canonicalId: 'tortilla_mais', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Pita-Brot', category: 'Brot & Backwaren', canonicalId: 'pita', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fladenbrot', category: 'Brot & Backwaren', canonicalId: 'fladenbrot', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Paniermehl', category: 'Brot & Backwaren', canonicalId: 'paniermehl', defaultUnit: 'g', aliases: ['Semmelbrösel', 'Breadcrumbs']),

    // ──────────────────────────────────────────────────────
    // BACKEN & MEHL
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Mehl (Type 405)', category: 'Backen', canonicalId: 'mehl_405', defaultUnit: 'g', aliases: ['Weizenmehl', 'Mehl']),
    IngredientEntry(name: 'Mehl (Type 550)', category: 'Backen', canonicalId: 'mehl_550', defaultUnit: 'g'),
    IngredientEntry(name: 'Dinkelmehl', category: 'Backen', canonicalId: 'dinkelmehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Vollkornmehl', category: 'Backen', canonicalId: 'mehl_vollkorn', defaultUnit: 'g'),
    IngredientEntry(name: 'Maismehl', category: 'Backen', canonicalId: 'maismehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Mandelmehl', category: 'Backen', canonicalId: 'mandelmehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Zucker', category: 'Backen', canonicalId: 'zucker', defaultUnit: 'g'),
    IngredientEntry(name: 'Brauner Zucker', category: 'Backen', canonicalId: 'zucker_braun', defaultUnit: 'g'),
    IngredientEntry(name: 'Puderzucker', category: 'Backen', canonicalId: 'puderzucker', defaultUnit: 'g'),
    IngredientEntry(name: 'Backpulver', category: 'Backen', canonicalId: 'backpulver', defaultUnit: 'g'),
    IngredientEntry(name: 'Natron', category: 'Backen', canonicalId: 'natron', defaultUnit: 'g'),
    IngredientEntry(name: 'Trockenhefe', category: 'Backen', canonicalId: 'hefe_trocken', defaultUnit: 'Päckchen'),
    IngredientEntry(name: 'Frischhefe', category: 'Backen', canonicalId: 'hefe_frisch', defaultUnit: 'Würfel'),
    IngredientEntry(name: 'Stärke', category: 'Backen', canonicalId: 'staerke', defaultUnit: 'g', aliases: ['Speisestärke', 'Kartoffelstärke']),
    IngredientEntry(name: 'Vanillinzucker', category: 'Backen', canonicalId: 'vanillinzucker', defaultUnit: 'Päckchen'),
    IngredientEntry(name: 'Vanilleextrakt', category: 'Backen', canonicalId: 'vanilleextrakt', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kakaopulver', category: 'Backen', canonicalId: 'kakao', defaultUnit: 'g'),
    IngredientEntry(name: 'Schokolade (Zartbitter)', category: 'Backen', canonicalId: 'schokolade_zb', defaultUnit: 'g'),
    IngredientEntry(name: 'Schokolade (Vollmilch)', category: 'Backen', canonicalId: 'schokolade_vm', defaultUnit: 'g'),
    IngredientEntry(name: 'Schokoladenraspeln', category: 'Backen', canonicalId: 'schoko_raspeln', defaultUnit: 'g'),
    IngredientEntry(name: 'Gelatine', category: 'Backen', canonicalId: 'gelatine', defaultUnit: 'Blatt'),
    IngredientEntry(name: 'Agar-Agar', category: 'Backen', canonicalId: 'agar', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // ÖLE, ESSIG & SOSSEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Olivenöl', category: 'Öle & Essig', canonicalId: 'olivenoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Rapsöl', category: 'Öle & Essig', canonicalId: 'rapsoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sonnenblumenöl', category: 'Öle & Essig', canonicalId: 'sonnenblumenoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sesamöl', category: 'Öle & Essig', canonicalId: 'sesamoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kokosnussöl', category: 'Öle & Essig', canonicalId: 'kokosoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Weißweinessig', category: 'Öle & Essig', canonicalId: 'essig_weisswein', defaultUnit: 'ml'),
    IngredientEntry(name: 'Balsamico', category: 'Öle & Essig', canonicalId: 'balsamico', defaultUnit: 'ml', aliases: ['Balsamicoessig']),
    IngredientEntry(name: 'Apfelessig', category: 'Öle & Essig', canonicalId: 'essig_apfel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sojasauce', category: 'Öle & Essig', canonicalId: 'sojasauce', defaultUnit: 'ml'),
    IngredientEntry(name: 'Worcestershiresauce', category: 'Öle & Essig', canonicalId: 'worcester', defaultUnit: 'ml'),
    IngredientEntry(name: 'Tabasco', category: 'Öle & Essig', canonicalId: 'tabasco', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sriracha', category: 'Öle & Essig', canonicalId: 'sriracha', defaultUnit: 'ml'),
    IngredientEntry(name: 'Fischsauce', category: 'Öle & Essig', canonicalId: 'fischsauce', defaultUnit: 'ml'),
    IngredientEntry(name: 'Hoisinsauce', category: 'Öle & Essig', canonicalId: 'hoisinsauce', defaultUnit: 'ml'),
    IngredientEntry(name: 'Teriyakisauce', category: 'Öle & Essig', canonicalId: 'teriyaki', defaultUnit: 'ml'),
    IngredientEntry(name: 'Oyster Sauce', category: 'Öle & Essig', canonicalId: 'oyster_sauce', defaultUnit: 'ml', aliases: ['Austernsauce']),

    // ──────────────────────────────────────────────────────
    // KONSERVEN & GLÄSER
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Tomaten (Dose)', category: 'Konserven', canonicalId: 'tomaten_dose', defaultUnit: 'Dose', aliases: ['Dosentomaten']),
    IngredientEntry(name: 'Tomaten (stückig)', category: 'Konserven', canonicalId: 'tomaten_stueckig', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Tomaten (passiert)', category: 'Konserven', canonicalId: 'tomaten_passiert', defaultUnit: 'Packung', aliases: ['Passata']),
    IngredientEntry(name: 'Tomatenmark', category: 'Konserven', canonicalId: 'tomatenmark', defaultUnit: 'EL'),
    IngredientEntry(name: 'Kokosmilch', category: 'Konserven', canonicalId: 'kokosmilch', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Kokosmilch (leicht)', category: 'Konserven', canonicalId: 'kokosmilch_leicht', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Erbsen (Dose)', category: 'Konserven', canonicalId: 'erbsen_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Linsensuppe (Dose)', category: 'Konserven', canonicalId: 'linsen_dose', defaultUnit: 'Dose'),

    // ──────────────────────────────────────────────────────
    // BRÜHE & SUPPEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Gemüsebrühe', category: 'Gewürze & Soßen', canonicalId: 'gemuese_bruehe', defaultUnit: 'ml', aliases: ['Gemüsebrühe']),
    IngredientEntry(name: 'Hühnerbrühe', category: 'Gewürze & Soßen', canonicalId: 'huehn_bruehe', defaultUnit: 'ml'),
    IngredientEntry(name: 'Rinderbrühe', category: 'Gewürze & Soßen', canonicalId: 'rind_bruehe', defaultUnit: 'ml'),
    IngredientEntry(name: 'Gemüsebrühwürfel', category: 'Gewürze & Soßen', canonicalId: 'gemuese_brueh_wuerfel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Miso-Paste', category: 'Gewürze & Soßen', canonicalId: 'miso', defaultUnit: 'EL'),

    // ──────────────────────────────────────────────────────
    // GEWÜRZE (TROCKEN) – Basisgewürze
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Salz', category: 'Gewürze & Soßen', canonicalId: 'salz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Pfeffer', category: 'Gewürze & Soßen', canonicalId: 'pfeffer', defaultUnit: 'TL', aliases: ['Schwarzer Pfeffer']),
    IngredientEntry(name: 'Paprikapulver (süß)', category: 'Gewürze & Soßen', canonicalId: 'paprika_suess', defaultUnit: 'TL'),
    IngredientEntry(name: 'Paprikapulver (scharf)', category: 'Gewürze & Soßen', canonicalId: 'paprika_scharf', defaultUnit: 'TL'),
    IngredientEntry(name: 'Kreuzkümmel', category: 'Gewürze & Soßen', canonicalId: 'kreuzku', defaultUnit: 'TL', aliases: ['Cumin', 'Kümmel']),
    IngredientEntry(name: 'Curry (Pulver)', category: 'Gewürze & Soßen', canonicalId: 'curry', defaultUnit: 'TL'),
    IngredientEntry(name: 'Kurkuma', category: 'Gewürze & Soßen', canonicalId: 'kurkuma', defaultUnit: 'TL', aliases: ['Gelbwurz']),
    IngredientEntry(name: 'Zimt', category: 'Gewürze & Soßen', canonicalId: 'zimt', defaultUnit: 'TL'),
    IngredientEntry(name: 'Oregano', category: 'Gewürze & Soßen', canonicalId: 'oregano', defaultUnit: 'TL'),
    IngredientEntry(name: 'Thymian (trocken)', category: 'Gewürze & Soßen', canonicalId: 'thymian_trocken', defaultUnit: 'TL'),
    IngredientEntry(name: 'Rosmarin (trocken)', category: 'Gewürze & Soßen', canonicalId: 'rosmarin_trocken', defaultUnit: 'TL'),
    IngredientEntry(name: 'Lorbeerblatt', category: 'Gewürze & Soßen', canonicalId: 'lorbeer', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chili (Flocken)', category: 'Gewürze & Soßen', canonicalId: 'chili_flocken', defaultUnit: 'TL'),
    IngredientEntry(name: 'Chili (frisch)', category: 'Obst & Gemüse', canonicalId: 'chili_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Muskatnuss', category: 'Gewürze & Soßen', canonicalId: 'muskat', defaultUnit: 'TL'),
    IngredientEntry(name: 'Kardamom', category: 'Gewürze & Soßen', canonicalId: 'kardamom', defaultUnit: 'TL'),
    IngredientEntry(name: 'Koriander (gemahlen)', category: 'Gewürze & Soßen', canonicalId: 'koriander_gemahlen', defaultUnit: 'TL'),
    IngredientEntry(name: 'Koriander (frisch)', category: 'Obst & Gemüse', canonicalId: 'koriander_frisch', defaultUnit: 'Bund'),

    // ──────────────────────────────────────────────────────
    // NÜSSE, SAMEN & TROCKENFRÜCHTE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Mandeln', category: 'Nüsse & Samen', canonicalId: 'mandeln', defaultUnit: 'g'),
    IngredientEntry(name: 'Mandeln (gemahlen)', category: 'Nüsse & Samen', canonicalId: 'mandeln_gemahlen', defaultUnit: 'g'),
    IngredientEntry(name: 'Walnüsse', category: 'Nüsse & Samen', canonicalId: 'walnuesse', defaultUnit: 'g'),
    IngredientEntry(name: 'Cashewkerne', category: 'Nüsse & Samen', canonicalId: 'cashew', defaultUnit: 'g'),
    IngredientEntry(name: 'Erdnüsse', category: 'Nüsse & Samen', canonicalId: 'erdnuesse', defaultUnit: 'g'),
    IngredientEntry(name: 'Erdnussbutter', category: 'Nüsse & Samen', canonicalId: 'erdnuss_butter', defaultUnit: 'EL'),
    IngredientEntry(name: 'Haselnüsse', category: 'Nüsse & Samen', canonicalId: 'haselnuesse', defaultUnit: 'g'),
    IngredientEntry(name: 'Pistazienkerne', category: 'Nüsse & Samen', canonicalId: 'pistazien', defaultUnit: 'g'),
    IngredientEntry(name: 'Pinienkerne', category: 'Nüsse & Samen', canonicalId: 'pinienkerne', defaultUnit: 'g'),
    IngredientEntry(name: 'Kürbiskerne', category: 'Nüsse & Samen', canonicalId: 'kuerbiskerne', defaultUnit: 'g'),
    IngredientEntry(name: 'Sonnenblumenkerne', category: 'Nüsse & Samen', canonicalId: 'sonnenblumen_kerne', defaultUnit: 'g'),
    IngredientEntry(name: 'Leinsamen', category: 'Nüsse & Samen', canonicalId: 'leinsamen', defaultUnit: 'g'),
    IngredientEntry(name: 'Chiasamen', category: 'Nüsse & Samen', canonicalId: 'chia', defaultUnit: 'g'),
    IngredientEntry(name: 'Sesam', category: 'Nüsse & Samen', canonicalId: 'sesam', defaultUnit: 'g'),
    IngredientEntry(name: 'Rosinen', category: 'Nüsse & Samen', canonicalId: 'rosinen', defaultUnit: 'g'),
    IngredientEntry(name: 'Datteln', category: 'Nüsse & Samen', canonicalId: 'datteln', defaultUnit: 'g'),
    IngredientEntry(name: 'Getrocknete Aprikosen', category: 'Nüsse & Samen', canonicalId: 'aprikosen_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Kokosraspeln', category: 'Nüsse & Samen', canonicalId: 'kokosraspeln', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // SÜSSES, AUFSTRICHE & MARMELADEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Honig', category: 'Süßes & Aufstriche', canonicalId: 'honig', defaultUnit: 'EL'),
    IngredientEntry(name: 'Ahornsirup', category: 'Süßes & Aufstriche', canonicalId: 'ahornsirup', defaultUnit: 'EL'),
    IngredientEntry(name: 'Agavendicksaft', category: 'Süßes & Aufstriche', canonicalId: 'agavendicksaft', defaultUnit: 'EL'),
    IngredientEntry(name: 'Marmelade (Erdbeere)', category: 'Süßes & Aufstriche', canonicalId: 'marmelade_erdbeere', defaultUnit: 'EL'),
    IngredientEntry(name: 'Nuss-Nougat-Creme', category: 'Süßes & Aufstriche', canonicalId: 'nougat_creme', defaultUnit: 'EL'),

    // ──────────────────────────────────────────────────────
    // GETRÄNKE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Mineralwasser', category: 'Getränke', canonicalId: 'wasser_mineral', defaultUnit: 'L'),
    IngredientEntry(name: 'Orangensaft', category: 'Getränke', canonicalId: 'oj', defaultUnit: 'L'),
    IngredientEntry(name: 'Apfelsaft', category: 'Getränke', canonicalId: 'apfelsaft', defaultUnit: 'L'),
    IngredientEntry(name: 'Kaffee (gemahlen)', category: 'Getränke', canonicalId: 'kaffee_gemahlen', defaultUnit: 'g'),
    IngredientEntry(name: 'Kaffee (Bohnen)', category: 'Getränke', canonicalId: 'kaffee_bohnen', defaultUnit: 'g'),
    IngredientEntry(name: 'Grüner Tee', category: 'Getränke', canonicalId: 'tee_gruen', defaultUnit: 'g'),
    IngredientEntry(name: 'Schwarzer Tee', category: 'Getränke', canonicalId: 'tee_schwarz', defaultUnit: 'g'),
    IngredientEntry(name: 'Rotwein', category: 'Getränke', canonicalId: 'rotwein', defaultUnit: 'ml'),
    IngredientEntry(name: 'Weißwein', category: 'Getränke', canonicalId: 'weisswein', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // FRÜHSTÜCK & MÜSLI
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Müsli', category: 'Frühstück', canonicalId: 'muesli', defaultUnit: 'g'),
    IngredientEntry(name: 'Granola', category: 'Frühstück', canonicalId: 'granola', defaultUnit: 'g'),
    IngredientEntry(name: 'Cornflakes', category: 'Frühstück', canonicalId: 'cornflakes', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // SONSTIGES / VERSCHIEDENES
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Hefe (Würfel)', category: 'Backen', canonicalId: 'hefe_wuerfel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Speisestärke', category: 'Backen', canonicalId: 'speisestaerke', defaultUnit: 'EL'),
    IngredientEntry(name: 'Sauerteig-Starter', category: 'Backen', canonicalId: 'sauerteig', defaultUnit: 'g'),
    IngredientEntry(name: 'Tempura-Teig', category: 'Vorrat', canonicalId: 'tempura', defaultUnit: 'g'),
    IngredientEntry(name: 'Blätterteig', category: 'Backen', canonicalId: 'blaetterteig', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Mürbeteig', category: 'Backen', canonicalId: 'muerbeteig', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Filoteig', category: 'Backen', canonicalId: 'filoteig', defaultUnit: 'Packung'),

    // ──────────────────────────────────────────────────────
    // WURST & AUFSCHNITT (KÜHLTHEKE)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Leberwurst', category: 'Wurst & Aufschnitt', canonicalId: 'leberwurst', defaultUnit: 'g'),
    IngredientEntry(name: 'Teewurst', category: 'Wurst & Aufschnitt', canonicalId: 'teewurst', defaultUnit: 'g'),
    IngredientEntry(name: 'Mortadella', category: 'Wurst & Aufschnitt', canonicalId: 'mortadella', defaultUnit: 'g'),
    IngredientEntry(name: 'Lyoner', category: 'Wurst & Aufschnitt', canonicalId: 'lyoner', defaultUnit: 'g', aliases: ['Fleischwurst']),
    IngredientEntry(name: 'Bierschinken', category: 'Wurst & Aufschnitt', canonicalId: 'bierschinken', defaultUnit: 'g'),
    IngredientEntry(name: 'Chorizo', category: 'Wurst & Aufschnitt', canonicalId: 'chorizo', defaultUnit: 'g'),
    IngredientEntry(name: 'Pepperoni', category: 'Wurst & Aufschnitt', canonicalId: 'pepperoni', defaultUnit: 'g'),
    IngredientEntry(name: 'Prosciutto', category: 'Wurst & Aufschnitt', canonicalId: 'prosciutto', defaultUnit: 'g', aliases: ['Parmaschinken']),
    IngredientEntry(name: 'Serrano-Schinken', category: 'Wurst & Aufschnitt', canonicalId: 'serrano', defaultUnit: 'g'),
    IngredientEntry(name: 'Guanciale', category: 'Wurst & Aufschnitt', canonicalId: 'guanciale', defaultUnit: 'g'),
    IngredientEntry(name: 'Pancetta', category: 'Wurst & Aufschnitt', canonicalId: 'pancetta', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // KÄSE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Camembert', category: 'Milchprodukte', canonicalId: 'camembert', defaultUnit: 'g'),
    IngredientEntry(name: 'Brie', category: 'Milchprodukte', canonicalId: 'brie', defaultUnit: 'g'),
    IngredientEntry(name: 'Gorgonzola', category: 'Milchprodukte', canonicalId: 'gorgonzola', defaultUnit: 'g'),
    IngredientEntry(name: 'Pecorino', category: 'Milchprodukte', canonicalId: 'pecorino', defaultUnit: 'g'),
    IngredientEntry(name: 'Gruyère', category: 'Milchprodukte', canonicalId: 'gruyere', defaultUnit: 'g', aliases: ['Greyerzer']),
    IngredientEntry(name: 'Halloumi', category: 'Milchprodukte', canonicalId: 'halloumi', defaultUnit: 'g'),
    IngredientEntry(name: 'Hüttenkäse', category: 'Milchprodukte', canonicalId: 'huettenkaese', defaultUnit: 'g', aliases: ['Cottage Cheese']),
    IngredientEntry(name: 'Burrata', category: 'Milchprodukte', canonicalId: 'burrata', defaultUnit: 'g'),
    IngredientEntry(name: 'Schmelzkäse', category: 'Milchprodukte', canonicalId: 'schmelzkaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Käse (gerieben)', category: 'Milchprodukte', canonicalId: 'kaese_gerieben', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // FERTIGPRODUKTE & CONVENIENCE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Tiefkühlpizza', category: 'Fertigprodukte', canonicalId: 'tk_pizza', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tiefkühlgemüse-Mix', category: 'Fertigprodukte', canonicalId: 'tk_gemuese_mix', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Pommes', category: 'Fertigprodukte', canonicalId: 'tk_pommes', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Burger', category: 'Fertigprodukte', canonicalId: 'tk_burger', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Instantnudeln', category: 'Fertigprodukte', canonicalId: 'instant_nudeln', defaultUnit: 'Packung', aliases: ['Ramen', 'Cup Noodles']),
    IngredientEntry(name: 'Instantsuppe', category: 'Fertigprodukte', canonicalId: 'instant_suppe', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Dosensuppe', category: 'Fertigprodukte', canonicalId: 'dose_suppe', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Fertigsauce (Bolognese)', category: 'Fertigprodukte', canonicalId: 'sauce_bolognese', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Fertigsauce (Tomaten)', category: 'Fertigprodukte', canonicalId: 'sauce_tomate', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Fertigsauce (Curry)', category: 'Fertigprodukte', canonicalId: 'sauce_curry', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Fertig-Gulasch', category: 'Fertigprodukte', canonicalId: 'fertig_gulasch', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Fertig-Linsensuppe', category: 'Fertigprodukte', canonicalId: 'fertig_linsensuppe', defaultUnit: 'Dose'),

    // ──────────────────────────────────────────────────────
    // ASIATISCHE ZUTATEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Ramen-Nudeln', category: 'Asiatisch', canonicalId: 'ramen_nudeln', defaultUnit: 'g'),
    IngredientEntry(name: 'Udon-Nudeln', category: 'Asiatisch', canonicalId: 'udon', defaultUnit: 'g'),
    IngredientEntry(name: 'Soba-Nudeln', category: 'Asiatisch', canonicalId: 'soba', defaultUnit: 'g'),
    IngredientEntry(name: 'Glasnudeln', category: 'Asiatisch', canonicalId: 'glasnudeln', defaultUnit: 'g'),
    IngredientEntry(name: 'Nori-Blätter', category: 'Asiatisch', canonicalId: 'nori', defaultUnit: 'Blatt', aliases: ['Sushi-Nori']),
    IngredientEntry(name: 'Sushi-Reis', category: 'Asiatisch', canonicalId: 'sushi_reis', defaultUnit: 'g'),
    IngredientEntry(name: 'Reisessig', category: 'Asiatisch', canonicalId: 'reisessig', defaultUnit: 'ml'),
    IngredientEntry(name: 'Wasabi', category: 'Asiatisch', canonicalId: 'wasabi', defaultUnit: 'g'),
    IngredientEntry(name: 'Ingwer (eingelegter)', category: 'Asiatisch', canonicalId: 'ingwer_eingel', defaultUnit: 'g'),
    IngredientEntry(name: 'Kokosmilch (Tetra)', category: 'Asiatisch', canonicalId: 'kokosmilch_tetra', defaultUnit: 'ml'),
    IngredientEntry(name: 'Currypaste (rot)', category: 'Asiatisch', canonicalId: 'curry_paste_rot', defaultUnit: 'EL'),
    IngredientEntry(name: 'Currypaste (grün)', category: 'Asiatisch', canonicalId: 'curry_paste_gruen', defaultUnit: 'EL'),
    IngredientEntry(name: 'Currypaste (gelb)', category: 'Asiatisch', canonicalId: 'curry_paste_gelb', defaultUnit: 'EL'),
    IngredientEntry(name: 'Sambal Oelek', category: 'Asiatisch', canonicalId: 'sambal', defaultUnit: 'TL'),
    IngredientEntry(name: 'Tamarinde', category: 'Asiatisch', canonicalId: 'tamarinde', defaultUnit: 'g'),
    IngredientEntry(name: 'Zitronengras', category: 'Asiatisch', canonicalId: 'zitronengras', defaultUnit: 'Stück', aliases: ['Lemongrass']),
    IngredientEntry(name: 'Kaffirlimettenblätter', category: 'Asiatisch', canonicalId: 'kaffirblatt', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Galgant', category: 'Asiatisch', canonicalId: 'galgant', defaultUnit: 'g'),
    IngredientEntry(name: 'Edamame (TK)', category: 'Asiatisch', canonicalId: 'edamame_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Bambussprossen (Dose)', category: 'Asiatisch', canonicalId: 'bambus_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sojasprossen', category: 'Asiatisch', canonicalId: 'sojasprossen', defaultUnit: 'g'),
    IngredientEntry(name: 'Pak Choi', category: 'Asiatisch', canonicalId: 'pak_choi', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Bok Choy', category: 'Asiatisch', canonicalId: 'bok_choy', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Shiitake-Pilze', category: 'Asiatisch', canonicalId: 'shiitake', defaultUnit: 'g'),
    IngredientEntry(name: 'Shiitake-Pilze (getrocknet)', category: 'Asiatisch', canonicalId: 'shiitake_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Wakame (Algen)', category: 'Asiatisch', canonicalId: 'wakame', defaultUnit: 'g'),
    IngredientEntry(name: 'Mirin', category: 'Asiatisch', canonicalId: 'mirin', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sake', category: 'Asiatisch', canonicalId: 'sake', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bonito-Flocken', category: 'Asiatisch', canonicalId: 'bonito', defaultUnit: 'g'),
    IngredientEntry(name: 'Dashi', category: 'Asiatisch', canonicalId: 'dashi', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // MEDITERRANE / SÜDEUROPÄISCHE ZUTATEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Oliven (schwarz)', category: 'Mediterran', canonicalId: 'oliven_schwarz', defaultUnit: 'g'),
    IngredientEntry(name: 'Oliven (grün)', category: 'Mediterran', canonicalId: 'oliven_gruen', defaultUnit: 'g'),
    IngredientEntry(name: 'Kalamata-Oliven', category: 'Mediterran', canonicalId: 'oliven_kalamata', defaultUnit: 'g'),
    IngredientEntry(name: 'Kapern', category: 'Mediterran', canonicalId: 'kapern', defaultUnit: 'g'),
    IngredientEntry(name: 'Artischockenherzen (Glas)', category: 'Mediterran', canonicalId: 'artischocke_glas', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Getrocknete Tomaten (Öl)', category: 'Mediterran', canonicalId: 'tom_getrocknet_oel', defaultUnit: 'g'),
    IngredientEntry(name: 'Getrocknete Tomaten', category: 'Mediterran', canonicalId: 'tom_getrocknet', defaultUnit: 'g'),
    IngredientEntry(name: 'Pesto (Basilikum)', category: 'Mediterran', canonicalId: 'pesto_basilikum', defaultUnit: 'EL'),
    IngredientEntry(name: 'Pesto (Rosso)', category: 'Mediterran', canonicalId: 'pesto_rosso', defaultUnit: 'EL'),
    IngredientEntry(name: 'Hummus', category: 'Mediterran', canonicalId: 'hummus', defaultUnit: 'g'),
    IngredientEntry(name: 'Tahini', category: 'Mediterran', canonicalId: 'tahini', defaultUnit: 'EL', aliases: ['Sesampaste']),
    IngredientEntry(name: 'Za\'atar', category: 'Mediterran', canonicalId: 'zaatar', defaultUnit: 'TL'),
    IngredientEntry(name: 'Harissa', category: 'Mediterran', canonicalId: 'harissa', defaultUnit: 'TL'),
    IngredientEntry(name: 'Ras el Hanout', category: 'Mediterran', canonicalId: 'ras_el_hanout', defaultUnit: 'TL'),
    IngredientEntry(name: 'Sumac', category: 'Mediterran', canonicalId: 'sumac', defaultUnit: 'TL'),

    // ──────────────────────────────────────────────────────
    // MEXIKANISCH / LATEINAMERIKANISCH
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Jalapeños (Glas)', category: 'Mexikanisch', canonicalId: 'jalapeno_glas', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Jalapeños (frisch)', category: 'Mexikanisch', canonicalId: 'jalapeno_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chipotle (Dose)', category: 'Mexikanisch', canonicalId: 'chipotle_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Guacamole', category: 'Mexikanisch', canonicalId: 'guacamole', defaultUnit: 'g'),
    IngredientEntry(name: 'Salsa', category: 'Mexikanisch', canonicalId: 'salsa', defaultUnit: 'g'),
    IngredientEntry(name: 'Nachos', category: 'Mexikanisch', canonicalId: 'nachos', defaultUnit: 'g'),
    IngredientEntry(name: 'Taco-Schalen', category: 'Mexikanisch', canonicalId: 'taco_schalen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Enchilada-Sauce', category: 'Mexikanisch', canonicalId: 'enchilada_sauce', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Schwarze Bohnen (Dose)', category: 'Mexikanisch', canonicalId: 'bohnen_schwarz', defaultUnit: 'Dose'),

    // ──────────────────────────────────────────────────────
    // INDISCH / ORIENTALISCH
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Garam Masala', category: 'Gewürze & Soßen', canonicalId: 'garam_masala', defaultUnit: 'TL'),
    IngredientEntry(name: 'Tandoori Masala', category: 'Gewürze & Soßen', canonicalId: 'tandoori_masala', defaultUnit: 'TL'),
    IngredientEntry(name: 'Paneer', category: 'Milchprodukte', canonicalId: 'paneer', defaultUnit: 'g'),
    IngredientEntry(name: 'Ghee', category: 'Milchprodukte', canonicalId: 'ghee', defaultUnit: 'EL'),
    IngredientEntry(name: 'Naan-Brot', category: 'Brot & Backwaren', canonicalId: 'naan', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chapati', category: 'Brot & Backwaren', canonicalId: 'chapati', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Basmati-Reis (Langkorn)', category: 'Nudeln & Getreide', canonicalId: 'basmati_langkorn', defaultUnit: 'g'),
    IngredientEntry(name: 'Linsen (Beluga)', category: 'Vorrat', canonicalId: 'linsen_beluga', defaultUnit: 'g'),
    IngredientEntry(name: 'Bockshornklee', category: 'Gewürze & Soßen', canonicalId: 'bockshornklee', defaultUnit: 'TL'),
    IngredientEntry(name: 'Asafoetida', category: 'Gewürze & Soßen', canonicalId: 'asafoetida', defaultUnit: 'Prise'),

    // ──────────────────────────────────────────────────────
    // WEITERE PILZE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Austernpilze', category: 'Obst & Gemüse', canonicalId: 'austernpilze', defaultUnit: 'g'),
    IngredientEntry(name: 'Kräuterseitlinge', category: 'Obst & Gemüse', canonicalId: 'kraeuterseitling', defaultUnit: 'g'),
    IngredientEntry(name: 'Pfifferlinge', category: 'Obst & Gemüse', canonicalId: 'pfifferlinge', defaultUnit: 'g'),
    IngredientEntry(name: 'Steinpilze (getrocknet)', category: 'Obst & Gemüse', canonicalId: 'steinpilze_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Champignons (Dose)', category: 'Konserven', canonicalId: 'champignons_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Portobello-Pilze', category: 'Obst & Gemüse', canonicalId: 'portobello', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // WEITERE GEMÜSESORTEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Mangold', category: 'Obst & Gemüse', canonicalId: 'mangold', defaultUnit: 'g'),
    IngredientEntry(name: 'Grünkohl', category: 'Obst & Gemüse', canonicalId: 'gruenkohl', defaultUnit: 'g', aliases: ['Kale']),
    IngredientEntry(name: 'Wirsing', category: 'Obst & Gemüse', canonicalId: 'wirsing', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Spitzkohl', category: 'Obst & Gemüse', canonicalId: 'spitzkohl', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chinakohl', category: 'Obst & Gemüse', canonicalId: 'chinakohl', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Pak Choi', category: 'Obst & Gemüse', canonicalId: 'pak_choi_de', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Pastinake', category: 'Obst & Gemüse', canonicalId: 'pastinake', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Topinambur', category: 'Obst & Gemüse', canonicalId: 'topinambur', defaultUnit: 'g'),
    IngredientEntry(name: 'Schwarzwurzel', category: 'Obst & Gemüse', canonicalId: 'schwarzwurzel', defaultUnit: 'g'),
    IngredientEntry(name: 'Meerrettich', category: 'Obst & Gemüse', canonicalId: 'meerrettich', defaultUnit: 'g'),
    IngredientEntry(name: 'Meerrettich (Glas)', category: 'Konserven', canonicalId: 'meerrettich_glas', defaultUnit: 'EL'),
    IngredientEntry(name: 'Rote Paprika (geröstet, Glas)', category: 'Konserven', canonicalId: 'paprika_roast_glas', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Mais-Kolben', category: 'Obst & Gemüse', canonicalId: 'mais_kolben', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kürbis (Hokkaido)', category: 'Obst & Gemüse', canonicalId: 'kuerbis_hokkaido', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kürbis (Butternut)', category: 'Obst & Gemüse', canonicalId: 'kuerbis_butternut', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kürbis (TK)', category: 'Obst & Gemüse', canonicalId: 'kuerbis_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Romanesco', category: 'Obst & Gemüse', canonicalId: 'romanesco', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Okra', category: 'Obst & Gemüse', canonicalId: 'okra', defaultUnit: 'g'),
    IngredientEntry(name: 'Süßkartoffel (TK)', category: 'Obst & Gemüse', canonicalId: 'suesskartoffel_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Kartoffeln (festkochend)', category: 'Obst & Gemüse', canonicalId: 'kartoffel_fest', defaultUnit: 'kg'),
    IngredientEntry(name: 'Kartoffeln (mehligkochend)', category: 'Obst & Gemüse', canonicalId: 'kartoffel_mehlig', defaultUnit: 'kg'),
    IngredientEntry(name: 'Frühkartoffeln', category: 'Obst & Gemüse', canonicalId: 'kartoffel_frueh', defaultUnit: 'kg'),

    // ──────────────────────────────────────────────────────
    // WEITERE OBST- UND EXOTISCHE SORTEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Granatapfel', category: 'Obst & Gemüse', canonicalId: 'granatapfel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Papaya', category: 'Obst & Gemüse', canonicalId: 'papaya', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Melone (Wassermelone)', category: 'Obst & Gemüse', canonicalId: 'wassermelone', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Melone (Honigmelone)', category: 'Obst & Gemüse', canonicalId: 'honigmelone', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Feigen (frisch)', category: 'Obst & Gemüse', canonicalId: 'feige_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Feigen (getrocknet)', category: 'Nüsse & Samen', canonicalId: 'feige_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Pflaumen', category: 'Obst & Gemüse', canonicalId: 'pflaume', defaultUnit: 'g'),
    IngredientEntry(name: 'Zwetschgen', category: 'Obst & Gemüse', canonicalId: 'zwetschge', defaultUnit: 'g'),
    IngredientEntry(name: 'Aprikosen (frisch)', category: 'Obst & Gemüse', canonicalId: 'aprikose_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Litschi', category: 'Obst & Gemüse', canonicalId: 'litschi', defaultUnit: 'g'),
    IngredientEntry(name: 'Drachenfrucht', category: 'Obst & Gemüse', canonicalId: 'drachenfrucht', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Passionsfrucht', category: 'Obst & Gemüse', canonicalId: 'passionsfrucht', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kokosnuss', category: 'Obst & Gemüse', canonicalId: 'kokosnuss', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Grapefruit', category: 'Obst & Gemüse', canonicalId: 'grapefruit', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Physalis', category: 'Obst & Gemüse', canonicalId: 'physalis', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // WEITERE KONSERVEN & GLÄSER
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Sardinen (Dose)', category: 'Konserven', canonicalId: 'sardinen_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Makrele (Dose)', category: 'Konserven', canonicalId: 'makrele_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Lachs (Dose)', category: 'Konserven', canonicalId: 'lachs_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Rindfleisch (Dose)', category: 'Konserven', canonicalId: 'rind_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Linseneintopf (Dose)', category: 'Konserven', canonicalId: 'linsen_eintopf_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sauerkraut (Dose)', category: 'Konserven', canonicalId: 'sauerkraut_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sauerkraut (Glas)', category: 'Konserven', canonicalId: 'sauerkraut_glas', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Rote Bete (Glas)', category: 'Konserven', canonicalId: 'rote_bete_glas', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Gurken (eingelegte)', category: 'Konserven', canonicalId: 'gurken_eingel', defaultUnit: 'Glas', aliases: ['Gewürzgurken', 'Essiggurken']),
    IngredientEntry(name: 'Senf', category: 'Konserven', canonicalId: 'senf', defaultUnit: 'TL', aliases: ['Mittelscharf', 'Dijon']),
    IngredientEntry(name: 'Senf (Dijon)', category: 'Konserven', canonicalId: 'senf_dijon', defaultUnit: 'TL'),
    IngredientEntry(name: 'Senf (süß)', category: 'Konserven', canonicalId: 'senf_suess', defaultUnit: 'TL'),
    IngredientEntry(name: 'Ketchup', category: 'Konserven', canonicalId: 'ketchup', defaultUnit: 'EL'),
    IngredientEntry(name: 'Mayonnaise', category: 'Konserven', canonicalId: 'mayo', defaultUnit: 'EL'),
    IngredientEntry(name: 'Remoulade', category: 'Konserven', canonicalId: 'remoulade', defaultUnit: 'EL'),
    IngredientEntry(name: 'Tzatziki', category: 'Konserven', canonicalId: 'tzatziki', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // WEITERE GEWÜRZE & KRÄUTER (TROCKEN)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Anis', category: 'Gewürze & Soßen', canonicalId: 'anis', defaultUnit: 'TL'),
    IngredientEntry(name: 'Fenchelsamen', category: 'Gewürze & Soßen', canonicalId: 'fenchel_samen', defaultUnit: 'TL'),
    IngredientEntry(name: 'Nelken', category: 'Gewürze & Soßen', canonicalId: 'nelken', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Sternanis', category: 'Gewürze & Soßen', canonicalId: 'sternanis', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kümmel (gemahlen)', category: 'Gewürze & Soßen', canonicalId: 'kuemmel_gem', defaultUnit: 'TL'),
    IngredientEntry(name: 'Safran', category: 'Gewürze & Soßen', canonicalId: 'safran', defaultUnit: 'g'),
    IngredientEntry(name: 'Bohnenkraut', category: 'Gewürze & Soßen', canonicalId: 'bohnenkraut', defaultUnit: 'TL'),
    IngredientEntry(name: 'Majoran', category: 'Gewürze & Soßen', canonicalId: 'majoran', defaultUnit: 'TL'),
    IngredientEntry(name: 'Salbei (trocken)', category: 'Gewürze & Soßen', canonicalId: 'salbei_trocken', defaultUnit: 'TL'),
    IngredientEntry(name: 'Salbei (frisch)', category: 'Obst & Gemüse', canonicalId: 'salbei_frisch', defaultUnit: 'Blatt'),
    IngredientEntry(name: 'Estragon', category: 'Gewürze & Soßen', canonicalId: 'estragon', defaultUnit: 'TL'),
    IngredientEntry(name: 'Liebstöckel', category: 'Gewürze & Soßen', canonicalId: 'liebstoeckel', defaultUnit: 'TL'),
    IngredientEntry(name: 'Curryblätter', category: 'Gewürze & Soßen', canonicalId: 'curryblaetter', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chipotle-Pulver', category: 'Gewürze & Soßen', canonicalId: 'chipotle_pulver', defaultUnit: 'TL'),
    IngredientEntry(name: 'Cayennepfeffer', category: 'Gewürze & Soßen', canonicalId: 'cayenne', defaultUnit: 'TL'),
    IngredientEntry(name: 'Szechuanpfeffer', category: 'Gewürze & Soßen', canonicalId: 'szechuan', defaultUnit: 'TL'),
    IngredientEntry(name: 'Schwarzer Sesam', category: 'Nüsse & Samen', canonicalId: 'sesam_schwarz', defaultUnit: 'g'),
    IngredientEntry(name: 'Fleur de Sel', category: 'Gewürze & Soßen', canonicalId: 'fleur_de_sel', defaultUnit: 'g'),
    IngredientEntry(name: 'Meersalz', category: 'Gewürze & Soßen', canonicalId: 'meersalz', defaultUnit: 'g'),
    IngredientEntry(name: 'Jodsalz', category: 'Gewürze & Soßen', canonicalId: 'jodsalz', defaultUnit: 'g'),
    IngredientEntry(name: 'Räucherpaprika', category: 'Gewürze & Soßen', canonicalId: 'raeucherpaprika', defaultUnit: 'TL', aliases: ['Paprika geräuchert', 'Smoked Paprika']),
    IngredientEntry(name: 'Kräuter der Provence', category: 'Gewürze & Soßen', canonicalId: 'kraeuter_provence', defaultUnit: 'TL'),
    IngredientEntry(name: 'Italienische Kräuter', category: 'Gewürze & Soßen', canonicalId: 'kraeuter_ital', defaultUnit: 'TL'),
    IngredientEntry(name: 'Grillgewürz', category: 'Gewürze & Soßen', canonicalId: 'grillgewuerz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Barbecue-Sauce', category: 'Öle & Essig', canonicalId: 'bbq_sauce', defaultUnit: 'EL'),
    IngredientEntry(name: 'Pfeffer (weiß)', category: 'Gewürze & Soßen', canonicalId: 'pfeffer_weiss', defaultUnit: 'TL'),
    IngredientEntry(name: 'Pfeffer (bunt)', category: 'Gewürze & Soßen', canonicalId: 'pfeffer_bunt', defaultUnit: 'TL'),

    // ──────────────────────────────────────────────────────
    // BACKZUTATEN ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Zuckerrübensirup', category: 'Backen', canonicalId: 'zuckersirup', defaultUnit: 'EL'),
    IngredientEntry(name: 'Kokosnusszucker', category: 'Backen', canonicalId: 'kokos_zucker', defaultUnit: 'g'),
    IngredientEntry(name: 'Stevia', category: 'Backen', canonicalId: 'stevia', defaultUnit: 'g'),
    IngredientEntry(name: 'Erythrit', category: 'Backen', canonicalId: 'erythrit', defaultUnit: 'g'),
    IngredientEntry(name: 'Xanthan', category: 'Backen', canonicalId: 'xanthan', defaultUnit: 'g'),
    IngredientEntry(name: 'Flohsamenschalen', category: 'Backen', canonicalId: 'flohsamen', defaultUnit: 'g'),
    IngredientEntry(name: 'Reismehl', category: 'Backen', canonicalId: 'reismehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Buchweizenmehl', category: 'Backen', canonicalId: 'buchweizenmehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Kichererbsenmehl', category: 'Backen', canonicalId: 'kichererbsenmehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Weiße Schokolade', category: 'Backen', canonicalId: 'schokolade_weiss', defaultUnit: 'g'),
    IngredientEntry(name: 'Kuvertüre', category: 'Backen', canonicalId: 'kuvertuere', defaultUnit: 'g'),
    IngredientEntry(name: 'Marzipan', category: 'Backen', canonicalId: 'marzipan', defaultUnit: 'g'),
    IngredientEntry(name: 'Fondant', category: 'Backen', canonicalId: 'fondant', defaultUnit: 'g'),
    IngredientEntry(name: 'Lebkuchengewürz', category: 'Backen', canonicalId: 'lebkuchen_gewuerz', defaultUnit: 'TL'),

    // ──────────────────────────────────────────────────────
    // GETRÄNKE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Espresso', category: 'Getränke', canonicalId: 'espresso', defaultUnit: 'ml'),
    IngredientEntry(name: 'Instantkaffee', category: 'Getränke', canonicalId: 'kaffee_instant', defaultUnit: 'g', aliases: ['Nescafé']),
    IngredientEntry(name: 'Kakao (Trinkkakao)', category: 'Getränke', canonicalId: 'trinkkakao', defaultUnit: 'g'),
    IngredientEntry(name: 'Heiße Schokolade', category: 'Getränke', canonicalId: 'heisse_schokolade', defaultUnit: 'g'),
    IngredientEntry(name: 'Kamillentee', category: 'Getränke', canonicalId: 'tee_kamille', defaultUnit: 'g'),
    IngredientEntry(name: 'Pfefferminztee', category: 'Getränke', canonicalId: 'tee_pfefferminz', defaultUnit: 'g'),
    IngredientEntry(name: 'Ingwertee', category: 'Getränke', canonicalId: 'tee_ingwer', defaultUnit: 'g'),
    IngredientEntry(name: 'Multivitaminsaft', category: 'Getränke', canonicalId: 'multivitaminsaft', defaultUnit: 'L'),
    IngredientEntry(name: 'Tomatensaft', category: 'Getränke', canonicalId: 'tomatensaft', defaultUnit: 'L'),
    IngredientEntry(name: 'Prosecco', category: 'Getränke', canonicalId: 'prosecco', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bier', category: 'Getränke', canonicalId: 'bier', defaultUnit: 'L'),
    IngredientEntry(name: 'Kochwein (Rot)', category: 'Getränke', canonicalId: 'kochwein_rot', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kochwein (Weiß)', category: 'Getränke', canonicalId: 'kochwein_weiss', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sekt', category: 'Getränke', canonicalId: 'sekt', defaultUnit: 'ml'),
    IngredientEntry(name: 'Gin', category: 'Getränke', canonicalId: 'gin', defaultUnit: 'ml'),
    IngredientEntry(name: 'Rum', category: 'Getränke', canonicalId: 'rum', defaultUnit: 'ml'),
    IngredientEntry(name: 'Brandy / Cognac', category: 'Getränke', canonicalId: 'cognac', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // FRÜHSTÜCK ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Dinkelflakes', category: 'Frühstück', canonicalId: 'dinkelflakes', defaultUnit: 'g'),
    IngredientEntry(name: 'Chiapudding', category: 'Frühstück', canonicalId: 'chiapudding', defaultUnit: 'g'),
    IngredientEntry(name: 'Overnight Oats', category: 'Frühstück', canonicalId: 'overnight_oats', defaultUnit: 'g'),
    IngredientEntry(name: 'Protein-Pulver', category: 'Frühstück', canonicalId: 'protein_pulver', defaultUnit: 'g'),
    IngredientEntry(name: 'Whey-Protein', category: 'Frühstück', canonicalId: 'whey', defaultUnit: 'g'),
    IngredientEntry(name: 'Leinöl', category: 'Öle & Essig', canonicalId: 'leinoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kokosfett', category: 'Öle & Essig', canonicalId: 'kokosfett', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // TIEFKÜHLPRODUKTE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Tiefkühl-Blattspinat', category: 'Tiefkühl', canonicalId: 'tk_blattspinat', defaultUnit: 'g', aliases: ['Spinat TK']),
    IngredientEntry(name: 'Tiefkühl-Erbsen', category: 'Tiefkühl', canonicalId: 'tk_erbsen', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Mais', category: 'Tiefkühl', canonicalId: 'tk_mais', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Brokkoli', category: 'Tiefkühl', canonicalId: 'tk_brokkoli', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Blumenkohl', category: 'Tiefkühl', canonicalId: 'tk_blumenkohl', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Rosenkohl', category: 'Tiefkühl', canonicalId: 'tk_rosenkohl', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Karotten', category: 'Tiefkühl', canonicalId: 'tk_karotten', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Süßkartoffel', category: 'Tiefkühl', canonicalId: 'tk_suesskartoffel', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Pilze', category: 'Tiefkühl', canonicalId: 'tk_pilze', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Spargel', category: 'Tiefkühl', canonicalId: 'tk_spargel', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Ratatouille', category: 'Tiefkühl', canonicalId: 'tk_ratatouille', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Steak', category: 'Tiefkühl', canonicalId: 'tk_steak', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Maultaschen', category: 'Tiefkühl', canonicalId: 'tk_maultaschen', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Dim Sum', category: 'Tiefkühl', canonicalId: 'tk_dim_sum', defaultUnit: 'g'),
    IngredientEntry(name: 'Tiefkühl-Croissants', category: 'Tiefkühl', canonicalId: 'tk_croissants', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tiefkühl-Brötchen', category: 'Tiefkühl', canonicalId: 'tk_broetchen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tiefkühl-Eis (Vanille)', category: 'Tiefkühl', canonicalId: 'tk_eis_vanille', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // HYGIENE & HAUSHALT (KEIN ESSEN, ABER OFT IN EINKAUFSLISTEN)
    // ──────────────────────────────────────────────────────

    // ── PAPIERWAREN ──────────────────────────────────────
    IngredientEntry(name: 'Toilettenpapier', category: 'Haushalt', canonicalId: 'klopapier', defaultUnit: 'Rolle', aliases: ['Klopapier', 'WC-Papier']),
    IngredientEntry(name: 'Toilettenpapier (3-lagig)', category: 'Haushalt', canonicalId: 'klopapier_3lag', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Toilettenpapier (4-lagig)', category: 'Haushalt', canonicalId: 'klopapier_4lag', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Toilettenpapier (Großpackung)', category: 'Haushalt', canonicalId: 'klopapier_gross', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Feuchtes Toilettenpapier', category: 'Haushalt', canonicalId: 'feuchtes_klopapier', defaultUnit: 'Packung', aliases: ['Po-Tücher']),
    IngredientEntry(name: 'Küchenpapier', category: 'Haushalt', canonicalId: 'kuechenpapier', defaultUnit: 'Rolle', aliases: ['Küchenrolle']),
    IngredientEntry(name: 'Küchenpapier (extra stark)', category: 'Haushalt', canonicalId: 'kuechenpapier_stark', defaultUnit: 'Rolle'),
    IngredientEntry(name: 'Alufolie', category: 'Haushalt', canonicalId: 'alufolie', defaultUnit: 'Rolle', aliases: ['Aluminiumfolie']),
    IngredientEntry(name: 'Frischhaltefolie', category: 'Haushalt', canonicalId: 'frischhaltefolie', defaultUnit: 'Rolle'),
    IngredientEntry(name: 'Backpapier', category: 'Haushalt', canonicalId: 'backpapier', defaultUnit: 'Rolle', aliases: ['Pergamentpapier']),
    IngredientEntry(name: 'Backpapier (vorgeschnitten)', category: 'Haushalt', canonicalId: 'backpapier_zuschnitt', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Gefrierbeutel', category: 'Haushalt', canonicalId: 'gefrierbeutel', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Papiertaschentücher', category: 'Haushalt', canonicalId: 'taschentuecher', defaultUnit: 'Packung', aliases: ['Taschentücher', 'Kleenex']),
    IngredientEntry(name: 'Papiertaschentücher (Großpackung)', category: 'Haushalt', canonicalId: 'taschentuecher_gross', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Tempos (Einzelpack)', category: 'Haushalt', canonicalId: 'taschentuecher_einzeln', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Servietten (Papier)', category: 'Haushalt', canonicalId: 'servietten', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Servietten (Stoff)', category: 'Haushalt', canonicalId: 'servietten_stoff', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Einwegbecher (Papier)', category: 'Haushalt', canonicalId: 'einwegbecher_papier', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Einwegteller (Papier)', category: 'Haushalt', canonicalId: 'einwegteller', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Einwegbesteck (Set)', category: 'Haushalt', canonicalId: 'einwegbesteck', defaultUnit: 'Packung'),

    // ── SPÜLKÜCHE & REINIGUNG ─────────────────────────────
    IngredientEntry(name: 'Spülmittel', category: 'Haushalt', canonicalId: 'spuelmittel', defaultUnit: 'Flasche', aliases: ['Geschirrspülmittel']),
    IngredientEntry(name: 'Spülmittel (Konzentrat)', category: 'Haushalt', canonicalId: 'spuelmittel_konz', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Spülmittel (sensitiv)', category: 'Haushalt', canonicalId: 'spuelmittel_sensitiv', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Spülmaschinentabs', category: 'Haushalt', canonicalId: 'spuelmaschinentabs', defaultUnit: 'Packung', aliases: ['Geschirrspültabs']),
    IngredientEntry(name: 'Spülmaschinentabs (All-in-1)', category: 'Haushalt', canonicalId: 'spueltabs_allin1', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Spülmaschinensalz', category: 'Haushalt', canonicalId: 'spuelmaschinensalz', defaultUnit: 'kg'),
    IngredientEntry(name: 'Klarspüler', category: 'Haushalt', canonicalId: 'klarspueler', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Spülmaschinenentkalker', category: 'Haushalt', canonicalId: 'spuelm_entkalker', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Küchenschwamm', category: 'Haushalt', canonicalId: 'kuechenschwamm', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Topfreiniger (Schwamm)', category: 'Haushalt', canonicalId: 'topfreiniger_schwamm', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Spülbürste', category: 'Haushalt', canonicalId: 'spuelbuerste', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Topfbürste', category: 'Haushalt', canonicalId: 'topfbuerste', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Stahlwolle', category: 'Haushalt', canonicalId: 'stahlwolle', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Scheuerpulver', category: 'Haushalt', canonicalId: 'scheuerpulver', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Scheuermilch', category: 'Haushalt', canonicalId: 'scheuermilch', defaultUnit: 'Flasche'),

    // ── WÄSCHEPFLEGE ─────────────────────────────────────
    IngredientEntry(name: 'Waschmittel (Pulver)', category: 'Haushalt', canonicalId: 'waschmittel', defaultUnit: 'kg'),
    IngredientEntry(name: 'Waschmittel (Flüssig)', category: 'Haushalt', canonicalId: 'waschmittel_fluessig', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Waschmittel (Pods/Caps)', category: 'Haushalt', canonicalId: 'waschmittel_pods', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Waschmittel (Colorwäsche)', category: 'Haushalt', canonicalId: 'waschmittel_color', defaultUnit: 'kg'),
    IngredientEntry(name: 'Waschmittel (Feinwäsche)', category: 'Haushalt', canonicalId: 'waschmittel_fein', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Weichspüler', category: 'Haushalt', canonicalId: 'weichspueler', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Weichspüler (Konzentrat)', category: 'Haushalt', canonicalId: 'weichspueler_konz', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Wäscheduft-Booster', category: 'Haushalt', canonicalId: 'waesche_booster', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Fleckentferner', category: 'Haushalt', canonicalId: 'fleckentferner', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Fleckentferner-Spray', category: 'Haushalt', canonicalId: 'fleckentferner_spray', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Wäschestärke', category: 'Haushalt', canonicalId: 'waeschestaerke', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Trocknerblatt', category: 'Haushalt', canonicalId: 'trocknerblatt', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Mottenschutz', category: 'Haushalt', canonicalId: 'mottenschutz', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Bügeleisen-Entkalkung', category: 'Haushalt', canonicalId: 'buegel_entkalker', defaultUnit: 'Packung'),

    // ── HAUSHALTSREINIGER ─────────────────────────────────
    IngredientEntry(name: 'Allzweckreiniger', category: 'Haushalt', canonicalId: 'allzweckreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Allzweckreiniger (Spray)', category: 'Haushalt', canonicalId: 'allzweckreiniger_spray', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Küchenreiniger', category: 'Haushalt', canonicalId: 'kuechenreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Backofenreiniger', category: 'Haushalt', canonicalId: 'backofenreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Fettlöser', category: 'Haushalt', canonicalId: 'fettloeser', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Glasreiniger', category: 'Haushalt', canonicalId: 'glasreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Bodenreiniger', category: 'Haushalt', canonicalId: 'bodenreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'WC-Reiniger', category: 'Haushalt', canonicalId: 'wc_reiniger', defaultUnit: 'Flasche', aliases: ['Toilettenreiniger']),
    IngredientEntry(name: 'WC-Stein', category: 'Haushalt', canonicalId: 'wc_stein', defaultUnit: 'Stück'),
    IngredientEntry(name: 'WC-Ente', category: 'Haushalt', canonicalId: 'wc_ente', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Rohrfrei', category: 'Haushalt', canonicalId: 'rohrfrei', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Abflussreiniger', category: 'Haushalt', canonicalId: 'abflussreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Badreiniger', category: 'Haushalt', canonicalId: 'badreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Kalkentferner', category: 'Haushalt', canonicalId: 'kalkentferner', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Entkalkungstabs', category: 'Haushalt', canonicalId: 'entkalkungstabs', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Waschmaschinenreiniger', category: 'Haushalt', canonicalId: 'waschm_reiniger', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Kühlschrankreiniger', category: 'Haushalt', canonicalId: 'kuehlschrank_reiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Fensterreiniger', category: 'Haushalt', canonicalId: 'fensterreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Polsterreiniger', category: 'Haushalt', canonicalId: 'polsterreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Teppichreiniger', category: 'Haushalt', canonicalId: 'teppichreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Edelstahlreiniger', category: 'Haushalt', canonicalId: 'edelstahlreiniger', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Möbelpolitur', category: 'Haushalt', canonicalId: 'moebelpolitur', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Natron (Haushalt)', category: 'Haushalt', canonicalId: 'natron_haushalt', defaultUnit: 'g'),
    IngredientEntry(name: 'Essig (Reinigung)', category: 'Haushalt', canonicalId: 'essig_reinigung', defaultUnit: 'Flasche', aliases: ['Haushaltsessig']),
    IngredientEntry(name: 'Zitronensäure', category: 'Haushalt', canonicalId: 'zitronensaeure', defaultUnit: 'g'),
    IngredientEntry(name: 'Desinfektionsmittel', category: 'Haushalt', canonicalId: 'desinfektion', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Desinfektionsspray', category: 'Haushalt', canonicalId: 'desinfektionsspray', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Desinfektionsgel (Hände)', category: 'Haushalt', canonicalId: 'desinfektionsgel', defaultUnit: 'Flasche'),

    // ── REINIGUNGSUTENSILIEN ──────────────────────────────
    IngredientEntry(name: 'Mikrofasertuch', category: 'Haushalt', canonicalId: 'mikrofasertuch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Mikrofasertücher (Set)', category: 'Haushalt', canonicalId: 'mikrofasertuch_set', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Fensterleder', category: 'Haushalt', canonicalId: 'fensterleder', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Einweghandschuhe', category: 'Haushalt', canonicalId: 'einweghandschuhe', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Gummihandschuhe', category: 'Haushalt', canonicalId: 'gummihandschuhe', defaultUnit: 'Paar'),
    IngredientEntry(name: 'Wischmop', category: 'Haushalt', canonicalId: 'wischmop', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Wischmopp (Ersatztuch)', category: 'Haushalt', canonicalId: 'mop_ersatz', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Staubwedel', category: 'Haushalt', canonicalId: 'staubwedel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Handfeger', category: 'Haushalt', canonicalId: 'handfeger', defaultUnit: 'Stück'),
    IngredientEntry(name: 'WC-Bürste', category: 'Haushalt', canonicalId: 'wc_buerste', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Klobürste (Ersatz)', category: 'Haushalt', canonicalId: 'klobuerste_ersatz', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Stielwischer (Flachwischer)', category: 'Haushalt', canonicalId: 'flachwischer', defaultUnit: 'Stück'),

    // ── MÜLL & ENTSORGUNG ─────────────────────────────────
    IngredientEntry(name: 'Müllbeutel (klein, 10L)', category: 'Haushalt', canonicalId: 'muellbeutel_klein', defaultUnit: 'Packung', aliases: ['Müllsäcke']),
    IngredientEntry(name: 'Müllbeutel (mittel, 35L)', category: 'Haushalt', canonicalId: 'muellbeutel', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Müllbeutel (groß, 60L)', category: 'Haushalt', canonicalId: 'muellbeutel_gross', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Müllsäcke (120L)', category: 'Haushalt', canonicalId: 'muellsack_120', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Biomüllbeutel (kompostierbar)', category: 'Haushalt', canonicalId: 'biomuell_beutel', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Papiertüten (Einkauf)', category: 'Haushalt', canonicalId: 'papiertueten', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Hundekotbeutel', category: 'Haushalt', canonicalId: 'hundekot_beutel', defaultUnit: 'Packung'),

    // ── ZAHNPFLEGE ───────────────────────────────────────
    IngredientEntry(name: 'Zahnpasta', category: 'Körperpflege', canonicalId: 'zahnpasta', defaultUnit: 'Tube', aliases: ['Zahncreme']),
    IngredientEntry(name: 'Zahnpasta (Whitening)', category: 'Körperpflege', canonicalId: 'zahnpasta_white', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Zahnpasta (sensitiv)', category: 'Körperpflege', canonicalId: 'zahnpasta_sensitiv', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Zahnpasta (Kinder)', category: 'Körperpflege', canonicalId: 'zahnpasta_kinder', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Zahnpasta (fluoridarm)', category: 'Körperpflege', canonicalId: 'zahnpasta_fluoridfrei', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Zahnbürste (manuell)', category: 'Körperpflege', canonicalId: 'zahnbuerste', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Zahnbürste (weich)', category: 'Körperpflege', canonicalId: 'zahnbuerste_weich', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Zahnbürste (elektrisch, Aufsatz)', category: 'Körperpflege', canonicalId: 'zahnbuerste_el_aufsatz', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Zahnseide', category: 'Körperpflege', canonicalId: 'zahnseide', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Zahnseide (Wachsband)', category: 'Körperpflege', canonicalId: 'zahnseide_wachs', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Interdentalbürsten', category: 'Körperpflege', canonicalId: 'interdental', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Mundwasser', category: 'Körperpflege', canonicalId: 'mundwasser', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Mundspülung (antibakteriell)', category: 'Körperpflege', canonicalId: 'mundspuehlung', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Zungenreiniger', category: 'Körperpflege', canonicalId: 'zungenreiniger', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Aufbiss-Schiene', category: 'Körperpflege', canonicalId: 'aufbissschiene', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Zahnaufhellungs-Streifen', category: 'Körperpflege', canonicalId: 'zahnweiss_streifen', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Gebissreiniger-Tabs', category: 'Körperpflege', canonicalId: 'gebissreiniger', defaultUnit: 'Packung'),

    // ── HAARPFLEGE ───────────────────────────────────────
    IngredientEntry(name: 'Shampoo', category: 'Körperpflege', canonicalId: 'shampoo', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (Fettiges Haar)', category: 'Körperpflege', canonicalId: 'shampoo_fettig', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (Trockenes Haar)', category: 'Körperpflege', canonicalId: 'shampoo_trocken', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (Coloriert)', category: 'Körperpflege', canonicalId: 'shampoo_color', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (Anti-Schuppen)', category: 'Körperpflege', canonicalId: 'shampoo_schuppen', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (Kinder, tränenlos)', category: 'Körperpflege', canonicalId: 'shampoo_kinder', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (2-in-1)', category: 'Körperpflege', canonicalId: 'shampoo_2in1', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (Bio)', category: 'Körperpflege', canonicalId: 'shampoo_bio', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (Volumen)', category: 'Körperpflege', canonicalId: 'shampoo_volumen', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shampoo (Keratin)', category: 'Körperpflege', canonicalId: 'shampoo_keratin', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Trockenshampoo', category: 'Körperpflege', canonicalId: 'trockenshampoo', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Spülung', category: 'Körperpflege', canonicalId: 'haarspuelung', defaultUnit: 'Flasche', aliases: ['Conditioner', 'Haarspülung']),
    IngredientEntry(name: 'Spülung (Feuchtigkeit)', category: 'Körperpflege', canonicalId: 'haarspuehlung_feuchtig', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Spülung (Reparatur)', category: 'Körperpflege', canonicalId: 'haarspuehlung_repair', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Haarmaske', category: 'Körperpflege', canonicalId: 'haarmaske', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Haarkur', category: 'Körperpflege', canonicalId: 'haarkur', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Leave-in Conditioner', category: 'Körperpflege', canonicalId: 'leave_in', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Haaröl', category: 'Körperpflege', canonicalId: 'haaroel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Haaröl (Argan)', category: 'Körperpflege', canonicalId: 'haaroel_argan', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Haarserum', category: 'Körperpflege', canonicalId: 'haarserum', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Haargel', category: 'Körperpflege', canonicalId: 'haargel', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Haargel (extra stark)', category: 'Körperpflege', canonicalId: 'haargel_stark', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Haarwachs', category: 'Körperpflege', canonicalId: 'haarwachs', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Haarpomade', category: 'Körperpflege', canonicalId: 'pomade', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Haarschaum', category: 'Körperpflege', canonicalId: 'haarschaum', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Haarlack', category: 'Körperpflege', canonicalId: 'haarlack', defaultUnit: 'Dose', aliases: ['Haarspray']),
    IngredientEntry(name: 'Haarlack (extra stark)', category: 'Körperpflege', canonicalId: 'haarlack_stark', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Haarfarbe', category: 'Körperpflege', canonicalId: 'haarfarbe', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Haarfarbe (Aufheller)', category: 'Körperpflege', canonicalId: 'haarfarbe_aufheller', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Haarfarbe (Tönung)', category: 'Körperpflege', canonicalId: 'haartoening', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Henna (Haare)', category: 'Körperpflege', canonicalId: 'henna_haar', defaultUnit: 'g'),
    IngredientEntry(name: 'Haarbürste', category: 'Körperpflege', canonicalId: 'haarbuerste', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kamm', category: 'Körperpflege', canonicalId: 'kamm', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Entwirrbürste', category: 'Körperpflege', canonicalId: 'entwirrbueste', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Haarnadeln', category: 'Körperpflege', canonicalId: 'haarnadeln', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Haargummis', category: 'Körperpflege', canonicalId: 'haargummis', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Haarspangen', category: 'Körperpflege', canonicalId: 'haarspangen', defaultUnit: 'Packung'),

    // ── KÖRPERPFLEGE & DUSCHEN ───────────────────────────
    IngredientEntry(name: 'Duschgel', category: 'Körperpflege', canonicalId: 'duschgel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Duschgel (für Männer)', category: 'Körperpflege', canonicalId: 'duschgel_men', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Duschgel (Sensitive)', category: 'Körperpflege', canonicalId: 'duschgel_sensitiv', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Duschgel (Erfrischend)', category: 'Körperpflege', canonicalId: 'duschgel_frisch', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Duschgel (Kinder)', category: 'Körperpflege', canonicalId: 'duschgel_kinder', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Badeöl', category: 'Körperpflege', canonicalId: 'badeoel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Badeschaum', category: 'Körperpflege', canonicalId: 'badeschaum', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Badezusatz (Badesalz)', category: 'Körperpflege', canonicalId: 'badesalz', defaultUnit: 'g'),
    IngredientEntry(name: 'Badebombe', category: 'Körperpflege', canonicalId: 'badebombe', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Seife (fest)', category: 'Körperpflege', canonicalId: 'seife', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Seife (flüssig)', category: 'Körperpflege', canonicalId: 'seife_fluessig', defaultUnit: 'Flasche', aliases: ['Flüssigseife']),
    IngredientEntry(name: 'Handseife (antibakteriell)', category: 'Körperpflege', canonicalId: 'handseife_antibak', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Seifenspender', category: 'Körperpflege', canonicalId: 'seifenspender', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Peeling-Duschgel', category: 'Körperpflege', canonicalId: 'peeling_duschgel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Körperpeeling', category: 'Körperpflege', canonicalId: 'koerperpeeling', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Badeschwamm', category: 'Körperpflege', canonicalId: 'badeschwamm', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Luffaschwamm', category: 'Körperpflege', canonicalId: 'luffaschwamm', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Waschlappen', category: 'Körperpflege', canonicalId: 'waschlappen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Körperschwamm (Netz)', category: 'Körperpflege', canonicalId: 'netzschwamm', defaultUnit: 'Stück'),

    // ── KÖRPER- & HAUTPFLEGE ─────────────────────────────
    IngredientEntry(name: 'Körpercreme', category: 'Körperpflege', canonicalId: 'koerpercreme', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Körpercreme (Feuchtigkeit)', category: 'Körperpflege', canonicalId: 'koerpercreme_feuchtig', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Körperlotion', category: 'Körperpflege', canonicalId: 'koerperlotion', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Körperbutter', category: 'Körperpflege', canonicalId: 'koerperbutter', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Körperbutter (Shea)', category: 'Körperpflege', canonicalId: 'shea_butter', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Körperöl', category: 'Körperpflege', canonicalId: 'koerperoel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Handcreme', category: 'Körperpflege', canonicalId: 'handcreme', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Handcreme (intensiv)', category: 'Körperpflege', canonicalId: 'handcreme_intensiv', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Handlotion', category: 'Körperpflege', canonicalId: 'handlotion', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Nagelpflegeöl', category: 'Körperpflege', canonicalId: 'nagelpflegeoel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Nagellack', category: 'Körperpflege', canonicalId: 'nagellack', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Nagellackentferner', category: 'Körperpflege', canonicalId: 'nagellackentferner', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Nagelpflege (Set)', category: 'Körperpflege', canonicalId: 'nagelpflege_set', defaultUnit: 'Set'),
    IngredientEntry(name: 'Fußcreme', category: 'Körperpflege', canonicalId: 'fusscreme', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Fußcreme (Hornhaut)', category: 'Körperpflege', canonicalId: 'fusscreme_hornhaut', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Fußbad', category: 'Körperpflege', canonicalId: 'fussbad', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Lippenpflege', category: 'Körperpflege', canonicalId: 'lippenpflege', defaultUnit: 'Stück', aliases: ['Lippenbalsam', 'Chapstick']),
    IngredientEntry(name: 'Lippenpflege (UV-Schutz)', category: 'Körperpflege', canonicalId: 'lippenpflege_uv', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Gesichtscreme', category: 'Körperpflege', canonicalId: 'gesichtscreme', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Gesichtscreme (Tag)', category: 'Körperpflege', canonicalId: 'gesichtscreme_tag', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Gesichtscreme (Nacht)', category: 'Körperpflege', canonicalId: 'gesichtscreme_nacht', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Gesichtsserum', category: 'Körperpflege', canonicalId: 'gesichtsserum', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Augencreme', category: 'Körperpflege', canonicalId: 'augencreme', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Gesichtsmaske', category: 'Körperpflege', canonicalId: 'gesichtsmaske', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Gesichtspeeling', category: 'Körperpflege', canonicalId: 'gesichtspeeling', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Gesichtswasser (Toner)', category: 'Körperpflege', canonicalId: 'gesichtswasser', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Mizellenwasser', category: 'Körperpflege', canonicalId: 'mizellenwasser', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Make-up-Entferner', category: 'Körperpflege', canonicalId: 'makeup_entferner', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Sonnencreme (LSF 30)', category: 'Körperpflege', canonicalId: 'sonnencreme_30', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Sonnencreme (LSF 50)', category: 'Körperpflege', canonicalId: 'sonnencreme_50', defaultUnit: 'Tube'),
    IngredientEntry(name: 'After-Sun-Lotion', category: 'Körperpflege', canonicalId: 'after_sun', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Selbstbräuner', category: 'Körperpflege', canonicalId: 'selbstbraeuner', defaultUnit: 'Flasche'),

    // ── DAMENHEIGIENE ─────────────────────────────────────
    IngredientEntry(name: 'Damenbinden', category: 'Körperpflege', canonicalId: 'damenbinden', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Damenbinden (extra dünn)', category: 'Körperpflege', canonicalId: 'damenbinden_duenn', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Slipeinlagen', category: 'Körperpflege', canonicalId: 'slipeinlagen', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Tampons (regular)', category: 'Körperpflege', canonicalId: 'tampons_regular', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Tampons (super)', category: 'Körperpflege', canonicalId: 'tampons_super', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Menstruationstasse', category: 'Körperpflege', canonicalId: 'menstruationstasse', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Intimwaschlösung', category: 'Körperpflege', canonicalId: 'intimwaschloesung', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Intimspray', category: 'Körperpflege', canonicalId: 'intimspray', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Intimdeodorant', category: 'Körperpflege', canonicalId: 'intimdeodrant', defaultUnit: 'Flasche'),

    // ── DEOS & PARFUM ─────────────────────────────────────
    IngredientEntry(name: 'Deo (Spray)', category: 'Körperpflege', canonicalId: 'deo', defaultUnit: 'Dose', aliases: ['Deodorant']),
    IngredientEntry(name: 'Deo (Roll-On)', category: 'Körperpflege', canonicalId: 'deo_rollon', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Deo (Stick)', category: 'Körperpflege', canonicalId: 'deo_stick', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Deo (Creme)', category: 'Körperpflege', canonicalId: 'deo_creme', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Deo (für Männer)', category: 'Körperpflege', canonicalId: 'deo_men', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Deo (48h)', category: 'Körperpflege', canonicalId: 'deo_48h', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Antiperspirant', category: 'Körperpflege', canonicalId: 'antiperspirant', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Bodyspray', category: 'Körperpflege', canonicalId: 'bodyspray', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Eau de Toilette', category: 'Körperpflege', canonicalId: 'eau_toilette', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Parfum (Damen)', category: 'Körperpflege', canonicalId: 'parfum_damen', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Parfum (Herren)', category: 'Körperpflege', canonicalId: 'parfum_herren', defaultUnit: 'Flasche'),

    // ── RASUR & ENTHAARUNG ────────────────────────────────
    IngredientEntry(name: 'Rasierschaum', category: 'Körperpflege', canonicalId: 'rasierschaum', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Rasiergel', category: 'Körperpflege', canonicalId: 'rasiergel', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Rasieröl', category: 'Körperpflege', canonicalId: 'rasieroel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Rasierer (Einweg)', category: 'Körperpflege', canonicalId: 'rasierer', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rasierklingen (Ersatz)', category: 'Körperpflege', canonicalId: 'rasierklingen', defaultUnit: 'Packung'),
    IngredientEntry(name: 'After Shave (Lotion)', category: 'Körperpflege', canonicalId: 'aftershave', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'After Shave (Balsam)', category: 'Körperpflege', canonicalId: 'aftershave_balsam', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Enthaarungscreme', category: 'Körperpflege', canonicalId: 'enthaarungscreme', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Enthaarungsstreifen', category: 'Körperpflege', canonicalId: 'enthaarungsstreifen', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Epilator-Aufsatz', category: 'Körperpflege', canonicalId: 'epilator_aufsatz', defaultUnit: 'Stück'),

    // ── WATTEPFLEGE & HYGIENE-UTENSILIEN ─────────────────
    IngredientEntry(name: 'Wattepads', category: 'Körperpflege', canonicalId: 'wattepads', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Wattepads (Bio)', category: 'Körperpflege', canonicalId: 'wattepads_bio', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Wattestäbchen', category: 'Körperpflege', canonicalId: 'wattestabchen', defaultUnit: 'Packung', aliases: ['Q-Tips']),
    IngredientEntry(name: 'Wattebaeusche', category: 'Körperpflege', canonicalId: 'wattebausch', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Feuchttücher (Babywipes)', category: 'Körperpflege', canonicalId: 'babywipes', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Feuchttücher (Make-Up)', category: 'Körperpflege', canonicalId: 'feuchttuecher_makeup', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Feuchttücher (Allgemein)', category: 'Körperpflege', canonicalId: 'feuchttuecher', defaultUnit: 'Packung'),

    // ── ERSTE HILFE & APOTHEKE ────────────────────────────
    IngredientEntry(name: 'Pflaster', category: 'Haushalt', canonicalId: 'pflaster', defaultUnit: 'Packung', aliases: ['Band-Aid', 'Wundpflaster']),
    IngredientEntry(name: 'Pflaster (wasserfest)', category: 'Haushalt', canonicalId: 'pflaster_wasserfest', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Pflaster (Kinder)', category: 'Haushalt', canonicalId: 'pflaster_kinder', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Wundauflage', category: 'Haushalt', canonicalId: 'wundauflage', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Verbandwatte', category: 'Haushalt', canonicalId: 'verbandwatte', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Mullbinde', category: 'Haushalt', canonicalId: 'mullbinde', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Wunddesinfektionsmittel', category: 'Haushalt', canonicalId: 'wunddesinfektion', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Aspirin', category: 'Haushalt', canonicalId: 'aspirin', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Ibuprofen', category: 'Haushalt', canonicalId: 'ibuprofen', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Paracetamol', category: 'Haushalt', canonicalId: 'paracetamol', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Hustensaft', category: 'Haushalt', canonicalId: 'hustensaft', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Nasenspray', category: 'Haushalt', canonicalId: 'nasenspray', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Nasenspülung', category: 'Haushalt', canonicalId: 'nasenspuelung', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Fieberthermometer', category: 'Haushalt', canonicalId: 'fieberthermometer', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Blutdruckmessgerät', category: 'Haushalt', canonicalId: 'blutdruckmesser', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tabletten (Mehrzweck)', category: 'Haushalt', canonicalId: 'tabletten_allg', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Augentropfen', category: 'Haushalt', canonicalId: 'augentropfen', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Ohrentropfen', category: 'Haushalt', canonicalId: 'ohrentropfen', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Sonnenbrillentuch', category: 'Haushalt', canonicalId: 'brillentuch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kondome', category: 'Körperpflege', canonicalId: 'kondome', defaultUnit: 'Packung'),

    // ── WINDELN & BABYCARE ────────────────────────────────
    IngredientEntry(name: 'Windeln (Größe 1)', category: 'Baby & Kind', canonicalId: 'windeln_1', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Windeln (Größe 2)', category: 'Baby & Kind', canonicalId: 'windeln_2', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Windeln (Größe 3)', category: 'Baby & Kind', canonicalId: 'windeln_3', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Windeln (Größe 4)', category: 'Baby & Kind', canonicalId: 'windeln_4', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Windeln (Größe 5)', category: 'Baby & Kind', canonicalId: 'windeln_5', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Windeln (Größe 6)', category: 'Baby & Kind', canonicalId: 'windeln_6', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Windelhosen (Pull-up)', category: 'Baby & Kind', canonicalId: 'windelhosen', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Feuchttücher (Baby)', category: 'Baby & Kind', canonicalId: 'feuchttuecher_baby', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Babycreme (Wundschutz)', category: 'Baby & Kind', canonicalId: 'baby_wundschutz', defaultUnit: 'Tube'),
    IngredientEntry(name: 'Babyöl', category: 'Baby & Kind', canonicalId: 'babyoel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Babyshampoo', category: 'Baby & Kind', canonicalId: 'babyshampoo', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Baby-Duschgel', category: 'Baby & Kind', canonicalId: 'baby_duschgel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Babypuder', category: 'Baby & Kind', canonicalId: 'babypuder', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Schnuller', category: 'Baby & Kind', canonicalId: 'schnuller', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Stillpads', category: 'Baby & Kind', canonicalId: 'stillpads', defaultUnit: 'Packung'),

    // ──────────────────────────────────────────────────────
    // FLEISCH & GEFLÜGEL ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Entenbrust', category: 'Fleisch & Fisch', canonicalId: 'enten_brust', defaultUnit: 'g'),
    IngredientEntry(name: 'Entenkeule', category: 'Fleisch & Fisch', canonicalId: 'enten_keule', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Gänsebraten', category: 'Fleisch & Fisch', canonicalId: 'gaense_braten', defaultUnit: 'g'),
    IngredientEntry(name: 'Truthahn', category: 'Fleisch & Fisch', canonicalId: 'truthahn', defaultUnit: 'g', aliases: ['Pute (ganz)']),
    IngredientEntry(name: 'Lammkeule', category: 'Fleisch & Fisch', canonicalId: 'lamm_keule', defaultUnit: 'g'),
    IngredientEntry(name: 'Lammkotelett', category: 'Fleisch & Fisch', canonicalId: 'lamm_kotlett', defaultUnit: 'g'),
    IngredientEntry(name: 'Lammhack', category: 'Fleisch & Fisch', canonicalId: 'lamm_hack', defaultUnit: 'g'),
    IngredientEntry(name: 'Kalbsschnitzel', category: 'Fleisch & Fisch', canonicalId: 'kalb_schnitzel', defaultUnit: 'g'),
    IngredientEntry(name: 'Kalbsfilet', category: 'Fleisch & Fisch', canonicalId: 'kalb_filet', defaultUnit: 'g'),
    IngredientEntry(name: 'Kalbsleber', category: 'Fleisch & Fisch', canonicalId: 'kalb_leber', defaultUnit: 'g'),
    IngredientEntry(name: 'Rinderleber', category: 'Fleisch & Fisch', canonicalId: 'rind_leber', defaultUnit: 'g'),
    IngredientEntry(name: 'Rinderknochen', category: 'Fleisch & Fisch', canonicalId: 'rind_knochen', defaultUnit: 'g'),
    IngredientEntry(name: 'Ochsenschwanz', category: 'Fleisch & Fisch', canonicalId: 'ochsenschwanz', defaultUnit: 'g'),
    IngredientEntry(name: 'Knochen (Hähnchen)', category: 'Fleisch & Fisch', canonicalId: 'haehnchen_knochen', defaultUnit: 'g'),
    IngredientEntry(name: 'Hähnchen-Flügel', category: 'Fleisch & Fisch', canonicalId: 'haehnchen_fluegel', defaultUnit: 'Stück', aliases: ['Wings', 'Chicken Wings']),
    IngredientEntry(name: 'Schweinsbauch (Scheiben)', category: 'Fleisch & Fisch', canonicalId: 'schwein_bauch_scheibe', defaultUnit: 'g'),
    IngredientEntry(name: 'Schweinekotelett', category: 'Fleisch & Fisch', canonicalId: 'schwein_kotlett', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rinderrippen', category: 'Fleisch & Fisch', canonicalId: 'rind_rippen', defaultUnit: 'g', aliases: ['Beef Ribs']),
    IngredientEntry(name: 'Spareribs', category: 'Fleisch & Fisch', canonicalId: 'spareribs', defaultUnit: 'g'),
    IngredientEntry(name: 'Bison-Hack', category: 'Fleisch & Fisch', canonicalId: 'bison_hack', defaultUnit: 'g'),
    IngredientEntry(name: 'Wildschweinkeule', category: 'Fleisch & Fisch', canonicalId: 'wild_schwein', defaultUnit: 'g'),
    IngredientEntry(name: 'Rehkeule', category: 'Fleisch & Fisch', canonicalId: 'reh_keule', defaultUnit: 'g'),
    IngredientEntry(name: 'Hirschgulasch', category: 'Fleisch & Fisch', canonicalId: 'hirsch_gulasch', defaultUnit: 'g'),
    IngredientEntry(name: 'Hasenkeule', category: 'Fleisch & Fisch', canonicalId: 'hase_keule', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Taubenbrust', category: 'Fleisch & Fisch', canonicalId: 'taube_brust', defaultUnit: 'Stück'),

    // ──────────────────────────────────────────────────────
    // FISCH ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Dorade', category: 'Fleisch & Fisch', canonicalId: 'dorade', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Wolfsbarsch', category: 'Fleisch & Fisch', canonicalId: 'wolfsbarsch', defaultUnit: 'Stück', aliases: ['Branzino', 'Bar']),
    IngredientEntry(name: 'Rotbarsch', category: 'Fleisch & Fisch', canonicalId: 'rotbarsch', defaultUnit: 'g'),
    IngredientEntry(name: 'Scholle', category: 'Fleisch & Fisch', canonicalId: 'scholle', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Seelachs', category: 'Fleisch & Fisch', canonicalId: 'seelachs', defaultUnit: 'g'),
    IngredientEntry(name: 'Pangasius', category: 'Fleisch & Fisch', canonicalId: 'pangasius', defaultUnit: 'g'),
    IngredientEntry(name: 'Tilapia', category: 'Fleisch & Fisch', canonicalId: 'tilapia', defaultUnit: 'g'),
    IngredientEntry(name: 'Zander', category: 'Fleisch & Fisch', canonicalId: 'zander', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Hecht', category: 'Fleisch & Fisch', canonicalId: 'hecht', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Karpfen', category: 'Fleisch & Fisch', canonicalId: 'karpfen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Hering (frisch)', category: 'Fleisch & Fisch', canonicalId: 'hering_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Hering (Matjes)', category: 'Fleisch & Fisch', canonicalId: 'hering_matjes', defaultUnit: 'g'),
    IngredientEntry(name: 'Hering (Bismarck)', category: 'Fleisch & Fisch', canonicalId: 'hering_bismarck', defaultUnit: 'g'),
    IngredientEntry(name: 'Räucherlachs', category: 'Fleisch & Fisch', canonicalId: 'lachs_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Räuchermakrele', category: 'Fleisch & Fisch', canonicalId: 'makrele_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Räucherforelle', category: 'Fleisch & Fisch', canonicalId: 'forelle_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Tintenfisch', category: 'Fleisch & Fisch', canonicalId: 'tintenfisch', defaultUnit: 'g', aliases: ['Kalmar', 'Squid']),
    IngredientEntry(name: 'Oktopus', category: 'Fleisch & Fisch', canonicalId: 'oktopus', defaultUnit: 'g'),
    IngredientEntry(name: 'Muscheln', category: 'Fleisch & Fisch', canonicalId: 'muscheln', defaultUnit: 'g', aliases: ['Miesmuscheln']),
    IngredientEntry(name: 'Jakobsmuscheln', category: 'Fleisch & Fisch', canonicalId: 'jakobsmuscheln', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Austern', category: 'Fleisch & Fisch', canonicalId: 'austern', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Hummer', category: 'Fleisch & Fisch', canonicalId: 'hummer', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Languste', category: 'Fleisch & Fisch', canonicalId: 'languste', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Krabben', category: 'Fleisch & Fisch', canonicalId: 'krabben', defaultUnit: 'g', aliases: ['Nordseekrabben']),
    IngredientEntry(name: 'Kaviar', category: 'Fleisch & Fisch', canonicalId: 'kaviar', defaultUnit: 'g'),
    IngredientEntry(name: 'Anchovis', category: 'Fleisch & Fisch', canonicalId: 'anchovis', defaultUnit: 'g', aliases: ['Sardellen']),

    // ──────────────────────────────────────────────────────
    // PFLANZLICHE PROTEINQUELLEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Seitan', category: 'Pflanzliche Proteine', canonicalId: 'seitan', defaultUnit: 'g'),
    IngredientEntry(name: 'Jackfrucht (Dose)', category: 'Pflanzliche Proteine', canonicalId: 'jackfrucht_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Lupinenschrot', category: 'Pflanzliche Proteine', canonicalId: 'lupinenschrot', defaultUnit: 'g'),
    IngredientEntry(name: 'Erbsenprotein', category: 'Pflanzliche Proteine', canonicalId: 'erbsenprotein', defaultUnit: 'g'),
    IngredientEntry(name: 'Hanfprotein', category: 'Pflanzliche Proteine', canonicalId: 'hanfprotein', defaultUnit: 'g'),
    IngredientEntry(name: 'Natto', category: 'Pflanzliche Proteine', canonicalId: 'natto', defaultUnit: 'g'),
    IngredientEntry(name: 'Quorn', category: 'Pflanzliche Proteine', canonicalId: 'quorn', defaultUnit: 'g'),
    IngredientEntry(name: 'Beyond Meat', category: 'Pflanzliche Proteine', canonicalId: 'beyond_meat', defaultUnit: 'g'),
    IngredientEntry(name: 'Vegane Bratwurst', category: 'Pflanzliche Proteine', canonicalId: 'vegan_bratwurst', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Veganer Aufschnitt', category: 'Pflanzliche Proteine', canonicalId: 'vegan_aufschnitt', defaultUnit: 'g'),
    IngredientEntry(name: 'Veganer Käse', category: 'Pflanzliche Proteine', canonicalId: 'vegan_kaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Cashew-Käse', category: 'Pflanzliche Proteine', canonicalId: 'cashew_kaese', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // KÄSE NOCHMALS ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Bergkäse', category: 'Milchprodukte', canonicalId: 'bergkaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Tilsiter', category: 'Milchprodukte', canonicalId: 'tilsiter', defaultUnit: 'g'),
    IngredientEntry(name: 'Butterkäse', category: 'Milchprodukte', canonicalId: 'butterkaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Räucherkäse', category: 'Milchprodukte', canonicalId: 'raeucherkaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Weichkäse', category: 'Milchprodukte', canonicalId: 'weichkaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Manchego', category: 'Milchprodukte', canonicalId: 'manchego', defaultUnit: 'g'),
    IngredientEntry(name: 'Taleggio', category: 'Milchprodukte', canonicalId: 'taleggio', defaultUnit: 'g'),
    IngredientEntry(name: 'Provolone', category: 'Milchprodukte', canonicalId: 'provolone', defaultUnit: 'g'),
    IngredientEntry(name: 'Asiago', category: 'Milchprodukte', canonicalId: 'asiago', defaultUnit: 'g'),
    IngredientEntry(name: 'Ricotta Salata', category: 'Milchprodukte', canonicalId: 'ricotta_salata', defaultUnit: 'g'),
    IngredientEntry(name: 'Scamorza', category: 'Milchprodukte', canonicalId: 'scamorza', defaultUnit: 'g'),
    IngredientEntry(name: 'Streichkäse', category: 'Milchprodukte', canonicalId: 'streichkaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Milchschnitte', category: 'Milchprodukte', canonicalId: 'milchschnitte', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kefir', category: 'Milchprodukte', canonicalId: 'kefir', defaultUnit: 'ml'),
    IngredientEntry(name: 'Buttermilch', category: 'Milchprodukte', canonicalId: 'buttermilch', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kokosjogurt', category: 'Milchprodukte', canonicalId: 'kokos_jogurt', defaultUnit: 'g'),
    IngredientEntry(name: 'Sojajoghurt', category: 'Milchprodukte', canonicalId: 'soja_jogurt', defaultUnit: 'g'),
    IngredientEntry(name: 'Mandeljoghurt', category: 'Milchprodukte', canonicalId: 'mandel_jogurt', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // BACKWAREN & TEIGPRODUKTE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Croissant', category: 'Brot & Backwaren', canonicalId: 'croissant', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Bagel', category: 'Brot & Backwaren', canonicalId: 'bagel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Ciabatta', category: 'Brot & Backwaren', canonicalId: 'ciabatta', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Focaccia', category: 'Brot & Backwaren', canonicalId: 'focaccia', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Pumpernickel', category: 'Brot & Backwaren', canonicalId: 'pumpernickel', defaultUnit: 'Scheibe'),
    IngredientEntry(name: 'Knäckebrot', category: 'Brot & Backwaren', canonicalId: 'knaeckebrot', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Reiswaffeln', category: 'Brot & Backwaren', canonicalId: 'reiswaffeln', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Maiscracker', category: 'Brot & Backwaren', canonicalId: 'maiscracker', defaultUnit: 'g'),
    IngredientEntry(name: 'Dinkelbrötchen', category: 'Brot & Backwaren', canonicalId: 'dinkelbroetchen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Vollkorntoast', category: 'Brot & Backwaren', canonicalId: 'vollkorntoast', defaultUnit: 'Scheibe'),
    IngredientEntry(name: 'Waffeln (frisch)', category: 'Brot & Backwaren', canonicalId: 'waffeln_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Blinis', category: 'Brot & Backwaren', canonicalId: 'blinis', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Muffins', category: 'Brot & Backwaren', canonicalId: 'muffins', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Brioche', category: 'Brot & Backwaren', canonicalId: 'brioche', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Laugengebäck', category: 'Brot & Backwaren', canonicalId: 'laugengebaeck', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Dinkelkracker', category: 'Brot & Backwaren', canonicalId: 'dinkelkracker', defaultUnit: 'g'),
    IngredientEntry(name: 'Gnocchi (frisch)', category: 'Nudeln & Getreide', canonicalId: 'gnocchi_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Gnocchi (TK)', category: 'Tiefkühl', canonicalId: 'gnocchi_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Schupfnudeln', category: 'Nudeln & Getreide', canonicalId: 'schupfnudeln', defaultUnit: 'g'),
    IngredientEntry(name: 'Maultaschen (frisch)', category: 'Nudeln & Getreide', canonicalId: 'maultaschen_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Ravioli (frisch)', category: 'Nudeln & Getreide', canonicalId: 'ravioli_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Ravioli (Dose)', category: 'Konserven', canonicalId: 'ravioli_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Spätzle (frisch)', category: 'Nudeln & Getreide', canonicalId: 'spaetzle_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Spätzle (TK)', category: 'Tiefkühl', canonicalId: 'spaetzle_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Buchweizen', category: 'Nudeln & Getreide', canonicalId: 'buchweizen', defaultUnit: 'g'),
    IngredientEntry(name: 'Hirse', category: 'Nudeln & Getreide', canonicalId: 'hirse', defaultUnit: 'g'),
    IngredientEntry(name: 'Amaranth', category: 'Nudeln & Getreide', canonicalId: 'amaranth', defaultUnit: 'g'),
    IngredientEntry(name: 'Teff', category: 'Nudeln & Getreide', canonicalId: 'teff', defaultUnit: 'g'),
    IngredientEntry(name: 'Dinkel (Körner)', category: 'Nudeln & Getreide', canonicalId: 'dinkel_koerner', defaultUnit: 'g'),
    IngredientEntry(name: 'Roggen (Körner)', category: 'Nudeln & Getreide', canonicalId: 'roggen_koerner', defaultUnit: 'g'),
    IngredientEntry(name: 'Gerste (Körner)', category: 'Nudeln & Getreide', canonicalId: 'gerste_koerner', defaultUnit: 'g'),
    IngredientEntry(name: 'Graupen', category: 'Nudeln & Getreide', canonicalId: 'graupen', defaultUnit: 'g'),
    IngredientEntry(name: 'Weizengrieß', category: 'Nudeln & Getreide', canonicalId: 'grieß', defaultUnit: 'g', aliases: ['Grieß', 'Semolina']),
    IngredientEntry(name: 'Maisgrieß', category: 'Nudeln & Getreide', canonicalId: 'maisgrieß', defaultUnit: 'g'),
    IngredientEntry(name: 'Tortellini (frisch)', category: 'Nudeln & Getreide', canonicalId: 'tortellini_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Tortellini (TK)', category: 'Tiefkühl', canonicalId: 'tortellini_tk', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // SÜSSWAREN & SNACKS
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Gummibärchen', category: 'Süßwaren & Snacks', canonicalId: 'gummibaerchen', defaultUnit: 'g'),
    IngredientEntry(name: 'Schokoladenriegel', category: 'Süßwaren & Snacks', canonicalId: 'schoko_riegel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kekse', category: 'Süßwaren & Snacks', canonicalId: 'kekse', defaultUnit: 'g', aliases: ['Plätzchen', 'Cookies']),
    IngredientEntry(name: 'Butterkekse', category: 'Süßwaren & Snacks', canonicalId: 'butterkekse', defaultUnit: 'g'),
    IngredientEntry(name: 'Salzstangen', category: 'Süßwaren & Snacks', canonicalId: 'salzstangen', defaultUnit: 'g'),
    IngredientEntry(name: 'Chips (Paprika)', category: 'Süßwaren & Snacks', canonicalId: 'chips_paprika', defaultUnit: 'g'),
    IngredientEntry(name: 'Chips (Salz)', category: 'Süßwaren & Snacks', canonicalId: 'chips_salz', defaultUnit: 'g'),
    IngredientEntry(name: 'Tortilla-Chips', category: 'Süßwaren & Snacks', canonicalId: 'tortilla_chips', defaultUnit: 'g'),
    IngredientEntry(name: 'Popcorn (fertig)', category: 'Süßwaren & Snacks', canonicalId: 'popcorn_fertig', defaultUnit: 'g'),
    IngredientEntry(name: 'Puffreis', category: 'Süßwaren & Snacks', canonicalId: 'puffreis', defaultUnit: 'g'),
    IngredientEntry(name: 'Müsliriegel', category: 'Süßwaren & Snacks', canonicalId: 'muesli_riegel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Nussriegel', category: 'Süßwaren & Snacks', canonicalId: 'nuss_riegel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Studentenfutter', category: 'Süßwaren & Snacks', canonicalId: 'studentenfutter', defaultUnit: 'g'),
    IngredientEntry(name: 'Lakritze', category: 'Süßwaren & Snacks', canonicalId: 'lakritze', defaultUnit: 'g'),
    IngredientEntry(name: 'Bonbons', category: 'Süßwaren & Snacks', canonicalId: 'bonbons', defaultUnit: 'g'),
    IngredientEntry(name: 'Kaugummi', category: 'Süßwaren & Snacks', canonicalId: 'kaugummi', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Waffeln (TK)', category: 'Tiefkühl', canonicalId: 'waffeln_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Speiseeis (Schoko)', category: 'Tiefkühl', canonicalId: 'eis_schoko', defaultUnit: 'g'),
    IngredientEntry(name: 'Speiseeis (Erdbeer)', category: 'Tiefkühl', canonicalId: 'eis_erdbeer', defaultUnit: 'g'),
    IngredientEntry(name: 'Eis am Stiel', category: 'Tiefkühl', canonicalId: 'eis_stiel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Sorbet (Zitrone)', category: 'Tiefkühl', canonicalId: 'sorbet_zitrone', defaultUnit: 'g'),
    IngredientEntry(name: 'Crêpes (TK)', category: 'Tiefkühl', canonicalId: 'crepes_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Lebkuchen', category: 'Süßwaren & Snacks', canonicalId: 'lebkuchen', defaultUnit: 'g'),
    IngredientEntry(name: 'Spekulatius', category: 'Süßwaren & Snacks', canonicalId: 'spekulatius', defaultUnit: 'g'),
    IngredientEntry(name: 'Löffelbiskuits', category: 'Süßwaren & Snacks', canonicalId: 'loeffelbiskuit', defaultUnit: 'g'),
    IngredientEntry(name: 'Keksteig (fertig)', category: 'Backen', canonicalId: 'keksteig_fertig', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Waffelteig (fertig)', category: 'Backen', canonicalId: 'waffelteig_fertig', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Pfannkuchenteig (fertig)', category: 'Backen', canonicalId: 'pfannkuchen_teig', defaultUnit: 'Packung'),

    // ──────────────────────────────────────────────────────
    // WURSTWAREN & AUFSCHNITT ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Blutwurst', category: 'Wurst & Aufschnitt', canonicalId: 'blutwurst', defaultUnit: 'g'),
    IngredientEntry(name: 'Weißwurst', category: 'Wurst & Aufschnitt', canonicalId: 'weisswurst', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Currywurst', category: 'Wurst & Aufschnitt', canonicalId: 'currywurst', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Bockwurst', category: 'Wurst & Aufschnitt', canonicalId: 'bockwurst', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Frankfurter', category: 'Wurst & Aufschnitt', canonicalId: 'frankfurter', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Cervelatwurst', category: 'Wurst & Aufschnitt', canonicalId: 'cervelat', defaultUnit: 'g'),
    IngredientEntry(name: 'Schwarzwälder Schinken', category: 'Wurst & Aufschnitt', canonicalId: 'schwarzwaelder', defaultUnit: 'g'),
    IngredientEntry(name: 'Coppa', category: 'Wurst & Aufschnitt', canonicalId: 'coppa', defaultUnit: 'g'),
    IngredientEntry(name: 'Nduja', category: 'Wurst & Aufschnitt', canonicalId: 'nduja', defaultUnit: 'g'),
    IngredientEntry(name: 'Merguez', category: 'Wurst & Aufschnitt', canonicalId: 'merguez', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Toulouse-Würstchen', category: 'Wurst & Aufschnitt', canonicalId: 'toulouse', defaultUnit: 'Stück'),

    // ──────────────────────────────────────────────────────
    // ÖKOLANDBAU / BIO-SPEZIFISCH
    // (gleiche Produkte, aber oft gesucht mit Bio-Präfix)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Bio-Eier', category: 'Milchprodukte', canonicalId: 'bio_eier', defaultUnit: 'Stück', aliases: ['Freilandeier']),
    IngredientEntry(name: 'Bio-Hähnchen', category: 'Fleisch & Fisch', canonicalId: 'bio_haehnchen', defaultUnit: 'g', aliases: ['Freilandhuhn']),
    IngredientEntry(name: 'Bio-Milch', category: 'Milchprodukte', canonicalId: 'bio_milch', defaultUnit: 'L'),
    IngredientEntry(name: 'Bio-Butter', category: 'Milchprodukte', canonicalId: 'bio_butter', defaultUnit: 'g'),
    IngredientEntry(name: 'Bio-Gemüse-Box', category: 'Obst & Gemüse', canonicalId: 'bio_gemuese_box', defaultUnit: 'Stück'),

    // ──────────────────────────────────────────────────────
    // WEITERE KRÄUTER & GEWÜRZMISCHUNGEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Curry-Mix (scharf)', category: 'Gewürze & Soßen', canonicalId: 'curry_scharf', defaultUnit: 'TL'),
    IngredientEntry(name: 'Tikka Masala Gewürz', category: 'Gewürze & Soßen', canonicalId: 'tikka_masala', defaultUnit: 'TL'),
    IngredientEntry(name: 'Jerk-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'jerk_gewuerz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Cajun-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'cajun', defaultUnit: 'TL'),
    IngredientEntry(name: 'Fünf-Gewürze-Pulver', category: 'Gewürze & Soßen', canonicalId: 'fuenf_gewuerze', defaultUnit: 'TL', aliases: ['Five Spice']),
    IngredientEntry(name: 'Baharat', category: 'Gewürze & Soßen', canonicalId: 'baharat', defaultUnit: 'TL'),
    IngredientEntry(name: 'Chermoula', category: 'Gewürze & Soßen', canonicalId: 'chermoula', defaultUnit: 'TL'),
    IngredientEntry(name: 'Dukkah', category: 'Gewürze & Soßen', canonicalId: 'dukkah', defaultUnit: 'TL'),
    IngredientEntry(name: 'Furikake', category: 'Gewürze & Soßen', canonicalId: 'furikake', defaultUnit: 'TL'),
    IngredientEntry(name: 'Shichimi Togarashi', category: 'Gewürze & Soßen', canonicalId: 'shichimi', defaultUnit: 'TL'),
    IngredientEntry(name: 'Tonkabohne', category: 'Gewürze & Soßen', canonicalId: 'tonkabohne', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Piment', category: 'Gewürze & Soßen', canonicalId: 'piment', defaultUnit: 'TL', aliases: ['Nelkenpfeffer']),
    IngredientEntry(name: 'Wacholderbeeren', category: 'Gewürze & Soßen', canonicalId: 'wacholder', defaultUnit: 'TL'),
    IngredientEntry(name: 'Koriandersamen', category: 'Gewürze & Soßen', canonicalId: 'koriander_samen', defaultUnit: 'TL'),
    IngredientEntry(name: 'Senfsamen', category: 'Gewürze & Soßen', canonicalId: 'senfsamen', defaultUnit: 'TL'),
    IngredientEntry(name: 'Schwarzkümmel', category: 'Gewürze & Soßen', canonicalId: 'schwarzkuemmel', defaultUnit: 'TL'),
    IngredientEntry(name: 'Liebstöckelblätter', category: 'Gewürze & Soßen', canonicalId: 'liebstoeckel_blatt', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Vadouvan', category: 'Gewürze & Soßen', canonicalId: 'vadouvan', defaultUnit: 'TL'),
    IngredientEntry(name: 'Mace (Muskatblüte)', category: 'Gewürze & Soßen', canonicalId: 'mace', defaultUnit: 'TL'),

    // ──────────────────────────────────────────────────────
    // WEITERES OBST & GEMÜSE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Nektarine', category: 'Obst & Gemüse', canonicalId: 'nektarine', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Stachelbeeren', category: 'Obst & Gemüse', canonicalId: 'stachelbeere', defaultUnit: 'g'),
    IngredientEntry(name: 'Johannisbeeren (rot)', category: 'Obst & Gemüse', canonicalId: 'johannisbeere_rot', defaultUnit: 'g'),
    IngredientEntry(name: 'Johannisbeeren (schwarz)', category: 'Obst & Gemüse', canonicalId: 'johannisbeere_schwarz', defaultUnit: 'g'),
    IngredientEntry(name: 'Holunderblüten', category: 'Obst & Gemüse', canonicalId: 'holunderbluete', defaultUnit: 'g'),
    IngredientEntry(name: 'Holunderbeeren', category: 'Obst & Gemüse', canonicalId: 'holunderbeere', defaultUnit: 'g'),
    IngredientEntry(name: 'Aronia-Beeren', category: 'Obst & Gemüse', canonicalId: 'aronia', defaultUnit: 'g'),
    IngredientEntry(name: 'Cranberries (frisch)', category: 'Obst & Gemüse', canonicalId: 'cranberry_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Cranberries (getrocknet)', category: 'Nüsse & Samen', canonicalId: 'cranberry_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Kumquat', category: 'Obst & Gemüse', canonicalId: 'kumquat', defaultUnit: 'g'),
    IngredientEntry(name: 'Yuzu', category: 'Obst & Gemüse', canonicalId: 'yuzu', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Bergamotte', category: 'Obst & Gemüse', canonicalId: 'bergamotte', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tamarillo', category: 'Obst & Gemüse', canonicalId: 'tamarillo', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rhabarber', category: 'Obst & Gemüse', canonicalId: 'rhabarber', defaultUnit: 'g'),
    IngredientEntry(name: 'Quitte', category: 'Obst & Gemüse', canonicalId: 'quitte', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Brombeer', category: 'Obst & Gemüse', canonicalId: 'brombeere', defaultUnit: 'g'),
    IngredientEntry(name: 'Moltebeere', category: 'Obst & Gemüse', canonicalId: 'moltebeere', defaultUnit: 'g'),
    IngredientEntry(name: 'Kapstachelbeere', category: 'Obst & Gemüse', canonicalId: 'kapstachelbeere', defaultUnit: 'g', aliases: ['Physalis']),
    IngredientEntry(name: 'Sternfrucht', category: 'Obst & Gemüse', canonicalId: 'sternfrucht', defaultUnit: 'Stück', aliases: ['Carambola']),
    IngredientEntry(name: 'Artischocke (frisch)', category: 'Obst & Gemüse', canonicalId: 'artischocke_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chicorée', category: 'Obst & Gemüse', canonicalId: 'chicoree', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Radicchio', category: 'Obst & Gemüse', canonicalId: 'radicchio', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Endivien', category: 'Obst & Gemüse', canonicalId: 'endivie', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Löwenzahn', category: 'Obst & Gemüse', canonicalId: 'loewenzahn', defaultUnit: 'g'),
    IngredientEntry(name: 'Bärlauch', category: 'Obst & Gemüse', canonicalId: 'baerlauch', defaultUnit: 'g'),
    IngredientEntry(name: 'Brennnessel', category: 'Obst & Gemüse', canonicalId: 'brennnessel', defaultUnit: 'g'),
    IngredientEntry(name: 'Portulak', category: 'Obst & Gemüse', canonicalId: 'portulak', defaultUnit: 'g'),
    IngredientEntry(name: 'Kapuzinerkresse', category: 'Obst & Gemüse', canonicalId: 'kapuzinerkresse', defaultUnit: 'g'),
    IngredientEntry(name: 'Wasserkresse', category: 'Obst & Gemüse', canonicalId: 'wasserkresse', defaultUnit: 'g'),
    IngredientEntry(name: 'Babyspinat', category: 'Obst & Gemüse', canonicalId: 'babyspinat', defaultUnit: 'g'),
    IngredientEntry(name: 'Rukola (Baby)', category: 'Obst & Gemüse', canonicalId: 'rucola_baby', defaultUnit: 'g'),
    IngredientEntry(name: 'Maissalat-Mix', category: 'Obst & Gemüse', canonicalId: 'mais_salat_mix', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // MILCHERSATZ & VEGANE PRODUKTE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Reismilch', category: 'Milchprodukte', canonicalId: 'reismilch', defaultUnit: 'L'),
    IngredientEntry(name: 'Kokosnussdrink', category: 'Milchprodukte', canonicalId: 'kokosnussdrink', defaultUnit: 'L'),
    IngredientEntry(name: 'Erbsendrink', category: 'Milchprodukte', canonicalId: 'erbsendrink', defaultUnit: 'L'),
    IngredientEntry(name: 'Cashewdrink', category: 'Milchprodukte', canonicalId: 'cashewdrink', defaultUnit: 'L'),
    IngredientEntry(name: 'Dinkeldrink', category: 'Milchprodukte', canonicalId: 'dinkeldrink', defaultUnit: 'L'),
    IngredientEntry(name: 'Vegane Butter', category: 'Milchprodukte', canonicalId: 'vegan_butter', defaultUnit: 'g'),
    IngredientEntry(name: 'Vegane Sahne', category: 'Milchprodukte', canonicalId: 'vegan_sahne', defaultUnit: 'ml'),
    IngredientEntry(name: 'Veganer Quark', category: 'Milchprodukte', canonicalId: 'vegan_quark', defaultUnit: 'g'),
    IngredientEntry(name: 'Veganes Schmalz', category: 'Milchprodukte', canonicalId: 'vegan_schmalz', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // SAUCEN & DIPS ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Hollandaise', category: 'Öle & Essig', canonicalId: 'hollandaise', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bearnaise', category: 'Öle & Essig', canonicalId: 'bearnaise', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bratensauce', category: 'Öle & Essig', canonicalId: 'bratensauce', defaultUnit: 'ml'),
    IngredientEntry(name: 'Demi-glace', category: 'Öle & Essig', canonicalId: 'demi_glace', defaultUnit: 'ml'),
    IngredientEntry(name: 'Tahini-Dip', category: 'Öle & Essig', canonicalId: 'tahini_dip', defaultUnit: 'g'),
    IngredientEntry(name: 'Ajvar', category: 'Öle & Essig', canonicalId: 'ajvar', defaultUnit: 'g'),
    IngredientEntry(name: 'Baba Ghanoush', category: 'Mediterran', canonicalId: 'baba_ghanoush', defaultUnit: 'g'),
    IngredientEntry(name: 'Muhammara', category: 'Mediterran', canonicalId: 'muhammara', defaultUnit: 'g'),
    IngredientEntry(name: 'Chimichurri', category: 'Öle & Essig', canonicalId: 'chimichurri', defaultUnit: 'EL'),
    IngredientEntry(name: 'Gremolata', category: 'Öle & Essig', canonicalId: 'gremolata', defaultUnit: 'EL'),
    IngredientEntry(name: 'Tapenade', category: 'Mediterran', canonicalId: 'tapenade', defaultUnit: 'EL'),
    IngredientEntry(name: 'Romesco', category: 'Mediterran', canonicalId: 'romesco', defaultUnit: 'EL'),
    IngredientEntry(name: 'Mojo (grün)', category: 'Öle & Essig', canonicalId: 'mojo_gruen', defaultUnit: 'EL'),
    IngredientEntry(name: 'Mojo (rot)', category: 'Öle & Essig', canonicalId: 'mojo_rot', defaultUnit: 'EL'),
    IngredientEntry(name: 'Ponzu', category: 'Asiatisch', canonicalId: 'ponzu', defaultUnit: 'ml'),
    IngredientEntry(name: 'Gochujang', category: 'Asiatisch', canonicalId: 'gochujang', defaultUnit: 'EL'),
    IngredientEntry(name: 'Doenjang', category: 'Asiatisch', canonicalId: 'doenjang', defaultUnit: 'EL'),
    IngredientEntry(name: 'Doubanjiang', category: 'Asiatisch', canonicalId: 'doubanjiang', defaultUnit: 'EL'),
    IngredientEntry(name: 'XO-Sauce', category: 'Asiatisch', canonicalId: 'xo_sauce', defaultUnit: 'EL'),
    IngredientEntry(name: 'Chili-Öl', category: 'Asiatisch', canonicalId: 'chili_oel', defaultUnit: 'EL'),
    IngredientEntry(name: 'Bulgogi-Sauce', category: 'Asiatisch', canonicalId: 'bulgogi_sauce', defaultUnit: 'EL'),

    // ──────────────────────────────────────────────────────
    // GESUNDHEIT & NAHRUNGSERGÄNZUNG
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Spirulina', category: 'Gesundheit', canonicalId: 'spirulina', defaultUnit: 'g'),
    IngredientEntry(name: 'Chlorella', category: 'Gesundheit', canonicalId: 'chlorella', defaultUnit: 'g'),
    IngredientEntry(name: 'Açaí-Pulver', category: 'Gesundheit', canonicalId: 'acai', defaultUnit: 'g'),
    IngredientEntry(name: 'Matcha-Pulver', category: 'Gesundheit', canonicalId: 'matcha', defaultUnit: 'g'),
    IngredientEntry(name: 'Weizengrasputver', category: 'Gesundheit', canonicalId: 'weizengras', defaultUnit: 'g'),
    IngredientEntry(name: 'Lucuma-Pulver', category: 'Gesundheit', canonicalId: 'lucuma', defaultUnit: 'g'),
    IngredientEntry(name: 'Maca-Pulver', category: 'Gesundheit', canonicalId: 'maca', defaultUnit: 'g'),
    IngredientEntry(name: 'Ashwagandha', category: 'Gesundheit', canonicalId: 'ashwagandha', defaultUnit: 'g'),
    IngredientEntry(name: 'Kollagen-Pulver', category: 'Gesundheit', canonicalId: 'kollagen', defaultUnit: 'g'),
    IngredientEntry(name: 'Omega-3 Kapseln', category: 'Gesundheit', canonicalId: 'omega3', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Vitamin D Tropfen', category: 'Gesundheit', canonicalId: 'vit_d', defaultUnit: 'ml'),
    IngredientEntry(name: 'Apfelessig (roh)', category: 'Gesundheit', canonicalId: 'essig_apfel_roh', defaultUnit: 'EL'),
    IngredientEntry(name: 'Hanfsamen', category: 'Nüsse & Samen', canonicalId: 'hanfsamen', defaultUnit: 'g'),
    IngredientEntry(name: 'Gojibeeren', category: 'Gesundheit', canonicalId: 'gojibeere', defaultUnit: 'g'),
    IngredientEntry(name: 'Kokoswasser', category: 'Getränke', canonicalId: 'kokoswasser', defaultUnit: 'ml'),
    IngredientEntry(name: 'Aloe-Vera-Saft', category: 'Gesundheit', canonicalId: 'aloe_vera', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kombucha', category: 'Getränke', canonicalId: 'kombucha', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kefir-Wasser', category: 'Getränke', canonicalId: 'kefir_wasser', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // HAUSHALT DIVERSES (ELEKTRO, LICHT, SONSTIGES)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Bügelbrettbezug', category: 'Haushalt', canonicalId: 'buegelbrett', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Haushaltsfolie', category: 'Haushalt', canonicalId: 'haushaltsfolie', defaultUnit: 'Rolle'),
    IngredientEntry(name: 'Glühbirne', category: 'Haushalt', canonicalId: 'gluehbirne', defaultUnit: 'Stück'),
    IngredientEntry(name: 'LED-Birne', category: 'Haushalt', canonicalId: 'led_birne', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Batterien (AA)', category: 'Haushalt', canonicalId: 'batterien_aa', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Batterien (AAA)', category: 'Haushalt', canonicalId: 'batterien_aaa', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Batterien (9V)', category: 'Haushalt', canonicalId: 'batterien_9v', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Akkus (AA)', category: 'Haushalt', canonicalId: 'akkus_aa', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Kerzen', category: 'Haushalt', canonicalId: 'kerzen', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Teelichter', category: 'Haushalt', canonicalId: 'teelichter', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Stabkerzen', category: 'Haushalt', canonicalId: 'stabkerzen', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Streichhölzer', category: 'Haushalt', canonicalId: 'streichhoelzer', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Feuerzeug', category: 'Haushalt', canonicalId: 'feuerzeug', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kabelbinder', category: 'Haushalt', canonicalId: 'kabelbinder', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Klebeband', category: 'Haushalt', canonicalId: 'klebeband', defaultUnit: 'Rolle'),
    IngredientEntry(name: 'Tesa (Tesafilm)', category: 'Haushalt', canonicalId: 'tesafilm', defaultUnit: 'Rolle'),
    IngredientEntry(name: 'Schere', category: 'Haushalt', canonicalId: 'schere', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Briefumschläge', category: 'Haushalt', canonicalId: 'briefumschlaege', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Kugelschreiber', category: 'Haushalt', canonicalId: 'kugelschreiber', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Notizbuch', category: 'Haushalt', canonicalId: 'notizbuch', defaultUnit: 'Stück'),

    // ──────────────────────────────────────────────────────
    // GETRÄNKE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Limo (Zitrone)', category: 'Getränke', canonicalId: 'limo_zitrone', defaultUnit: 'L'),
    IngredientEntry(name: 'Limo (Orange)', category: 'Getränke', canonicalId: 'limo_orange', defaultUnit: 'L'),
    IngredientEntry(name: 'Cola', category: 'Getränke', canonicalId: 'cola', defaultUnit: 'L'),
    IngredientEntry(name: 'Energydrink', category: 'Getränke', canonicalId: 'energydrink', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Eistee', category: 'Getränke', canonicalId: 'eistee', defaultUnit: 'L'),
    IngredientEntry(name: 'Ginger Beer', category: 'Getränke', canonicalId: 'ginger_beer', defaultUnit: 'ml'),
    IngredientEntry(name: 'Ginger Ale', category: 'Getränke', canonicalId: 'ginger_ale', defaultUnit: 'ml'),
    IngredientEntry(name: 'Tonic Water', category: 'Getränke', canonicalId: 'tonic', defaultUnit: 'ml'),
    IngredientEntry(name: 'Club Soda', category: 'Getränke', canonicalId: 'club_soda', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bitter Lemon', category: 'Getränke', canonicalId: 'bitter_lemon', defaultUnit: 'ml'),
    IngredientEntry(name: 'Holunderblütensirup', category: 'Getränke', canonicalId: 'holunder_sirup', defaultUnit: 'ml'),
    IngredientEntry(name: 'Grenadine', category: 'Getränke', canonicalId: 'grenadine', defaultUnit: 'ml'),
    IngredientEntry(name: 'Zitronensirup', category: 'Getränke', canonicalId: 'zitronen_sirup', defaultUnit: 'ml'),
    IngredientEntry(name: 'Ingwersirup', category: 'Getränke', canonicalId: 'ingwer_sirup', defaultUnit: 'ml'),
    IngredientEntry(name: 'Vodka', category: 'Getränke', canonicalId: 'vodka', defaultUnit: 'ml'),
    IngredientEntry(name: 'Whisky', category: 'Getränke', canonicalId: 'whisky', defaultUnit: 'ml'),
    IngredientEntry(name: 'Tequila', category: 'Getränke', canonicalId: 'tequila', defaultUnit: 'ml'),
    IngredientEntry(name: 'Amaretto', category: 'Getränke', canonicalId: 'amaretto', defaultUnit: 'ml'),
    IngredientEntry(name: 'Baileys', category: 'Getränke', canonicalId: 'baileys', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kahlúa', category: 'Getränke', canonicalId: 'kahlua', defaultUnit: 'ml'),
    IngredientEntry(name: 'Triple Sec', category: 'Getränke', canonicalId: 'triple_sec', defaultUnit: 'ml', aliases: ['Cointreau']),
    IngredientEntry(name: 'Aperol', category: 'Getränke', canonicalId: 'aperol', defaultUnit: 'ml'),
    IngredientEntry(name: 'Campari', category: 'Getränke', canonicalId: 'campari', defaultUnit: 'ml'),
    IngredientEntry(name: 'Vermouth (trocken)', category: 'Getränke', canonicalId: 'vermouth_trocken', defaultUnit: 'ml'),
    IngredientEntry(name: 'Vermouth (süß)', category: 'Getränke', canonicalId: 'vermouth_suess', defaultUnit: 'ml'),
    IngredientEntry(name: 'Schaumwein', category: 'Getränke', canonicalId: 'schaumwein', defaultUnit: 'ml'),
    IngredientEntry(name: 'Rhabarbersaft', category: 'Getränke', canonicalId: 'rhabarbersaft', defaultUnit: 'ml'),
    IngredientEntry(name: 'Granatapfelsaft', category: 'Getränke', canonicalId: 'granatapfelsaft', defaultUnit: 'ml'),
    IngredientEntry(name: 'Mangosaft', category: 'Getränke', canonicalId: 'mangosaft', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // ASIA-KÜCHE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Kimchi', category: 'Asiatisch', canonicalId: 'kimchi', defaultUnit: 'g'),
    IngredientEntry(name: 'Gochugaru (Chiliflocken)', category: 'Asiatisch', canonicalId: 'gochugaru', defaultUnit: 'TL'),
    IngredientEntry(name: 'Doenjang (Sojabohnenpaste)', category: 'Asiatisch', canonicalId: 'doenjang2', defaultUnit: 'EL'),
    IngredientEntry(name: 'Sesam-Paste', category: 'Asiatisch', canonicalId: 'sesam_paste', defaultUnit: 'EL'),
    IngredientEntry(name: 'Schwarze Bohnenpaste', category: 'Asiatisch', canonicalId: 'schwarze_bohnen_paste', defaultUnit: 'EL'),
    IngredientEntry(name: 'Reismehl (Klebreis)', category: 'Asiatisch', canonicalId: 'klebreismehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Pandan-Blätter', category: 'Asiatisch', canonicalId: 'pandan', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kokosnussraspeln (ungesüßt)', category: 'Asiatisch', canonicalId: 'kokos_ungesuess', defaultUnit: 'g'),
    IngredientEntry(name: 'Reiscracker', category: 'Asiatisch', canonicalId: 'reiscracker', defaultUnit: 'g'),
    IngredientEntry(name: 'Sushi-Essig', category: 'Asiatisch', canonicalId: 'sushi_essig', defaultUnit: 'ml'),
    IngredientEntry(name: 'Dashi-Pulver', category: 'Asiatisch', canonicalId: 'dashi_pulver', defaultUnit: 'g'),
    IngredientEntry(name: 'Mentsuyu', category: 'Asiatisch', canonicalId: 'mentsuyu', defaultUnit: 'ml'),
    IngredientEntry(name: 'Schwarzer Reisessig', category: 'Asiatisch', canonicalId: 'schwarzer_reisessig', defaultUnit: 'ml'),
    IngredientEntry(name: 'Glasnudeln (Mungobohne)', category: 'Asiatisch', canonicalId: 'glasnudeln_mungo', defaultUnit: 'g'),
    IngredientEntry(name: 'Reispapier', category: 'Asiatisch', canonicalId: 'reispapier', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Frühlingsrollenteig', category: 'Asiatisch', canonicalId: 'fruehlingsrollenteig', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Gyoza-Teig', category: 'Asiatisch', canonicalId: 'gyoza_teig', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Wonton-Teig', category: 'Asiatisch', canonicalId: 'wonton_teig', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fertig-Gyoza (TK)', category: 'Tiefkühl', canonicalId: 'tk_gyoza', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fertig-Frühlingsrollen (TK)', category: 'Tiefkühl', canonicalId: 'tk_fruehlingsrollen', defaultUnit: 'Stück'),

    // ──────────────────────────────────────────────────────
    // SÜDDEUTSCHE / ÖSTERREICHISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Semmelknödel (TK)', category: 'Tiefkühl', canonicalId: 'tk_semmelknoedel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kartoffelknödel (TK)', category: 'Tiefkühl', canonicalId: 'tk_kartoffelknoedel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kaiserschmarrn-Mix', category: 'Backen', canonicalId: 'kaiserschmarrn_mix', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Strudel-Teig', category: 'Backen', canonicalId: 'strudel_teig', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Liptauer', category: 'Milchprodukte', canonicalId: 'liptauer', defaultUnit: 'g'),
    IngredientEntry(name: 'Topfen', category: 'Milchprodukte', canonicalId: 'topfen', defaultUnit: 'g', aliases: ['Quark (österr.)']),
    IngredientEntry(name: 'Grammelschmalz', category: 'Haushalt', canonicalId: 'grammelschmalz', defaultUnit: 'g'),
    IngredientEntry(name: 'Schweineschmalz', category: 'Öle & Essig', canonicalId: 'schweineschmalz', defaultUnit: 'g'),
    IngredientEntry(name: 'Gänseschmalz', category: 'Öle & Essig', canonicalId: 'gaenseschmalz', defaultUnit: 'g'),
    IngredientEntry(name: 'Bratengelee', category: 'Konserven', canonicalId: 'bratengelee', defaultUnit: 'g'),
    IngredientEntry(name: 'Senf (grobkörnig)', category: 'Konserven', canonicalId: 'senf_grob', defaultUnit: 'TL'),
    IngredientEntry(name: 'Preiselbeeren (Glas)', category: 'Konserven', canonicalId: 'preiselbeere_glas', defaultUnit: 'Glas'),

    // ──────────────────────────────────────────────────────
    // WEITERE KONSERVEN / GLÄSER
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Maronen (Dose)', category: 'Konserven', canonicalId: 'maronen_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Maronen (vakuum)', category: 'Konserven', canonicalId: 'maronen_vak', defaultUnit: 'g'),
    IngredientEntry(name: 'Kastanien (Püree)', category: 'Konserven', canonicalId: 'kastanien_puree', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Kürbispüree (Dose)', category: 'Konserven', canonicalId: 'kuerbis_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Cranberry-Sauce', category: 'Konserven', canonicalId: 'cranberry_sauce', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Apfelmus (Glas)', category: 'Konserven', canonicalId: 'apfelmus', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Pflaumenmus', category: 'Konserven', canonicalId: 'pflaumenmus', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Quittenkonfitüre', category: 'Konserven', canonicalId: 'quittenkonfiture', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Orangenmarmelade', category: 'Konserven', canonicalId: 'orangenmarmelade', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Himbeermarmelade', category: 'Konserven', canonicalId: 'himbeermarmelade', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Curd (Lemon)', category: 'Konserven', canonicalId: 'lemon_curd', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Ingwermarmelade', category: 'Konserven', canonicalId: 'ingwermarmelade', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Würzige Mangochutney', category: 'Konserven', canonicalId: 'mango_chutney', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Tamarinden-Paste', category: 'Konserven', canonicalId: 'tamarinde_paste', defaultUnit: 'g'),
    IngredientEntry(name: 'Chilisauce (süß)', category: 'Konserven', canonicalId: 'chili_sauce_suess', defaultUnit: 'ml', aliases: ['Sweet Chili']),
    IngredientEntry(name: 'Plum-Sauce', category: 'Asiatisch', canonicalId: 'plum_sauce', defaultUnit: 'ml'),
    IngredientEntry(name: 'Schwarzes Sesamöl', category: 'Öle & Essig', canonicalId: 'sesamoel_schwarz', defaultUnit: 'ml'),
    IngredientEntry(name: 'Trüffelöl', category: 'Öle & Essig', canonicalId: 'trueffeloel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Arganöl', category: 'Öle & Essig', canonicalId: 'arganoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Traubenkernöl', category: 'Öle & Essig', canonicalId: 'traubenkernoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kürbiskernöl', category: 'Öle & Essig', canonicalId: 'kuerbiskernoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Walnussöl', category: 'Öle & Essig', canonicalId: 'walnussoel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Haselnussöl', category: 'Öle & Essig', canonicalId: 'haselnussoel', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // ITALIENISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Aceto Balsamico (tradizionale)', category: 'Mediterran', canonicalId: 'balsamico_trad', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bottarga', category: 'Mediterran', canonicalId: 'bottarga', defaultUnit: 'g'),
    IngredientEntry(name: 'Nduja (calabrese)', category: 'Mediterran', canonicalId: 'nduja_cal', defaultUnit: 'g'),
    IngredientEntry(name: 'Lardo', category: 'Mediterran', canonicalId: 'lardo', defaultUnit: 'g'),
    IngredientEntry(name: 'Bresaola', category: 'Wurst & Aufschnitt', canonicalId: 'bresaola', defaultUnit: 'g'),
    IngredientEntry(name: 'Stracciatella (Käse)', category: 'Milchprodukte', canonicalId: 'stracciatella_kaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Grana Padano', category: 'Milchprodukte', canonicalId: 'grana_padano', defaultUnit: 'g'),
    IngredientEntry(name: 'Parmigiano Reggiano', category: 'Milchprodukte', canonicalId: 'parmigiano', defaultUnit: 'g'),
    IngredientEntry(name: 'Pecorino Romano', category: 'Milchprodukte', canonicalId: 'pecorino_romano', defaultUnit: 'g'),
    IngredientEntry(name: 'Caciocavallo', category: 'Milchprodukte', canonicalId: 'caciocavallo', defaultUnit: 'g'),
    IngredientEntry(name: 'Gorgonzola Dolce', category: 'Milchprodukte', canonicalId: 'gorgonzola_dolce', defaultUnit: 'g'),
    IngredientEntry(name: 'Polenta (vorgekocht)', category: 'Nudeln & Getreide', canonicalId: 'polenta_vg', defaultUnit: 'g'),
    IngredientEntry(name: 'Farro', category: 'Nudeln & Getreide', canonicalId: 'farro', defaultUnit: 'g', aliases: ['Emmer']),
    IngredientEntry(name: 'Orzo', category: 'Nudeln & Getreide', canonicalId: 'orzo', defaultUnit: 'g', aliases: ['Risoni']),
    IngredientEntry(name: 'Ditali', category: 'Nudeln & Getreide', canonicalId: 'ditali', defaultUnit: 'g'),
    IngredientEntry(name: 'Orecchiette', category: 'Nudeln & Getreide', canonicalId: 'orecchiette', defaultUnit: 'g'),
    IngredientEntry(name: 'Bucatini', category: 'Nudeln & Getreide', canonicalId: 'bucatini', defaultUnit: 'g'),
    IngredientEntry(name: 'Pappardelle', category: 'Nudeln & Getreide', canonicalId: 'pappardelle', defaultUnit: 'g'),
    IngredientEntry(name: 'Capellini', category: 'Nudeln & Getreide', canonicalId: 'capellini', defaultUnit: 'g', aliases: ['Engelshaar']),
    IngredientEntry(name: 'Conchiglie', category: 'Nudeln & Getreide', canonicalId: 'conchiglie', defaultUnit: 'g'),
    IngredientEntry(name: 'Casarecce', category: 'Nudeln & Getreide', canonicalId: 'casarecce', defaultUnit: 'g'),
    IngredientEntry(name: 'Trofie', category: 'Nudeln & Getreide', canonicalId: 'trofie', defaultUnit: 'g'),
    IngredientEntry(name: 'Paccheri', category: 'Nudeln & Getreide', canonicalId: 'paccheri', defaultUnit: 'g'),
    IngredientEntry(name: 'Pizzateig (fertig)', category: 'Brot & Backwaren', canonicalId: 'pizzateig', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Pizzasauce (Glas)', category: 'Konserven', canonicalId: 'pizzasauce', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Trüffel (schwarz)', category: 'Mediterran', canonicalId: 'trueffel_schwarz', defaultUnit: 'g'),
    IngredientEntry(name: 'Trüffel (weiß)', category: 'Mediterran', canonicalId: 'trueffel_weiss', defaultUnit: 'g'),
    IngredientEntry(name: 'Trüffelpaste', category: 'Mediterran', canonicalId: 'trueffel_paste', defaultUnit: 'g'),
    IngredientEntry(name: 'Antipasti-Mix (Glas)', category: 'Mediterran', canonicalId: 'antipasti_mix', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Caponata', category: 'Mediterran', canonicalId: 'caponata', defaultUnit: 'g'),
    IngredientEntry(name: 'Giardiniera', category: 'Mediterran', canonicalId: 'giardiniera', defaultUnit: 'Glas'),

    // ──────────────────────────────────────────────────────
    // SPANISCHE / PORTUGIESISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Sobrasada', category: 'Wurst & Aufschnitt', canonicalId: 'sobrasada', defaultUnit: 'g'),
    IngredientEntry(name: 'Morcilla', category: 'Wurst & Aufschnitt', canonicalId: 'morcilla', defaultUnit: 'g'),
    IngredientEntry(name: 'Jamón Ibérico', category: 'Wurst & Aufschnitt', canonicalId: 'jamon_iberico', defaultUnit: 'g'),
    IngredientEntry(name: 'Jamón Serrano', category: 'Wurst & Aufschnitt', canonicalId: 'jamon_serrano', defaultUnit: 'g'),
    IngredientEntry(name: 'Pata Negra', category: 'Wurst & Aufschnitt', canonicalId: 'pata_negra', defaultUnit: 'g'),
    IngredientEntry(name: 'Padrón-Paprika', category: 'Obst & Gemüse', canonicalId: 'padron', defaultUnit: 'g'),
    IngredientEntry(name: 'Piquillo-Paprika (Glas)', category: 'Konserven', canonicalId: 'piquillo', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Chorizo (frisch)', category: 'Wurst & Aufschnitt', canonicalId: 'chorizo_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chorizo (geräuchert)', category: 'Wurst & Aufschnitt', canonicalId: 'chorizo_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Paprika (geräuchert, Pulver)', category: 'Gewürze & Soßen', canonicalId: 'paprika_esp', defaultUnit: 'TL', aliases: ['Pimentón']),
    IngredientEntry(name: 'Manchego (alt)', category: 'Milchprodukte', canonicalId: 'manchego_curado', defaultUnit: 'g'),
    IngredientEntry(name: 'Bacalao (Stockfisch)', category: 'Fleisch & Fisch', canonicalId: 'bacalao', defaultUnit: 'g'),
    IngredientEntry(name: 'Sardinillas (Dose)', category: 'Konserven', canonicalId: 'sardinillas', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Meeresfrüchte-Cocktail', category: 'Konserven', canonicalId: 'meeresfruechte_cocktail', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Gambas', category: 'Fleisch & Fisch', canonicalId: 'gambas', defaultUnit: 'g'),
    IngredientEntry(name: 'Sepien-Tinte', category: 'Mediterran', canonicalId: 'sepien_tinte', defaultUnit: 'g'),
    IngredientEntry(name: 'Arroz Bomba', category: 'Nudeln & Getreide', canonicalId: 'arroz_bomba', defaultUnit: 'g', aliases: ['Paella-Reis']),

    // ──────────────────────────────────────────────────────
    // FRANZÖSISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Foie Gras', category: 'Fleisch & Fisch', canonicalId: 'foie_gras', defaultUnit: 'g'),
    IngredientEntry(name: 'Confit de Canard', category: 'Fleisch & Fisch', canonicalId: 'confit_canard', defaultUnit: 'g'),
    IngredientEntry(name: 'Rillettes', category: 'Konserven', canonicalId: 'rillettes', defaultUnit: 'g'),
    IngredientEntry(name: 'Pâté (Landpastete)', category: 'Konserven', canonicalId: 'pate', defaultUnit: 'g'),
    IngredientEntry(name: 'Boeuf Bourguignon-Würfel', category: 'Konserven', canonicalId: 'boeuf_bourg', defaultUnit: 'g'),
    IngredientEntry(name: 'Herbes de Provence', category: 'Gewürze & Soßen', canonicalId: 'herbes_provence', defaultUnit: 'TL'),
    IngredientEntry(name: 'Fines Herbes', category: 'Gewürze & Soßen', canonicalId: 'fines_herbes', defaultUnit: 'TL'),
    IngredientEntry(name: 'Bouquet Garni', category: 'Gewürze & Soßen', canonicalId: 'bouquet_garni', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Creme Double', category: 'Milchprodukte', canonicalId: 'creme_double', defaultUnit: 'ml'),
    IngredientEntry(name: 'Crème Pâtissière', category: 'Backen', canonicalId: 'creme_patissiere', defaultUnit: 'g'),
    IngredientEntry(name: 'Madeleines', category: 'Süßwaren & Snacks', canonicalId: 'madeleines', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Macarons', category: 'Süßwaren & Snacks', canonicalId: 'macarons', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Canelés', category: 'Süßwaren & Snacks', canonicalId: 'caneles', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fleur de Sel (Bretagne)', category: 'Gewürze & Soßen', canonicalId: 'fleur_bretagne', defaultUnit: 'g'),
    IngredientEntry(name: 'Dijon-Senf', category: 'Konserven', canonicalId: 'dijon_senf', defaultUnit: 'TL'),
    IngredientEntry(name: 'Escargots (Dose)', category: 'Konserven', canonicalId: 'escargots', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Comté', category: 'Milchprodukte', canonicalId: 'comte', defaultUnit: 'g'),
    IngredientEntry(name: 'Reblochon', category: 'Milchprodukte', canonicalId: 'reblochon', defaultUnit: 'g'),
    IngredientEntry(name: 'Époisses', category: 'Milchprodukte', canonicalId: 'epoisses', defaultUnit: 'g'),
    IngredientEntry(name: 'Roquefort', category: 'Milchprodukte', canonicalId: 'roquefort', defaultUnit: 'g'),
    IngredientEntry(name: 'Mimolette', category: 'Milchprodukte', canonicalId: 'mimolette', defaultUnit: 'g'),
    IngredientEntry(name: 'Crêpe-Teig', category: 'Backen', canonicalId: 'crepe_teig', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Galette-Mehl', category: 'Backen', canonicalId: 'galette_mehl', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // GRIECHISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Loukaniko', category: 'Wurst & Aufschnitt', canonicalId: 'loukaniko', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kasseri', category: 'Milchprodukte', canonicalId: 'kasseri', defaultUnit: 'g'),
    IngredientEntry(name: 'Graviera', category: 'Milchprodukte', canonicalId: 'graviera', defaultUnit: 'g'),
    IngredientEntry(name: 'Kefalotiri', category: 'Milchprodukte', canonicalId: 'kefalotiri', defaultUnit: 'g'),
    IngredientEntry(name: 'Mastix (Chios)', category: 'Gewürze & Soßen', canonicalId: 'mastix', defaultUnit: 'g'),
    IngredientEntry(name: 'Taramasalata', category: 'Mediterran', canonicalId: 'taramasalata', defaultUnit: 'g'),
    IngredientEntry(name: 'Spanakopita-Teig', category: 'Backen', canonicalId: 'spanakopita', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Dolmades (Dose)', category: 'Konserven', canonicalId: 'dolmades', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Weinblätter (Glas)', category: 'Konserven', canonicalId: 'weinblaetter', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Ouzo', category: 'Getränke', canonicalId: 'ouzo', defaultUnit: 'ml'),
    IngredientEntry(name: 'Honig (Thymian)', category: 'Süßes & Aufstriche', canonicalId: 'honig_thymian', defaultUnit: 'EL'),

    // ──────────────────────────────────────────────────────
    // TÜRKISCHE / LEVANTINISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Bulgur (grob)', category: 'Nudeln & Getreide', canonicalId: 'bulgur_grob', defaultUnit: 'g'),
    IngredientEntry(name: 'Freekeh', category: 'Nudeln & Getreide', canonicalId: 'freekeh', defaultUnit: 'g'),
    IngredientEntry(name: 'Biber Salçası (Paprikapaste)', category: 'Mediterran', canonicalId: 'biber_salca', defaultUnit: 'EL'),
    IngredientEntry(name: 'Domates Salçası (Tomatenpaste)', category: 'Mediterran', canonicalId: 'domates_salca', defaultUnit: 'EL'),
    IngredientEntry(name: 'Pekmez (Traubensirup)', category: 'Süßes & Aufstriche', canonicalId: 'pekmez', defaultUnit: 'EL'),
    IngredientEntry(name: 'Sumac (türkisch)', category: 'Gewürze & Soßen', canonicalId: 'sumac_tr', defaultUnit: 'TL'),
    IngredientEntry(name: 'Urfa Biber', category: 'Gewürze & Soßen', canonicalId: 'urfa_biber', defaultUnit: 'TL'),
    IngredientEntry(name: 'Aleppo-Pfeffer', category: 'Gewürze & Soßen', canonicalId: 'aleppo', defaultUnit: 'TL'),
    IngredientEntry(name: 'Kaymak', category: 'Milchprodukte', canonicalId: 'kaymak', defaultUnit: 'g'),
    IngredientEntry(name: 'Ayran', category: 'Getränke', canonicalId: 'ayran', defaultUnit: 'ml'),
    IngredientEntry(name: 'Labneh', category: 'Milchprodukte', canonicalId: 'labneh', defaultUnit: 'g'),
    IngredientEntry(name: 'Sucuk', category: 'Wurst & Aufschnitt', canonicalId: 'sucuk', defaultUnit: 'g'),
    IngredientEntry(name: 'Pastırma', category: 'Wurst & Aufschnitt', canonicalId: 'pastirma', defaultUnit: 'g'),
    IngredientEntry(name: 'Antep-Pistazien', category: 'Nüsse & Samen', canonicalId: 'antep_pistazien', defaultUnit: 'g'),
    IngredientEntry(name: 'Tahin (türkisch)', category: 'Mediterran', canonicalId: 'tahin_tr', defaultUnit: 'EL'),
    IngredientEntry(name: 'Helva', category: 'Süßwaren & Snacks', canonicalId: 'helva', defaultUnit: 'g'),
    IngredientEntry(name: 'Lokum (Türkische Freude)', category: 'Süßwaren & Snacks', canonicalId: 'lokum', defaultUnit: 'g'),
    IngredientEntry(name: 'Baklava', category: 'Süßwaren & Snacks', canonicalId: 'baklava', defaultUnit: 'g'),
    IngredientEntry(name: 'Raki', category: 'Getränke', canonicalId: 'raki', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // NORDAFRIKANISCHE / ARABISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Couscous (Vollkorn)', category: 'Nudeln & Getreide', canonicalId: 'couscous_vk', defaultUnit: 'g'),
    IngredientEntry(name: 'M\'hamsa (Handgerollter Couscous)', category: 'Nudeln & Getreide', canonicalId: 'mhamsa', defaultUnit: 'g'),
    IngredientEntry(name: 'Merguez-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'merguez_gewuerz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Chermoula-Paste', category: 'Mediterran', canonicalId: 'chermoula_paste', defaultUnit: 'EL'),
    IngredientEntry(name: 'Preserved Lemon (eingelegte Zitrone)', category: 'Konserven', canonicalId: 'preserved_lemon', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Harissa (scharf)', category: 'Mediterran', canonicalId: 'harissa_scharf', defaultUnit: 'TL'),
    IngredientEntry(name: 'Arissa (Rosen-Harissa)', category: 'Mediterran', canonicalId: 'arissa', defaultUnit: 'TL'),
    IngredientEntry(name: 'Medjool-Datteln', category: 'Nüsse & Samen', canonicalId: 'datteln_medjool', defaultUnit: 'g'),
    IngredientEntry(name: 'Couscous-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'couscous_gewuerz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Arganöl (geröstet)', category: 'Öle & Essig', canonicalId: 'arganoel_roest', defaultUnit: 'ml'),
    IngredientEntry(name: 'Berberitzen', category: 'Nüsse & Samen', canonicalId: 'berberitzen', defaultUnit: 'g'),
    IngredientEntry(name: 'Rose Water', category: 'Backen', canonicalId: 'rosenwasser', defaultUnit: 'ml', aliases: ['Rosenwasser']),
    IngredientEntry(name: 'Orange Blossom Water', category: 'Backen', canonicalId: 'orangenbluetenwasser', defaultUnit: 'ml', aliases: ['Orangenblütenwasser']),
    IngredientEntry(name: 'Granatapfelmelasse', category: 'Süßes & Aufstriche', canonicalId: 'granatapfel_melasse', defaultUnit: 'EL'),
    IngredientEntry(name: 'Carob-Pulver', category: 'Backen', canonicalId: 'carob', defaultUnit: 'g', aliases: ['Johannisbrotmehl']),
    IngredientEntry(name: 'Smen (marokkanische Butter)', category: 'Öle & Essig', canonicalId: 'smen', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // INDISCHE KÜCHE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Chana Dal', category: 'Vorrat', canonicalId: 'chana_dal', defaultUnit: 'g'),
    IngredientEntry(name: 'Moong Dal', category: 'Vorrat', canonicalId: 'moong_dal', defaultUnit: 'g'),
    IngredientEntry(name: 'Urad Dal', category: 'Vorrat', canonicalId: 'urad_dal', defaultUnit: 'g'),
    IngredientEntry(name: 'Toor Dal', category: 'Vorrat', canonicalId: 'toor_dal', defaultUnit: 'g'),
    IngredientEntry(name: 'Masoor Dal (rote Linsen)', category: 'Vorrat', canonicalId: 'masoor_dal', defaultUnit: 'g'),
    IngredientEntry(name: 'Idli-Reismehl', category: 'Backen', canonicalId: 'idli_mehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Dosa-Mix', category: 'Backen', canonicalId: 'dosa_mix', defaultUnit: 'g'),
    IngredientEntry(name: 'Poha (Reisflocken)', category: 'Frühstück', canonicalId: 'poha', defaultUnit: 'g'),
    IngredientEntry(name: 'Murmura (gepuffter Reis)', category: 'Frühstück', canonicalId: 'murmura', defaultUnit: 'g'),
    IngredientEntry(name: 'Papadam', category: 'Brot & Backwaren', canonicalId: 'papadam', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Roti (frisch)', category: 'Brot & Backwaren', canonicalId: 'roti', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Paratha', category: 'Brot & Backwaren', canonicalId: 'paratha', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Puri', category: 'Brot & Backwaren', canonicalId: 'puri', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Amchur (Mangopulver)', category: 'Gewürze & Soßen', canonicalId: 'amchur', defaultUnit: 'TL'),
    IngredientEntry(name: 'Kala Namak (Schwarzsalz)', category: 'Gewürze & Soßen', canonicalId: 'kala_namak', defaultUnit: 'TL'),
    IngredientEntry(name: 'Chaat Masala', category: 'Gewürze & Soßen', canonicalId: 'chaat_masala', defaultUnit: 'TL'),
    IngredientEntry(name: 'Panch Phoron', category: 'Gewürze & Soßen', canonicalId: 'panch_phoron', defaultUnit: 'TL'),
    IngredientEntry(name: 'Kashmiri Chili', category: 'Gewürze & Soßen', canonicalId: 'kashmiri_chili', defaultUnit: 'TL'),
    IngredientEntry(name: 'Tamarindenpaste', category: 'Gewürze & Soßen', canonicalId: 'tamarindenpaste', defaultUnit: 'EL'),
    IngredientEntry(name: 'Kokosraspeln (geröstet)', category: 'Nüsse & Samen', canonicalId: 'kokos_roest', defaultUnit: 'g'),
    IngredientEntry(name: 'Curryketchup', category: 'Konserven', canonicalId: 'curry_ketchup', defaultUnit: 'EL'),
    IngredientEntry(name: 'Ghee (bio)', category: 'Milchprodukte', canonicalId: 'ghee_bio', defaultUnit: 'EL'),
    IngredientEntry(name: 'Kokosessig', category: 'Öle & Essig', canonicalId: 'kokosessig', defaultUnit: 'ml'),
    IngredientEntry(name: 'Jackfrucht (frisch)', category: 'Obst & Gemüse', canonicalId: 'jackfrucht_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Drumstick (Meerrettichbaum)', category: 'Obst & Gemüse', canonicalId: 'drumstick', defaultUnit: 'g'),
    IngredientEntry(name: 'Bitter Gourd (Bittermelone)', category: 'Obst & Gemüse', canonicalId: 'bitter_gourd', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tinda (Apfelkürbis)', category: 'Obst & Gemüse', canonicalId: 'tinda', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Methi (Bockshornkleeblätter)', category: 'Obst & Gemüse', canonicalId: 'methi', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // KOREANISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Gochujang (scharf)', category: 'Asiatisch', canonicalId: 'gochujang_scharf', defaultUnit: 'EL'),
    IngredientEntry(name: 'Ssamjang', category: 'Asiatisch', canonicalId: 'ssamjang', defaultUnit: 'EL'),
    IngredientEntry(name: 'Perilla-Blätter', category: 'Asiatisch', canonicalId: 'perilla', defaultUnit: 'g', aliases: ['Shiso', 'Kkaennip']),
    IngredientEntry(name: 'Daikon-Rettich', category: 'Asiatisch', canonicalId: 'daikon', defaultUnit: 'g'),
    IngredientEntry(name: 'Kkakdugi (Rettich-Kimchi)', category: 'Asiatisch', canonicalId: 'kkakdugi', defaultUnit: 'g'),
    IngredientEntry(name: 'Sikhye (Reisgetränk)', category: 'Getränke', canonicalId: 'sikhye', defaultUnit: 'ml'),
    IngredientEntry(name: 'Makgeolli', category: 'Getränke', canonicalId: 'makgeolli', defaultUnit: 'ml'),
    IngredientEntry(name: 'Doenjang-Jjigae-Paste', category: 'Asiatisch', canonicalId: 'doenjang_jjigae', defaultUnit: 'EL'),
    IngredientEntry(name: 'Japchae-Nudeln', category: 'Asiatisch', canonicalId: 'japchae', defaultUnit: 'g'),
    IngredientEntry(name: 'Tteok (Reiskuchen)', category: 'Asiatisch', canonicalId: 'tteok', defaultUnit: 'g'),
    IngredientEntry(name: 'Miyeok (Meereswürze)', category: 'Asiatisch', canonicalId: 'miyeok', defaultUnit: 'g'),
    IngredientEntry(name: 'Dobu (koreanischer Tofu)', category: 'Asiatisch', canonicalId: 'dobu', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // JAPANISCHE KÜCHE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Mochi', category: 'Asiatisch', canonicalId: 'mochi', defaultUnit: 'g'),
    IngredientEntry(name: 'Daifuku', category: 'Süßwaren & Snacks', canonicalId: 'daifuku', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Onigiri-Reis', category: 'Asiatisch', canonicalId: 'onigiri_reis', defaultUnit: 'g'),
    IngredientEntry(name: 'Okonomiyaki-Mehl', category: 'Backen', canonicalId: 'okonomiyaki_mehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Takoyaki-Mehl', category: 'Backen', canonicalId: 'takoyaki_mehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Katsuobushi (Thunfischflocken)', category: 'Asiatisch', canonicalId: 'katsuobushi', defaultUnit: 'g'),
    IngredientEntry(name: 'Kombu (Algen)', category: 'Asiatisch', canonicalId: 'kombu', defaultUnit: 'g'),
    IngredientEntry(name: 'Dashi-Brühe', category: 'Asiatisch', canonicalId: 'dashi_bruehe', defaultUnit: 'ml'),
    IngredientEntry(name: 'Shiso-Blätter (rot)', category: 'Asiatisch', canonicalId: 'shiso_rot', defaultUnit: 'g'),
    IngredientEntry(name: 'Yuzu-Juice', category: 'Asiatisch', canonicalId: 'yuzu_juice', defaultUnit: 'ml'),
    IngredientEntry(name: 'Matcha (Kochqualität)', category: 'Asiatisch', canonicalId: 'matcha_koch', defaultUnit: 'g'),
    IngredientEntry(name: 'Panko', category: 'Asiatisch', canonicalId: 'panko', defaultUnit: 'g', aliases: ['Japanisches Paniermehl']),
    IngredientEntry(name: 'Tonkatsu-Sauce', category: 'Asiatisch', canonicalId: 'tonkatsu_sauce', defaultUnit: 'EL'),
    IngredientEntry(name: 'Kewpie-Mayonnaise', category: 'Asiatisch', canonicalId: 'kewpie', defaultUnit: 'EL'),
    IngredientEntry(name: 'Natto (gefroren)', category: 'Asiatisch', canonicalId: 'natto_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Mentaiko (Pollock-Rogen)', category: 'Asiatisch', canonicalId: 'mentaiko', defaultUnit: 'g'),
    IngredientEntry(name: 'Ikura (Lachsrogen)', category: 'Asiatisch', canonicalId: 'ikura', defaultUnit: 'g'),
    IngredientEntry(name: 'Ume-Paste (Pflaume)', category: 'Asiatisch', canonicalId: 'ume_paste', defaultUnit: 'EL'),
    IngredientEntry(name: 'Sansho-Pfeffer', category: 'Asiatisch', canonicalId: 'sansho', defaultUnit: 'TL'),

    // ──────────────────────────────────────────────────────
    // CHINESISCHE KÜCHE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Char Siu Sauce', category: 'Asiatisch', canonicalId: 'char_siu', defaultUnit: 'EL'),
    IngredientEntry(name: 'Shaoxing-Reiswein', category: 'Asiatisch', canonicalId: 'shaoxing', defaultUnit: 'ml'),
    IngredientEntry(name: 'Schwarze Bohnensauce', category: 'Asiatisch', canonicalId: 'schwarze_bohnen_sauce', defaultUnit: 'EL'),
    IngredientEntry(name: 'Chili-Bohnenpaste (Doubanjiang)', category: 'Asiatisch', canonicalId: 'doubanjiang_paste', defaultUnit: 'EL'),
    IngredientEntry(name: 'Mu Err Pilze (Holzohrpilze)', category: 'Asiatisch', canonicalId: 'mu_err', defaultUnit: 'g'),
    IngredientEntry(name: 'Enoki-Pilze', category: 'Asiatisch', canonicalId: 'enoki', defaultUnit: 'g'),
    IngredientEntry(name: 'King Oyster Mushroom', category: 'Asiatisch', canonicalId: 'king_oyster', defaultUnit: 'g'),
    IngredientEntry(name: 'Bambussprossen (frisch)', category: 'Asiatisch', canonicalId: 'bambus_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Wasserkastanien (Dose)', category: 'Asiatisch', canonicalId: 'wasserkastanien', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Lotuswurzeln', category: 'Asiatisch', canonicalId: 'lotuswurzel', defaultUnit: 'g'),
    IngredientEntry(name: 'Tapioka-Perlen', category: 'Asiatisch', canonicalId: 'tapioka', defaultUnit: 'g'),
    IngredientEntry(name: 'Bubble Tea-Basis', category: 'Getränke', canonicalId: 'bubble_tea', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Lap Cheong (Chorizo chin.)', category: 'Wurst & Aufschnitt', canonicalId: 'lap_cheong', defaultUnit: 'g'),
    IngredientEntry(name: 'Zha Cai (eingelegter Kohl)', category: 'Asiatisch', canonicalId: 'zha_cai', defaultUnit: 'g'),
    IngredientEntry(name: 'Doubanjiang (milde)', category: 'Asiatisch', canonicalId: 'doubanjiang_mild', defaultUnit: 'EL'),
    IngredientEntry(name: 'Lao Gan Ma (Chiliöl)', category: 'Asiatisch', canonicalId: 'lao_gan_ma', defaultUnit: 'EL'),

    // ──────────────────────────────────────────────────────
    // SÜDOSTASIATISCHE KÜCHE (THAI, VIETNAMESISCH, etc.)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Krachai (Fingerroot)', category: 'Asiatisch', canonicalId: 'krachai', defaultUnit: 'g'),
    IngredientEntry(name: 'Pandan-Extrakt', category: 'Backen', canonicalId: 'pandan_extrakt', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bohnenkrautsalz', category: 'Gewürze & Soßen', canonicalId: 'bohnenkraut_salz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Kleber-Reis (Glutinous Rice)', category: 'Asiatisch', canonicalId: 'klebreis', defaultUnit: 'g'),
    IngredientEntry(name: 'Nam Pla (Fischsauce thai.)', category: 'Asiatisch', canonicalId: 'nam_pla', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sriracha (original)', category: 'Asiatisch', canonicalId: 'sriracha_orig', defaultUnit: 'ml'),
    IngredientEntry(name: 'Pad-Thai-Sauce', category: 'Asiatisch', canonicalId: 'pad_thai_sauce', defaultUnit: 'EL'),
    IngredientEntry(name: 'Massaman-Paste', category: 'Asiatisch', canonicalId: 'massaman_paste', defaultUnit: 'EL'),
    IngredientEntry(name: 'Panang-Paste', category: 'Asiatisch', canonicalId: 'panang_paste', defaultUnit: 'EL'),
    IngredientEntry(name: 'Galangal-Pulver', category: 'Gewürze & Soßen', canonicalId: 'galangal_pulver', defaultUnit: 'TL'),
    IngredientEntry(name: 'Pho-Gewürzset', category: 'Asiatisch', canonicalId: 'pho_gewuerz', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rau Ram (Vietnamesischer Koriander)', category: 'Asiatisch', canonicalId: 'rau_ram', defaultUnit: 'g'),
    IngredientEntry(name: 'Nước Chấm (Dip)', category: 'Asiatisch', canonicalId: 'nuoc_cham', defaultUnit: 'ml'),
    IngredientEntry(name: 'Belacan (Garnelenpaste)', category: 'Asiatisch', canonicalId: 'belacan', defaultUnit: 'g'),
    IngredientEntry(name: 'Kaffernlimette', category: 'Asiatisch', canonicalId: 'kaffernlimette', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Bittermelone (TK)', category: 'Tiefkühl', canonicalId: 'bittermelone_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Okra (TK)', category: 'Tiefkühl', canonicalId: 'okra_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Neem-Blätter', category: 'Asiatisch', canonicalId: 'neem', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // MEXIKANISCHE / LATEINAMERIKANISCHE KÜCHE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Ancho-Chili (trocken)', category: 'Mexikanisch', canonicalId: 'ancho_chili', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Pasilla-Chili', category: 'Mexikanisch', canonicalId: 'pasilla', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Mulato-Chili', category: 'Mexikanisch', canonicalId: 'mulato', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Guajillo-Chili', category: 'Mexikanisch', canonicalId: 'guajillo', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chihuacle-Chili', category: 'Mexikanisch', canonicalId: 'chihuacle', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Epazote', category: 'Mexikanisch', canonicalId: 'epazote', defaultUnit: 'g'),
    IngredientEntry(name: 'Huitlacoche', category: 'Mexikanisch', canonicalId: 'huitlacoche', defaultUnit: 'g'),
    IngredientEntry(name: 'Nopal (Kaktusblätter)', category: 'Mexikanisch', canonicalId: 'nopal', defaultUnit: 'g'),
    IngredientEntry(name: 'Masa Harina', category: 'Backen', canonicalId: 'masa_harina', defaultUnit: 'g'),
    IngredientEntry(name: 'Pozole-Mais', category: 'Mexikanisch', canonicalId: 'pozole_mais', defaultUnit: 'g'),
    IngredientEntry(name: 'Crema Mexicana', category: 'Milchprodukte', canonicalId: 'crema_mexicana', defaultUnit: 'ml'),
    IngredientEntry(name: 'Cotija-Käse', category: 'Milchprodukte', canonicalId: 'cotija', defaultUnit: 'g'),
    IngredientEntry(name: 'Queso Fresco', category: 'Milchprodukte', canonicalId: 'queso_fresco', defaultUnit: 'g'),
    IngredientEntry(name: 'Cacao Nibs', category: 'Backen', canonicalId: 'cacao_nibs', defaultUnit: 'g'),
    IngredientEntry(name: 'Mezcal', category: 'Getränke', canonicalId: 'mezcal', defaultUnit: 'ml'),
    IngredientEntry(name: 'Horchata-Mix', category: 'Getränke', canonicalId: 'horchata', defaultUnit: 'g'),
    IngredientEntry(name: 'Tamarindo-Getränk', category: 'Getränke', canonicalId: 'tamarindo_drink', defaultUnit: 'ml'),
    IngredientEntry(name: 'Yuca / Maniok', category: 'Obst & Gemüse', canonicalId: 'yuca', defaultUnit: 'g'),
    IngredientEntry(name: 'Plantain (Kochbanane)', category: 'Obst & Gemüse', canonicalId: 'plantain', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Tomatillo', category: 'Obst & Gemüse', canonicalId: 'tomatillo', defaultUnit: 'g'),
    IngredientEntry(name: 'Chayote', category: 'Obst & Gemüse', canonicalId: 'chayote', defaultUnit: 'Stück'),

    // ──────────────────────────────────────────────────────
    // AMERIKANISCHE KÜCHE / BBQ
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Beef Brisket', category: 'Fleisch & Fisch', canonicalId: 'brisket', defaultUnit: 'g'),
    IngredientEntry(name: 'Pulled Pork (fertig)', category: 'Fleisch & Fisch', canonicalId: 'pulled_pork', defaultUnit: 'g'),
    IngredientEntry(name: 'BBQ-Rub (trocken)', category: 'Gewürze & Soßen', canonicalId: 'bbq_rub', defaultUnit: 'TL'),
    IngredientEntry(name: 'Liquid Smoke', category: 'Gewürze & Soßen', canonicalId: 'liquid_smoke', defaultUnit: 'TL'),
    IngredientEntry(name: 'Jack Daniel\'s BBQ-Sauce', category: 'Öle & Essig', canonicalId: 'jd_bbq', defaultUnit: 'EL'),
    IngredientEntry(name: 'Frank\'s RedHot', category: 'Öle & Essig', canonicalId: 'franks_redhot', defaultUnit: 'EL'),
    IngredientEntry(name: 'Jalapeño-Cheddar-Mix', category: 'Milchprodukte', canonicalId: 'jalapeno_cheddar', defaultUnit: 'g'),
    IngredientEntry(name: 'Cheddar', category: 'Milchprodukte', canonicalId: 'cheddar', defaultUnit: 'g'),
    IngredientEntry(name: 'Cheddar (gerieben)', category: 'Milchprodukte', canonicalId: 'cheddar_gerieben', defaultUnit: 'g'),
    IngredientEntry(name: 'Cream Cheese', category: 'Milchprodukte', canonicalId: 'cream_cheese', defaultUnit: 'g', aliases: ['Doppelrahmfrischkäse']),
    IngredientEntry(name: 'Ranch Dressing', category: 'Öle & Essig', canonicalId: 'ranch', defaultUnit: 'EL'),
    IngredientEntry(name: 'Blue Cheese Dressing', category: 'Öle & Essig', canonicalId: 'blue_cheese_dressing', defaultUnit: 'EL'),
    IngredientEntry(name: 'Thousand Island', category: 'Öle & Essig', canonicalId: 'thousand_island', defaultUnit: 'EL'),
    IngredientEntry(name: 'Burger Buns', category: 'Brot & Backwaren', canonicalId: 'burger_bun', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Brioche Burger Bun', category: 'Brot & Backwaren', canonicalId: 'brioche_bun', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Hot Dog-Brötchen', category: 'Brot & Backwaren', canonicalId: 'hotdog_bun', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Cornbread-Mix', category: 'Backen', canonicalId: 'cornbread_mix', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Maple Syrup', category: 'Süßes & Aufstriche', canonicalId: 'maple_syrup', defaultUnit: 'EL', aliases: ['Ahornsirup (kanadisch)']),
    IngredientEntry(name: 'Peanut Butter (chunky)', category: 'Süßes & Aufstriche', canonicalId: 'peanut_butter_chunky', defaultUnit: 'EL'),
    IngredientEntry(name: 'Grape Jelly', category: 'Konserven', canonicalId: 'grape_jelly', defaultUnit: 'EL'),
    IngredientEntry(name: 'Pickles (amerikanisch)', category: 'Konserven', canonicalId: 'pickles_us', defaultUnit: 'g'),
    IngredientEntry(name: 'Jalapeños (Scheiben)', category: 'Konserven', canonicalId: 'jalapeno_scheiben', defaultUnit: 'g'),
    IngredientEntry(name: 'Cheerios', category: 'Frühstück', canonicalId: 'cheerios', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // BRITISCHE / IRISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Marmite', category: 'Süßes & Aufstriche', canonicalId: 'marmite', defaultUnit: 'g'),
    IngredientEntry(name: 'Clotted Cream', category: 'Milchprodukte', canonicalId: 'clotted_cream', defaultUnit: 'g'),
    IngredientEntry(name: 'Branston Pickle', category: 'Konserven', canonicalId: 'branston', defaultUnit: 'g'),
    IngredientEntry(name: 'HP Sauce', category: 'Öle & Essig', canonicalId: 'hp_sauce', defaultUnit: 'EL'),
    IngredientEntry(name: 'Guinness', category: 'Getränke', canonicalId: 'guinness', defaultUnit: 'ml'),
    IngredientEntry(name: 'Black Pudding', category: 'Wurst & Aufschnitt', canonicalId: 'black_pudding', defaultUnit: 'g'),
    IngredientEntry(name: 'Sausages (Cumberland)', category: 'Wurst & Aufschnitt', canonicalId: 'cumberland', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Baked Beans (Dose)', category: 'Konserven', canonicalId: 'baked_beans', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Stilton', category: 'Milchprodukte', canonicalId: 'stilton', defaultUnit: 'g'),
    IngredientEntry(name: 'Cheddar (vintage)', category: 'Milchprodukte', canonicalId: 'cheddar_vintage', defaultUnit: 'g'),
    IngredientEntry(name: 'Scones-Mix', category: 'Backen', canonicalId: 'scones_mix', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Digestive Biscuits', category: 'Süßwaren & Snacks', canonicalId: 'digestive', defaultUnit: 'g'),
    IngredientEntry(name: 'Oatmeal (schottisch)', category: 'Frühstück', canonicalId: 'oatmeal', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // OSTEUROPÄISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Kaviar (Imitation)', category: 'Konserven', canonicalId: 'kaviar_imitation', defaultUnit: 'g'),
    IngredientEntry(name: 'Sauerkraut (frisch)', category: 'Obst & Gemüse', canonicalId: 'sauerkraut_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Rote Bete (frisch)', category: 'Obst & Gemüse', canonicalId: 'rote_bete_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kwas', category: 'Getränke', canonicalId: 'kwas', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kefir (russisch)', category: 'Milchprodukte', canonicalId: 'kefir_ru', defaultUnit: 'ml'),
    IngredientEntry(name: 'Smetana', category: 'Milchprodukte', canonicalId: 'smetana', defaultUnit: 'g', aliases: ['Sauerrahm (russisch)']),
    IngredientEntry(name: 'Tvorog', category: 'Milchprodukte', canonicalId: 'tvorog', defaultUnit: 'g', aliases: ['Quark (russisch)']),
    IngredientEntry(name: 'Borscht-Paste', category: 'Konserven', canonicalId: 'borscht_paste', defaultUnit: 'g'),
    IngredientEntry(name: 'Buckwheat (Buchweizen Kascha)', category: 'Nudeln & Getreide', canonicalId: 'kascha', defaultUnit: 'g'),
    IngredientEntry(name: 'Blinimehl', category: 'Backen', canonicalId: 'blinimehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Hering (mariniert)', category: 'Konserven', canonicalId: 'hering_mar', defaultUnit: 'g'),
    IngredientEntry(name: 'Pilze (getrocknet, Mix)', category: 'Konserven', canonicalId: 'pilze_mix_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Ajvar (scharf)', category: 'Konserven', canonicalId: 'ajvar_scharf', defaultUnit: 'g'),
    IngredientEntry(name: 'Liptauer-Paprika', category: 'Milchprodukte', canonicalId: 'liptauer_paprika', defaultUnit: 'g'),
    IngredientEntry(name: 'Pfefferoni (mild)', category: 'Konserven', canonicalId: 'pfefferoni_mild', defaultUnit: 'g'),
    IngredientEntry(name: 'Pfefferoni (scharf)', category: 'Konserven', canonicalId: 'pfefferoni_scharf', defaultUnit: 'g'),
    IngredientEntry(name: 'Zwetschgenlekvar', category: 'Konserven', canonicalId: 'zwetschgenlekvar', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // SKANDINAVISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Gravlax', category: 'Fleisch & Fisch', canonicalId: 'gravlax', defaultUnit: 'g'),
    IngredientEntry(name: 'Surströmming', category: 'Konserven', canonicalId: 'surstroemming', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Lutfisk', category: 'Fleisch & Fisch', canonicalId: 'lutfisk', defaultUnit: 'g'),
    IngredientEntry(name: 'Renskav (Rentier)', category: 'Fleisch & Fisch', canonicalId: 'renskav', defaultUnit: 'g'),
    IngredientEntry(name: 'Elch (Fleisch)', category: 'Fleisch & Fisch', canonicalId: 'elch', defaultUnit: 'g'),
    IngredientEntry(name: 'Knäckebrot (Rye)', category: 'Brot & Backwaren', canonicalId: 'knaecke_rye', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Wasa-Cracker', category: 'Brot & Backwaren', canonicalId: 'wasa', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Kavring (schwedisch)', category: 'Brot & Backwaren', canonicalId: 'kavring', defaultUnit: 'Scheibe'),
    IngredientEntry(name: 'Dill-Senf (schwedisch)', category: 'Konserven', canonicalId: 'dill_senf', defaultUnit: 'EL'),
    IngredientEntry(name: 'Lingonbeeren (Preiselbeeren)', category: 'Konserven', canonicalId: 'lingon', defaultUnit: 'g'),
    IngredientEntry(name: 'Cloudberry Jam (Moltebeere)', category: 'Konserven', canonicalId: 'cloudberry_jam', defaultUnit: 'g'),
    IngredientEntry(name: 'Aquavit', category: 'Getränke', canonicalId: 'aquavit', defaultUnit: 'ml'),
    IngredientEntry(name: 'Glögg', category: 'Getränke', canonicalId: 'gloegg', defaultUnit: 'ml'),
    IngredientEntry(name: 'Brunost (Ziegenkäse)', category: 'Milchprodukte', canonicalId: 'brunost', defaultUnit: 'g'),
    IngredientEntry(name: 'Jarlsberg', category: 'Milchprodukte', canonicalId: 'jarlsberg', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // AFRIKANISCHE KÜCHE (SUB-SAHARA)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Fufu-Mehl', category: 'Backen', canonicalId: 'fufu', defaultUnit: 'g'),
    IngredientEntry(name: 'Egusi (Kürbiskernesubstitut)', category: 'Nüsse & Samen', canonicalId: 'egusi', defaultUnit: 'g'),
    IngredientEntry(name: 'Ugali-Maismehl', category: 'Backen', canonicalId: 'ugali', defaultUnit: 'g'),
    IngredientEntry(name: 'Jollof-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'jollof', defaultUnit: 'TL'),
    IngredientEntry(name: 'Suya-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'suya', defaultUnit: 'TL'),
    IngredientEntry(name: 'Berbere (äthiopisch)', category: 'Gewürze & Soßen', canonicalId: 'berbere', defaultUnit: 'TL'),
    IngredientEntry(name: 'Niter Kibbeh', category: 'Öle & Essig', canonicalId: 'niter_kibbeh', defaultUnit: 'EL'),
    IngredientEntry(name: 'Injera-Mehl (Teff)', category: 'Backen', canonicalId: 'injera_mehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Plantain-Mehl', category: 'Backen', canonicalId: 'plantain_mehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Palm Oil', category: 'Öle & Essig', canonicalId: 'palmoel', defaultUnit: 'ml', aliases: ['Palmöl']),
    IngredientEntry(name: 'Moringa-Pulver', category: 'Gesundheit', canonicalId: 'moringa', defaultUnit: 'g'),
    IngredientEntry(name: 'Baobab-Pulver', category: 'Gesundheit', canonicalId: 'baobab', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // NAHOSTKÜCHE ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Falafel-Mix', category: 'Mediterran', canonicalId: 'falafel_mix', defaultUnit: 'g'),
    IngredientEntry(name: 'Shawarma-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'shawarma', defaultUnit: 'TL'),
    IngredientEntry(name: 'Kafta-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'kafta', defaultUnit: 'TL'),
    IngredientEntry(name: 'Mulukhiyah (Jute)', category: 'Obst & Gemüse', canonicalId: 'mulukhiyah', defaultUnit: 'g'),
    IngredientEntry(name: 'Maftoul (Palästinensischer Couscous)', category: 'Nudeln & Getreide', canonicalId: 'maftoul', defaultUnit: 'g'),
    IngredientEntry(name: 'Kawareh (Kalbsfüße)', category: 'Fleisch & Fisch', canonicalId: 'kawareh', defaultUnit: 'g'),
    IngredientEntry(name: 'Awarma (Hammel-Konfit)', category: 'Fleisch & Fisch', canonicalId: 'awarma', defaultUnit: 'g'),
    IngredientEntry(name: 'Dibs Rumman (Granatapfelmelasse)', category: 'Süßes & Aufstriche', canonicalId: 'dibs_rumman', defaultUnit: 'EL'),
    IngredientEntry(name: 'Halva (Sesam)', category: 'Süßwaren & Snacks', canonicalId: 'halva_sesam', defaultUnit: 'g'),
    IngredientEntry(name: 'Namoura (Grieß-Dessert)', category: 'Süßwaren & Snacks', canonicalId: 'namoura', defaultUnit: 'g'),
    IngredientEntry(name: 'Qatayef', category: 'Süßwaren & Snacks', canonicalId: 'qatayef', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Jallab-Sirup', category: 'Getränke', canonicalId: 'jallab', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sahlab-Pulver', category: 'Getränke', canonicalId: 'sahlab', defaultUnit: 'g'),
    IngredientEntry(name: 'Arak', category: 'Getränke', canonicalId: 'arak', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // PERUANISCHE / SÜD-AMERIKANISCHE KÜCHE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Aji Amarillo (Paste)', category: 'Mexikanisch', canonicalId: 'aji_amarillo', defaultUnit: 'EL'),
    IngredientEntry(name: 'Aji Panca (Paste)', category: 'Mexikanisch', canonicalId: 'aji_panca', defaultUnit: 'EL'),
    IngredientEntry(name: 'Rocoto (Chili)', category: 'Mexikanisch', canonicalId: 'rocoto', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Lúcuma (frisch/Pulver)', category: 'Obst & Gemüse', canonicalId: 'lucuma_frucht', defaultUnit: 'g'),
    IngredientEntry(name: 'Chirimoya (Cherimoya)', category: 'Obst & Gemüse', canonicalId: 'chirimoya', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Maracuya (Passionsfrucht)', category: 'Obst & Gemüse', canonicalId: 'maracuya', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Purple Corn (Morada)', category: 'Nudeln & Getreide', canonicalId: 'purple_corn', defaultUnit: 'g'),
    IngredientEntry(name: 'Causa-Kartoffeln (gelb)', category: 'Obst & Gemüse', canonicalId: 'causa_kartoffeln', defaultUnit: 'g'),
    IngredientEntry(name: 'Choclo (Riesenmaiskörner)', category: 'Obst & Gemüse', canonicalId: 'choclo', defaultUnit: 'g'),
    IngredientEntry(name: 'Pisco', category: 'Getränke', canonicalId: 'pisco', defaultUnit: 'ml'),
    IngredientEntry(name: 'Chicha Morada', category: 'Getränke', canonicalId: 'chicha_morada', defaultUnit: 'ml'),
    IngredientEntry(name: 'Leche de Tigre', category: 'Mediterran', canonicalId: 'leche_de_tigre', defaultUnit: 'ml'),
    IngredientEntry(name: 'Cancha (gerösteter Mais)', category: 'Süßwaren & Snacks', canonicalId: 'cancha', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // SÜSSE BACKZUTATEN & DESSERTS WELTWEIT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Dulce de Leche', category: 'Süßes & Aufstriche', canonicalId: 'dulce_de_leche', defaultUnit: 'g'),
    IngredientEntry(name: 'Cajeta (Ziegen-Karamell)', category: 'Süßes & Aufstriche', canonicalId: 'cajeta', defaultUnit: 'g'),
    IngredientEntry(name: 'Karamell-Sauce', category: 'Backen', canonicalId: 'karamell_sauce', defaultUnit: 'ml'),
    IngredientEntry(name: 'Salzkaramell-Sauce', category: 'Backen', canonicalId: 'salzkaramell', defaultUnit: 'ml'),
    IngredientEntry(name: 'Schoko-Ganache', category: 'Backen', canonicalId: 'ganache', defaultUnit: 'g'),
    IngredientEntry(name: 'Pralinenfüllung', category: 'Backen', canonicalId: 'praline', defaultUnit: 'g'),
    IngredientEntry(name: 'Nougat (weiß)', category: 'Backen', canonicalId: 'nougat_weiss', defaultUnit: 'g'),
    IngredientEntry(name: 'Pistazienpaste', category: 'Backen', canonicalId: 'pistazien_paste', defaultUnit: 'g'),
    IngredientEntry(name: 'Haselnusspaste', category: 'Backen', canonicalId: 'haselnuss_paste', defaultUnit: 'g'),
    IngredientEntry(name: 'Speiseöl (neutral)', category: 'Öle & Essig', canonicalId: 'speiseoel_neutral', defaultUnit: 'ml'),
    IngredientEntry(name: 'Butter (gesalzen)', category: 'Milchprodukte', canonicalId: 'butter_gesalzen', defaultUnit: 'g'),
    IngredientEntry(name: 'Butterschmalz', category: 'Milchprodukte', canonicalId: 'butterschmalz', defaultUnit: 'g'),
    IngredientEntry(name: 'Kokosbutter', category: 'Backen', canonicalId: 'kokosbutter', defaultUnit: 'g'),
    IngredientEntry(name: 'Waffelwaffeln (fertig)', category: 'Süßwaren & Snacks', canonicalId: 'waffel_waffel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Eierlikör', category: 'Backen', canonicalId: 'eierlikor', defaultUnit: 'ml'),
    IngredientEntry(name: 'Rum-Aroma', category: 'Backen', canonicalId: 'rum_aroma', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bittermandelaroma', category: 'Backen', canonicalId: 'bittermandel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Zitronenabrieb (Schale)', category: 'Backen', canonicalId: 'zitronen_abrieb', defaultUnit: 'TL'),
    IngredientEntry(name: 'Orangenabrieb (Schale)', category: 'Backen', canonicalId: 'orangen_abrieb', defaultUnit: 'TL'),
    IngredientEntry(name: 'Agar Agar (Pulver)', category: 'Backen', canonicalId: 'agar_pulver', defaultUnit: 'g'),
    IngredientEntry(name: 'Carrageen', category: 'Backen', canonicalId: 'carrageen', defaultUnit: 'g'),
    IngredientEntry(name: 'Pektinpulver', category: 'Backen', canonicalId: 'pektin', defaultUnit: 'g'),
    IngredientEntry(name: 'Zuckerrübensirup (Zuckerrübe)', category: 'Backen', canonicalId: 'rueben_sirup', defaultUnit: 'EL'),
    IngredientEntry(name: 'Reissirup', category: 'Backen', canonicalId: 'reissirup', defaultUnit: 'EL'),
    IngredientEntry(name: 'Dattelsirup', category: 'Süßes & Aufstriche', canonicalId: 'dattelsirup', defaultUnit: 'EL'),
    IngredientEntry(name: 'Maulbeersirup', category: 'Süßes & Aufstriche', canonicalId: 'maulbeersirup', defaultUnit: 'EL'),

    // ──────────────────────────────────────────────────────
    // SUPERFOOD & KÖRNER ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Weizenkleie', category: 'Backen', canonicalId: 'weizenkleie', defaultUnit: 'g'),
    IngredientEntry(name: 'Haferkleie', category: 'Frühstück', canonicalId: 'haferkleie', defaultUnit: 'g'),
    IngredientEntry(name: 'Reiskleie', category: 'Frühstück', canonicalId: 'reiskleie', defaultUnit: 'g'),
    IngredientEntry(name: 'Weizenkeime', category: 'Frühstück', canonicalId: 'weizenkeime', defaultUnit: 'g'),
    IngredientEntry(name: 'Leinsamenschrot', category: 'Backen', canonicalId: 'leinsamenschrot', defaultUnit: 'g'),
    IngredientEntry(name: 'Goldleinsamen', category: 'Nüsse & Samen', canonicalId: 'leinsamen_gold', defaultUnit: 'g'),
    IngredientEntry(name: 'Mohn (blau)', category: 'Backen', canonicalId: 'mohn_blau', defaultUnit: 'g'),
    IngredientEntry(name: 'Mohn (weiß)', category: 'Backen', canonicalId: 'mohn_weiss', defaultUnit: 'g'),
    IngredientEntry(name: 'Kürbiskerne (geröstet)', category: 'Nüsse & Samen', canonicalId: 'kuerbiskerne_roest', defaultUnit: 'g'),
    IngredientEntry(name: 'Paranüsse', category: 'Nüsse & Samen', canonicalId: 'paranuesse', defaultUnit: 'g'),
    IngredientEntry(name: 'Macadamianüsse', category: 'Nüsse & Samen', canonicalId: 'macadamia', defaultUnit: 'g'),
    IngredientEntry(name: 'Pekannüsse', category: 'Nüsse & Samen', canonicalId: 'pekannuesse', defaultUnit: 'g'),
    IngredientEntry(name: 'Tigernüsse', category: 'Nüsse & Samen', canonicalId: 'tigernus', defaultUnit: 'g', aliases: ['Erdmandeln', 'Chufa']),
    IngredientEntry(name: 'Sacha Inchi', category: 'Nüsse & Samen', canonicalId: 'sacha_inchi', defaultUnit: 'g'),
    IngredientEntry(name: 'Nigellasamem (Schwarzkümmel)', category: 'Nüsse & Samen', canonicalId: 'nigella', defaultUnit: 'g'),
    IngredientEntry(name: 'Distelblüten (Safflor)', category: 'Gewürze & Soßen', canonicalId: 'safflor', defaultUnit: 'g'),
    IngredientEntry(name: 'Bockshornkleesamen', category: 'Gewürze & Soßen', canonicalId: 'bock_samen', defaultUnit: 'TL'),

    // ──────────────────────────────────────────────────────
    // KÄSE WELTWEIT ERWEITERT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Goat Cheese (Ziegenfrischkäse)', category: 'Milchprodukte', canonicalId: 'ziegenfrischkaese', defaultUnit: 'g'),
    IngredientEntry(name: 'Bûche de Chèvre', category: 'Milchprodukte', canonicalId: 'buche_chevre', defaultUnit: 'g'),
    IngredientEntry(name: 'Valençay', category: 'Milchprodukte', canonicalId: 'valencay', defaultUnit: 'g'),
    IngredientEntry(name: 'Ossau-Iraty', category: 'Milchprodukte', canonicalId: 'ossau_iraty', defaultUnit: 'g'),
    IngredientEntry(name: 'Idiazabal', category: 'Milchprodukte', canonicalId: 'idiazabal', defaultUnit: 'g'),
    IngredientEntry(name: 'Roncal', category: 'Milchprodukte', canonicalId: 'roncal', defaultUnit: 'g'),
    IngredientEntry(name: 'Raclette', category: 'Milchprodukte', canonicalId: 'raclette', defaultUnit: 'g'),
    IngredientEntry(name: 'Appenzeller', category: 'Milchprodukte', canonicalId: 'appenzeller', defaultUnit: 'g'),
    IngredientEntry(name: 'Sbrinz', category: 'Milchprodukte', canonicalId: 'sbrinz', defaultUnit: 'g'),
    IngredientEntry(name: 'Vacherin (Mont d\'Or)', category: 'Milchprodukte', canonicalId: 'vacherin', defaultUnit: 'g'),
    IngredientEntry(name: 'Esrom', category: 'Milchprodukte', canonicalId: 'esrom', defaultUnit: 'g'),
    IngredientEntry(name: 'Havarti', category: 'Milchprodukte', canonicalId: 'havarti', defaultUnit: 'g'),
    IngredientEntry(name: 'Danbo', category: 'Milchprodukte', canonicalId: 'danbo', defaultUnit: 'g'),
    IngredientEntry(name: 'Fontina', category: 'Milchprodukte', canonicalId: 'fontina', defaultUnit: 'g'),
    IngredientEntry(name: 'Toma Piemontese', category: 'Milchprodukte', canonicalId: 'toma', defaultUnit: 'g'),
    IngredientEntry(name: 'Queso Manchego', category: 'Milchprodukte', canonicalId: 'queso_manchego', defaultUnit: 'g'),

    // ──────────────────────────────────────────────────────
    // WEIN & SPIRITUOSEN KOCHEN
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Marsala', category: 'Getränke', canonicalId: 'marsala', defaultUnit: 'ml'),
    IngredientEntry(name: 'Madeira (Wein)', category: 'Getränke', canonicalId: 'madeira', defaultUnit: 'ml'),
    IngredientEntry(name: 'Portwein (rot)', category: 'Getränke', canonicalId: 'portwein_rot', defaultUnit: 'ml'),
    IngredientEntry(name: 'Portwein (weiß)', category: 'Getränke', canonicalId: 'portwein_weiss', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sherry (trocken)', category: 'Getränke', canonicalId: 'sherry_trocken', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sherry (süß)', category: 'Getränke', canonicalId: 'sherry_suess', defaultUnit: 'ml'),
    IngredientEntry(name: 'Calvados', category: 'Getränke', canonicalId: 'calvados', defaultUnit: 'ml'),
    IngredientEntry(name: 'Armagnac', category: 'Getränke', canonicalId: 'armagnac', defaultUnit: 'ml'),
    IngredientEntry(name: 'Grappa', category: 'Getränke', canonicalId: 'grappa', defaultUnit: 'ml'),
    IngredientEntry(name: 'Limoncello', category: 'Getränke', canonicalId: 'limoncello', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sambuca', category: 'Getränke', canonicalId: 'sambuca', defaultUnit: 'ml'),
    IngredientEntry(name: 'Cider (trocken)', category: 'Getränke', canonicalId: 'cider_trocken', defaultUnit: 'ml'),
    IngredientEntry(name: 'Cider (süß)', category: 'Getränke', canonicalId: 'cider_suess', defaultUnit: 'ml'),
    IngredientEntry(name: 'Mead (Honigwein)', category: 'Getränke', canonicalId: 'mead', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kräuterlikör', category: 'Getränke', canonicalId: 'kraeuterlikoer', defaultUnit: 'ml'),
    IngredientEntry(name: 'Crème de Cassis', category: 'Getränke', canonicalId: 'creme_cassis', defaultUnit: 'ml'),

    // ──────────────────────────────────────────────────────
    // SONSTIGES / KÜCHENZUBEHÖR IM SUPERMARKT
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Pergamentpapier', category: 'Haushalt', canonicalId: 'pergamentpapier', defaultUnit: 'Rolle'),
    IngredientEntry(name: 'Einmachgläser', category: 'Haushalt', canonicalId: 'einmachglaeser', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Einmachgummi', category: 'Haushalt', canonicalId: 'einmachgummi', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Tortenring', category: 'Haushalt', canonicalId: 'tortenring', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Spritzbeutel', category: 'Haushalt', canonicalId: 'spritzbeutel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Zahnstocher', category: 'Haushalt', canonicalId: 'zahnstocher', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Grillanzünder', category: 'Haushalt', canonicalId: 'grillanzuender', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Holzkohle', category: 'Haushalt', canonicalId: 'holzkohle', defaultUnit: 'Sack'),
    IngredientEntry(name: 'Grillbriketts', category: 'Haushalt', canonicalId: 'grillbriketts', defaultUnit: 'Sack'),
    IngredientEntry(name: 'Grillrost-Spray', category: 'Haushalt', canonicalId: 'grillrost_spray', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Trennspray (Backen)', category: 'Haushalt', canonicalId: 'trennspray', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Alkohol (Rum 54%)', category: 'Haushalt', canonicalId: 'rum54', defaultUnit: 'ml'),
    IngredientEntry(name: 'Küchenkrepp (extra stark)', category: 'Haushalt', canonicalId: 'kuechen_extra', defaultUnit: 'Rolle'),
    IngredientEntry(name: 'Gefrierdosen (Set)', category: 'Haushalt', canonicalId: 'gefrierdosen', defaultUnit: 'Set'),
    IngredientEntry(name: 'Vakuumbeutel', category: 'Haushalt', canonicalId: 'vakuumbeutel', defaultUnit: 'Packung'),
    IngredientEntry(name: 'Sous-Vide-Beutel', category: 'Haushalt', canonicalId: 'sous_vide_beutel', defaultUnit: 'Packung'),

    // ──────────────────────────────────────────────────────
    // BABYNAHRUNG & KINDERPRODUKTE
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Hipp Bio-Breikost', category: 'Baby & Kind', canonicalId: 'hipp_brei', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Babybrei (Getreide)', category: 'Baby & Kind', canonicalId: 'baby_brei_getreide', defaultUnit: 'g'),
    IngredientEntry(name: 'Babynahrung (Gemüse)', category: 'Baby & Kind', canonicalId: 'baby_gemuese', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Babynahrung (Obst)', category: 'Baby & Kind', canonicalId: 'baby_obst', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Babymilch Pre', category: 'Baby & Kind', canonicalId: 'babymilch_pre', defaultUnit: 'g'),
    IngredientEntry(name: 'Babymilch Stufe 1', category: 'Baby & Kind', canonicalId: 'babymilch_1', defaultUnit: 'g'),
    IngredientEntry(name: 'Babymilch Stufe 2', category: 'Baby & Kind', canonicalId: 'babymilch_2', defaultUnit: 'g'),
    IngredientEntry(name: 'Kinderkekse', category: 'Baby & Kind', canonicalId: 'kinderkekse', defaultUnit: 'g'),
    IngredientEntry(name: 'Kinderriegel', category: 'Baby & Kind', canonicalId: 'kinderriegel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Trinkbeutel (Frucht)', category: 'Baby & Kind', canonicalId: 'trinkbeutel', defaultUnit: 'Stück'),

    // ──────────────────────────────────────────────────────
    // TIERFUTTER (OFT ZUSAMMEN GEKAUFT)
    // ──────────────────────────────────────────────────────
    IngredientEntry(name: 'Hundefutter (Dose)', category: 'Tierfutter', canonicalId: 'hundefutter_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Hundefutter (trocken)', category: 'Tierfutter', canonicalId: 'hundefutter_trocken', defaultUnit: 'kg'),
    IngredientEntry(name: 'Katzenfutter (Dose)', category: 'Tierfutter', canonicalId: 'katzenfutter_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Katzenfutter (trocken)', category: 'Tierfutter', canonicalId: 'katzenfutter_trocken', defaultUnit: 'kg'),
    IngredientEntry(name: 'Katzensnacks', category: 'Tierfutter', canonicalId: 'katzensnacks', defaultUnit: 'g'),
    IngredientEntry(name: 'Hundeleckerlis', category: 'Tierfutter', canonicalId: 'hundeleckerlis', defaultUnit: 'g'),
    IngredientEntry(name: 'Vogelkörner', category: 'Tierfutter', canonicalId: 'vogelkoerner', defaultUnit: 'g'),
    IngredientEntry(name: 'Kaninchenfutter', category: 'Tierfutter', canonicalId: 'kaninchenfutter', defaultUnit: 'g'),
    IngredientEntry(name: 'Fischfutter', category: 'Tierfutter', canonicalId: 'fischfutter', defaultUnit: 'g'),

    // ══════════════════════════════════════════════════════
    // FISCH – VOLLSTÄNDIG & ALLE VARIANTEN
    // ══════════════════════════════════════════════════════

    // ── FRISCHFISCH (ZUSÄTZLICH) ──────────────────────────
    IngredientEntry(name: 'Barsch (frisch)', category: 'Fleisch & Fisch', canonicalId: 'barsch_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Brasse (frisch)', category: 'Fleisch & Fisch', canonicalId: 'brasse', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Flunder (frisch)', category: 'Fleisch & Fisch', canonicalId: 'flunder', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Seezunge (frisch)', category: 'Fleisch & Fisch', canonicalId: 'seezunge', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Steinbutt (frisch)', category: 'Fleisch & Fisch', canonicalId: 'steinbutt', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rochen (frisch)', category: 'Fleisch & Fisch', canonicalId: 'rochen', defaultUnit: 'g'),
    IngredientEntry(name: 'Aal (frisch)', category: 'Fleisch & Fisch', canonicalId: 'aal_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Wels (frisch)', category: 'Fleisch & Fisch', canonicalId: 'wels', defaultUnit: 'g'),
    IngredientEntry(name: 'Maifisch (frisch)', category: 'Fleisch & Fisch', canonicalId: 'maifisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Stint (frisch)', category: 'Fleisch & Fisch', canonicalId: 'stint', defaultUnit: 'g'),
    IngredientEntry(name: 'Bachsaibling (frisch)', category: 'Fleisch & Fisch', canonicalId: 'saibling', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Renke (frisch)', category: 'Fleisch & Fisch', canonicalId: 'renke', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Schleie (frisch)', category: 'Fleisch & Fisch', canonicalId: 'schleie', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Rutte / Quappe (frisch)', category: 'Fleisch & Fisch', canonicalId: 'rutte', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Goldbrasse (frisch)', category: 'Fleisch & Fisch', canonicalId: 'goldbrasse', defaultUnit: 'Stück', aliases: ['Orata']),
    IngredientEntry(name: 'Meerbarbe (frisch)', category: 'Fleisch & Fisch', canonicalId: 'meerbarbe', defaultUnit: 'Stück', aliases: ['Rouget']),
    IngredientEntry(name: 'Petersfisch (frisch)', category: 'Fleisch & Fisch', canonicalId: 'petersfisch', defaultUnit: 'Stück', aliases: ['John Dory']),
    IngredientEntry(name: 'Seeteufel (Lotte)', category: 'Fleisch & Fisch', canonicalId: 'seeteufel', defaultUnit: 'g', aliases: ['Lotte', 'Monkfish']),
    IngredientEntry(name: 'Knurrhahn (frisch)', category: 'Fleisch & Fisch', canonicalId: 'knurrhahn', defaultUnit: 'Stück', aliases: ['Gurknard']),
    IngredientEntry(name: 'Sägebarsch (frisch)', category: 'Fleisch & Fisch', canonicalId: 'saegebarsch', defaultUnit: 'g', aliases: ['Adlerbarsch']),
    IngredientEntry(name: 'Umberfisch (frisch)', category: 'Fleisch & Fisch', canonicalId: 'umberfisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Rotfeder (frisch)', category: 'Fleisch & Fisch', canonicalId: 'rotfeder', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Äsche (frisch)', category: 'Fleisch & Fisch', canonicalId: 'aesche', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Huchen (frisch)', category: 'Fleisch & Fisch', canonicalId: 'huchen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Nagelrochen (frisch)', category: 'Fleisch & Fisch', canonicalId: 'nagelrochen', defaultUnit: 'g'),

    // ── FISCH TIEFKÜHL ────────────────────────────────────
    IngredientEntry(name: 'Kabeljau (TK)', category: 'Fleisch & Fisch', canonicalId: 'kabeljau_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Seelachs (TK)', category: 'Fleisch & Fisch', canonicalId: 'seelachs_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Heilbutt (TK)', category: 'Fleisch & Fisch', canonicalId: 'heilbutt_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Scholle (TK)', category: 'Tiefkühl', canonicalId: 'scholle_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Seezunge (TK)', category: 'Tiefkühl', canonicalId: 'seezunge_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Steinbutt (TK)', category: 'Tiefkühl', canonicalId: 'steinbutt_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Rotbarsch (TK)', category: 'Tiefkühl', canonicalId: 'rotbarsch_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Forelle (TK)', category: 'Tiefkühl', canonicalId: 'forelle_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Dorade (TK)', category: 'Tiefkühl', canonicalId: 'dorade_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Wolfsbarsch (TK)', category: 'Tiefkühl', canonicalId: 'wolfsbarsch_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Pangasius (TK)', category: 'Tiefkühl', canonicalId: 'pangasius_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Tilapia (TK)', category: 'Tiefkühl', canonicalId: 'tilapia_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Hering (TK)', category: 'Tiefkühl', canonicalId: 'hering_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Makrele (TK)', category: 'Tiefkühl', canonicalId: 'makrele_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Thunfisch (TK, Steak)', category: 'Tiefkühl', canonicalId: 'thunfisch_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Bachsaibling (TK)', category: 'Tiefkühl', canonicalId: 'saibling_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fischfilet (Mix, TK)', category: 'Tiefkühl', canonicalId: 'fischfilet_mix_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Fischbällchen (TK)', category: 'Tiefkühl', canonicalId: 'fischbaellchen_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fischburger (TK)', category: 'Tiefkühl', canonicalId: 'fischburger_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fischpäckchen (TK)', category: 'Tiefkühl', canonicalId: 'fischpaeckchen_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Seeteufelmedaillons (TK)', category: 'Tiefkühl', canonicalId: 'seeteufel_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Thunfischburger (TK)', category: 'Tiefkühl', canonicalId: 'thunburger_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Lachsscheiben (TK)', category: 'Tiefkühl', canonicalId: 'lachs_scheiben_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Lachsburger (TK)', category: 'Tiefkühl', canonicalId: 'lachs_burger_tk', defaultUnit: 'Stück'),

    // ── MEERESFRÜCHTE TIEFKÜHL ────────────────────────────
    IngredientEntry(name: 'Garnelen (roh, TK)', category: 'Tiefkühl', canonicalId: 'garnelen_roh_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Garnelen (gegart, TK)', category: 'Tiefkühl', canonicalId: 'garnelen_gegart_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Garnelen (gepellt, TK)', category: 'Tiefkühl', canonicalId: 'garnelen_gepellt_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Riesengarnelen (TK)', category: 'Tiefkühl', canonicalId: 'riesengarnelen_tk', defaultUnit: 'Stück', aliases: ['King Prawns TK']),
    IngredientEntry(name: 'Jakobsmuscheln (TK)', category: 'Tiefkühl', canonicalId: 'jakobsmuscheln_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Muscheln (TK)', category: 'Tiefkühl', canonicalId: 'muscheln_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Tintenfischringe (TK)', category: 'Tiefkühl', canonicalId: 'tintenfisch_ringe_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Oktopus (TK)', category: 'Tiefkühl', canonicalId: 'oktopus_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Krabben (TK)', category: 'Tiefkühl', canonicalId: 'krabben_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Langostinos (TK)', category: 'Tiefkühl', canonicalId: 'langostinos_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Hummer (halb, TK)', category: 'Tiefkühl', canonicalId: 'hummer_halb_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Meeresfrüchte (Paella-Mix, TK)', category: 'Tiefkühl', canonicalId: 'paella_mix_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Meeresfrüchte (Wok-Mix, TK)', category: 'Tiefkühl', canonicalId: 'wok_mix_tk', defaultUnit: 'g'),

    // ── GERÄUCHERTER FISCH ────────────────────────────────
    IngredientEntry(name: 'Räucheraal', category: 'Fleisch & Fisch', canonicalId: 'aal_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Räuchermakrele (Filet)', category: 'Fleisch & Fisch', canonicalId: 'makrele_raeuch_filet', defaultUnit: 'g'),
    IngredientEntry(name: 'Räuchersprot', category: 'Fleisch & Fisch', canonicalId: 'sprot_raeuch', defaultUnit: 'g', aliases: ['Kieler Sprot']),
    IngredientEntry(name: 'Räucherhering', category: 'Fleisch & Fisch', canonicalId: 'hering_raeuch', defaultUnit: 'g', aliases: ['Bückling']),
    IngredientEntry(name: 'Bückling', category: 'Fleisch & Fisch', canonicalId: 'buckling', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Räucherkabeljau', category: 'Fleisch & Fisch', canonicalId: 'kabeljau_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Räucher-Rotbarsch', category: 'Fleisch & Fisch', canonicalId: 'rotbarsch_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Räuchersaibling', category: 'Fleisch & Fisch', canonicalId: 'saibling_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Räuchertintenfisch', category: 'Fleisch & Fisch', canonicalId: 'tintenfisch_raeuch', defaultUnit: 'g'),
    IngredientEntry(name: 'Cold-Smoked Lachs', category: 'Fleisch & Fisch', canonicalId: 'lachs_cold_smoked', defaultUnit: 'g'),
    IngredientEntry(name: 'Hot-Smoked Lachs', category: 'Fleisch & Fisch', canonicalId: 'lachs_hot_smoked', defaultUnit: 'g'),
    IngredientEntry(name: 'Räucherlachs (Scheiben)', category: 'Fleisch & Fisch', canonicalId: 'lachs_raeuch_scheiben', defaultUnit: 'g'),
    IngredientEntry(name: 'Haddock (geräuchert)', category: 'Fleisch & Fisch', canonicalId: 'haddock_raeuch', defaultUnit: 'g', aliases: ['Schellfisch geräuchert']),
    IngredientEntry(name: 'Kipper (ganzer Hering)', category: 'Fleisch & Fisch', canonicalId: 'kipper', defaultUnit: 'Stück'),

    // ── GETROCKNETER FISCH ────────────────────────────────
    IngredientEntry(name: 'Stockfisch (trocken)', category: 'Fleisch & Fisch', canonicalId: 'stockfisch', defaultUnit: 'g', aliases: ['Klippfisch', 'Dried Cod']),
    IngredientEntry(name: 'Klippfisch', category: 'Fleisch & Fisch', canonicalId: 'klippfisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Bombil (getrockneter Bombay Duck)', category: 'Fleisch & Fisch', canonicalId: 'bombil', defaultUnit: 'g'),
    IngredientEntry(name: 'Ikan Bilis (getrocknete Sardellen)', category: 'Fleisch & Fisch', canonicalId: 'ikan_bilis', defaultUnit: 'g'),
    IngredientEntry(name: 'Dried Shrimp (getrocknete Garnelen)', category: 'Fleisch & Fisch', canonicalId: 'dried_shrimp', defaultUnit: 'g', aliases: ['Getrocknete Garnelen']),
    IngredientEntry(name: 'Dried Squid (getrockneter Tintenfisch)', category: 'Fleisch & Fisch', canonicalId: 'dried_squid', defaultUnit: 'g'),
    IngredientEntry(name: 'Katsuobushi (Bonito, getrocknet)', category: 'Fleisch & Fisch', canonicalId: 'bonito_trocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Niboshi (getrocknete Sardine)', category: 'Fleisch & Fisch', canonicalId: 'niboshi', defaultUnit: 'g'),
    IngredientEntry(name: 'Sakura Ebi (getrocknete Garnelen, JP)', category: 'Fleisch & Fisch', canonicalId: 'sakura_ebi', defaultUnit: 'g'),
    IngredientEntry(name: 'Trockenfisch-Mix (Suppe)', category: 'Fleisch & Fisch', canonicalId: 'trockenfisch_mix', defaultUnit: 'g'),

    // ── FISCH IN DOSEN & GLÄSERN ──────────────────────────
    IngredientEntry(name: 'Thunfisch (Dose, Öl)', category: 'Konserven', canonicalId: 'thunfisch_dose_oel', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Thunfisch (Dose, Wasser)', category: 'Konserven', canonicalId: 'thunfisch_dose_wasser', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Thunfisch (Glas, Stücke)', category: 'Konserven', canonicalId: 'thunfisch_glas', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Sardinen (in Öl)', category: 'Konserven', canonicalId: 'sardinen_oel', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sardinen (in Tomatensauce)', category: 'Konserven', canonicalId: 'sardinen_tomaten', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sardinen (in Senfsauce)', category: 'Konserven', canonicalId: 'sardinen_senf', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sardellen (in Öl)', category: 'Konserven', canonicalId: 'sardellen_oel', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sardellen (in Salz)', category: 'Konserven', canonicalId: 'sardellen_salz', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Makrele (in Öl)', category: 'Konserven', canonicalId: 'makrele_oel', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Makrele (in Tomatensauce)', category: 'Konserven', canonicalId: 'makrele_tomaten', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Makrele (in Senfsauce)', category: 'Konserven', canonicalId: 'makrele_senf', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Hering (Sahnehering)', category: 'Konserven', canonicalId: 'hering_sahne', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Hering (Rollmops)', category: 'Konserven', canonicalId: 'hering_rollmops', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Hering (in Weinsoße)', category: 'Konserven', canonicalId: 'hering_weinsosse', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Hering (Hausfrauenart)', category: 'Konserven', canonicalId: 'hering_hausfr', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Hering (Brathering)', category: 'Konserven', canonicalId: 'hering_brat', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Lachs (Glas, geräuchert)', category: 'Konserven', canonicalId: 'lachs_glas_raeuch', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Kabeljau (Dose)', category: 'Konserven', canonicalId: 'kabeljau_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Rotbarsch (Dose)', category: 'Konserven', canonicalId: 'rotbarsch_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Sprotten (Dose)', category: 'Konserven', canonicalId: 'sprotten_dose', defaultUnit: 'Dose', aliases: ['Kieler Sprotten', 'Sprats']),
    IngredientEntry(name: 'Sprotten (geräuchert, Dose)', category: 'Konserven', canonicalId: 'sprotten_raeuch_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Krabben (Dose)', category: 'Konserven', canonicalId: 'krabben_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Tintenfisch (Dose)', category: 'Konserven', canonicalId: 'tintenfisch_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Muscheln (Dose, geräuchert)', category: 'Konserven', canonicalId: 'muscheln_raeuch_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Muscheln (Dose, in Knoblauch)', category: 'Konserven', canonicalId: 'muscheln_knoblauch_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Hummer (Dose)', category: 'Konserven', canonicalId: 'hummer_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Jakobsmuscheln (Dose)', category: 'Konserven', canonicalId: 'jakobs_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Anchovis (Tube)', category: 'Konserven', canonicalId: 'anchovis_tube', defaultUnit: 'g'),
    IngredientEntry(name: 'Fischpaste', category: 'Konserven', canonicalId: 'fischpaste', defaultUnit: 'g'),
    IngredientEntry(name: 'Krabbenpaste', category: 'Konserven', canonicalId: 'krabbenpaste', defaultUnit: 'g'),

    // ── MEERESFRÜCHTE FRISCH & KONSERVEN ──────────────────
    IngredientEntry(name: 'Venusmuscheln (frisch)', category: 'Fleisch & Fisch', canonicalId: 'venusmuscheln', defaultUnit: 'g', aliases: ['Vongole', 'Clams']),
    IngredientEntry(name: 'Miesmuscheln (frisch)', category: 'Fleisch & Fisch', canonicalId: 'miesmuscheln_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Herzmuscheln (frisch)', category: 'Fleisch & Fisch', canonicalId: 'herzmuscheln', defaultUnit: 'g'),
    IngredientEntry(name: 'Stockmuscheln (frisch)', category: 'Fleisch & Fisch', canonicalId: 'stockmuscheln', defaultUnit: 'g', aliases: ['Razor Clams']),
    IngredientEntry(name: 'Weinbergschnecken (Dose)', category: 'Konserven', canonicalId: 'weinbergschnecken', defaultUnit: 'Dose', aliases: ['Escargots']),
    IngredientEntry(name: 'Krabbenstäbchen (Surimi)', category: 'Fleisch & Fisch', canonicalId: 'surimi', defaultUnit: 'g', aliases: ['Surimi', 'Krebsfleischimitat']),
    IngredientEntry(name: 'Meeresfrüchte-Salat (Dose)', category: 'Konserven', canonicalId: 'meeresfruechte_salat', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Riesengarnelen (frisch)', category: 'Fleisch & Fisch', canonicalId: 'riesengarnelen_frisch', defaultUnit: 'Stück', aliases: ['King Prawns', 'Jumbo Shrimp']),
    IngredientEntry(name: 'Tigergarnelen (frisch)', category: 'Fleisch & Fisch', canonicalId: 'tigergarnelen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Black Tiger Prawns (TK)', category: 'Tiefkühl', canonicalId: 'black_tiger_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Scampi (frisch)', category: 'Fleisch & Fisch', canonicalId: 'scampi_frisch', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Scampi (TK)', category: 'Tiefkühl', canonicalId: 'scampi_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Froschschenkel (TK)', category: 'Tiefkühl', canonicalId: 'froschschenkel_tk', defaultUnit: 'Paar'),

    // ── FISCH-VERARBEITUNGSPRODUKTE ───────────────────────
    IngredientEntry(name: 'Fischfilet (paniert, TK)', category: 'Tiefkühl', canonicalId: 'fischfilet_paniert_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fischstäbchen (Mini, TK)', category: 'Tiefkühl', canonicalId: 'fischstaebchen_mini_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fish & Chips Mix (TK)', category: 'Tiefkühl', canonicalId: 'fish_chips_tk', defaultUnit: 'g'),
    IngredientEntry(name: 'Fischknusper (TK)', category: 'Tiefkühl', canonicalId: 'fischknusper_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fischnuggets (TK)', category: 'Tiefkühl', canonicalId: 'fischnuggets_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fischfrikadellen (TK)', category: 'Tiefkühl', canonicalId: 'fischfrikadellen_tk', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Lachstatar (frisch)', category: 'Fleisch & Fisch', canonicalId: 'lachstatar', defaultUnit: 'g'),
    IngredientEntry(name: 'Thunfischtatar (frisch)', category: 'Fleisch & Fisch', canonicalId: 'thunfischtatar', defaultUnit: 'g'),
    IngredientEntry(name: 'Fischsauce (fermentiert)', category: 'Fleisch & Fisch', canonicalId: 'fischsauce_ferm', defaultUnit: 'ml'),
    IngredientEntry(name: 'Lachscreme (Aufstrich)', category: 'Fertigprodukte', canonicalId: 'lachscreme', defaultUnit: 'g'),
    IngredientEntry(name: 'Forellencreme (Aufstrich)', category: 'Fertigprodukte', canonicalId: 'forellencreme', defaultUnit: 'g'),
    IngredientEntry(name: 'Krabbencreme (Aufstrich)', category: 'Fertigprodukte', canonicalId: 'krabbencreme', defaultUnit: 'g'),
    IngredientEntry(name: 'Räucherlachs-Creme', category: 'Fertigprodukte', canonicalId: 'raeuchlachs_creme', defaultUnit: 'g'),

    // ── KAVIAR & ROGEN ────────────────────────────────────
    IngredientEntry(name: 'Kaviar (Beluga)', category: 'Fleisch & Fisch', canonicalId: 'kaviar_beluga', defaultUnit: 'g'),
    IngredientEntry(name: 'Kaviar (Sevruga)', category: 'Fleisch & Fisch', canonicalId: 'kaviar_sevruga', defaultUnit: 'g'),
    IngredientEntry(name: 'Kaviar (Osietra)', category: 'Fleisch & Fisch', canonicalId: 'kaviar_osietra', defaultUnit: 'g'),
    IngredientEntry(name: 'Forellen-Kaviar', category: 'Fleisch & Fisch', canonicalId: 'kaviar_forelle', defaultUnit: 'g'),
    IngredientEntry(name: 'Lumpfisch-Kaviar (rot)', category: 'Konserven', canonicalId: 'lumpfisch_rot', defaultUnit: 'g'),
    IngredientEntry(name: 'Lumpfisch-Kaviar (schwarz)', category: 'Konserven', canonicalId: 'lumpfisch_schwarz', defaultUnit: 'g'),
    IngredientEntry(name: 'Seehasen-Kaviar', category: 'Konserven', canonicalId: 'seehasen_kaviar', defaultUnit: 'g'),
    IngredientEntry(name: 'Tobiko (Fliegenfischrogen)', category: 'Asiatisch', canonicalId: 'tobiko', defaultUnit: 'g'),
    IngredientEntry(name: 'Masago (Capelin-Rogen)', category: 'Asiatisch', canonicalId: 'masago', defaultUnit: 'g'),

    // ══════════════════════════════════════════════════════
    // ALKOHOL – VOLLSTÄNDIG
    // ══════════════════════════════════════════════════════

    // ── BIER ──────────────────────────────────────────────
    IngredientEntry(name: 'Pils (Dose)', category: 'Alkohol', canonicalId: 'bier_pils_dose', defaultUnit: 'Dose', aliases: ['Pilsner']),
    IngredientEntry(name: 'Pils (Flasche)', category: 'Alkohol', canonicalId: 'bier_pils_fl', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Helles (Flasche)', category: 'Alkohol', canonicalId: 'bier_helles', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Weizenbier', category: 'Alkohol', canonicalId: 'weizenbier', defaultUnit: 'Flasche', aliases: ['Weißbier', 'Hefeweizen']),
    IngredientEntry(name: 'Weizenbier (dunkel)', category: 'Alkohol', canonicalId: 'weizenbier_dunkel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Dunkel (Bier)', category: 'Alkohol', canonicalId: 'bier_dunkel', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Märzen', category: 'Alkohol', canonicalId: 'maerzen', defaultUnit: 'Flasche', aliases: ['Oktoberfestbier']),
    IngredientEntry(name: 'Kölsch', category: 'Alkohol', canonicalId: 'koelsch', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Alt (Düsseldorfer)', category: 'Alkohol', canonicalId: 'altbier', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Rauchbier', category: 'Alkohol', canonicalId: 'rauchbier', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Bockbier', category: 'Alkohol', canonicalId: 'bockbier', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Doppelbock', category: 'Alkohol', canonicalId: 'doppelbock', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Schwarzbier', category: 'Alkohol', canonicalId: 'schwarzbier', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Stout', category: 'Alkohol', canonicalId: 'stout', defaultUnit: 'Dose', aliases: ['Porter']),
    IngredientEntry(name: 'IPA (India Pale Ale)', category: 'Alkohol', canonicalId: 'ipa', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Pale Ale', category: 'Alkohol', canonicalId: 'pale_ale', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Craft Beer (Mix)', category: 'Alkohol', canonicalId: 'craft_beer', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Radler', category: 'Alkohol', canonicalId: 'radler', defaultUnit: 'Dose', aliases: ['Shandy']),
    IngredientEntry(name: 'Alkoholfreies Bier', category: 'Alkohol', canonicalId: 'bier_alkfrei', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Malzbier', category: 'Alkohol', canonicalId: 'malzbier', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Biermischgetränk (Cola)', category: 'Alkohol', canonicalId: 'bier_cola', defaultUnit: 'Dose', aliases: ['Diesel', 'Dreckiges']),

    // ── WEIN ──────────────────────────────────────────────
    IngredientEntry(name: 'Rotwein (trocken)', category: 'Alkohol', canonicalId: 'rotwein_trocken', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Rotwein (halbtrocken)', category: 'Alkohol', canonicalId: 'rotwein_halb', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Rotwein (lieblich)', category: 'Alkohol', canonicalId: 'rotwein_lieblich', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Weißwein (trocken)', category: 'Alkohol', canonicalId: 'weisswein_trocken', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Weißwein (halbtrocken)', category: 'Alkohol', canonicalId: 'weisswein_halb', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Weißwein (lieblich)', category: 'Alkohol', canonicalId: 'weisswein_lieblich', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Roséwein (trocken)', category: 'Alkohol', canonicalId: 'rose_trocken', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Roséwein (lieblich)', category: 'Alkohol', canonicalId: 'rose_lieblich', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Sekt (brut)', category: 'Alkohol', canonicalId: 'sekt_brut', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Sekt (halbtrocken)', category: 'Alkohol', canonicalId: 'sekt_halb', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Champagner', category: 'Alkohol', canonicalId: 'champagner', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Prosecco (Flasche)', category: 'Alkohol', canonicalId: 'prosecco_fl', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Cava', category: 'Alkohol', canonicalId: 'cava', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Riesling', category: 'Alkohol', canonicalId: 'riesling', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Grauburgunder', category: 'Alkohol', canonicalId: 'grauburgunder', defaultUnit: 'Flasche', aliases: ['Pinot Grigio']),
    IngredientEntry(name: 'Weißburgunder', category: 'Alkohol', canonicalId: 'weissburgunder', defaultUnit: 'Flasche', aliases: ['Pinot Blanc']),
    IngredientEntry(name: 'Sauvignon Blanc', category: 'Alkohol', canonicalId: 'sauvignon_blanc', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Chardonnay', category: 'Alkohol', canonicalId: 'chardonnay', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Spätburgunder', category: 'Alkohol', canonicalId: 'spaetburgunder', defaultUnit: 'Flasche', aliases: ['Pinot Noir']),
    IngredientEntry(name: 'Cabernet Sauvignon', category: 'Alkohol', canonicalId: 'cab_sauv', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Merlot', category: 'Alkohol', canonicalId: 'merlot', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Malbec', category: 'Alkohol', canonicalId: 'malbec', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Shiraz / Syrah', category: 'Alkohol', canonicalId: 'shiraz', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Tempranillo', category: 'Alkohol', canonicalId: 'tempranillo', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Sangiovese', category: 'Alkohol', canonicalId: 'sangiovese', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Primitivo', category: 'Alkohol', canonicalId: 'primitivo', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Barolo', category: 'Alkohol', canonicalId: 'barolo', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Brunello di Montalcino', category: 'Alkohol', canonicalId: 'brunello', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Bordeaux (rot)', category: 'Alkohol', canonicalId: 'bordeaux_rot', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Burgundy (Rotwein)', category: 'Alkohol', canonicalId: 'burgundy', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Rioja', category: 'Alkohol', canonicalId: 'rioja', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Chianti', category: 'Alkohol', canonicalId: 'chianti', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Vinho Verde', category: 'Alkohol', canonicalId: 'vinho_verde', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Gewürztraminer', category: 'Alkohol', canonicalId: 'gewuerztraminer', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Wein (Bag-in-Box)', category: 'Alkohol', canonicalId: 'bag_in_box', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Alkoholfreier Wein', category: 'Alkohol', canonicalId: 'wein_alkfrei', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Glühwein', category: 'Alkohol', canonicalId: 'gluehwein', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Glühwein (alkoholfrei)', category: 'Alkohol', canonicalId: 'gluehwein_alkfrei', defaultUnit: 'Flasche'),

    // ── SPIRITUOSEN: WHISKY / WHISKEY ─────────────────────
    IngredientEntry(name: 'Scotch Whisky', category: 'Alkohol', canonicalId: 'scotch', defaultUnit: 'ml'),
    IngredientEntry(name: 'Single Malt (Scotch)', category: 'Alkohol', canonicalId: 'single_malt', defaultUnit: 'ml'),
    IngredientEntry(name: 'Blended Scotch', category: 'Alkohol', canonicalId: 'blended_scotch', defaultUnit: 'ml'),
    IngredientEntry(name: 'Islay Whisky', category: 'Alkohol', canonicalId: 'islay', defaultUnit: 'ml'),
    IngredientEntry(name: 'Irish Whiskey', category: 'Alkohol', canonicalId: 'irish_whiskey', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bourbon', category: 'Alkohol', canonicalId: 'bourbon', defaultUnit: 'ml'),
    IngredientEntry(name: 'Tennessee Whiskey', category: 'Alkohol', canonicalId: 'tennessee', defaultUnit: 'ml'),
    IngredientEntry(name: 'Rye Whiskey', category: 'Alkohol', canonicalId: 'rye_whiskey', defaultUnit: 'ml'),
    IngredientEntry(name: 'Japanese Whisky', category: 'Alkohol', canonicalId: 'jap_whisky', defaultUnit: 'ml'),
    IngredientEntry(name: 'Canadian Whisky', category: 'Alkohol', canonicalId: 'can_whisky', defaultUnit: 'ml'),

    // ── SPIRITUOSEN: GIN ──────────────────────────────────
    IngredientEntry(name: 'London Dry Gin', category: 'Alkohol', canonicalId: 'gin_london_dry', defaultUnit: 'ml'),
    IngredientEntry(name: 'New Western Gin', category: 'Alkohol', canonicalId: 'gin_new_west', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sloe Gin', category: 'Alkohol', canonicalId: 'sloe_gin', defaultUnit: 'ml'),
    IngredientEntry(name: 'Navy Strength Gin', category: 'Alkohol', canonicalId: 'navy_gin', defaultUnit: 'ml'),
    IngredientEntry(name: 'Pink Gin', category: 'Alkohol', canonicalId: 'pink_gin', defaultUnit: 'ml'),
    IngredientEntry(name: 'Genever', category: 'Alkohol', canonicalId: 'genever', defaultUnit: 'ml'),

    // ── SPIRITUOSEN: RUM ──────────────────────────────────
    IngredientEntry(name: 'Weißer Rum', category: 'Alkohol', canonicalId: 'rum_weiss', defaultUnit: 'ml'),
    IngredientEntry(name: 'Brauner Rum', category: 'Alkohol', canonicalId: 'rum_braun', defaultUnit: 'ml'),
    IngredientEntry(name: 'Dunkler Rum', category: 'Alkohol', canonicalId: 'rum_dunkel', defaultUnit: 'ml'),
    IngredientEntry(name: 'Spiced Rum', category: 'Alkohol', canonicalId: 'rum_spiced', defaultUnit: 'ml'),
    IngredientEntry(name: 'Rum (Overproof)', category: 'Alkohol', canonicalId: 'rum_overproof', defaultUnit: 'ml'),
    IngredientEntry(name: 'Cachaça', category: 'Alkohol', canonicalId: 'cachaca', defaultUnit: 'ml'),
    IngredientEntry(name: 'Batida (Cachaça-Mix)', category: 'Alkohol', canonicalId: 'batida', defaultUnit: 'ml'),

    // ── SPIRITUOSEN: VODKA ────────────────────────────────
    IngredientEntry(name: 'Vodka (klar)', category: 'Alkohol', canonicalId: 'vodka_klar', defaultUnit: 'ml'),
    IngredientEntry(name: 'Vodka (Zitrus)', category: 'Alkohol', canonicalId: 'vodka_zitrus', defaultUnit: 'ml'),
    IngredientEntry(name: 'Vodka (Vanille)', category: 'Alkohol', canonicalId: 'vodka_vanille', defaultUnit: 'ml'),
    IngredientEntry(name: 'Potato Vodka', category: 'Alkohol', canonicalId: 'vodka_potato', defaultUnit: 'ml'),

    // ── SPIRITUOSEN: TEQUILA / MEZCAL ─────────────────────
    IngredientEntry(name: 'Blanco Tequila', category: 'Alkohol', canonicalId: 'tequila_blanco', defaultUnit: 'ml'),
    IngredientEntry(name: 'Reposado Tequila', category: 'Alkohol', canonicalId: 'tequila_reposado', defaultUnit: 'ml'),
    IngredientEntry(name: 'Añejo Tequila', category: 'Alkohol', canonicalId: 'tequila_anejo', defaultUnit: 'ml'),
    IngredientEntry(name: 'Mezcal (smoky)', category: 'Alkohol', canonicalId: 'mezcal_smoky', defaultUnit: 'ml'),

    // ── SPIRITUOSEN: COGNAC / BRANDY ──────────────────────
    IngredientEntry(name: 'VS Cognac', category: 'Alkohol', canonicalId: 'cognac_vs', defaultUnit: 'ml'),
    IngredientEntry(name: 'VSOP Cognac', category: 'Alkohol', canonicalId: 'cognac_vsop', defaultUnit: 'ml'),
    IngredientEntry(name: 'XO Cognac', category: 'Alkohol', canonicalId: 'cognac_xo', defaultUnit: 'ml'),
    IngredientEntry(name: 'Weinbrand', category: 'Alkohol', canonicalId: 'weinbrand', defaultUnit: 'ml'),
    IngredientEntry(name: 'Obstbrand', category: 'Alkohol', canonicalId: 'obstbrand', defaultUnit: 'ml'),
    IngredientEntry(name: 'Zwetschgenbrand', category: 'Alkohol', canonicalId: 'zwetschgen_brand', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kirschwasser', category: 'Alkohol', canonicalId: 'kirschwasser', defaultUnit: 'ml'),
    IngredientEntry(name: 'Mirabellenschnaps', category: 'Alkohol', canonicalId: 'mirabelle_schnaps', defaultUnit: 'ml'),
    IngredientEntry(name: 'Birnenbrand (Williams)', category: 'Alkohol', canonicalId: 'williams', defaultUnit: 'ml'),
    IngredientEntry(name: 'Himbeergeist', category: 'Alkohol', canonicalId: 'himbeergeist', defaultUnit: 'ml'),

    // ── SPIRITUOSEN: DIVERSE ──────────────────────────────
    IngredientEntry(name: 'Korn (Doppelkorn)', category: 'Alkohol', canonicalId: 'korn', defaultUnit: 'ml'),
    IngredientEntry(name: 'Klarer Schnaps', category: 'Alkohol', canonicalId: 'klarer', defaultUnit: 'ml'),
    IngredientEntry(name: 'Jägermeister', category: 'Alkohol', canonicalId: 'jaegermeister', defaultUnit: 'ml'),
    IngredientEntry(name: 'Underberg', category: 'Alkohol', canonicalId: 'underberg', defaultUnit: 'ml'),
    IngredientEntry(name: 'Fernet Branca', category: 'Alkohol', canonicalId: 'fernet', defaultUnit: 'ml'),
    IngredientEntry(name: 'Cynar', category: 'Alkohol', canonicalId: 'cynar', defaultUnit: 'ml'),
    IngredientEntry(name: 'Pernod', category: 'Alkohol', canonicalId: 'pernod', defaultUnit: 'ml'),
    IngredientEntry(name: 'Pastis', category: 'Alkohol', canonicalId: 'pastis', defaultUnit: 'ml'),
    IngredientEntry(name: 'Absinth', category: 'Alkohol', canonicalId: 'absinth', defaultUnit: 'ml'),
    IngredientEntry(name: 'Chartreuse (grün)', category: 'Alkohol', canonicalId: 'chartreuse_gruen', defaultUnit: 'ml'),
    IngredientEntry(name: 'Chartreuse (gelb)', category: 'Alkohol', canonicalId: 'chartreuse_gelb', defaultUnit: 'ml'),
    IngredientEntry(name: 'Bénédictine', category: 'Alkohol', canonicalId: 'benedictine', defaultUnit: 'ml'),
    IngredientEntry(name: 'Drambuie', category: 'Alkohol', canonicalId: 'drambuie', defaultUnit: 'ml'),
    IngredientEntry(name: 'Frangelico', category: 'Alkohol', canonicalId: 'frangelico', defaultUnit: 'ml'),
    IngredientEntry(name: 'Midori', category: 'Alkohol', canonicalId: 'midori', defaultUnit: 'ml'),
    IngredientEntry(name: 'Blue Curaçao', category: 'Alkohol', canonicalId: 'blue_curacao', defaultUnit: 'ml'),
    IngredientEntry(name: 'Peach Schnapps', category: 'Alkohol', canonicalId: 'peach_schnapps', defaultUnit: 'ml'),
    IngredientEntry(name: 'Elderflower Liqueur', category: 'Alkohol', canonicalId: 'elderflower_liqueur', defaultUnit: 'ml', aliases: ['Holunderblütenlikör']),
    IngredientEntry(name: 'St-Germain', category: 'Alkohol', canonicalId: 'st_germain', defaultUnit: 'ml'),
    IngredientEntry(name: 'Maraschino Liqueur', category: 'Alkohol', canonicalId: 'maraschino', defaultUnit: 'ml'),
    IngredientEntry(name: 'Crème de Menthe', category: 'Alkohol', canonicalId: 'creme_menthe', defaultUnit: 'ml'),
    IngredientEntry(name: 'Crème de Cacao', category: 'Alkohol', canonicalId: 'creme_cacao', defaultUnit: 'ml'),
    IngredientEntry(name: 'Crème de Violette', category: 'Alkohol', canonicalId: 'creme_violette', defaultUnit: 'ml'),
    IngredientEntry(name: 'Absinthe Verte', category: 'Alkohol', canonicalId: 'absinthe_verte', defaultUnit: 'ml'),
    IngredientEntry(name: 'Schnapsglas-Set', category: 'Alkohol', canonicalId: 'schnapsglas', defaultUnit: 'Stück'),

    // ── WEIN-COCKTAIL-ZUTATEN ─────────────────────────────
    IngredientEntry(name: 'Aperol Spritz Set', category: 'Alkohol', canonicalId: 'aperol_set', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Hugo Basis (Holunder)', category: 'Alkohol', canonicalId: 'hugo_basis', defaultUnit: 'ml'),
    IngredientEntry(name: 'Sangria-Basis', category: 'Alkohol', canonicalId: 'sangria_basis', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Weinschorle-Mix', category: 'Alkohol', canonicalId: 'weinschorle', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Bitter (Cocktail)', category: 'Alkohol', canonicalId: 'cocktail_bitter', defaultUnit: 'ml', aliases: ['Angostura']),
    IngredientEntry(name: 'Peychaud\'s Bitters', category: 'Alkohol', canonicalId: 'peychauds', defaultUnit: 'ml'),
    IngredientEntry(name: 'Orange Bitters', category: 'Alkohol', canonicalId: 'orange_bitters', defaultUnit: 'ml'),

    // ══════════════════════════════════════════════════════
    // SPORTLERERNÄHRUNG & FITNESS
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Proteinshake (Vanille)', category: 'Sport & Fitness', canonicalId: 'protein_vanille', defaultUnit: 'g'),
    IngredientEntry(name: 'Proteinshake (Schokolade)', category: 'Sport & Fitness', canonicalId: 'protein_schoko', defaultUnit: 'g'),
    IngredientEntry(name: 'Proteinriegel', category: 'Sport & Fitness', canonicalId: 'protein_riegel', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Creatin Monohydrat', category: 'Sport & Fitness', canonicalId: 'creatin', defaultUnit: 'g'),
    IngredientEntry(name: 'BCAA Pulver', category: 'Sport & Fitness', canonicalId: 'bcaa', defaultUnit: 'g'),
    IngredientEntry(name: 'Pre-Workout', category: 'Sport & Fitness', canonicalId: 'pre_workout', defaultUnit: 'g'),
    IngredientEntry(name: 'Iso-Drink Pulver', category: 'Sport & Fitness', canonicalId: 'iso_drink', defaultUnit: 'g'),
    IngredientEntry(name: 'Sportgetränk (fertig)', category: 'Sport & Fitness', canonicalId: 'sport_drink', defaultUnit: 'Flasche'),
    IngredientEntry(name: 'Rote-Beete-Saft (Sport)', category: 'Sport & Fitness', canonicalId: 'rote_bete_saft', defaultUnit: 'ml'),
    IngredientEntry(name: 'Magnesium (Brausetablette)', category: 'Sport & Fitness', canonicalId: 'magnesium_brause', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Elektrolyt-Tabs', category: 'Sport & Fitness', canonicalId: 'elektrolyt', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Chia-Energie-Gel', category: 'Sport & Fitness', canonicalId: 'chia_gel', defaultUnit: 'g'),
    IngredientEntry(name: 'Traubenzucker', category: 'Sport & Fitness', canonicalId: 'traubenzucker', defaultUnit: 'g'),
    IngredientEntry(name: 'Energy Bar (Nuss)', category: 'Sport & Fitness', canonicalId: 'energy_bar', defaultUnit: 'Stück'),

    // ══════════════════════════════════════════════════════
    // GLUTENFREI / ALLERGIKERPRODUKTE
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Glutenfreies Brot', category: 'Glutenfrei', canonicalId: 'gf_brot', defaultUnit: 'Scheibe'),
    IngredientEntry(name: 'Glutenfreie Nudeln', category: 'Glutenfrei', canonicalId: 'gf_nudeln', defaultUnit: 'g'),
    IngredientEntry(name: 'Glutenfreies Mehl (Mix)', category: 'Glutenfrei', canonicalId: 'gf_mehl_mix', defaultUnit: 'g'),
    IngredientEntry(name: 'Glutenfreies Backpulver', category: 'Glutenfrei', canonicalId: 'gf_backpulver', defaultUnit: 'g'),
    IngredientEntry(name: 'Glutenfreie Haferflocken', category: 'Glutenfrei', canonicalId: 'gf_haferflocken', defaultUnit: 'g'),
    IngredientEntry(name: 'Glutenfreie Cornflakes', category: 'Glutenfrei', canonicalId: 'gf_cornflakes', defaultUnit: 'g'),
    IngredientEntry(name: 'Maismehl (glutenfrei)', category: 'Glutenfrei', canonicalId: 'gf_maismehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Tapioka-Mehl', category: 'Glutenfrei', canonicalId: 'gf_tapioka', defaultUnit: 'g'),
    IngredientEntry(name: 'Pfeilwurzelmehl', category: 'Glutenfrei', canonicalId: 'gf_pfeilwurzel', defaultUnit: 'g'),
    IngredientEntry(name: 'Sorghummehl', category: 'Glutenfrei', canonicalId: 'sorghum', defaultUnit: 'g'),

    // ══════════════════════════════════════════════════════
    // INTERNATIONALE SAUCEN & DIPS (ZUSÄTZLICH)
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Tzatziki (griechisch)', category: 'Mediterran', canonicalId: 'tzatziki_gr', defaultUnit: 'g'),
    IngredientEntry(name: 'Cacik (türkisch)', category: 'Mediterran', canonicalId: 'cacik', defaultUnit: 'g'),
    IngredientEntry(name: 'Raita (indisch)', category: 'Mediterran', canonicalId: 'raita', defaultUnit: 'g'),
    IngredientEntry(name: 'Mango Lassi', category: 'Getränke', canonicalId: 'mango_lassi', defaultUnit: 'ml'),
    IngredientEntry(name: 'Salsa Verde', category: 'Mexikanisch', canonicalId: 'salsa_verde', defaultUnit: 'g'),
    IngredientEntry(name: 'Salsa Roja', category: 'Mexikanisch', canonicalId: 'salsa_roja', defaultUnit: 'g'),
    IngredientEntry(name: 'Pico de Gallo', category: 'Mexikanisch', canonicalId: 'pico_de_gallo', defaultUnit: 'g'),
    IngredientEntry(name: 'Mole Negro', category: 'Mexikanisch', canonicalId: 'mole_negro', defaultUnit: 'g'),
    IngredientEntry(name: 'Mole Rojo', category: 'Mexikanisch', canonicalId: 'mole_rojo', defaultUnit: 'g'),
    IngredientEntry(name: 'Green Goddess Dressing', category: 'Öle & Essig', canonicalId: 'green_goddess', defaultUnit: 'EL'),
    IngredientEntry(name: 'Caesar Dressing', category: 'Öle & Essig', canonicalId: 'caesar_dressing', defaultUnit: 'EL'),
    IngredientEntry(name: 'Tahini-Dressing', category: 'Öle & Essig', canonicalId: 'tahini_dressing', defaultUnit: 'EL'),
    IngredientEntry(name: 'Yuzu-Ponzu', category: 'Asiatisch', canonicalId: 'yuzu_ponzu', defaultUnit: 'ml'),
    IngredientEntry(name: 'Nam Jim (Thai-Dip)', category: 'Asiatisch', canonicalId: 'nam_jim', defaultUnit: 'ml'),
    IngredientEntry(name: 'Satay-Sauce', category: 'Asiatisch', canonicalId: 'satay_sauce', defaultUnit: 'EL'),

    // ══════════════════════════════════════════════════════
    // KRÄUTERTEES & HEISSGETRÄNKE VOLLSTÄNDIG
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Rooibos-Tee', category: 'Getränke', canonicalId: 'rooibos', defaultUnit: 'g'),
    IngredientEntry(name: 'Hagebutten-Tee', category: 'Getränke', canonicalId: 'hagebutten_tee', defaultUnit: 'g'),
    IngredientEntry(name: 'Brennnessel-Tee', category: 'Getränke', canonicalId: 'brennnessel_tee', defaultUnit: 'g'),
    IngredientEntry(name: 'Lavendel-Tee', category: 'Getränke', canonicalId: 'lavendel_tee', defaultUnit: 'g'),
    IngredientEntry(name: 'Zitronenmelisse-Tee', category: 'Getränke', canonicalId: 'melisse_tee', defaultUnit: 'g'),
    IngredientEntry(name: 'Schleimdorn-Tee', category: 'Getränke', canonicalId: 'schlehdorn_tee', defaultUnit: 'g'),
    IngredientEntry(name: 'Früchtetee (Beeren)', category: 'Getränke', canonicalId: 'fruechtetee_beeren', defaultUnit: 'g'),
    IngredientEntry(name: 'Früchtetee (Exotisch)', category: 'Getränke', canonicalId: 'fruechtetee_exotisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Earl Grey', category: 'Getränke', canonicalId: 'earl_grey', defaultUnit: 'g'),
    IngredientEntry(name: 'Chai Tee', category: 'Getränke', canonicalId: 'chai', defaultUnit: 'g'),
    IngredientEntry(name: 'Chai Latte Pulver', category: 'Getränke', canonicalId: 'chai_latte', defaultUnit: 'g'),
    IngredientEntry(name: 'Matcha Latte Pulver', category: 'Getränke', canonicalId: 'matcha_latte', defaultUnit: 'g'),
    IngredientEntry(name: 'Golden Milk Pulver', category: 'Getränke', canonicalId: 'golden_milk', defaultUnit: 'g'),
    IngredientEntry(name: 'Kakao (Trinkschokolade)', category: 'Getränke', canonicalId: 'trinkschoko', defaultUnit: 'g'),
    IngredientEntry(name: 'Kaffee-Kapseln', category: 'Getränke', canonicalId: 'kaffee_kapseln', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Cold Brew Konzentrat', category: 'Getränke', canonicalId: 'cold_brew', defaultUnit: 'ml'),
    IngredientEntry(name: 'Kaffeelikör', category: 'Alkohol', canonicalId: 'kaffeelikoer', defaultUnit: 'ml'),
    IngredientEntry(name: 'Irish Coffee Basis', category: 'Alkohol', canonicalId: 'irish_coffee', defaultUnit: 'ml'),

    // ══════════════════════════════════════════════════════
    // FERMENTIERTE PRODUKTE & PROBIOTIKA
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Miso (weiß)', category: 'Fermentiert', canonicalId: 'miso_weiss', defaultUnit: 'g'),
    IngredientEntry(name: 'Miso (rot)', category: 'Fermentiert', canonicalId: 'miso_rot', defaultUnit: 'g'),
    IngredientEntry(name: 'Tempeh (frisch)', category: 'Fermentiert', canonicalId: 'tempeh_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Natto (fermentiert)', category: 'Fermentiert', canonicalId: 'natto_ferm', defaultUnit: 'g'),
    IngredientEntry(name: 'Kimchi (selbst gemacht)', category: 'Fermentiert', canonicalId: 'kimchi_selbst', defaultUnit: 'g'),
    IngredientEntry(name: 'Sauerkraut (selbst gemacht)', category: 'Fermentiert', canonicalId: 'sauerkraut_selbst', defaultUnit: 'g'),
    IngredientEntry(name: 'Kvass (Brottrunk)', category: 'Fermentiert', canonicalId: 'kvass', defaultUnit: 'ml'),
    IngredientEntry(name: 'Wasserkefir', category: 'Fermentiert', canonicalId: 'wasserkefir', defaultUnit: 'ml'),
    IngredientEntry(name: 'Jun-Tee', category: 'Fermentiert', canonicalId: 'jun_tee', defaultUnit: 'ml'),
    IngredientEntry(name: 'Koji (Reis)', category: 'Fermentiert', canonicalId: 'koji', defaultUnit: 'g'),
    IngredientEntry(name: 'Garum', category: 'Fermentiert', canonicalId: 'garum', defaultUnit: 'ml'),
    IngredientEntry(name: 'Fermentierte Cashews', category: 'Fermentiert', canonicalId: 'cashews_ferm', defaultUnit: 'g'),
    IngredientEntry(name: 'Kefir (Milch)', category: 'Fermentiert', canonicalId: 'kefir_milch', defaultUnit: 'ml'),
    IngredientEntry(name: 'Joghurt (selbst gemacht)', category: 'Fermentiert', canonicalId: 'joghurt_selbst', defaultUnit: 'g'),
    IngredientEntry(name: 'Kimchi-Paste', category: 'Fermentiert', canonicalId: 'kimchi_paste', defaultUnit: 'g'),

    // ══════════════════════════════════════════════════════
    // GEMÜSE-KONSERVEN WELTWEIT (ERWEITERT)
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Edamame (Dose)', category: 'Konserven', canonicalId: 'edamame_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Herzpalmen (Dose)', category: 'Konserven', canonicalId: 'herzpalmen', defaultUnit: 'Dose', aliases: ['Palmherzen']),
    IngredientEntry(name: 'Jackfrucht (jung, Dose)', category: 'Konserven', canonicalId: 'jackfrucht_jung', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Kohlrabi (Glas)', category: 'Konserven', canonicalId: 'kohlrabi_glas', defaultUnit: 'Glas'),
    IngredientEntry(name: 'Spargel (Dose)', category: 'Konserven', canonicalId: 'spargel_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Mangostücke (Dose)', category: 'Konserven', canonicalId: 'mango_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Pfirsiche (Dose)', category: 'Konserven', canonicalId: 'pfirsich_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Birnen (Dose)', category: 'Konserven', canonicalId: 'birnen_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Kirschen (Dose)', category: 'Konserven', canonicalId: 'kirschen_dose', defaultUnit: 'Dose'),
    IngredientEntry(name: 'Fruchtcocktail (Dose)', category: 'Konserven', canonicalId: 'fruchtcocktail', defaultUnit: 'Dose'),

    // ══════════════════════════════════════════════════════
    // ZUSÄTZLICHE DEUTSCHE SPEZIALITÄTEN
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Obatzda', category: 'Milchprodukte', canonicalId: 'obatzda', defaultUnit: 'g'),
    IngredientEntry(name: 'Fleischkäse', category: 'Wurst & Aufschnitt', canonicalId: 'fleischkaese', defaultUnit: 'g', aliases: ['Leberkäse']),
    IngredientEntry(name: 'Weißwurst (Paar)', category: 'Wurst & Aufschnitt', canonicalId: 'weisswurst_paar', defaultUnit: 'Paar'),
    IngredientEntry(name: 'Nürnberger Rostbratwurst', category: 'Wurst & Aufschnitt', canonicalId: 'nuernberger', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Thüringer Rostbratwurst', category: 'Wurst & Aufschnitt', canonicalId: 'thueringer_brat', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Münchner Weißwurst-Senf', category: 'Konserven', canonicalId: 'weisswurst_senf', defaultUnit: 'EL'),
    IngredientEntry(name: 'Sauerbraten-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'sauerbraten_gewuerz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Gulasch-Gewürz', category: 'Gewürze & Soßen', canonicalId: 'gulasch_gewuerz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Lebkuchengewürz (Mischung)', category: 'Backen', canonicalId: 'lebkuchen_misch', defaultUnit: 'TL'),
    IngredientEntry(name: 'Stollen-Gewürz', category: 'Backen', canonicalId: 'stollen_gewuerz', defaultUnit: 'TL'),
    IngredientEntry(name: 'Pfefferkuchen', category: 'Süßwaren & Snacks', canonicalId: 'pfefferkuchen', defaultUnit: 'g'),
    IngredientEntry(name: 'Aachener Printen', category: 'Süßwaren & Snacks', canonicalId: 'printen', defaultUnit: 'g'),
    IngredientEntry(name: 'Dresdner Stollen', category: 'Süßwaren & Snacks', canonicalId: 'stollen', defaultUnit: 'g'),
    IngredientEntry(name: 'Schwarzwälder Kirschtorte', category: 'Süßwaren & Snacks', canonicalId: 'sw_kirschtorte', defaultUnit: 'g'),
    IngredientEntry(name: 'Berliner Pfannkuchen', category: 'Brot & Backwaren', canonicalId: 'berliner', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Quarkkeulchen', category: 'Brot & Backwaren', canonicalId: 'quarkkeulchen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Bienenstich (Kuchen)', category: 'Süßwaren & Snacks', canonicalId: 'bienenstich', defaultUnit: 'g'),
    IngredientEntry(name: 'Streuselkuchen', category: 'Süßwaren & Snacks', canonicalId: 'streuselkuchen', defaultUnit: 'g'),
    IngredientEntry(name: 'Pflaumenkuchen', category: 'Süßwaren & Snacks', canonicalId: 'pflaumenkuchen', defaultUnit: 'g'),

    // ══════════════════════════════════════════════════════
    // GEWÜRZE & ZUTATEN DER WEIHNACHTSBÄCKEREI
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Anisplätzchen-Gewürz', category: 'Backen', canonicalId: 'anis_plaetzchen', defaultUnit: 'TL'),
    IngredientEntry(name: 'Hirschhornsalz', category: 'Backen', canonicalId: 'hirschhornsalz', defaultUnit: 'g'),
    IngredientEntry(name: 'Pottasche', category: 'Backen', canonicalId: 'pottasche', defaultUnit: 'g'),
    IngredientEntry(name: 'Zuckerguss (fertig)', category: 'Backen', canonicalId: 'zuckerguss', defaultUnit: 'g'),
    IngredientEntry(name: 'Silberperlen (Dekoration)', category: 'Backen', canonicalId: 'silberperlen', defaultUnit: 'g'),
    IngredientEntry(name: 'Bunte Streusel', category: 'Backen', canonicalId: 'bunte_streusel', defaultUnit: 'g'),
    IngredientEntry(name: 'Schokoglasur', category: 'Backen', canonicalId: 'schokoglasur', defaultUnit: 'g'),
    IngredientEntry(name: 'Weiße Glasur', category: 'Backen', canonicalId: 'weisse_glasur', defaultUnit: 'g'),
    IngredientEntry(name: 'Lebensmittelfarbe (rot)', category: 'Backen', canonicalId: 'lebmittel_farbe_rot', defaultUnit: 'ml'),
    IngredientEntry(name: 'Lebensmittelfarbe (blau)', category: 'Backen', canonicalId: 'lebmittel_farbe_blau', defaultUnit: 'ml'),
    IngredientEntry(name: 'Lebensmittelfarbe (grün)', category: 'Backen', canonicalId: 'lebmittel_farbe_gruen', defaultUnit: 'ml'),
    IngredientEntry(name: 'Essbares Gold', category: 'Backen', canonicalId: 'essbares_gold', defaultUnit: 'g'),

    // ══════════════════════════════════════════════════════
    // FRISCHPRODUKTE / CONVENIENCE KÜHLTHEKE
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Dönerfleisch (Hähnchen)', category: 'Fleisch & Fisch', canonicalId: 'doener_haehnchen', defaultUnit: 'g'),
    IngredientEntry(name: 'Dönerfleisch (Lamm)', category: 'Fleisch & Fisch', canonicalId: 'doener_lamm', defaultUnit: 'g'),
    IngredientEntry(name: 'Dönerfleisch (Mix)', category: 'Fleisch & Fisch', canonicalId: 'doener_mix', defaultUnit: 'g'),
    IngredientEntry(name: 'Falafel (fertig, Dose)', category: 'Fertigprodukte', canonicalId: 'falafel_dose', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Hummus (Kühlregal)', category: 'Fertigprodukte', canonicalId: 'hummus_fertig', defaultUnit: 'g'),
    IngredientEntry(name: 'Tzatziki (Kühlregal)', category: 'Fertigprodukte', canonicalId: 'tzatziki_fertig', defaultUnit: 'g'),
    IngredientEntry(name: 'Guacamole (Kühlregal)', category: 'Fertigprodukte', canonicalId: 'guacamole_fertig', defaultUnit: 'g'),
    IngredientEntry(name: 'Lachsaufstrich', category: 'Fertigprodukte', canonicalId: 'lachs_aufstrich', defaultUnit: 'g'),
    IngredientEntry(name: 'Thunfischaufstrich', category: 'Fertigprodukte', canonicalId: 'thunfisch_aufstrich', defaultUnit: 'g'),
    IngredientEntry(name: 'Veganer Aufstrich (Kühlregal)', category: 'Fertigprodukte', canonicalId: 'vegan_aufstrich_kuehl', defaultUnit: 'g'),
    IngredientEntry(name: 'Gefüllte Hähnchenrolle', category: 'Fertigprodukte', canonicalId: 'haehnchen_rolle', defaultUnit: 'g'),
    IngredientEntry(name: 'Fertig-Hähnchen (gebraten)', category: 'Fertigprodukte', canonicalId: 'haehnchen_gebraten', defaultUnit: 'g'),
    IngredientEntry(name: 'Fertig-Schnitzel', category: 'Fertigprodukte', canonicalId: 'schnitzel_fertig', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Fertig-Frikadellen', category: 'Fertigprodukte', canonicalId: 'frikadellen_fertig', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Vegane Frikadellen', category: 'Fertigprodukte', canonicalId: 'vegan_frikadellen', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Frische Suppe (Kühlregal)', category: 'Fertigprodukte', canonicalId: 'suppe_kuehl', defaultUnit: 'ml'),
    IngredientEntry(name: 'Fertig-Lasagne', category: 'Fertigprodukte', canonicalId: 'lasagne_fertig', defaultUnit: 'g'),
    IngredientEntry(name: 'Fertig-Curry', category: 'Fertigprodukte', canonicalId: 'curry_fertig', defaultUnit: 'g'),
    IngredientEntry(name: 'Fertig-Chili con Carne', category: 'Fertigprodukte', canonicalId: 'chili_fertig', defaultUnit: 'g'),
    IngredientEntry(name: 'Fertig-Eintopf', category: 'Fertigprodukte', canonicalId: 'eintopf_fertig', defaultUnit: 'g'),

    // ══════════════════════════════════════════════════════
    // SAISONALES (FRÜHLING / SOMMER / HERBST / WINTER)
    // ══════════════════════════════════════════════════════
    IngredientEntry(name: 'Bärlauch (Frühling)', category: 'Obst & Gemüse', canonicalId: 'baerlauch_fruehling', defaultUnit: 'g'),
    IngredientEntry(name: 'Spargelzeit (weiß, dick)', category: 'Obst & Gemüse', canonicalId: 'spargel_dick', defaultUnit: 'kg'),
    IngredientEntry(name: 'Erdbeeren (Saison)', category: 'Obst & Gemüse', canonicalId: 'erdbeere_saison', defaultUnit: 'kg'),
    IngredientEntry(name: 'Mirabellen (Sommer)', category: 'Obst & Gemüse', canonicalId: 'mirabelle', defaultUnit: 'g'),
    IngredientEntry(name: 'Renekloden (Sommer)', category: 'Obst & Gemüse', canonicalId: 'reneklode', defaultUnit: 'g'),
    IngredientEntry(name: 'Brombeeren (Herbst)', category: 'Obst & Gemüse', canonicalId: 'brombeere_herbst', defaultUnit: 'g'),
    IngredientEntry(name: 'Kastanien (frisch, Herbst)', category: 'Obst & Gemüse', canonicalId: 'kastanie_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Pfifferlinge (Saison)', category: 'Obst & Gemüse', canonicalId: 'pfifferlinge_saison', defaultUnit: 'g'),
    IngredientEntry(name: 'Walnüsse (frisch, Herbst)', category: 'Nüsse & Samen', canonicalId: 'walnuss_frisch', defaultUnit: 'g'),
    IngredientEntry(name: 'Quitten (Herbst)', category: 'Obst & Gemüse', canonicalId: 'quitte_herbst', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Feldsalat (Herbst/Winter)', category: 'Obst & Gemüse', canonicalId: 'feldsalat_winter', defaultUnit: 'g'),
    IngredientEntry(name: 'Grünkohl (Winter)', category: 'Obst & Gemüse', canonicalId: 'gruenkohl_winter', defaultUnit: 'g'),
    IngredientEntry(name: 'Rosenkohl (Winter)', category: 'Obst & Gemüse', canonicalId: 'rosenkohl_winter', defaultUnit: 'g'),
    IngredientEntry(name: 'Pastinaken (Winter)', category: 'Obst & Gemüse', canonicalId: 'pastinake_winter', defaultUnit: 'g'),
    IngredientEntry(name: 'Schwarzwurzel (Winter)', category: 'Obst & Gemüse', canonicalId: 'schwarzwurzel_winter', defaultUnit: 'g'),
    IngredientEntry(name: 'Blutorangen (Winter)', category: 'Obst & Gemüse', canonicalId: 'blutorange', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Clementinen (Winter)', category: 'Obst & Gemüse', canonicalId: 'clementine', defaultUnit: 'Stück'),
    IngredientEntry(name: 'Meerrettich (frisch, Winter)', category: 'Obst & Gemüse', canonicalId: 'meerrettich_frisch', defaultUnit: 'g'),
  ];

  /// Kategorien die KEINE Kochzutaten sind (Haushalt, Hygiene, Tierfutter …)
  static const Set<String> _nonCookingCategories = {
    'Haushalt',
    'Körperpflege',
    'Tierfutter',
    'Baby & Kind',
  };

  /// Gewürz-Kategorien (Einträge die beim Vorrats-Abgleich als optional gelten)
  static const Set<String> _spiceCategories = {
    'Gewürze & Soßen',
  };

  /// Gibt true zurück wenn der Katalog-Eintrag ein Gewürz / eine Würzmischung ist.
  static bool isSpice(IngredientEntry entry) =>
      _spiceCategories.contains(entry.category);

  /// Prüft ob ein Zutatennamen im Katalog einem Gewürz entspricht.
  static bool isSpiceByName(String name) {
    final lower = name.toLowerCase().trim();
    return all.any((e) =>
        _spiceCategories.contains(e.category) &&
        (e.name.toLowerCase() == lower ||
            e.aliases.any((a) => a.toLowerCase() == lower)));
  }

  /// Sucht nur Kochzutaten (ohne Haushalt, Körperpflege, Tierfutter).
  static List<IngredientEntry> searchCooking(String query, {int maxResults = 15}) {
    if (query.trim().isEmpty) return [];
    final cookingOnly = all.where((e) => !_nonCookingCategories.contains(e.category)).toList();
    final normalized = _normalize(query.toLowerCase().trim());

    final scored = <({IngredientEntry entry, int score})>[];
    for (final entry in cookingOnly) {
      final nameLower = _normalize(entry.name.toLowerCase());
      int score = 0;
      if (nameLower == normalized) {
        score = 100;
      } else if (nameLower.startsWith(normalized)) {
        score = 80;
      } else if (nameLower.contains(normalized)) {
        score = 60;
      } else {
        for (final alias in entry.aliases) {
          final aliasLower = _normalize(alias.toLowerCase());
          if (aliasLower.startsWith(normalized)) {
            score = 50;
            break;
          } else if (aliasLower.contains(normalized)) {
            score = 40;
            break;
          }
        }
      }
      if (score > 0) scored.add((entry: entry, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((e) => e.entry).toList();
  }

  /// Sucht Einträge anhand eines Suchbegriffs (fuzzy, Umlaut-tolerant).
  static List<IngredientEntry> search(String query, {int maxResults = 15}) {
    if (query.trim().isEmpty) return [];
    final normalized = _normalize(query.toLowerCase().trim());

    final scored = <({IngredientEntry entry, int score})>[];

    for (final entry in all) {
      final nameLower = _normalize(entry.name.toLowerCase());
      int score = 0;

      if (nameLower == normalized) {
        score = 100;
      } else if (nameLower.startsWith(normalized)) {
        score = 80;
      } else if (nameLower.contains(normalized)) {
        score = 60;
      } else {
        // Aliases prüfen
        for (final alias in entry.aliases) {
          final aliasLower = _normalize(alias.toLowerCase());
          if (aliasLower.startsWith(normalized)) {
            score = 50;
            break;
          } else if (aliasLower.contains(normalized)) {
            score = 40;
            break;
          }
        }
      }

      if (score > 0) {
        scored.add((entry: entry, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((e) => e.entry).toList();
  }

  /// Normalisiert Umlaute und Sonderzeichen für die Suche.
  static String _normalize(String s) {
    return s
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('Ä', 'ae')
        .replaceAll('Ö', 'oe')
        .replaceAll('Ü', 'ue');
  }

  /// Gibt alle verfügbaren Kategorien zurück.
  static List<String> get categories {
    final cats = all.map((e) => e.category).toSet().toList();
    cats.sort();
    return cats;
  }
}

