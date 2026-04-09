import 'package:kokomu/core/data/ingredient_catalog.dart';

/// Zentrale Liste von Basisgewürzen und -zutaten die als immer vorhanden
/// gelten und NICHT als "fehlend" im Vorrat angezeigt werden sollen.
/// Wird in recipe_detail_screen, kitchen_screen und groq_service verwendet.
const Set<String> kStapleIngredients = {
  // Salz & Pfeffer
  'salz', 'pfeffer', 'schwarzer pfeffer', 'weißer pfeffer', 'meersalz',
  'himalaya salz', 'jodsalz', 'fleur de sel', 'kala namak', 'sel gris',
  // Öle & Fette
  'öl', 'olivenöl', 'sonnenblumenöl', 'rapsöl', 'speiseöl', 'pflanzenöl',
  'kokosöl', 'sesamöl', 'butter', 'margarine', 'butterschmalz', 'ghee',
  'walnussöl', 'haselnussöl', 'traubenkernöl', 'avocadoöl',
  // Essig
  'essig', 'apfelessig', 'weißweinessig', 'rotweinessig', 'balsamico',
  'balsamicoessig', 'reisessig', 'sherryessig', 'himbeeressig',
  // Süße
  'zucker', 'weißer zucker', 'brauner zucker', 'puderzucker', 'vanillezucker',
  'honig', 'agavendicksaft', 'ahornsirup', 'rohrzucker', 'kokosblütenzucker',
  'stevia', 'xylit', 'erythrit', 'reissirup',
  // Mehl & Stärke
  'mehl', 'weizenmehl', 'speisestärke', 'kartoffelstärke', 'maisstärke',
  'backpulver', 'natron', 'hefe', 'weinsteinbackpulver',
  // Wasser
  'wasser', 'leitungswasser', 'mineralwasser',
  // Milch & Sahne (basics)
  'milch', 'sahne', 'schlagsahne',
  // Gewürze & Kräuter – vollständig
  'knoblauch', 'knoblauchzehe', 'knoblauchzehen', 'knoblauchpulver',
  'zwiebel', 'zwiebeln', 'zwiebelpulver', 'schalotte', 'schalotten',
  'paprikapulver', 'paprikapulver (süß)', 'paprikapulver (scharf)',
  'edelsüß paprika', 'geräucherte paprika', 'rosenpaprika',
  'kreuzkümmel', 'kümmel', 'cumin',
  'oregano', 'thymian', 'rosmarin', 'basilikum', 'petersilie',
  'lorbeer', 'lorbeerblatt', 'lorbeerblätter',
  'zimt', 'zimtstange', 'zimtstangen',
  'muskatnuss', 'muskat', 'muskatblüte',
  'nelken', 'gewürznelken', 'kardamom', 'kardamomkapsel',
  'kurkuma', 'gelbwurz',
  'curry', 'currypulver', 'garam masala', 'ras el hanout',
  'ingwer', 'ingwerpulver',
  'chili', 'chilipulver', 'chilischote', 'chilischoten',
  'chili (flocken)', 'chiliflocken', 'cayennepfeffer',
  'dill', 'schnittlauch', 'salbei', 'majoran',
  'koriander', 'korianderblätter', 'koriandersamen', 'korianderpulver',
  'fenchel', 'fenchelsamen', 'fenchelgrün',
  'anis', 'sternanis', 'anissamen',
  'senf', 'dijon senf', 'senf mittelscharf', 'senfkörner', 'senfpulver',
  'piment', 'wacholderbeeren', 'wacholder',
  'bockshornklee', 'curryblätter', 'asafoetida',
  'sumach', 'za\'atar', 'berbere', 'baharat',
  'tandoori masala', 'chat masala', 'panch phoron',
  'pfeffer (bunt)', 'grüner pfeffer', 'roter pfeffer', 'langer pfeffer',
  'meerrettich', 'meerrettichpulver',
  'wasabi', 'wasabipulver',
  'safran', 'kurkuma safran',
  'vanille', 'vanilleschote', 'vanilleextrakt', 'vanillearoma',
  'zitronenabrieb', 'zitronenzeste', 'orangenzeste', 'orangenabrieb',
  'rosenblüten', 'lavendel',
  // Saucen & Würzmittel (basics)
  'sojasauce', 'worcestershire', 'worcestersauce', 'tabasco',
  'fischsauce', 'austernsoße', 'hoisinsauce', 'teriyakisauce',
  'tomatenmark', 'tomatenpassata',
  'zitronensaft', 'limettensaft', 'orangensaft',
  'brühe', 'gemüsebrühe', 'hühnerbrühe', 'rinderbrühe',
  'gemüsebrühwürfel', 'hühnerbrühwürfel', 'rinderbrühwürfel',
  'miso', 'miso-paste',
};

/// Prüft ob eine Zutat als Basiszutat gilt (case-insensitive).
/// Berücksichtigt auch alle Gewürze aus dem IngredientCatalog.
bool isStapleIngredient(String ingredientName) {
  final lower = ingredientName.toLowerCase().trim();
  // Direkter Treffer in der statischen Liste
  if (kStapleIngredients.contains(lower)) return true;
  // Teilstring-Prüfung für zusammengesetzte Namen (z.B. "frischer Knoblauch")
  if (kStapleIngredients.any((staple) =>
      lower.contains(staple) || (staple.contains(lower) && staple.length > 3))) {
    return true;
  }
  // Alle Gewürze aus dem IngredientCatalog gelten ebenfalls als Basiszutat
  return IngredientCatalog.isSpiceByName(lower);
}

/// Kurzform des Hinweistexts für KI-Prompts.
const String kStapleIngredientPromptHint =
    'Folgende Basisgewürze und -zutaten gelten als immer im Haushalt vorhanden '
    'und müssen NICHT als Zutaten aufgeführt werden (außer in ungewöhnlichen Mengen): '
    'Salz, Pfeffer, Öl (Oliven-, Raps-, Sonnenblumen-), Butter, Essig, Zucker, '
    'Mehl, Backpulver, Wasser, Knoblauch, Zwiebeln, Paprikapulver, Oregano, '
    'Thymian, Basilikum, Petersilie, Lorbeer, Zimt, Muskat, Brühe, Senf, '
    'Sojasauce, Tomatenmark, Zitronensaft.';
