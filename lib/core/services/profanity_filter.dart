/// Profanity-Filter für Kokomi
/// Schützt Chat, Social Posts und Kommentare vor Beleidigungen und Hate Speech.
class ProfanityFilter {
  ProfanityFilter._();

  // ── Blockliste (Deutsch + Englisch + Leetspeak) ───────────────────────────
  static const _blocked = <String>[
    // Deutsch – Schimpfwörter
    'scheiße','scheisse','scheiß','scheiss',
    'fick','ficken','gefickt',
    'wichser','wichsen','wichs',
    'arsch','arschloch','arschgeige','arschwipe',
    'piss','pisser','pissen',
    'kacke','kacken','kacker','kackbratze',
    'schlampe','hure','nutte',
    'bastard','vollidiot','vollpfosten','volltrottel',
    'idiot','idioten','idiotin',
    'depp','deppert',
    'trottel',
    'spast','spasti',
    'mongo',
    'penner','pennerin',
    'hurensohn','hurensöhne',
    'votze','möse',
    'kanake','kanaken',
    'kackvogel','mistkerl','miststück',
    'blödmann','blödmänner',
    'dummkopf','dummarsch',
    'beschissen',
    // Hate Speech / Diskriminierung
    'neger','nigger','nigga',
    'nazi','nazis','faschist','faschisten',
    'zigeuner',
    // Bedrohungen
    'töte dich','umbringen','abstechen','erschießen',
    'stirb','krepier','verrecke','verrecken',
    'verpiss dich',
    // Englisch
    'fuck','fucker','fucking','fucked','fucks',
    'shit','shitty','bullshit',
    'bitch','bitches',
    'asshole','assholes','ass hole',
    'cunt','cunts',
    'motherfucker','motherfucking',
    'prick','dickhead','douchebag',
    'wanker','tosser',
    'bastard','bastards',
    'damn you','go to hell',
    // Leetspeak-Varianten
    'sch3iss','f1ck','fvck','a55hole','a55','5hit',
    'b1tch','wh0re',
  ];

  /// Gibt `true` zurück wenn Text geblockt werden soll.
  static bool contains(String text) {
    final n = _normalize(text);
    return _blocked.any((w) => _matches(n, _normalize(w)));
  }

  /// Gibt `null` wenn ok, sonst eine Fehlermeldung für den User.
  static String? validate(String text) {
    if (text.trim().isEmpty) return null;
    if (contains(text)) {
      return 'Bitte keine Beleidigungen oder unangemessene Sprache verwenden.';
    }
    return null;
  }

  /// Ersetzt gefundene Wörter durch Sternchen (z.B. f***).
  static String clean(String text) {
    var result = text;
    for (final word in _blocked) {
      try {
        final pattern = RegExp(
          r'\b' + RegExp.escape(word) + r'\b',
          caseSensitive: false,
          unicode: true,
        );
        result = result.replaceAllMapped(pattern, (m) {
          final w = m.group(0) ?? '';
          return w.isEmpty ? w : '${w[0]}${'*' * (w.length - 1)}';
        });
      } catch (_) {}
    }
    return result;
  }

  // ── intern ────────────────────────────────────────────────────────────────

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ä', 'ae').replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue').replaceAll('ß', 'ss')
      .replaceAll('3', 'e').replaceAll('0', 'o')
      .replaceAll('1', 'i').replaceAll('@', 'a')
      .replaceAll('\$', 's').replaceAll('*', '')
      .replaceAll('!', 'i').replaceAll('4', 'a');

  static bool _matches(String text, String word) {
    try {
      return RegExp(
        r'\b' + RegExp.escape(word) + r'\b',
        caseSensitive: false,
        unicode: true,
      ).hasMatch(text);
    } catch (_) {
      return text.contains(word);
    }
  }
}

