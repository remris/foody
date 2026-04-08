/// Erkennt die Einkaufskategorie anhand des Artikelnamens.
/// Wird für die automatische Gruppierung auf der Einkaufsliste verwendet.
class ShoppingCategory {
  final String name;
  final String emoji;
  final int sortOrder;

  const ShoppingCategory(this.name, this.emoji, this.sortOrder);

  static const obst = ShoppingCategory('Obst & Gemüse', '🥬', 0);
  static const milch = ShoppingCategory('Milch & Käse', '🧀', 1);
  static const fleisch = ShoppingCategory('Fleisch & Fisch', '🥩', 2);
  static const brot = ShoppingCategory('Brot & Backwaren', '🍞', 3);
  static const tiefkuehl = ShoppingCategory('Tiefkühl', '🧊', 4);
  static const getraenke = ShoppingCategory('Getränke', '🥤', 5);
  static const konserven = ShoppingCategory('Konserven & Vorrat', '🥫', 6);
  static const gewuerze = ShoppingCategory('Gewürze & Soßen', '🧂', 7);
  static const snacks = ShoppingCategory('Snacks & Süßes', '🍫', 8);
  static const hygiene = ShoppingCategory('Hygiene & Haushalt', '🧹', 9);
  static const koerperpflege = ShoppingCategory('Körperpflege', '🧴', 10);
  static const baby = ShoppingCategory('Baby & Kind', '👶', 11);
  static const sonstiges = ShoppingCategory('Sonstiges', '📦', 12);

  static const all = [
    obst, milch, fleisch, brot, tiefkuehl, getraenke, konserven, gewuerze, snacks, hygiene, koerperpflege, baby, sonstiges,
  ];

  /// Mapping: Keyword → Kategorie.
  static final _keywords = <String, ShoppingCategory>{
    // Obst & Gemüse
    'apfel': obst, 'äpfel': obst, 'birne': obst, 'banane': obst, 'orange': obst,
    'zitrone': obst, 'limette': obst, 'traube': obst, 'erdbeere': obst,
    'himbeere': obst, 'blaubeere': obst, 'kirsche': obst, 'mango': obst,
    'ananas': obst, 'kiwi': obst, 'melone': obst, 'pfirsich': obst,
    'tomate': obst, 'tomaten': obst, 'gurke': obst, 'paprika': obst,
    'zwiebel': obst, 'knoblauch': obst, 'kartoffel': obst, 'karotte': obst,
    'möhre': obst, 'brokkoli': obst, 'blumenkohl': obst, 'spinat': obst,
    'salat': obst, 'zucchini': obst, 'aubergine': obst, 'pilz': obst,
    'champignon': obst, 'lauch': obst, 'sellerie': obst, 'ingwer': obst,
    'avocado': obst, 'mais': obst, 'erbse': obst, 'bohne': obst,
    'linse': obst, 'radieschen': obst, 'rettich': obst, 'fenchel': obst,
    'kohlrabi': obst, 'rote bete': obst, 'süßkartoffel': obst,
    'petersilie': obst, 'basilikum': obst, 'koriander': obst,
    'schnittlauch': obst, 'dill': obst, 'rosmarin': obst, 'thymian': obst,
    'minze': obst, 'gemüse': obst, 'obst': obst, 'kräuter': obst,
    // Milch & Käse
    'milch': milch, 'käse': milch, 'butter': milch, 'joghurt': milch,
    'quark': milch, 'sahne': milch, 'schmand': milch, 'frischkäse': milch,
    'mozzarella': milch, 'parmesan': milch, 'gouda': milch, 'emmentaler': milch,
    'cheddar': milch, 'feta': milch, 'mascarpone': milch, 'ricotta': milch,
    'skyr': milch, 'kefir': milch, 'ei': milch, 'eier': milch,
    'margarine': milch, 'crème fraîche': milch,
    // Fleisch & Fisch
    'fleisch': fleisch, 'hähnchen': fleisch, 'huhn': fleisch, 'hühnchen': fleisch,
    'rind': fleisch, 'schwein': fleisch, 'pute': fleisch, 'hack': fleisch,
    'wurst': fleisch, 'schinken': fleisch, 'speck': fleisch, 'salami': fleisch,
    'lachs': fleisch, 'fisch': fleisch, 'thunfisch': fleisch, 'garnele': fleisch,
    'schnitzel': fleisch, 'steak': fleisch, 'filet': fleisch,
    // Brot & Backwaren
    'brot': brot, 'brötchen': brot, 'toast': brot, 'croissant': brot,
    'kuchen': brot, 'torte': brot, 'mehl': brot, 'hefe': brot,
    'backpulver': brot, 'baguette': brot,
    // Tiefkühl
    'tiefkühl': tiefkuehl, 'pizza': tiefkuehl, 'eis': tiefkuehl,
    'tk-': tiefkuehl, 'gefroren': tiefkuehl, 'pommes': tiefkuehl,
    // Getränke
    'wasser': getraenke, 'saft': getraenke, 'cola': getraenke, 'bier': getraenke,
    'wein': getraenke, 'limo': getraenke, 'tee': getraenke, 'kaffee': getraenke,
    'sprudel': getraenke, 'getränk': getraenke, 'drink': getraenke,
    // Konserven & Vorrat
    'nudel': konserven, 'pasta': konserven, 'spaghetti': konserven,
    'reis': konserven, 'dose': konserven, 'konserve': konserven,
    'tomatenmark': konserven, 'passierte': konserven, 'müsli': konserven,
    'haferflocken': konserven, 'cornflakes': konserven, 'zucker': konserven,
    'öl': konserven, 'olivenöl': konserven, 'essig': konserven,
    'couscous': konserven, 'bohnen': konserven, 'kichererbsen': konserven,
    // Gewürze & Soßen
    'salz': gewuerze, 'pfeffer': gewuerze, 'soße': gewuerze, 'sauce': gewuerze,
    'ketchup': gewuerze, 'senf': gewuerze, 'mayo': gewuerze, 'sojasauce': gewuerze,
    'gewürz': gewuerze, 'zimt': gewuerze, 'paprika pulver': gewuerze,
    'curry': gewuerze, 'brühe': gewuerze, 'bouillon': gewuerze,
    // Snacks & Süßes
    'schokolade': snacks, 'chips': snacks, 'keks': snacks, 'gummibär': snacks,
    'nuss': snacks, 'nüsse': snacks, 'müsliriegel': snacks, 'bonbon': snacks,
    'süß': snacks, 'riegel': snacks, 'popcorn': snacks,
    // Hygiene & Haushalt
    'spülmittel': hygiene, 'waschmittel': hygiene, 'müllbeutel': hygiene,
    'küchenpapier': hygiene, 'toilettenpapier': hygiene, 'klopapier': hygiene,
    'alufolie': hygiene, 'backpapier': hygiene, 'gefrierbeutel': hygiene,
    'spülmaschinentabs': hygiene, 'weichspüler': hygiene, 'allzweckreiniger': hygiene,
    'wc-reiniger': hygiene, 'glasreiniger': hygiene, 'badreiniger': hygiene,
    'küchenreiniger': hygiene, 'backofenreiniger': hygiene, 'rohrfrei': hygiene,
    'fleckentferner': hygiene, 'natron': hygiene, 'zitronensäure': hygiene,
    'desinfektionsmittel': hygiene, 'desinfektionsgel': hygiene,
    'mikrofasertuch': hygiene, 'müllsack': hygiene, 'servietten': hygiene,
    'einweghandschuhe': hygiene, 'gummihandschuhe': hygiene,
    'pflaster': hygiene, 'verbandwatte': hygiene, 'mullbinde': hygiene,
    'ibuprofen': hygiene, 'paracetamol': hygiene, 'aspirin': hygiene,
    'nasenspray': hygiene, 'hustensaft': hygiene, 'augentropfen': hygiene,
    'batterien': hygiene, 'glühbirne': hygiene, 'kerzen': hygiene,
    'streichhölzer': hygiene, 'klebeband': hygiene,
    // Körperpflege
    'shampoo': koerperpflege, 'seife': koerperpflege, 'zahnpasta': koerperpflege,
    'zahnbürste': koerperpflege, 'zahnseide': koerperpflege, 'mundwasser': koerperpflege,
    'duschgel': koerperpflege, 'deodorant': koerperpflege, 'deo': koerperpflege,
    'körpercreme': koerperpflege, 'körperlotion': koerperpflege,
    'handcreme': koerperpflege, 'fußcreme': koerperpflege,
    'lippenpflege': koerperpflege, 'sonnencreme': koerperpflege,
    'gesichtscreme': koerperpflege, 'haargel': koerperpflege,
    'haarlack': koerperpflege, 'haarfarbe': koerperpflege,
    'haarmaske': koerperpflege, 'spülung': koerperpflege, 'conditioner': koerperpflege,
    'rasierschaum': koerperpflege, 'rasierer': koerperpflege,
    'wattepads': koerperpflege, 'wattestäbchen': koerperpflege,
    'feuchttücher': koerperpflege, 'tampons': koerperpflege,
    'damenbinden': koerperpflege, 'slipeinlagen': koerperpflege,
    'parfum': koerperpflege, 'eau de toilette': koerperpflege,
    'nagellack': koerperpflege, 'nagellackentferner': koerperpflege,
    'kondome': koerperpflege, 'enthaarung': koerperpflege,
    // Baby & Kind
    'windeln': baby, 'babyöl': baby, 'babyshampoo': baby, 'babycreme': baby,
    'babywipes': baby, 'schnuller': baby, 'stillpads': baby, 'babypuder': baby,
  };

  /// Erkennt die Kategorie eines Einkaufslistenartikels.
  static ShoppingCategory categorize(String itemName) {
    final lower = itemName.toLowerCase().trim();
    // Exakte Treffer zuerst
    if (_keywords.containsKey(lower)) return _keywords[lower]!;
    // Teilwort-Treffer
    for (final entry in _keywords.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }
    return sonstiges;
  }
}

