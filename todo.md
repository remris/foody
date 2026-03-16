# TODO – Smart Kitchen App (Foody)

> Stand: 2026-03-16  
> Grundlage: `project.md` + aktueller Projektstatus  
> Das Projekt ist ein leerer Flutter-Scaffold. Alle Features müssen von Grund auf implementiert werden.

---

## 🔧 Phase 1 – Projekt-Setup

### Abhängigkeiten & Konfiguration
- [ ] `pubspec.yaml` – alle benötigten Pakete hinzufügen:
  - [ ] `flutter_riverpod`
  - [ ] `go_router`
  - [ ] `supabase_flutter`
  - [ ] `mobile_scanner`
  - [ ] `camera`
  - [ ] `dio` oder `http`
  - [ ] `freezed` + `freezed_annotation`
  - [ ] `json_serializable`
  - [ ] `build_runner` (dev)
  - [ ] `flutter_dotenv` (für API-Keys)
- [ ] `flutter pub get` ausführen
- [ ] `.env`-Datei für Supabase-URL, Anon-Key, OpenAI-Key anlegen
- [ ] `.env` in `.gitignore` eintragen
- [ ] `analysis_options.yaml` auf Projektstandards anpassen

### Ordnerstruktur anlegen (`lib/`)
- [ ] `lib/core/constants/` – z. B. `app_constants.dart`
- [ ] `lib/core/services/` – z. B. `supabase_service.dart`
- [ ] `lib/core/utils/` – Hilfsfunktionen
- [ ] `lib/features/auth/data/`
- [ ] `lib/features/auth/domain/`
- [ ] `lib/features/auth/presentation/`
- [ ] `lib/features/inventory/data/`
- [ ] `lib/features/inventory/domain/`
- [ ] `lib/features/inventory/presentation/`
- [ ] `lib/features/recipes/data/`
- [ ] `lib/features/recipes/domain/`
- [ ] `lib/features/recipes/presentation/`
- [ ] `lib/features/shopping_list/data/`
- [ ] `lib/features/shopping_list/domain/`
- [ ] `lib/features/shopping_list/presentation/`
- [ ] `lib/features/scanner/data/`
- [ ] `lib/features/scanner/domain/`
- [ ] `lib/features/scanner/presentation/`
- [ ] `lib/models/` – globale Shared-Models
- [ ] `lib/widgets/` – wiederverwendbare Widgets

### Supabase Projekt
- [ ] Supabase-Projekt erstellen (supabase.com)
- [ ] Datenbank-Tabellen anlegen:
  - [ ] `ingredients`
  - [ ] `user_inventory`
  - [ ] `recipes`
  - [ ] `recipe_ingredients`
  - [ ] `shopping_list`
- [ ] Row Level Security (RLS) für alle Tabellen aktivieren
- [ ] Storage-Buckets anlegen: `food_images`, `receipt_images`
- [ ] Supabase-URL & Anon-Key in `.env` eintragen

### App-Einstiegspunkt
- [ ] `main.dart` aufräumen (Standard-Demo-Code entfernen)
- [ ] Supabase in `main()` initialisieren
- [ ] `ProviderScope` (Riverpod) als Root-Widget einrichten
- [ ] `go_router` konfigurieren (initiale Routen)

---

## 🔐 Phase 2 – Authentifizierung

### Backend
- [ ] Supabase Auth aktivieren (E-Mail/Passwort)
- [ ] Optional: Google OAuth aktivieren

### Models & Repository
- [ ] `UserModel` (freezed) erstellen
- [ ] `AuthRepository` Interface definieren
- [ ] `AuthRepositoryImpl` mit Supabase Auth implementieren:
  - [ ] `signUp(email, password)`
  - [ ] `signIn(email, password)`
  - [ ] `signOut()`
  - [ ] `getCurrentUser()`
  - [ ] Auth-State-Stream

### State Management
- [ ] `AuthNotifier` / `AuthProvider` (Riverpod) erstellen
- [ ] Auth-State (eingeloggt / ausgeloggt / loading) verwalten

### UI
- [ ] `LoginScreen` erstellen
- [ ] `RegisterScreen` erstellen
- [ ] Formularvalidierung (E-Mail, Passwort)
- [ ] Fehlerbehandlung (falsches Passwort, etc.)
- [ ] Redirect nach Login → Home
- [ ] Redirect nach Logout → Login
- [ ] Auth-Guard in `go_router` einrichten

### ✅ Deliverable: Registrierung & Login funktionieren

---

## 🥦 Phase 3 – Inventar-System

### Models & Repository
- [ ] `Ingredient`-Model (freezed + json_serializable)
- [ ] `UserInventoryItem`-Model (freezed + json_serializable)
- [ ] `IngredientRepository` Interface + Impl:
  - [ ] Ingredient per Barcode/Name suchen
  - [ ] Ingredient anlegen (falls nicht vorhanden)
- [ ] `InventoryRepository` Interface + Impl:
  - [ ] `getInventory(userId)`
  - [ ] `addItem(item)`
  - [ ] `updateItem(item)`
  - [ ] `deleteItem(id)`

### State Management
- [ ] `InventoryNotifier` / `InventoryProvider` (Riverpod)
- [ ] Filter-Provider (nach Kategorie)
- [ ] Sortier-Provider (nach Ablaufdatum)

### UI
- [ ] `InventoryScreen` – Liste aller Zutaten
- [ ] `InventoryItemCard` – Widget für einzelne Zutat
- [ ] `AddIngredientScreen` / Bottom Sheet – Zutat manuell hinzufügen
- [ ] `EditIngredientScreen` – Zutat bearbeiten
- [ ] Lösch-Funktion (Swipe oder Button)
- [ ] Filter-Chip-Leiste (nach Kategorie)
- [ ] Sortierung nach Ablaufdatum
- [ ] Ablaufdatum-Anzeige (z. B. rot wenn < 3 Tage)

### ✅ Deliverable: Inventar-Verwaltung funktioniert

---

## 📷 Phase 4 – Barcode-Scanner

### Setup
- [ ] `mobile_scanner` konfigurieren
- [ ] Kamera-Berechtigungen:
  - [ ] Android: `AndroidManifest.xml` anpassen
  - [ ] iOS: `Info.plist` anpassen

### Data Layer
- [ ] `OpenFoodFacts`-Service implementieren:
  - [ ] GET `https://world.openfoodfacts.org/api/v0/product/{barcode}.json`
  - [ ] Response-Model parsen
  - [ ] Produktname, Kategorie extrahieren
- [ ] `ScannerRepository` Interface + Impl

### State Management
- [ ] `ScannerNotifier` / `ScannerProvider` (Riverpod)
- [ ] Scan-Ergebnis-State verwalten

### UI
- [ ] `ScannerScreen` – Kamera-View mit Barcode-Overlay
- [ ] Scan-Ergebnis-Dialog / Bottom Sheet:
  - [ ] Produktname anzeigen
  - [ ] Menge & Einheit eingeben
  - [ ] Ablaufdatum eingeben
  - [ ] "Zum Inventar hinzufügen"-Button
- [ ] Fehlerbehandlung (Barcode nicht gefunden)

### ✅ Deliverable: Barcode-Scan fügt Zutat zum Inventar hinzu

---

## 🍽️ Phase 5 – Rezept-Vorschläge (AI)

### Setup
- [ ] OpenAI API-Key in `.env` eintragen
- [ ] `OpenAIService` implementieren (dio/http)

### Data Layer
- [ ] Prompt-Baustein: Zutaten-Liste → Rezeptvorschläge
- [ ] Response parsen → `Recipe`-Model
- [ ] `Recipe`-Model (freezed): Titel, Beschreibung, Zutaten, Schritte, Kochzeit, Schwierigkeit
- [ ] `RecipeRepository` Interface + Impl:
  - [ ] `getSuggestedRecipes(ingredients)`
  - [ ] `generateRecipe(ingredients)` (manuell)

### State Management
- [ ] `RecipeNotifier` / `RecipeProvider` (Riverpod)
- [ ] Loading / Error / Success-State

### UI
- [ ] `RecipesScreen` – Liste der Rezeptvorschläge
- [ ] `RecipeCard` – Widget für einzelnes Rezept
- [ ] `RecipeDetailScreen` – Vollansicht eines Rezepts:
  - [ ] Zutaten-Liste
  - [ ] Schritt-für-Schritt-Anleitung
  - [ ] Kochzeit & Schwierigkeit
- [ ] "Rezepte suchen"-Button (löst API-Anfrage aus)
- [ ] Ladeindikator während Generierung
- [ ] Fehlerbehandlung (API nicht erreichbar, etc.)

### ✅ Deliverable: KI-generierte Rezeptvorschläge werden angezeigt

---

## 🛒 Phase 6 – Einkaufsliste (optional nach MVP)

### Data Layer
- [ ] `ShoppingListItem`-Model (freezed)
- [ ] `ShoppingListRepository` Interface + Impl:
  - [ ] `getItems(userId)`
  - [ ] `addItem(item)`
  - [ ] `toggleChecked(id)`
  - [ ] `deleteItem(id)`

### State Management
- [ ] `ShoppingListNotifier` / `ShoppingListProvider` (Riverpod)

### UI
- [ ] `ShoppingListScreen`
- [ ] Item hinzufügen (Input-Feld)
- [ ] Checkbox zum Abhaken
- [ ] Item löschen (Swipe)

### ✅ Deliverable: Einkaufsliste funktioniert

---

## 🧾 Phase 7 – Kassenbon-Scanner (optional nach MVP)

### Setup
- [ ] Google Vision API oder Tesseract entscheiden & einrichten
- [ ] API-Key in `.env` eintragen

### Data Layer
- [ ] `ReceiptOcrService` implementieren
- [ ] Produktnamen aus OCR-Response extrahieren
- [ ] Mapping auf `Ingredient`-Model

### UI
- [ ] `ReceiptScannerScreen` – Kamera-View
- [ ] Ergebnis-Liste: erkannte Produkte
- [ ] Bestätigen & Zum Inventar hinzufügen

### ✅ Deliverable: Bon-Scan fügt Zutaten automatisch hinzu

---

## 🧭 Navigation & Shell

- [ ] Bottom Navigation Bar:
  - [ ] Inventar
  - [ ] Scanner
  - [ ] Rezepte
  - [ ] Einkaufsliste
- [ ] `go_router` Shell-Route konfigurieren
- [ ] Deep-Link-Handling vorbereiten

---

## 🎨 UI / Design

- [ ] App-Theme definieren (Farben, Typografie)
- [ ] Dark Mode Support
- [ ] App-Icon anpassen
- [ ] Splash Screen anpassen
- [ ] Leere Zustände (Empty States) für alle Listen
- [ ] Globales Error-Widget / Snackbar-System
- [ ] Ladeindikator-Widget (wiederverwendbar)

---

## 🧪 Testing

- [ ] Unit-Tests für Repositories
- [ ] Unit-Tests für Notifier/Provider
- [ ] Widget-Tests für wichtige Screens
- [ ] Integrationstests (optional)

---

## 🚀 Release-Vorbereitung

- [ ] App-Name & Bundle-ID anpassen (`foody` → final)
- [ ] Android: `build.gradle` – `applicationId` setzen
- [ ] iOS: `Info.plist` – Bundle-ID setzen
- [ ] API-Keys aus Code entfernen / absichern
- [ ] Supabase RLS vollständig testen
- [ ] Performance-Profiling
- [ ] App-Store / Play-Store Assets vorbereiten

---

## 📌 Nächster Schritt

> **Jetzt starten mit:** Phase 1 – `pubspec.yaml` befüllen und Ordnerstruktur anlegen.

