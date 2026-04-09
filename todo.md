# kokomu – App-Verbesserungen Tracker

## Plan: 8 App-Verbesserungen & Bug-Fixes (alle erledigt ✅)

| # | Aufgabe | Status |
|---|---------|--------|
| 1 | Route-Fix "Plan erstellen" im Profil | ✅ |
| 2 | Shopping-Cart-Button → Auswahl-Dialog | ✅ |
| 3 | Eigene Rezepte: Like/Save/Favorit ausblenden | ✅ |
| 4 | Gewürze nicht als "fehlend" markieren | ✅ |
| 5 | Non-Pro Wochenplan-Gate | ✅ |
| 6 | Anzeigename / Haushaltsname trennen | ✅ |
| 7 | Tags im Rezept-Editor | ✅ |
| 8 | 5 KI-Rezepte + Airfryer/OnePot | ✅ |

---

## Neue Verbesserungen (April 2026)

| # | Aufgabe | Status |
|---|---------|--------|
| 9  | 3-stufiger Registrierungsflow (E-Mail/PW → Namen → Woher+AGB) | ✅ Erledigt |
| 10 | Non-Pro: + und Ordner-Button ausgegraut; `...` komplett disabled mit Pro-Hinweis | ✅ Erledigt |
| 11 | Einkaufsmodus in shopping_list_screen (übersichtliche Darstellung, Fortschrittsbalken) | ✅ Erledigt |
| 12 | "Liste abschließen" Dialog (In Vorrat übernehmen / Leeren) | ✅ Erledigt |
| 13 | Tags-UI: TagPickerSheet mit klarer Trennung (Ausgewählt vs. Vorschläge) + eigener Tag | ✅ Erledigt |

---

## Noch offen / Ausstehend

- Supabase Migration 24 ausführen (`supabase_migration_24_household_nickname.sql`)
- `shoppingListRepository.deleteItem` muss für `clearAll` verfügbar sein (prüfen)
- iOS: Noch für später geplant


## Plan: 8 App-Verbesserungen & Bug-Fixes

| # | Aufgabe | Status |
|---|---------|--------|
| 1 | Route-Fix "Plan erstellen" im Profil | ✅ War bereits korrekt (`context.push('/kitchen/meal-plan/new')`, `NewMealPlanScreen()` ohne const) |
| 2 | Shopping-Cart-Button → Auswahl-Dialog (Bottom-Sheet mit Checkboxen) | ✅ War bereits implementiert als `_KitchenShoppingSheet` mit Vorauswahl (nicht im Vorrat + nicht Basis-Zutat) |
| 3 | Eigene Rezepte: Like/Save/Favorit ausblenden | ✅ War bereits implementiert (`if (recipe.source != 'own')`) |
| 4 | Gewürze nicht als "fehlend" markieren | ✅ Erledigt – `kStapleIngredients` massiv erweitert, `IngredientCatalog.isSpiceByName()` integriert |
| 5 | Non-Pro Wochenplan-Gate mit ausgegrautem Menü (Option B) | ✅ War bereits implementiert (`enabled: isPro`, Lock-Icon) |
| 6 | Anzeigename (Community) + Haushaltsname trennen | ✅ Erledigt – `householdNickname` in `UserProfile`, Repository, Provider und `edit_profile_screen.dart` |
| 7 | Tags im Rezept-Editor (manual_recipe_screen + edit_sheet) | ✅ Erledigt – Chip-Autocomplete mit Standard-Tags in `manual_recipe_screen.dart` und `_EditRecipeSheet`, Tags werden gespeichert und angezeigt |
| 8 | Mehr KI-Rezepte: 5 statt 3 + Airfryer/OnePot in _styleTags | ✅ Erledigt – `groq_service.dart` auf EXAKT 5, `_styleTags` in `kitchen_screen.dart` ergänzt |

---

## Geänderte Dateien

- `lib/core/data/ingredient_catalog.dart` – `searchCooking()`, `isSpice()`, `isSpiceByName()` hinzugefügt
- `lib/core/constants/staple_ingredients.dart` – massiv erweitert, nutzt jetzt `IngredientCatalog.isSpiceByName()`
- `lib/features/recipes/presentation/manual_recipe_screen.dart` – Tags-UI (Chip-Autocomplete), `searchCooking` statt `search`
- `lib/features/recipes/presentation/recipe_detail_screen.dart` – Tags in `_EditRecipeSheet` (anzeigen + bearbeiten), Tags-Chips in Detailansicht
- `lib/core/services/groq_service.dart` – 5 statt 3 Rezepte in allen Prompts
- `lib/features/recipes/presentation/kitchen_screen.dart` – Airfryer + OnePot in `_styleTags`
- `lib/models/user_profile.dart` – `householdNickname` Feld hinzugefügt
- `lib/features/profile/data/user_profile_repository.dart` – `householdNickname` im `updateProfile`
- `lib/features/profile/presentation/profile_provider.dart` – `householdNickname` Parameter
- `lib/features/profile/presentation/edit_profile_screen.dart` – Haushalts-Spitzname Feld in UI

## Nächste offene Punkte (optional)

- Supabase Migration: `household_nickname` Spalte in `user_profiles` Tabelle hinzufügen (ALTER TABLE)
- Tags im Rezept auch beim Veröffentlichen in Community mitgeben
- `isOwn`-Check auch in Community-Rezept-Detail (kein Like bei eigenen veröffentlichten Rezepten)


## Plan: 8 App-Verbesserungen & Bug-Fixes

| # | Aufgabe | Status |
|---|---------|--------|
| 1 | Route-Fix "Plan erstellen" im Profil | ✅ Bereits korrekt (`context.push('/kitchen/meal-plan/new')`, `NewMealPlanScreen()` ohne const) |
| 2 | Shopping-Cart-Button → Auswahl-Dialog (Bottom-Sheet mit Checkboxen) | ✅ Bereits implementiert als `_KitchenShoppingSheet` |
| 3 | Eigene Rezepte: Like/Save/Favorit ausblenden | ✅ Bereits implementiert (`if (recipe.source != 'own')`) |
| 4 | Gewürze nicht als "fehlend" markieren (kStapleIngredients erweitert, isSpiceByName) | ✅ Erledigt |
| 5 | Non-Pro Wochenplan-Gate mit ausgegrautem Menü (Option B) | ✅ Bereits implementiert (enabled: isPro, Lock-Icon) |
| 6 | Anzeigename (Community) + Haushaltsname trennen | 🔲 Offen |
| 7 | Tags im Rezept-Editor (manual_recipe_screen + edit_sheet) | 🔲 Offen |
| 8 | Mehr KI-Rezepte: 5 statt 3 + Airfryer/OnePot in _styleTags | 🔲 Offen |

---

## Details

### Schritt 6 – Anzeigename / Haushaltsname
- `UserProfile` um `householdNickname` erweitern
- `edit_profile_screen.dart` separates Feld hinzufügen
- Community-`displayName` gegen `social_profiles` eindeutig prüfen

### Schritt 7 – Tags im Rezept-Editor
- Tags-Chip-Input in `manual_recipe_screen.dart` (Standard-Tags: Airfryer, OnePot, MealPrep, Vegan, Vegetarisch, Glutenfrei, Low Carb, High Protein, Schnell, Backen…)
- Tags beim Speichern in `FoodRecipe.tags` mitschreiben
- Tags auch im `_EditRecipeSheet` (recipe_detail_screen.dart) befüllen
- Tags im `recipe_detail_screen.dart` anzeigen

### Schritt 8 – Mehr KI-Rezepte (5 statt 3)
- `groq_service.dart`: `_randomHint()` auf 5 Küchen, alle Prompts auf „EXAKT 5"
- `kitchen_screen.dart`: `_styleTags` um Airfryer und OnePot ergänzen

