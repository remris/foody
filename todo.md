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


---

## Feature: Meine Communities ✅ Implementiert

### Design-Entscheidungen (abgestimmt)
| Punkt | Entscheidung |
|-------|-------------|
| Beitritt | Per Einladungscode **oder** PLZ-Suche – beides möglich |
| Genehmigung | Admin muss jeden Beitritt manuell bestätigen (wie Haushalt) |
| Pro-Gate | Nur **Erstellen** einer Community erfordert Pro; Beitreten ist kostenlos |
| Max. Mitglieder | **50 pro Community** (Supabase-Trigger erzwingt Limit) |
| Community-Feed | Rein intern – nur Mitglieder sehen Posts, **nicht** im globalen Feed |
| Reste-Sharing | Nach „Abgeholt"-Klick wird Eintrag sofort gelöscht (Supabase-Trigger) – keine Eskalation der Liste |
| Einstiegspunkt | Avatar-Menü → **Meine Communities** (unter „Mein Haushalt") |

### Implementierte Dateien
| Datei | Beschreibung |
|-------|-------------|
| `supabase_migration_26_communities.sql` | Tabellen: communities, community_members, community_posts, community_shares + Trigger + RLS |
| `lib/models/community.dart` | Models: Community, CommunityMember, CommunityPost, CommunityShare |
| `lib/features/community/data/community_local_repository.dart` | Alle DB-Operationen |
| `lib/features/community/presentation/community_local_provider.dart` | Riverpod-Provider + Actions-Notifier |
| `lib/features/community/presentation/community_list_screen.dart` | Übersicht, Erstellen (Pro), Beitreten (Code + PLZ) |
| `lib/features/community/presentation/community_detail_screen.dart` | Feed / Teilen / Mitglieder-Tabs; Admin-Verwaltung |
| `lib/widgets/main_shell.dart` | Menü-Eintrag „Meine Communities" + Route `/communities` |
| `lib/core/router/app_router.dart` | Route `/communities` → `CommunityListScreen` |

### Noch ausstehend (vor Go-Live)
- [ ] `supabase_migration_26_communities.sql` im Supabase-Dashboard ausführen
- [ ] `community_posts` Tabelle: Spalte `author_name` + `author_avatar` aus `social_profiles` via JOIN befüllen (alternativ reicht der gecachte `author_name` beim Insert)
- [ ] Push-Benachrichtigung wenn Beitrittsanfrage genehmigt wird (optional, spätere Erweiterung)

---

## Feature: Community Teilen – Erweiterter Usecase (Abholungs-Flow + Hilfsanfragen)

### Konzept
Der Teilen-Tab in der Community soll zwei Bereiche haben:
1. **Angebote** (Reste / Lebensmittel verschenken)
2. **Suchanfragen** (z.B. „Ich brauche eine Tasse Zucker")

### Angebote – erweiterter Flow
| Schritt | Beschreibung |
|---------|-------------|
| Erstellen | User erstellt Angebot (Name, Menge, Hinweis) |
| Anfragen | Anderer User klickt „Abholen anfragen" → Ersteller sieht die Anfrage unter seinem Angebot |
| Bestätigen | Ersteller bestätigt einen Abholer (andere Anfragen werden abgelehnt) |
| Mini-Chat | Nach Bestätigung: Ersteller ↔ Abholer schreiben kurz (Ort, Zeitpunkt) |
| Abschließen | Ersteller markiert als „Abgeholt" → Eintrag wird gelöscht |

### Suchanfragen – neuer Flow
| Schritt | Beschreibung |
|---------|-------------|
| Erstellen | User erstellt Anfrage: z.B. „5 Eier gesucht" |
| Aushelfen | Anderer User klickt „Aushelfen" → Ersteller sieht das Angebot |
| Mini-Chat | Ersteller akzeptiert → Ersteller ↔ Aushelfer kommunizieren (Wo/Wann) |
| Schließen | Ersteller schließt Anfrage → wird gelöscht |

### Benötigte DB-Tabellen
- `community_share_requests` – Abholungsanfragen für ein Angebot  
  `(id, share_id, community_id, user_id, display_name, message, status: pending/accepted/rejected, created_at)`
- `community_help_requests` – Suchanfragen  
  `(id, community_id, user_id, display_name, item_name, quantity, note, status: open/closed, created_at)`
- `community_help_offers` – Angebote auf Suchanfragen  
  `(id, request_id, community_id, user_id, display_name, message, status: pending/accepted, created_at)`
- `community_messages` – Mini-Chat (für Shares & Help)  
  `(id, context_type: share/help, context_id, sender_id, sender_name, recipient_id, text, created_at, read_at)`

### Implementierung  
- [x] SQL Migration: `supabase_migration_27_share_requests.sql`
- [x] Models: `CommunityShareRequest`, `CommunityHelpRequest`, `CommunityHelpOffer`, `CommunityMessage`
- [x] Repository: community_local_repository.dart erweitert
- [x] Provider: community_local_provider.dart erweitert
- [x] UI: Share-Tab mit 2 Sub-Tabs (Angebote / Suche), Anfragen-Badge, Mini-Chat-Sheet


