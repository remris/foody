import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kokomi/core/services/supabase_service.dart';
import 'package:kokomi/models/recipe.dart';

/// Zweistufiges Caching-System für KI-Rezepte.
///
/// Stufe 1 – In-Memory: Innerhalb einer App-Session sofort verfügbar.
///           Verhindert Doppelgenerierungen wenn User zurück navigiert.
///
/// Stufe 2 – Lokal (SharedPreferences): Überlebt App-Neustart.
///           TTL: 24 Stunden. Bis zu 50 Einträge.
///
/// Stufe 3 – Supabase (Community-Cache): Wenn viele User ähnliche
///           Anfragen stellen, werden Ergebnisse geteilt.
///           TTL: 7 Tage. Spart Groq-API-Calls für alle.
///
/// Cache-Key = SHA-256 Hash der sortierten, normalisierten Zutaten.
/// Beispiel: ["Tomaten","Käse","Pasta"] → gleicher Hash wie ["Pasta","Tomaten","Käse"]
class RecipeCacheService {
  static const _localKey = 'recipe_cache_v2';
  static const _localTtlHours = 1; // 1h statt 24h → frische KI-Ergebnisse
  static const _supabaseTtlDays = 7;
  static const _maxLocalEntries = 50;

  // ── In-Memory Cache (Session) ──────────────────────────────────────────
  static final Map<String, _CacheEntry> _memoryCache = {};

  // ── Cache-Key generieren ──────────────────────────────────────────────

  /// Normalisiert Zutaten und erstellt einen deterministischen Hash.
  /// ["Pasta", "Tomaten", "Käse"] == ["käse", "pasta", "tomaten"] (case-insensitive, sortiert)
  static String buildKey(List<String> ingredients, {String? promptExtra}) {
    final normalized = ingredients
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();
    final input = normalized.join(',') + (promptExtra ?? '');
    return sha256.convert(utf8.encode(input)).toString().substring(0, 16);
  }

  static String buildPromptKey(String prompt) {
    final normalized = prompt.toLowerCase().trim();
    return 'p_${sha256.convert(utf8.encode(normalized)).toString().substring(0, 14)}';
  }

  // ── Lesen ──────────────────────────────────────────────────────────────

  /// Gibt gecachte Rezepte zurück, oder null wenn kein gültiger Cache.
  /// [forceRefresh]: Wenn true, wird der gesamte Cache übersprungen –
  /// der User bekommt garantiert frisch generierte Rezepte.
  static Future<List<FoodRecipe>?> get(String key,
      {bool forceRefresh = false}) async {
    // Bei forceRefresh: nichts zurückgeben → immer neu generieren
    if (forceRefresh) return null;

    // 1. In-Memory
    final mem = _memoryCache[key];
    if (mem != null && !mem.isExpired) {
      return _shuffle(mem.recipes);
    }

    // 2. Lokal
    final local = await _getLocal(key);
    if (local != null) {
      _memoryCache[key] = _CacheEntry(local);
      return _shuffle(local);
    }

    // 3. Supabase Community-Cache
    final remote = await _getRemote(key);
    if (remote != null) {
      _memoryCache[key] = _CacheEntry(remote);
      await _saveLocal(key, remote);
      return _shuffle(remote);
    }

    return null;
  }

  /// Schreibt Rezepte in alle Cache-Stufen.
  static Future<void> set(String key, List<FoodRecipe> recipes) async {
    _memoryCache[key] = _CacheEntry(recipes);
    await _saveLocal(key, recipes);
    await _saveRemote(key, recipes);
  }

  /// Trackt eine Zutaten-Anfrage in ingredient_query_stats (fire & forget).
  /// Ermöglicht proaktives Precaching beliebter Kombinationen.
  static void trackQuery(List<String> ingredients) {
    if (ingredients.isEmpty) return;
    final key = buildKey(ingredients);
    final normalized = ingredients
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();

    SupabaseService.client.rpc('upsert_ingredient_stats', params: {
      'p_cache_key': key,
      'p_ingredients': normalized,
    }).then((_) {}).catchError((_) {});
    // Fehler ignorieren – Tracking ist nicht kritisch
  }

  // ── Lokal ──────────────────────────────────────────────────────────────

  static Future<List<FoodRecipe>?> _getLocal(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      if (raw == null) return null;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = map[key] as Map<String, dynamic>?;
      if (entry == null) return null;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        entry['expires_at'] as int,
      );
      if (DateTime.now().isAfter(expiresAt)) {
        // Abgelaufenen Eintrag entfernen
        map.remove(key);
        await prefs.setString(_localKey, jsonEncode(map));
        return null;
      }

      final list = (entry['recipes'] as List)
          .map((r) => FoodRecipe.fromJson(r as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveLocal(String key, List<FoodRecipe> recipes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      final map = raw != null
          ? (jsonDecode(raw) as Map<String, dynamic>)
          : <String, dynamic>{};

      // Max-Entries: ältesten entfernen
      if (map.length >= _maxLocalEntries) {
        final sorted = map.entries.toList()
          ..sort((a, b) {
            final ea = (a.value as Map)['expires_at'] as int? ?? 0;
            final eb = (b.value as Map)['expires_at'] as int? ?? 0;
            return ea.compareTo(eb);
          });
        map.remove(sorted.first.key);
      }

      map[key] = {
        'expires_at': DateTime.now()
            .add(const Duration(hours: _localTtlHours))
            .millisecondsSinceEpoch,
        'recipes': recipes.map((r) => r.toJson()).toList(),
      };

      await prefs.setString(_localKey, jsonEncode(map));
    } catch (_) {}
  }

  // ── Supabase Community-Cache ───────────────────────────────────────────

  static Future<List<FoodRecipe>?> _getRemote(String key) async {
    try {
      final data = await SupabaseService.client
          .from('recipe_cache')
          .select('recipes_json, expires_at')
          .eq('cache_key', key)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (data == null) return null;

      final list = (jsonDecode(data['recipes_json'] as String) as List)
          .map((r) => FoodRecipe.fromJson(r as Map<String, dynamic>))
          .toList();

      // Hit-Counter erhöhen (atomisch via RPC, fire & forget)
      SupabaseService.client
          .rpc('increment_cache_hits', params: {'p_cache_key': key})
          .then((_) {})
          .catchError((_) {});

      return list;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveRemote(
      String key, List<FoodRecipe> recipes) async {
    try {
      await SupabaseService.client.from('recipe_cache').upsert({
        'cache_key': key,
        'recipes_json': jsonEncode(recipes.map((r) => r.toJson()).toList()),
        'expires_at': DateTime.now()
            .add(const Duration(days: _supabaseTtlDays))
            .toIso8601String(),
        'hit_count': 1,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'cache_key');
    } catch (_) {
      // Supabase nicht verfügbar → nur lokal gecacht, kein Problem
    }
  }

  // ── Hilfsmethoden ──────────────────────────────────────────────────────

  /// Mischung damit User bei Cache-Hit trotzdem variierende Reihenfolge sieht.
  static List<FoodRecipe> _shuffle(List<FoodRecipe> recipes) {
    final copy = recipes.toList();
    copy.shuffle(Random());
    return copy;
  }

  /// Lokalen Cache komplett leeren (für Entwicklung / Tests).
  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey);
    _memoryCache.clear();
  }

  /// Abgelaufene lokale Einträge bereinigen.
  static Future<int> pruneExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      if (raw == null) return 0;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;
      final before = map.length;
      map.removeWhere((k, v) {
        final ea = (v as Map)['expires_at'] as int? ?? 0;
        return ea < now;
      });
      await prefs.setString(_localKey, jsonEncode(map));
      return before - map.length;
    } catch (_) {
      return 0;
    }
  }
}

class _CacheEntry {
  final List<FoodRecipe> recipes;
  final DateTime expiresAt;

  _CacheEntry(this.recipes)
      : expiresAt = DateTime.now().add(const Duration(minutes: 30));

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

