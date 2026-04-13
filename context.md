# kokomu – Context & Architecture Reference

> **Immer vor jedem Task lesen. Nach jedem größeren Feature aktualisieren.**
> Letzte Aktualisierung: 2026-04-12

---

## 1. Projekt-Übersicht

| Key | Value |
|---|---|
| **App-Name** | kokomu |
| **Package** | `app.kokomu.app` |
| **Sprache** | Flutter / Dart (SDK ^3.7.2) |
| **State Management** | Riverpod (flutter_riverpod ^2.6.1) |
| **Navigation** | GoRouter (go_router ^14.8.1) |
| **Backend** | Supabase (supabase_flutter ^2.8.4) |
| **KI-Rezepte** | Groq API (via Proxy) |
| **Monetarisierung** | RevenueCat (purchases_flutter) |
| **Error Tracking** | Sentry (sentry_flutter) |
| **Min Android API** | 21 |
| **iOS** | noch nicht aktiv (geplant in ~6 Monaten) |

---

## 2. Ordnerstruktur

```
lib/
├── main.dart                          # App-Einstieg, Supabase/Sentry init
├── core/
│   ├── constants/                     # staple_ingredients.dart (Basisgewürze)
│   ├── data/
│   │   ├── ingredient_catalog.dart    # ~2000 Lebensmittel (nur Name, Kategorie, Einheit, Aliases)
│   │   └── nutrient_data.dart         # Nährwert-Lookup-Map nach canonicalId (kcal/protein/fat/carbs pro 100g)
│   ├── database/                      # Lokale DB-Helfer
│   ├── router/
│   │   └── app_router.dart            # GoRouter-Konfiguration, Auth-Guard
│   ├── services/
│   │   ├── groq_service.dart          # KI-Rezeptgenerierung (Groq LLM)
│   │   ├── nutrition_service.dart     # Zentrale Nährwert-Auflösung (Scan → Manuell → Katalog → Kategorie-Fallback)
│   │   ├── revenuecat_service.dart    # Pro/Free Abo-Prüfung
│   │   ├── supabase_service.dart      # Supabase-Client Singleton
│   │   ├── profanity_filter.dart      # Chat-/Post-Filter
│   │   └── ...
│   └── utils/
├── features/
│   ├── auth/                          # Login, Register (3-Step), Forgot Password
│   ├── community/                     # Community-System (PLZ-basiert, Posts, Teilen, Hilfe)
│   ├── dashboard/                     # Home-Screen mit Übersichten
│   ├── household/                     # Haushalt (Mitglieder, Chat, geteilter Vorrat)
│   ├── inventory/                     # Vorrat (Geöffnet-Status, Kategorien, Mindestbestand)
│   ├── meal_plan/                     # Wochenplaner (KI-Generierung, Slots)
│   ├── nutrition/                     # Ernährungstracking
│   ├── onboarding/                    # 3-Seiten Onboarding + Welcome-After-Register
│   ├── pantry/                        # Einkauf & Vorrat Tab-Container
│   ├── profile/                       # User-Profil, Following-Feed, Social Posts
│   ├── recipes/                       # Küche-Tab (KI-Rezepte, Manuell, Detail, Cooking-Mode)
│   ├── scanner/                       # Barcode-Scanner (OpenFoodFacts)
│   ├── settings/                      # Einstellungen, Paywall
│   └── shopping_list/                 # Einkaufslisten (Einkaufsmodus)
├── models/                            # Daten-Klassen
│   ├── recipe.dart                    # FoodRecipe, RecipeIngredient, NutritionInfo
│   ├── inventory_item.dart            # InventoryItem, Ingredient, IngredientNutrients
│   ├── community.dart                 # Community Model
│   ├── community_recipe.dart          # CommunityRecipe
│   ├── user_profile.dart              # UserProfile
│   ├── shopping_list.dart / _item.dart
│   └── ...
└── widgets/                           # Shared Widgets (CookingSpoonRating, TagPickerSheet, etc.)
```

---

## 3. Core Entities

### FoodRecipe (`lib/models/recipe.dart`)
```
id, title, description, cookingTimeMinutes, difficulty, servings,
ingredients: List<RecipeIngredient>,  steps: List<String>,
nutrition: NutritionInfo?, imageUrl?, tags: List<String>,
category: String? (Frühstück|Mittagessen|Abendessen|Snack),
source: String (own|ai|community), savedRecipeId?
```

### InventoryItem (`lib/models/inventory_item.dart`)
```
id, visibleName, ingredientName, amount, unit, category?,
householdId?, expirationDate?, minimumStock, barcode?,
nutrientInfo: IngredientNutrients?, openedAt?, consumedPercent,
isRemnant, createdAt, updatedAt
```

### IngredientNutrients (`lib/models/inventory_item.dart`)
```
kcalPer100g?, proteinPer100g?, fatPer100g?, carbsPer100g?,
fiberPer100g?, saltPer100g?
hasData → bool
forGrams(double) → IngredientNutrients
```

### IngredientEntry (`lib/core/data/ingredient_catalog.dart`)
```
name, category, canonicalId, defaultUnit?, aliases: List<String>
```
> **Keine Nährwerte hier!** → Nährwerte sind in `nutrient_data.dart`

### UserProfile (`lib/models/user_profile.dart`)
```
displayName (Community-Anzeigename), householdNickname (Haushalt-Spitzname)
```

---

## 4. Nährwert-Architektur (WICHTIG!)

**Trennung der Verantwortlichkeiten:**

| Datei | Zweck |
|---|---|
| `ingredient_catalog.dart` | Nur Zutatennamen, Kategorien, Einheiten, Aliases. **Keine Nährwerte.** |
| `nutrient_data.dart` | Statische Nährwert-Map (`canonicalId → [kcal, protein, fat, carbs]`). ~500+ Einträge. |
| `nutrition_service.dart` | Zentrale Auflösung: Scan (OpenFoodFacts) → Manuell → Katalog (`nutrient_data.dart`) → Kategorie-Fallback |
| `IngredientNutrients` (inventory_item.dart) | Runtime-Modell für Nährwerte, wird in InventoryItem und RecipeDetail verwendet |

**Lookup-Kette bei Rezept-Nährwertberechnung (`recipe_detail_screen.dart`):**
1. `recipe.nutrition` direkt (KI-generiert) → exakte Werte
2. `_computeNutrientsFromInventory()` → Inventar + Katalog-Fallback
   - Prüft erst `InventoryItem.nutrientInfo` (gescannt)
   - Dann `getNutrientsForIngredientName()` aus `nutrient_data.dart`
   - Zeigt Abdeckung an: "~Schätzwert (basierend auf X/Y Zutaten)"

**Wenn neue Lebensmittel hinzugefügt werden:**
- Zutat in `ingredient_catalog.dart` mit `canonicalId`
- Nährwerte in `nutrient_data.dart` Map `_nutrientsByCanonicalId` hinzufügen

---

## 5. Pro/Free Feature-Gates

| Feature | Free | Pro |
|---|---|---|
| Rezepte erstellen/bearbeiten | ✅ | ✅ |
| KI-Rezeptgenerierung | 3/Tag | Unbegrenzt |
| Wochenplan erstellen/speichern | ❌ | ✅ |
| Wochenplan teilen/übernehmen | ❌ | ✅ |
| Community erstellen | ❌ | ✅ |
| Community beitreten | ✅ | ✅ |

Gate-Prüfung: `ref.watch(isProProvider)` via RevenueCat.

---

## 6. Supabase-Tabellen (Kern)

```
saved_recipes          → Gespeicherte Rezepte (recipe_json JSONB)
inventory_items        → Vorrat (mit nutrient_info JSONB, opened_at, consumed_percent)
shopping_lists         → Einkaufslisten
shopping_list_items    → Einzelne Artikel
meal_plan_templates    → Wochenplan-Vorlagen
household_members      → Haushaltsmitglieder (display_name)
social_profiles        → Community-Profil (display_name unique)
social_posts           → Feed-Posts (mit attached_recipe_id, attached_plan_id)
community_recipes      → Veröffentlichte Rezepte
community_meal_plans   → Veröffentlichte Wochenpläne
communities            → Lokale Communities (PLZ-basiert)
community_members      → Mitgliedschaft + Rolle
community_posts        → Community-Posts
community_shares       → Teilen/Verschenken von Lebensmitteln
push_tokens            → Push-Token Registrierung
```

---

## 7. Coding Standards & Regeln

### Allgemein
- **Sprache:** Dart, UI-Texte auf Deutsch
- **State:** Riverpod `FutureProvider`, `StateNotifierProvider`, `AsyncNotifier`
- **Navigation:** `context.go()` für Tab-Wechsel, `context.push()` für Detailseiten
- **Fehler:** Immer `try/catch` mit Sentry-Reporting + User-Snackbar
- **Datei-Encoding:** UTF-8 ohne BOM (⚠ BOM `U+FEFF` verursacht Build-Fehler!)

### Namenskonventionen
- Dateien: `snake_case.dart`
- Klassen: `PascalCase`
- Provider: `camelCaseProvider` (z.B. `inventoryProvider`, `savedRecipesProvider`)
- Private Methoden: `_camelCase`
- Constants: `kCamelCase` (z.B. `kStapleSpices`)

### Feature-Ordner-Struktur
```
features/
  <feature>/
    data/           → Repository-Implementierungen
    domain/         → Repository-Interfaces (optional)
    presentation/   → Screens, Widgets, Provider
```

### UI-Patterns
- **Tags:** Immer `TagPickerSheet.show()` verwenden (einheitliches Bottom-Sheet)
- **Kategorien:** Nur 4 Mahlzeit-Kategorien: Frühstück, Mittagessen, Abendessen, Snack
- **Tabs:** Icon + Text in einer Row (nicht 2 Zeilen)
- **Non-Pro-Gates:** Buttons ausgegraut + SnackBar "Nur mit Pro verfügbar" (SnackBar auto-dismiss!)
- **Eigene Rezepte:** Kein Like/Save/Rating für eigene Rezepte
- **Gewürze:** `kStapleSpices` (staple_ingredients.dart) werden nie als "fehlend" markiert

### Anti-Patterns (VERMEIDEN!)
- ❌ Nährwerte direkt in `IngredientEntry` – immer `nutrient_data.dart` verwenden
- ❌ `const` vor Screens mit optionalen Parametern (verursacht Build-Fehler)
- ❌ BOM-Zeichen am Dateianfang
- ❌ Duplizierte Provider-Namen in derselben Datei
- ❌ `AnimatedContainer` mit `BoxConstraints(w=Infinity)` → `BoxConstraints(w=0)` Interpolation crasht

---

## 8. API Keys & Umgebung

Alle Keys in `.env` (gitignored!):
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
GROQ_API_KEY=
SENTRY_DSN=
REVENUECAT_ANDROID_KEY=
REVENUECAT_IOS_KEY=
```

---

## 9. Build & Deploy

```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# Analyse
dart analyze lib/
```

Vor Release prüfen:
- [ ] `.env` Werte korrekt
- [ ] Keine BOM-Zeichen (`U+FEFF`)
- [ ] `flutter analyze` clean
- [ ] Supabase Migrations ausgeführt
- [ ] RevenueCat Produkte konfiguriert

---

## 10. Offene Architektur-Entscheidungen

- **iOS:** Geplant in ~6 Monaten, dann `REVENUECAT_IOS_KEY` + Apple Store Setup
- **Push-Notifications:** Firebase FCM vorbereitet (`push_tokens` Tabelle existiert)
- **Offline-Fallback:** `connectivity_service.dart` + `offline_sync_service.dart` vorhanden
- **Nährwert-Erweiterung:** Bei neuem Lebensmittel → `ingredient_catalog.dart` + `nutrient_data.dart` Map erweitern

