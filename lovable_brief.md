# Foody - Smart Kitchen & Food Management App

## App-Beschreibung

Foody ist eine mobile App (Flutter, iOS & Android) zum intelligenten Verwalten von Lebensmitteln, Einkaufen und Kochen. Die App hilft Nutzern, Lebensmittelverschwendung zu reduzieren, smarter einzukaufen und mit KI-generierten Rezepten kreativ zu kochen.

**Zielgruppe:** Haushalte, WGs, Familien, gesundheitsbewusste Nutzer, Meal-Prep-Fans

**Kernversprechen:** Weniger Lebensmittelverschwendung, einfacheres Kochen, smarter Einkaufen.

---

## Navigation & Screen-Struktur

### Bottom Navigation (5 Elemente)
1. **Home** - Dashboard mit Tagesübersicht
2. **Vorrat** - Inventar + Einkaufslisten (Tabs)
3. **KI-Rezepte** (zentraler FAB, rund, Gradient) - KI-Rezeptgenerierung
4. **Küche** - Gespeicherte Rezepte + Wochenplan (Tabs)
5. **Entdecken** - Community Rezepte + Wochenpläne (Tabs)

### Avatar-Menü (oben rechts, PopupMenu)
- Profil
- Wochenplaner
- Ernährung & Tracking
- Mein Haushalt
- Einstellungen
- Pro-Upgrade

---

## Screens im Detail

### 1. Home / Dashboard
- Vorratsübersicht (kompakt, ablaufende Items)
- Heute kochen (Rezept aus Wochenplan)
- Offene Einkaufslisten
- Schnellzugriff (Scan, Rezept erstellen, KI)
- Ernährung heute (Makros, Kalorien)
- Koch-Streak & Wassertracker

### 2. Vorrat & Einkauf (kombiniert, Tab-Bar oben)

#### Tab: Einkauf
- Einkaufslisten (mehrere, benennbar, mit Haushalt teilbar)
- Items per Eingabe, Scan oder aus Rezepten hinzufügen
- Stammartikel / Vorschläge
- Items abhaken, Mengen, Preisschätzung
- Zwei FABs: Manuell (+) und Scan (Kamera-Icon)

#### Tab: Vorrat
- Alle Inventar-Items als Karten
- Filter: Lagerort (Kühlschrank, Tiefkühl, Vorratskammer)
- Filter: Haushalt vs. Privat (wenn in Haushalt)
- Suche, Sortierung (A-Z, MHD, Kategorie)
- Kategorien: Obst, Gemüse, Fleisch, Milch, Getränke, Snacks, Backwaren, Tiefkühl, Konserven, Gewürze, Öle, Getreide, Süßigkeiten, Haushalt & Reinigung, Hygiene, Baby, Sonstiges
- Swipe rechts = Bearbeiten, Swipe links = Löschen
- Tap = Edit-Sheet direkt öffnen
- Zwei FABs: Manuell (+) und Scan (Kamera-Icon)
- Bulk-Transfer: Items von Privat nach Haushalt verschieben

### 3. KI-Rezepte (Fullscreen via FAB)
- Prompt-Eingabefeld (optional)
- Stil-Tags (Italienisch, Asiatisch, Deutsch, Vegan, High Protein, Low Carb, etc.) als horizontal scrollbare Chips
- Toggle: Vorrat verwenden ja/nein
- Generieren-Button
- Ergebnis: 3 Rezept-Karten, klickbar zum Detail
- Free: 5 Generierungen/Woche, Pro: unlimitiert
- Anzeige verbleibender Generierungen

### 4. Küche (Tabs: Gespeichert | Wochenplan)

#### Tab: Gespeichert
- Alle gespeicherten Rezepte als Karten
- Filter: Favoriten, Mahlzeit-Typ, Kochzeit, Sammlung
- Rating-Badge auf jeder Karte
- Quick-Actions auf Karte: Wochenplan (+Kalender-Icon), Einkaufsliste (+Warenkorb-Icon)
- FAB: Eigenes Rezept erstellen

#### Tab: Wochenplan
- 7-Tage-Ansicht (Mo-So), je Tag: Frühstück, Mittag, Abend, Snack
- Rezepte zuweisen (aus gespeicherten oder KI)
- KI-Wochenplan generieren mit Diätpräferenzen-Dialog
- Vorlagen speichern/laden
- Gesamt-Kalorien pro Tag
- Wochennavigation (vor/zurück/heute)
- Tap auf Rezept = Vorschau-BottomSheet (Details, Kochen, Ändern, Entfernen)

### 5. Entdecken (Tabs: Rezepte | Wochenpläne)

#### Tab: Community Rezepte
- Feed mit Rezepten anderer User
- Suche, Filter nach Kategorie/Küche
- Bewertungen (Kochlöffel-System 1-5)
- Rezepte speichern, bewerten, teilen

#### Tab: Community Wochenpläne
- Feed mit geteilten Wochenplänen
- Tags (vegan, fitness, familie, etc.)
- Bewertungen
- Wochenplan übernehmen / als Vorlage speichern
- Zutaten zur Einkaufsliste hinzufügen

### 6. Rezept-Detail-Screen
- Titel, Beschreibung, Meta-Info (Zeit, Schwierigkeit, Portionen)
- Bewertungs-Zeile
- Portionen-Regler (skaliert Zutaten)
- Variationen (Vegetarisch, Vegan, Glutenfrei, etc.)
- Nährwert-Karte (Kalorien, Protein, Carbs, Fett, Ballaststoffe)
- Zutaten-Liste mit Allergen-Warnung
- Schritt-für-Schritt Anleitung
- 3 Icon-FABs: Kochen (Play), Einkaufsliste (Warenkorb), Wochenplan (Kalender)
- AppBar: Teilen, Favorit, Speichern, Sammlung, PDF-Export

### 7. Koch-Modus (Fullscreen)
- Schritt-für-Schritt mit Swipe-Navigation
- Erste Seite: Zutaten-Checkliste
- Timer-Funktion (Presets: 1-60 Min)
- Fortschrittsbalken
- Bildschirm bleibt an
- Fertig-Button: Streak tracken + optional Zutaten vom Vorrat abziehen

### 8. Haushalt
- Haushalt erstellen/beitreten (Einladungscode)
- Mitglieder verwalten (Admin: einladen, entfernen, auflösen)
- Beitrittsanfragen annehmen/ablehnen
- Haushalt-Chat
- Aktivitäts-Log
- Gemeinsamer Wochenplan (opt-in)
- Gemeinsamer Vorrat

### 9. Einstellungen
- Profil bearbeiten
- Benachrichtigungen (Ablauf-Erinnerung)
- Allergen-Filter
- Theme/Farbschema
- Ernährungsprofil (Kalorienziel, Gewicht, Aktivität)
- Testdaten generieren (Dev)

### 10. Paywall / Pro
- Vergleichstabelle Free vs Pro
- Monatlich 2,99 EUR / Jährlich 19,99 EUR
- Features: Unlimitierte KI, Nährwert-Tracking, Wochenplaner, Allergen-Filter, PDF-Export

---

## Design-System

### Prinzipien
- Material Design 3
- Clean, modern, leicht verspielt
- Fokus auf Lesbarkeit und schnelle Interaktion
- Gamification: Koch-Streak, Wassertracker

### Farben
- Primary: anpassbar (Lila default, weitere Optionen in Settings)
- Light & Dark Mode
- Gradient auf KI-FAB (Primary -> Tertiary)
- Accent-Farben fuer Kategorien (Obst=Gruen, Fleisch=Rot, etc.)

### Typography
- System-Font (Roboto/SF Pro)
- Headlines: Bold/W800
- Body: Regular/W400
- Labels: W600, kleinere Sizes

### Komponenten
- Cards mit 16px border-radius
- Chips/FilterChips fuer Tags
- BottomSheets fuer Aktionen
- Dialoge fuer Bestaetigungen
- FABs: Rund (zentral), Extended (Screens), Small (Detail-Aktionen)
- Badge auf Avatar fuer Benachrichtigungen
- Swipe-Actions auf Listen-Items
- Pull-to-refresh

### Navigation
- Bottom Navigation Bar mit CircularNotchedRectangle
- Zentraler docked FAB (KI-Rezepte)
- Tab-Bars innerhalb von Screens
- GoRouter fuer Deep Linking
- Avatar-PopupMenu fuer sekundaere Navigation

---

## Datenmodelle (Kern)

- **User**: id, email, isPro, createdAt
- **InventoryItem**: id, userId, name, category, quantity, unit, expiryDate, storageZone, isHousehold, barcode, imageUrl
- **FoodRecipe**: id, title, description, cookingTime, difficulty, servings, ingredients[], steps[], nutrition
- **ShoppingList**: id, userId, name, icon, householdId, items[]
- **ShoppingListItem**: id, listId, name, quantity, isChecked, price
- **MealPlanEntry**: id, userId, dayIndex, slot(breakfast/lunch/dinner/snack), recipe
- **Household**: id, name, inviteCode, adminId, members[]
- **CommunityRecipe**: id, userId, recipe, ratings, createdAt
- **CommunityMealPlan**: id, userId, name, description, tags[], days[], ratings

---

## Tech Stack
- **Frontend**: Flutter (Dart), Riverpod, GoRouter, Material 3
- **Backend**: Supabase (Auth, PostgreSQL, Storage, Edge Functions, Realtime)
- **KI**: Groq API (via Supabase Edge Function Proxy)
- **Food-Daten**: OpenFoodFacts API
- **Barcode**: mobile_scanner
- **Monetarisierung**: RevenueCat (geplant)

