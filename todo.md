# TODO – Smart Kitchen App (Kokomi)

> Stand: 2026-04-08 (aktualisiert)
> Grundlage: `project.md` + `feature.md` + aktueller Projektstatus + Feature-Planung

---

## 🚀 Release-Checkliste – MANUELL ERLEDIGEN

> Diese Punkte können nicht automatisch gemacht werden und müssen vor dem Store-Upload manuell durchgeführt werden.

### 🔴 BLOCKER – Ohne diese kein Store-Upload!

- [x] **App-Name final entscheiden** – **Kokomi** ✅ Domain `kokomi.app` gesichert
- [x] **App-Icon erstellen** (1024×1024px PNG, kein Alpha-Kanal) → in alle Auflösungen via `flutter_launcher_icons` exportiert; Android: `mipmap-*`, iOS: `AppIcon.appiconset` ✅
- [x] **RevenueCat-Integration** – `purchases_flutter` in `pubspec.yaml`, RevenueCat Dashboard konfiguriert ✅
- [x] **Groq-Proxy verifizieren** – Edge Function deployed, `.env` in `.gitignore` ✅
- [x] **Datenschutzerklärung** – DSGVO-konform erstellt (`assets/privacy_policy.html`), in Settings verlinkt ✅
- [x] **Nutzungsbedingungen / AGB** – erstellt (`assets/terms_of_service.html`), in Settings verlinkt ✅
- [x] **Impressum** – erstellt (`assets/imprint.html`), in Settings verlinkt ✅ ⚠️ Bitte eigene Adresse eintragen!
- [x] **Android Signing-Keystore erstellen** – `foody-release.jks` vorhanden, in `build.gradle.kts` eingetragen ✅
- [ ] **iOS Bundle-ID / Signing** – wird erst in ~6 Monaten benötigt (Android-First-Strategie)

### 🟡 WICHTIG – Sollte vor Launch fertig sein

- [ ] **Sentry Crash-Monitoring einbinden:**
  1. `sentry_flutter: ^8.0.0` in `pubspec.yaml`
  2. Supabase-Secret `SENTRY_DSN` setzen (aus sentry.io kostenlosem Account)
  3. `main.dart` mit `SentryFlutter.init(...)` wrappen
  4. Kostenloses Tier: 5.000 Events/Monat (reicht für Start)

- [ ] **RLS Security Audit** – Alle Supabase-Tabellen prüfen: `community_recipes`, `user_inventory`, `meal_plans`, `nutrition_log`, `saved_recipes`, `user_follows`, `push_tokens` – kein User darf fremde private Daten lesen. Besonders `meal_plans` (Haushalt vs. persönlich) und `nutrition_log` sind kritisch.

- [ ] **Push Notifications (FCM) einrichten:**
  1. Firebase-Projekt anlegen (console.firebase.google.com)
  2. `google-services.json` → `android/app/` + `GoogleService-Info.plist` → `ios/Runner/`
  3. `firebase_core: ^3.x` + `firebase_messaging: ^15.x` in `pubspec.yaml`
  4. `push_notification_service.dart` implementieren (Token speichern, Foreground/Background)
  5. Supabase-Migration `supabase_migration_20_push_tokens.sql` ausführen
  6. Supabase Edge Function `send-push` deployen (MHD-Trigger, Haushalt-Events)
  7. Settings-Screen: Notification-Einstellungen UI hinzufügen
  8. APNs-Zertifikat für iOS in Apple Developer Console erstellen

- [ ] **Play Store Listing vorbereiten** – Screenshots (mind. 2, empfohlen 5-8), Kurzbeschreibung (80 Zeichen), Langbeschreibung (4.000 Zeichen), Kategorie: „Essen & Trinken", Content-Rating ausfüllen
- [ ] **App Store Listing vorbereiten** – analog Play Store, zusätzlich: App-Vorschau-Video optional, Altersfreigabe

### 🟢 OPTIONAL – Kann auch nach Launch gemacht werden

- [ ] **flutter_launcher_icons.yaml** Konfigurationsdatei anlegen (nach Icon-Erstellung)
- [ ] **Account löschen** Funktion in Settings implementieren (DSGVO Art. 17 – Recht auf Löschung)
- [ ] **Daten exportieren** Funktion in Settings (DSGVO Art. 20 – Recht auf Datenportabilität), JSON-Export aller User-Daten
- [ ] **Consent-Banner** beim ersten Start für optionales Analytics-Tracking
- [ ] **RevenueCat Google Play Billing** – Google Play Console: Abos anlegen (`foody_pro_monthly`, `foody_pro_yearly`), Service-Account mit RevenueCat verknüpfen
- [ ] **RevenueCat App Store Connect** – Abos anlegen, Sandbox-Tester für Tests

---

## 🔔 Phase 34 – Push Notifications (Details)

### Neue Dateien
- [ ] `lib/core/services/push_notification_service.dart` – FCM-Token, Local Notifications, Permission-Request
- [ ] `supabase_migration_20_push_tokens.sql` – `push_tokens` + `notification_settings` Tabellen
- [ ] `supabase/functions/send-push/index.ts` – Edge Function für FCM-Versand

### Geänderte Dateien
- [ ] `main.dart` – `PushNotificationService.initialize()` beim App-Start
- [ ] `lib/features/settings/presentation/settings_screen.dart` – Notification-Präferenzen UI
- [ ] `pubspec.yaml` – `firebase_core` + `firebase_messaging` hinzufügen
- [ ] `android/app/build.gradle.kts` – `com.google.gms.google-services` Plugin aktivieren
- [ ] `android/settings.gradle.kts` – Google Services Plugin

---

## 💳 Phase 33 – RevenueCat (echte IAP)

### Voraussetzungen (manuell)
- [ ] RevenueCat Account erstellen (app.revenuecat.com, kostenlos bis 2.500 $/MTR)
- [ ] Android App anlegen + Google Play Billing API-Key verknüpfen
- [ ] iOS App anlegen + App Store Connect API-Key verknüpfen
- [ ] Entitlement `pro` erstellen
- [ ] Products: `foody_pro_monthly` (2,99 €) + `foody_pro_yearly` (19,99 €)
- [ ] Webhook-URL: `https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook`

### Neue Dateien
- [ ] `supabase/functions/revenuecat-webhook/index.ts` – Webhook empfängt Abo-Events → `subscriptions` Tabelle aktualisieren

### Geänderte Dateien
- [ ] `pubspec.yaml` – `purchases_flutter: ^8.0.0`
- [ ] `lib/features/settings/presentation/subscription_provider.dart` – RevenueCat statt lokaler Prüfung
- [ ] `lib/features/settings/presentation/paywall_screen.dart` – Echte Preise + Kauf-Logik
- [ ] `main.dart` – `Purchases.configure(...)` + `Purchases.logIn(userId)`

---

## 🎨 Phase 37 – App-Icon

### Schritte
- [ ] Icon-Konzept finalisieren (Empfehlung B „Fork & Leaf": Teal #00695C + Gabel-Blatt)
- [ ] 1024×1024px PNG erstellen (Figma / icon.kitchen / Illustrator)
- [ ] `assets/icon/` Ordner anlegen, `app_icon.png` + `app_icon_foreground.png` (Android Adaptive) ablegen
- [ ] `pubspec.yaml` dev_dependencies: `flutter_launcher_icons: ^0.14.0`
- [ ] `flutter_launcher_icons.yaml` im Root anlegen
- [ ] `dart run flutter_launcher_icons` ausführen
- [ ] Icons in `android/app/src/main/res/mipmap-*` und `ios/Runner/Assets.xcassets/AppIcon.appiconset` prüfen

---

### Abhängigkeiten & Konfiguration
- [x] `pubspec.yaml` – alle benötigten Pakete hinzugefügt
  - [x] `flutter_riverpod` + `riverpod_annotation`
  - [x] `go_router`
  - [x] `supabase_flutter`
  - [x] `mobile_scanner`
  - [x] `dio`
  - [x] `freezed_annotation` + `freezed`
  - [x] `json_serializable` + `json_annotation`
  - [x] `build_runner`
  - [x] `flutter_dotenv`
  - [x] `riverpod_generator` + `riverpod_lint` + `custom_lint`
  - [x] `shared_preferences`
- [x] `flutter pub get` ausgeführt
- [x] `.env`-Datei angelegt (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `OPENAI_API_KEY`)
- [x] `.env` in `.gitignore` eingetragen
- [x] `.env` als Flutter-Asset registriert

### Ordnerstruktur ✅
- [x] `lib/core/constants/` – `app_constants.dart`, `app_theme.dart`, `color_schemes.dart`
- [x] `lib/core/services/` – `supabase_service.dart`, `openai_service.dart`, `theme_provider.dart`
- [x] `lib/core/utils/` – `extensions.dart`
- [x] `lib/core/router/` – `app_router.dart`
- [x] `lib/features/auth/` (data / domain / presentation)
- [x] `lib/features/inventory/` (data / domain / presentation)
- [x] `lib/features/recipes/` (data / domain / presentation)
- [x] `lib/features/shopping_list/` (data / domain / presentation)
- [x] `lib/features/scanner/` (data / domain / presentation)
- [x] `lib/features/settings/` (presentation)
- [x] `lib/models/` – `app_user.dart`, `inventory_item.dart`, `recipe.dart`, `shopping_list_item.dart`
- [x] `lib/widgets/` – `main_shell.dart`

### App-Einstiegspunkt ✅
- [x] `main.dart` – Supabase init, ProviderScope, GoRouter, Theme
- [x] `go_router` konfiguriert (alle Routen + Auth-Guard)

---

## 🔐 Phase 2 – Authentifizierung ✅ CODE FERTIG

### Models & Repository ✅
- [x] `AuthRepository` Interface + `AuthRepositoryImpl` (Supabase Auth)
  - [x] `signUp`, `signIn`, `signOut`, `getCurrentUser`, Auth-Stream

### State Management ✅
- [x] `AuthNotifier` + `AuthProvider` (Riverpod AsyncNotifier)
- [x] `currentUserProvider`, `authStateProvider`

### UI ✅
- [x] `LoginScreen` mit Validierung
- [x] `RegisterScreen` mit Validierung
- [x] Fehlerbehandlung via SnackBar
- [x] Auth-Guard im Router (Redirect Login ↔ Home)

### ⏳ Supabase (du musst eingreifen)
- [x] **Supabase-Projekt erstellt**
- [x] **Auth aktiviert** (E-Mail/Passwort)
- [x] **URL + Anon-Key** in `.env` eingetragen

---

## 🥦 Phase 3 – Inventar-System ✅ CODE FERTIG (Basis)

### Models & Repository ✅
- [x] `Ingredient`-Model, `InventoryItem`-Model
- [x] `InventoryRepository` Interface + `InventoryRepositoryImpl` (Supabase)

### State Management ✅
- [x] `InventoryNotifier` (AsyncNotifier) – add / update / delete / refresh
- [x] `filteredInventoryProvider` (nach Kategorie)
- [x] `sortedInventoryProvider` (nach Ablaufdatum)
- [x] `categoriesProvider`

### UI ✅
- [x] `InventoryScreen` – Liste mit FilterChips + FAB
- [x] `_InventoryItemCard` – Ablaufdatum-Farbanzeige, Swipe-to-Delete
- [x] `AddInventoryItemSheet` – manuell hinzufügen/bearbeiten
- [x] Empty State

### ⏳ Supabase (du musst eingreifen)
- [ ] **Supabase-Tabelle `user_inventory`** anlegen – SQL siehe unten (Abschnitt "Supabase-Setup")

---

## 📷 Phase 4 – Barcode-Scanner ✅ CODE FERTIG

### Setup ✅
- [x] Android: `CAMERA`-Berechtigung in `AndroidManifest.xml`
- [x] iOS: `NSCameraUsageDescription` in `Info.plist`

### Data Layer ✅
- [x] `ScannerRepositoryImpl` – OpenFoodFacts API
- [x] `ScannerNotifier` / `scannerProvider`

### UI ✅
- [x] `ScannerScreen` – Kamera + Overlay + Torch/Flip
- [x] `_ScanResultSheet` – Produktname, Menge, Ablaufdatum, Inventar-Button
- [x] Fehlerbehandlung (Barcode nicht gefunden)

---

## 🍽️ Phase 5 – Rezept-Vorschläge (AI) ✅ CODE FERTIG (Basis)

### Data Layer ✅
- [x] `OpenAiService` – GPT-4o-mini Chat-Completion
- [x] `RecipeRepositoryImpl` – JSON-Response → `FoodRecipe`-Liste

### State Management ✅
- [x] `RecipeNotifier` – `generateFromInventory()`

### UI ✅
- [x] `RecipesScreen` – Liste + FAB + Empty State + Error State
- [x] `RecipeDetailScreen` – Zutaten, Schritte, Meta-Infos
- [x] Ladeindikator + Fehlerbehandlung

### ⏳ Keys (du musst eingreifen)
- [ ] **OpenAI API-Key** in `.env` eintragen (`OPENAI_API_KEY`)

---

## 🛒 Phase 6 – Einkaufsliste ✅ CODE FERTIG (Basis)

### Data Layer ✅
- [x] `ShoppingListItem`-Model
- [x] `ShoppingListRepositoryImpl` (Supabase)

### State Management ✅
- [x] `ShoppingListNotifier` – add / toggle / delete / clearChecked

### UI ✅
- [x] `ShoppingListScreen` – Eingabe + Checkbox-Liste + Swipe-to-Delete

### ⏳ Supabase (du musst eingreifen)
- [ ] **Supabase-Tabellen** anlegen – SQL siehe unten (Abschnitt "Supabase-Setup")

---

## 🎨 Phase 7 – UI / Design & Settings ✅ ERLEDIGT

- [x] App-Theme (Material 3, Light + Dark)
- [x] Dark Mode Support
- [x] 9 Farbschemata (Teal, Grün, Orange, Blau, Rot, Gelb, Lila, Deep Ocean, Rosé)
- [x] `color_schemes.dart` – Enum mit allen Farben
- [x] `theme_provider.dart` – Riverpod Provider + SharedPreferences Persistenz
- [x] `settings_screen.dart` – Farbwahl-Grid + Dark/Light/System Toggle + Logout
- [x] Settings-Tab in Navigation (5. Tab)
- [x] Empty States für alle Listen
- [x] Error States mit Retry-Button
- [x] Ladeindikator überall
- [ ] App-Icon anpassen
- [ ] Splash Screen anpassen

---

## 🏷️ Phase 8 – Kategorien & Tags ✅ CODE FERTIG

> Items wie Snacks, Gemüse, Getränke etc. als Kategorien/Tags verfügbar machen, um Inventar übersichtlich zu halten und neue Scans einfach einzuordnen.

### Vordefinierte Kategorien
- [x] `lib/core/constants/food_categories.dart` erstellt mit 14 vordefinierten Kategorien:
  - Obst, Gemüse, Fleisch & Fisch, Milchprodukte, Getränke, Snacks, Backwaren, Tiefkühl, Konserven, Gewürze & Kräuter, Öle & Soßen, Getreide & Nudeln, Süßigkeiten, Sonstiges
- [x] Jede Kategorie mit Icon und Farbe versehen
- [x] OpenFoodFacts-Mapping (`FoodCategory.fromOpenFoodFacts()`)

### Inventar-Integration
- [x] `AddInventoryItemSheet` erweitert: Kategorie-Auswahl als Chip-Grid
- [x] Scanner: automatische Kategorie-Zuweisung aus OpenFoodFacts `categories_tags`
- [x] `InventoryScreen`: Filter-Chips mit Icons und Farben
- [x] Filter-Chips aus vordefinierten Kategorien (die im Inventar vorkommen)

### Tags (erweitert)
- [x] `InventoryItem`-Model um `tags` (List<String>) erweitert
- [ ] UI für Freitext-Tags pro Item (z.B. "Bio", "Glutenfrei", "Vegan")

---

## 📋 Phase 9 – Produkt-Detailseite (Food Facts) ✅ CODE FERTIG

> Gegenstände im Detail anschauen können: Nährwerte, Bilder, Nutri-Score, Marke etc.

### OpenFoodFacts erweitern
- [x] `ScannerRepositoryImpl` erweitert: `lookupProductDetails()` mit zusätzlichen Feldern:
  - `nutriments` (kcal, Fett, Kohlenhydrate, Eiweiß, Zucker, Salz pro 100g)
  - `nutriscore_grade` (A–E)
  - `brands`, `quantity`, `allergens_tags`, `labels_tags`
- [x] Neues Model `ProductDetails` in `lib/models/product_details.dart`

### UI
- [x] `lib/features/inventory/presentation/item_detail_screen.dart` erstellt:
  - Produktbild, Name, Kategorie-Badge
  - Bestandsinfo (Menge, Ablaufdatum, Mindestbestand)
  - Nutri-Score Badge (A–E farbig)
  - Nährwert-Tabelle mit Fortschrittsbalken
  - Allergene & Labels
  - Barcode-Nummer
- [x] Route `/inventory/detail` in `app_router.dart`
- [x] Tap auf `_InventoryItemCard` → navigiert zur Detailseite
- [x] Barcode-Lookup über FutureProvider.family (Auto-Cache via Riverpod)

---

## 🔄 Phase 10 – Multi-Einkaufslisten ✅ CODE FERTIG

> Mehrere Listen (z.B. "Kaufland", "Edeka", "Obi") statt nur einer einzigen.

### Datenmodell
- [x] Neues Model `ShoppingList` in `lib/models/shopping_list.dart`
- [x] `ShoppingListItem` um `listId`-Feld erweitert
- [x] Supabase-Tabellen: `shopping_lists` + `shopping_list_items`

### State Management
- [x] `ShoppingListsNotifier` – CRUD für Listen (erstellen, umbenennen, löschen)
- [x] `ShoppingListNotifier` – Items pro ausgewählter Liste laden/verwalten
- [x] `selectedShoppingListProvider` – aktuelle Liste

### UI
- [x] ChoiceChips für Listen-Tabs (horizontal scrollbar)
- [x] Neue Liste erstellen Dialog (Name)
- [x] Long-Press auf Liste → Umbenennen / Löschen
- [x] Default-Liste "Einkauf" automatisch erstellt bei erstem Login
- [x] Neuer "+" Button in AppBar für neue Listen

---

## 📦 Phase 11 – Auto-Nachkauf (Threshold) ✅ CODE FERTIG

> Wenn Items im Inventar auf 0 gehen oder einen Threshold unterschreiten → automatisch auf Einkaufsliste.

### Datenmodell
- [x] `InventoryItem` um `minThreshold` (double, default 0) erweitert
- [x] `AddInventoryItemSheet`: Feld "Mindestbestand" hinzugefügt

### Logik
- [x] In `InventoryNotifier.updateItem()`: Prüfung ob `quantity <= minThreshold`
  - Auto-Add auf Einkaufsliste wenn Threshold unterschritten
  - Duplikat-Check: nur hinzufügen wenn nicht bereits auf Einkaufsliste
- [x] SharedPreferences-gesteuertes ein/aus (`auto_restock_enabled`)

### Settings
- [x] Global ein/aus Toggle in Settings: "Auto-Nachkauf aktivieren"
- [x] Pro Item konfigurierbar im Bearbeitungs-Sheet (Mindestbestand-Feld)

---

## 🍳 Phase 12 – Rezepte erweitern ⏳ TEILWEISE FERTIG

> Freitext-Rezeptgenerierung, Nährwerte, Speicherung, Zutaten → Einkaufsliste, Inventar-Auswahl, Online-Suche.

### 12a – Freitext-Prompt Generierung ✅
- [x] `RecipeNotifier` um `generateFromPrompt(String prompt)` erweitert
- [x] `OpenAiService` um `generateRecipesFromPrompt(String prompt)` erweitert
- [x] UI: Textfeld + "Generieren" Button im `RecipesScreen`
- [ ] Prompt-History speichern (optional)

### 12b – Inventar-basierte Auswahl ✅
- [x] `IngredientSelectionSheet` erstellt (BottomSheet mit Checkbox-Liste)
- [x] `RecipeNotifier.generateFromSelection()` implementiert
- [x] "Alle auswählen" / "Keine auswählen" Buttons
- [x] Optionaler zusätzlicher Wunsch (Freitext) bei Auswahl
- [x] Zwei Buttons im RecipesScreen: "Aus Vorrat" + "Zutaten wählen"

### 12c – Nährwert-Anzeige in Rezepten ✅
- [x] `FoodRecipe`-Model erweitert um `NutritionInfo` + `servings`
- [x] OpenAI-Prompt erweitert: Nährwerte pro Portion im JSON
- [x] `RecipeDetailScreen` erweitert: Nährwert-Karte mit Kalorien + Makro-Balken

### 12d – Rezepte speichern (Supabase) ✅
- [x] `SavedRecipeRepository` – CRUD (Supabase-Tabelle `saved_recipes`)
- [x] `SavedRecipesNotifier` – laden, speichern, löschen, Duplikat-Check
- [x] UI: Bookmark-Icon zum Speichern auf `RecipeDetailScreen`
- [x] TabBar im `RecipesScreen`: "Generieren" | "Gespeichert"

### 12e – Rezept-Zutaten auf Einkaufsliste packen ✅
- [x] Button "Zutaten einkaufen" auf `RecipeDetailScreen`
- [x] Dialog mit Checkbox-Liste aller Rezept-Zutaten
- [x] Vergleich mit Inventar: bereits vorhandene Zutaten automatisch abgehakt
- [x] Gewählte Zutaten → `ShoppingListNotifier.addItem()`

### 12f – Online-Rezeptsuche (TheMealDB) ✅
- [x] TheMealDB API integriert (kostenlos, kein API-Key nötig)
- [x] `OnlineRecipeService` in `lib/core/services/online_recipe_service.dart`
  - Suche nach Name, Zutat, Kategorie, Zufällig
  - TheMealDB JSON → FoodRecipe Konvertierung
- [x] `OnlineRecipeNotifier` + `onlineRecipeProvider`
- [x] 3. Tab "Online" im RecipesScreen
  - Suchfeld + Kategorie-Chips (Zufällig, Fleisch, Hähnchen, Vegetarisch, Fisch, Dessert, Pasta)
  - Ergebnisse im gleichen Format wie KI-Rezepte

---

## 🏠 Phase 13 – Einkauf → Inventar Übernahme ✅ CODE FERTIG

> Einfach bestimmen was eingekauft wurde und diese Items direkt ins Inventar übernehmen.

### Logik
- [x] Button "Ins Inventar übernehmen" auf der Einkaufsliste (AppBar-Action)
  - Nur abgehakte (gekaufte) Items werden übernommen
- [x] `TransferToInventorySheet`: Übernahme-Dialog mit Artikelliste
  - Schnell-Übernahme (Standardwerte, Details später bearbeiten)
- [x] `InventoryRepository.addItems()` Batch-Insert implementiert
- [x] Nach Übernahme: Option "Von Liste entfernen" (SwitchListTile)
- [x] Bestätigungs-SnackBar

### UI
- [x] `move_to_inbox` Icon in AppBar (nur sichtbar wenn abgehakte Items)
- [x] Übernahme-Sheet mit Artikelliste + Switch + Button

---

## ⏰ Phase 14 – Ablauf-Erinnerungen ✅ CODE FERTIG

> Push-Benachrichtigungen wenn Lebensmittel bald ablaufen.

### Setup
- [x] `flutter_local_notifications` Package hinzugefügt
- [x] `NotificationService` in `lib/core/services/notification_service.dart`
- [x] Android: Notification-Channel 'expiry_channel' konfiguriert
- [x] iOS: DarwinNotificationSettings konfiguriert

### Logik
- [x] Check beim Inventar-Laden: Items die in ≤ `warningDays` ablaufen
- [x] Notification: "⏰ X Artikel laufen bald ab" mit Item-Namen
- [x] `NotificationService.initialize()` in `main.dart`

### Settings
- [x] Toggle in Settings: "Ablauf-Erinnerungen" ein/aus
- [x] Warnungs-Schwelle konfigurierbar (1/3/5/7 Tage) via SegmentedButton

---

## ⭐ Phase 15 – Barcode-History & Favoriten ✅ CODE FERTIG

> Häufig gescannte Produkte merken, damit Wiedereinkauf schnell geht.

### Logik
- [x] `ScannedProductRepository` – recordScan, toggleFavorite, getLists
- [x] `ScannedProductsNotifier` – History laden, Scan aufzeichnen, Favoriten
- [x] Bei jedem Scan: `scan_count++` und `last_scanned_at` aktualisieren
- [x] Duplikat-Erkennung (existierender Barcode → Update statt Insert)

### UI
- [x] Scanner-Screen mit TabBar: "Scannen" | "Verlauf"
- [x] History-Tab: Liste aller gescannten Produkte (Name, Scan-Anzahl, Datum)
- [x] Favoriten mit Stern markierbar
- [x] Relative Zeitangaben (vor X Min./Std./Tagen)

---

## 👨‍👩‍👧 Phase 16 – Geteilter Haushalt ✅ CODE FERTIG

> Mehrere User teilen dasselbe Inventar und dieselben Einkaufslisten.

### Datenmodell
- [x] `Household`- und `HouseholdMember`-Model in `lib/models/household.dart`
- [x] Supabase-Tabellen `households` + `household_members` (SQL unten)

### Logik
- [x] `HouseholdRepository` – erstellen, beitreten, verlassen, Mitglieder laden
- [x] `HouseholdNotifier` + `householdProvider` / `householdMembersProvider`
- [x] 6-stelliger Einladungscode (alphanumerisch)
- [x] Code regenerieren, kopieren
- [x] Haushalt verlassen (letztes Mitglied → Haushalt wird gelöscht)

### UI
- [x] `HouseholdScreen` – Erstellen / Beitreten / Verlassen
- [x] Einladungscode anzeigen + kopieren + regenerieren
- [x] Mitgliederliste mit Admin/Mitglied-Rolle
- [x] Route `/settings/household` + Link in Settings

---

## 🏠 Phase 16b – Haushaltsvorrat ✅ CODE FERTIG

> Vorräte können privat oder dem Haushalt zugeordnet werden.

### SQL-Migration
- [x] `supabase_migration_13_household_inventory.sql` – `household_id`-Spalte, RLS-Policies, RPC-Funktionen
- [ ] **SQL in Supabase ausführen!**

### Model & Repository
- [x] `InventoryItem.householdId` + `isHousehold`-Getter
- [x] `InventoryRepository.getInventory()` – householdId-Parameter, OR-Filter
- [x] `migrateItemsToHousehold()` / `migrateItemsFromHousehold()` RPC-Aufrufe

### Provider
- [x] `InventoryScope`-Enum (all, personal, household)
- [x] `inventoryScopeProvider` – Filter-State
- [x] `filteredInventoryProvider` – Scope-basierte Filterung
- [x] `migrateToHousehold()` / `migrateFromHousehold()` im Notifier

### UI
- [x] Scope-Chips (Alle / Privat / Haushalt) in der Filter-Zeile
- [x] 🏠 Badge bei Haushalt-Items in der Liste
- [x] Privat/Haushalt SegmentedButton beim Hinzufügen
- [x] Migrations-Card in den Einstellungen
- [x] Leave-Dialog mit Option „Items mitnehmen"

---

## 🧾 Phase 17 – Kassenbon-Scanner ✅ CODE FERTIG

> Kassenzettel fotografieren → Items automatisch erkennen und ins Inventar.

- [x] `google_mlkit_text_recognition` + `image_picker` Packages
- [x] `ReceiptOcrService` in `lib/core/services/receipt_ocr_service.dart`
  - ML Kit Text Recognition (on-device, kostenlos)
  - Kassenbon-Parser: Preise, Mengen, Artikelnamen extrahieren
  - Header/Footer/Summen-Zeilen werden gefiltert
- [x] `ReceiptScannerScreen` – Kamera/Galerie → OCR → Ergebnisse
  - Foto aufnehmen oder aus Galerie wählen
  - Erkannte Artikel als Checkbox-Liste
  - Alle/Keine auswählen
  - Rohtext-Ansicht toggle
  - Ausgewählte Artikel → Inventar
- [x] Route `/scanner/receipt` + Button im Scanner-AppBar

---

## 🧭 Navigation & Shell ✅ ERLEDIGT

- [x] `MainShell` – `NavigationBar` mit 5 Tabs (Vorrat, Scanner, Rezepte, Einkauf, Settings)
- [x] `go_router` ShellRoute konfiguriert
- [x] Auth-Guard (Redirect Login ↔ App)

---

## 🧪 Testing

- [x] Widget-Test angepasst (`FoodyApp`)
- [ ] Unit-Tests für Repositories
- [ ] Unit-Tests für Notifier/Provider
- [ ] Widget-Tests für Screens
- [ ] Integration-Tests für kritische Flows (Login → Scan → Inventar)

---

## 🚀 Release-Vorbereitung ❌ NOCH OFFEN

- [x] `applicationId` in `android/app/build.gradle.kts` gesetzt → `app.kokomi.app` ✅
- [x] Bundle-ID in iOS gesetzt → `app.kokomi.app` ✅
- [x] API-Keys abgesichert – `.env` in `.gitignore`, alle Keys rotiert ✅
- [ ] Supabase RLS vollständig testen
- [ ] App-Store / Play-Store Assets vorbereiten
- [x] App-Icon erstellt ✅
- [ ] Splash Screen erstellen

---

## 📌 Implementierungs-Reihenfolge

> **Empfohlene Reihenfolge der noch offenen Phasen:**

| Prio | Phase | Beschreibung | Aufwand |
|------|-------|-------------|---------|
| ~~1~~ | ~~**Phase 8**~~ | ~~Kategorien & Tags~~ | ✅ Erledigt |
| ~~2~~ | ~~**Phase 9**~~ | ~~Produkt-Detailseite (Food Facts)~~ | ✅ Erledigt |
| ~~3~~ | ~~**Phase 12a**~~ | ~~Freitext-Rezeptgenerierung~~ | ✅ Erledigt |
| ~~4~~ | ~~**Phase 12b**~~ | ~~Inventar-Auswahl für Rezepte~~ | ✅ Erledigt |
| ~~5~~ | ~~**Phase 12c**~~ | ~~Nährwerte in Rezepten~~ | ✅ Erledigt |
| 6 | ~~**Phase 10**~~ | ~~Multi-Einkaufslisten~~ | ✅ Erledigt |
| ~~7~~ | ~~**Phase 12e**~~ | ~~Rezept-Zutaten → Einkaufsliste~~ | ✅ Erledigt |
| ~~8~~ | ~~**Phase 13**~~ | ~~Einkauf → Inventar Übernahme~~ | ✅ Erledigt |
| ~~9~~ | ~~**Phase 11**~~ | ~~Auto-Nachkauf (Threshold)~~ | ✅ Erledigt |
| 10 | ~~**Phase 12d**~~ | ~~Rezepte speichern (Supabase)~~ | ✅ Erledigt |
| 11 | ~~**Phase 12f**~~ | ~~Online-Rezeptsuche~~ | ✅ Erledigt |
| 12 | ~~**Phase 14**~~ | ~~Ablauf-Erinnerungen~~ | ✅ Erledigt |
| 13 | ~~**Phase 15**~~ | ~~Barcode-History & Favoriten~~ | ✅ Erledigt |
| 14 | ~~**Phase 16**~~ | ~~Geteilter Haushalt~~ | ✅ Erledigt |
| 15 | ~~**Phase 17**~~ | ~~Kassenbon-Scanner~~ | ✅ Erledigt |

---

## 📌 Supabase-Setup – Alle Tabellen

> **Führe diese SQL-Befehle im Supabase SQL Editor aus. Alle Tabellen die für das Projekt benötigt werden.**

### 1. `user_inventory` (Phase 3, 8, 9, 11)
```sql
create table user_inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  ingredient_id text not null,
  ingredient_name text not null,
  ingredient_category text,
  ingredient_image_url text,
  quantity float,
  unit text,
  expiry_date timestamptz,
  min_threshold float default 0,
  barcode text,
  tags text[],
  created_at timestamptz default now()
);
alter table user_inventory enable row level security;
create policy "Eigene Einträge" on user_inventory
  for all using (auth.uid() = user_id);
create index idx_inventory_user on user_inventory(user_id);
create index idx_inventory_barcode on user_inventory(barcode);
```

### 2. `shopping_lists` (Phase 10)
```sql
create table shopping_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  name text not null,
  icon text default 'shopping_cart',
  created_at timestamptz default now()
);
alter table shopping_lists enable row level security;
create policy "Eigene Listen" on shopping_lists
  for all using (auth.uid() = user_id);
```

### 3. `shopping_list_items` (Phase 6, 10)
```sql
create table shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid references shopping_lists not null,
  user_id uuid references auth.users not null,
  name text not null,
  quantity text,
  is_checked boolean default false,
  created_at timestamptz default now()
);
alter table shopping_list_items enable row level security;
create policy "Eigene Einträge" on shopping_list_items
  for all using (auth.uid() = user_id);
```

### 4. `saved_recipes` (Phase 12d)
```sql
create table saved_recipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  title text not null,
  recipe_json jsonb not null,
  source text default 'ai',
  created_at timestamptz default now()
);
alter table saved_recipes enable row level security;
create policy "Eigene Rezepte" on saved_recipes
  for all using (auth.uid() = user_id);
```

### 5. `scanned_products` (Phase 15)
```sql
create table scanned_products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  barcode text not null,
  product_name text not null,
  product_data jsonb,
  scan_count int default 1,
  is_favorite boolean default false,
  last_scanned_at timestamptz default now(),
  created_at timestamptz default now()
);
alter table scanned_products enable row level security;
create policy "Eigene Scans" on scanned_products
  for all using (auth.uid() = user_id);
create index idx_scanned_barcode on scanned_products(user_id, barcode);
```

### 6. `households` (Phase 16)
```sql
create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid references auth.users not null,
  invite_code text unique,
  created_at timestamptz default now()
);
alter table households enable row level security;
create policy "Haushalt sichtbar für Mitglieder" on households
  for all using (
    id in (select household_id from household_members where user_id = auth.uid())
  );
```

### 7. `household_members` (Phase 16)
```sql
create table household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households on delete cascade not null,
  user_id uuid references auth.users not null,
  role text default 'member' check (role in ('admin', 'member')),
  display_name text,
  joined_at timestamptz default now(),
  unique(household_id, user_id)
);
alter table household_members enable row level security;
create policy "Eigene Mitgliedschaft" on household_members
  for all using (
    household_id in (select household_id from household_members where user_id = auth.uid())
  );
```

> **Alle 7 Tabellen anlegen, dann ist die App voll funktionsfähig!**

---

## 📅 Phase 34 + 35 – Geteilter Haushalt-Wochenplan ✅ CODE FERTIG

> User können entscheiden ob ihr Wochenplan privat bleibt oder mit dem Haushalt geteilt wird.
> Die Entscheidung ist jederzeit umkehrbar – kein Datenverlust.

### Wie es funktioniert

**Opt-in beim Haushalt-Erstellen oder Beitreten:**
- Nach `createHousehold()` oder erfolgreichem `joinByCode()` erscheint einmalig ein Dialog:
  - **„Ja, Haushalt-Plan nutzen"** → `use_household_plan = true` gespeichert (lokal + Supabase `meal_plan_preferences`)
  - **„Nein, persönlicher Plan"** → `use_household_plan = false`, User bleibt Haushalt-Mitglied, sieht Einladungscode + Chat, hat aber seinen eigenen Wochenplan
- Jederzeit über Haushalt-Tab Toggle umschaltbar (Switch in der „Gemeinsamer Wochenplan" Sektion)
- Haushalt verlassen → Präferenz wird automatisch auf `false` zurückgesetzt

**Was passiert bei „Nein":**
- User ist normales Haushalt-Mitglied (Einladungscode, Aktivitätslog, Chat funktionieren)
- Sein Wochenplan ist rein persönlich
- Im Haushalt-Tab sieht er die Sektion „Gemeinsamer Wochenplan" mit einem Switch → er kann jederzeit beitreten
- Der Haushalt-Plan der anderen Mitglieder läuft weiter unabhängig

**Was passiert bei „Ja":**
- `meal_plans`-Einträge werden mit `household_id` gespeichert statt nur mit `user_id`
- Alle Haushaltsmitglieder die ebenfalls „Ja" gewählt haben sehen denselben Plan
- Jedes Mitglied kann Mahlzeiten hinzufügen/entfernen (RLS erlaubt das)
- Banner im Wochenplaner zeigt an ob Haushalt- oder persönlicher Plan aktiv ist (mit Quick-Toggle)

### Neue Dateien
- [x] `lib/features/household/presentation/household_meal_plan_preference_provider.dart`
  - `HouseholdMealPlanPreferenceNotifier` – lokal (SharedPreferences) + Supabase sync
  - `isUsingHouseholdPlanProvider` – kombinierter Provider (hasHousehold && prefersHousehold)
- [x] `supabase_migration_09_household_meal_plan.sql`
  - `household_id` Spalte in `meal_plans` (nullable, CASCADE DELETE)
  - Neue RLS-Policies: Mitglieder können geteilten Plan lesen/schreiben/löschen
  - `meal_plan_preferences`-Tabelle: speichert Präferenz pro User

### Geänderte Dateien
- [x] `meal_plan_provider.dart` – Haushalt-Modus in `build()`, `_loadFromSupabase()`, `setMeal()`, `removeMeal()`, `clearAll()`
- [x] `meal_plan_screen.dart` – Haushalt-Modus-Banner mit Quick-Toggle
- [x] `household_screen.dart` – Migrations-Dialog + `_HouseholdMealPlanSection` Widget
  - „Nein"-Klick: Haushalt-Mitglied, persönlicher Plan, Switch zum späteren Beitreten
  - „Ja"-Klick: Haushalt-Plan aktiv, alle sehen denselben Plan

### ⏳ Supabase (du musst eingreifen)
- [ ] `supabase_migration_09_household_meal_plan.sql` im Supabase SQL Editor ausführen

