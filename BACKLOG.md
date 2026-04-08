# 🍽️ Foody – Feature Backlog & Verbesserungen

> Zuletzt aktualisiert: April 2026
> Legende: ✅ Erledigt · 🔄 In Arbeit · 🔥 Hohe Priorität · 💡 Idee · 🐛 Bug · 🎨 Design · 🔧 Technik · 🚀 Release · 💰 Monetarisierung · 🤝 Kooperation

---

## 🏷️ App-Name & Branding – Strategische Entscheidung

> **Status:** Offen – Entscheidung muss VOR dem ersten öffentlichen Store-Listing fallen!
> Eine Umbenennung nach Launch ist technisch möglich (Bundle-ID bleibt gleich), kostet aber ASO-Rankings.

### Problem mit „Foody"
- Mehrfach belegt im App-Store: „Foody – Food Tracker" (DE), foody.ie (Irland, Food-Delivery), philippinische Food-App
- ASO-Konflikt → schlechte Auffindbarkeit in DE/AT/CH
- Wirkt generisch, wenig Differenzierung

### Alternative Namen (Verfügbarkeit jeweils prüfen)

| Name | Konzept | Domain |
|---|---|---|
| **Pantree** | Pantry + Tree (Wachstum), tech-modern, international skalierbar | pantree.app |
| **Mealio** | Meal + -io (App-Suffix), klar, merkfähig, international | mealio.app |
| **Kühlblick** | „Kühlschrank" + „Überblick", sehr deutsch, einprägsam | kühlblick.app |
| **Speyse** | Stilisiertes „Speise" (altdeutsch), europäisch, Premium-Feel | speyse.app |
| **Frisché** | Frische + franz. Touch, Nachhaltigkeits-Appeal | frische.app |
| **Vorratio** | Vorrat + Ratio (rationell), erklärt sich selbst, DACH-Markt | vorratio.app |
| **Speisr** | Speise + -r (modern, kurz wie Flickr/Tumblr) | speisr.app |

### Empfehlung
- 🥇 **Pantree** – international skalierbar, tech-modern, kein bekannter Namenskonflikt, trifft Vorrats-Kernfeature
- 🥈 **Mealio** – intuitiv, App-Store-freundlich, global verständlich
- 🥉 **Kühlblick** – wenn der Fokus klar auf DACH-Markt bleibt, sehr einprägsam

> **Nächster Schritt:** Verfügbarkeit im Play Store + App Store + Domain prüfen, dann festlegen.
> Bundle-ID `de.foodyapp.app` kann unabhängig vom Anzeigenamen bleiben.

---

## 🎨 App-Icon – Konzepte & Empfehlung

> **Status:** Splash Screen vorhanden (flutter_native_splash, Foody-Grün #2E7D32), aber App-Icon in allen Auflösungen fehlt noch – **Blocker für Store-Release!**

### Was im App-Store funktioniert
- Einfache Geometrie, ein dominantes Symbol
- Maximaler Kontrast zwischen Hintergrund und Symbol
- Kein Text unter 6pt (wird auf kleinen Thumbnails unleserlich)
- Erkennbar bei 29×29px (iOS Settings-Icon)
- Auf hellem UND dunklem Hintergrund funktionsfähig

### 4 Konzepte im Überblick

| # | Name | Stil | Farben | Symbol |
|---|---|---|---|---|
| **A** | „Grüner Kühlschrank" | Flat, abgerundetes Quadrat | #2E7D32 Grün + Weiß | Minimalistischer Kühlschrank mit kleinem Herz-Detail unten rechts |
| **B ⭐** | „Fork & Leaf" | Geometric, modern | Tiefes Teal #00695C + Cremeweiß | Gabel deren Zinken in Blätter übergehen – Natur + Kochen |
| **C** | „Scan-Herz" | Material 3, clean | Orange #E65100 + Weiß | Barcode-Form die in ein Herz übergeht – Scan + Community |
| **D** | „Magische Schüssel" | Bold Illustration | Lila/Violett + Gold | Schüssel mit Dampf als Sternenhimmel – Premium-Feel |

### ⭐ Empfehlung: Konzept B „Fork & Leaf"
Differenziert von Mitbewerbern · Passt zum DACH-Markt (Nachhaltigkeit/Frische) · Skaliert perfekt 16–1024px

### Technische Umsetzung
```yaml
# pubspec.yaml → dev_dependencies hinzufügen
flutter_launcher_icons: ^0.14.0

# flutter_launcher_icons.yaml (neues File im Projekt-Root anlegen)
flutter_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"       # 1024×1024px PNG, kein Alpha-Kanal
  adaptive_icon_background: "#00695C"           # Teal für Android Adaptive Icons
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
```

**Schritte:**
1. Icon als 1024×1024px PNG erstellen (Figma / icon.kitchen / appicon.co)
2. `assets/icon/` Ordner anlegen, PNGs dort ablegen
3. `dart run flutter_launcher_icons` ausführen
4. `android/` und `ios/` werden automatisch befüllt

---

## 🧭 App-Strategie: Küche, Community & Social

### Kernprinzip
Foody ist eine **smarte Küchen-App mit Community-Aspekt** – keine reine Rezept-App.
Der Nutzer steht im Zentrum: sein Vorrat, sein Haushalt, seine Gesundheit, seine Pläne.
Community ist Ergänzung für Inspiration und virales Wachstum, nicht der Hauptzweck.

### Die drei Säulen
| Säule | Inhalt | Wo in der App |
|---|---|---|
| **🏠 Meine Küche** | Vorrat, Einkauf, Wochenplan, KI-Rezepte, Kochmodus | Home + Küche-Tab |
| **👥 Haushalt** | Geteilter Vorrat, gemeinsamer Wochenplan, Chat, Einkauf teilen | Haushalt-Tab (via Avatar-Menü) |
| **🌍 Community** | Rezepte entdecken & teilen, Wochenpläne, Follows, Feed | Entdecken-Tab |

### Eigene vs. fremde Inhalte – klare Trennung
| Kontext | Was wird gezeigt |
|---|---|
| **Küche / Gespeichert** | Nur eigene gespeicherte + erstellte Rezepte |
| **Küche / Wochenplan** | Eigener oder Haushalt-Wochenplan |
| **Mein Bereich (Profil)** | Nur eigene **veröffentlichte** Rezepte + Wochenpläne + Follower/Following |
| **Entdecken / Rezepte** | Alle Community-Rezepte anderer User |
| **Entdecken / Wochenpläne** | Alle Community-Wochenpläne anderer User |
| **Feed (Home)** | Nur Inhalte von Usern denen ich folge |

### Was noch fehlt / Nächste Schritte
- [ ] **Öffentliche Profil-Seite** vollständig (Rezepte mit Aufrufen sichtbar) ← teilweise ✅
- [ ] **Follower/Following-Listen** klickbar im eigenen + fremden Profil ✅ **NEU**
- [ ] **Aufrufe (viewCount)** auf Rezept- und Wochenplan-Cards im eigenen Profil ✅ **NEU**
- [ ] **Autocomplete bei Rezept erstellen** (Zutaten-Vorschläge aus Katalog) ✅ **NEU**
- [ ] **view_count inkrementieren** wenn Rezept/Wochenplan-Detail geöffnet wird (Supabase RPC)
- [ ] **Kommentare** auf Wochenplänen (analog Community-Rezepte)
- [ ] **Benachrichtigungen** bei neuem Follower / Kommentar / Like
- [ ] **Aktivitäts-Zusammenfassung** im Profil: „Diese Woche 3 neue Follower, 12 Likes"


### Free vs. Pro – Übersicht

| Feature | 🆓 Free | ⭐ Pro (2,99 €/Mo · 19,99 €/Jahr) |
|---|---|---|
| Vorrat (unlimitiert) | ✅ | ✅ |
| Einkaufslisten (bis 3) | ✅ | ✅ unlimitiert |
| Barcode-Scanner | ✅ | ✅ |
| Online-Rezepte (TheMealDB) | ✅ | ✅ |
| Kochmodus (Schritt-für-Schritt) | ✅ | ✅ |
| Haushalt teilen (bis 2 Personen) | ✅ | ✅ bis 6 Personen |
| Kassenbon-Scanner | ✅ (3/Tag) | ✅ unlimitiert |
| KI-Rezepte generieren | **5 / Woche** | ✅ unlimitiert |
| Nährwert-Tracking & Makros | ❌ | ✅ |
| Mahlzeiten-Wochenplaner | ❌ | ✅ |
| Supermarkt-Angebote & Kooperationen | ❌ | ✅ |
| Ernährungsprofil (BMI/Kalorienziel) | ❌ | ✅ |
| Rezept-Export als PDF | ❌ | ✅ |
| Wochenplan-Export & Teilen | ❌ | ✅ |
| Allergen-Filter | ❌ | ✅ |
| Vorrat-Statistiken Dashboard | ❌ | ✅ |

> **Rationale:** Haushalt-Teilen (2 Personen) im Free = stärkster viraler Wachstumskanal.
> Wenn Person 2 mitmacht, upgraden beide eher auf Pro. KI-Limit 5/Woche ist spürbar aber
> nicht frustrierend – User lernen die KI kennen und wollen mehr.

### Preismodell
- **Free** – dauerhaft kostenlos, Kernfunktionen nutzbar
- **Pro Monatlich** – 2,99 €/Monat, jederzeit kündbar
- **Pro Jährlich** – 19,99 €/Jahr (= 1,67 €/Monat, **44% Ersparnis**), einmal jährlich abgerechnet
- *(Phase 2)* **Pro+ Familie** – 4,99 €/Monat, bis 6 Haushaltsmitglieder, Realtime-Sync

### Technische Implementierung (Phasen)
- **Phase 1 (aktuell):** Limit lokal per `SharedPreferences` + Supabase `subscriptions`-Tabelle, manuell setzbar (für Tests und Early Adopter)
- **Phase 2:** RevenueCat SDK (`purchases_flutter`) → Google Play Billing + Apple IAP in einem SDK, Webhook aktualisiert Supabase automatisch
- **Phase 3:** Supabase Edge Function als Groq-API-Proxy (API-Key nie im App-Bundle, Rate-Limit serverseitig erzwungen)

---

## 🤝 Supermarkt-Kooperationen & Angebote

> **Vision:** Foody wird zum smarten Einkaufsbegleiter – User sehen Wochenangebote von Rewe,
> Edeka, Lidl & Aldi direkt in der App. Die KI schlägt Rezepte vor die GENAU die aktuellen
> Angebote nutzen. Konzerne zahlen für die Platzierung → zweite Einnahmequelle neben dem Abo.

### Kurzfristig (technisch umsetzbar ohne Kooperation)
- [ ] **Supermarkt-Angebots-Scraper (inoffiziell)** – Rewe/Edeka APIs existieren inoffiziell,
  Angebote können abgerufen werden. Rechtliche Grauzone → nur als Proof of Concept.
- [ ] **Angebotsseite im Einkauf-Tab** – Neue Sektion „Diese Woche im Angebot 🏷️" mit
  Produktkarten (Name, Preis, Gültig bis). Filter nach Supermarkt.
- [ ] **„Aus Angeboten kochen"** – Button generiert KI-Rezepte die aktuelle Angebots-Produkte
  als Hauptzutaten verwenden. Günstiger einkaufen durch smarte Planung.
- [ ] **Angebot → Einkaufsliste** – Tap auf Angebotsartikel fügt ihn direkt zur Einkaufsliste hinzu.
- [ ] **Angebot → Vorrat** – Beim Einscannen eines Angebots-Barcodes → automatisch mit
  Preisinfo in den Vorrat übernehmen.

### Mittelfristig (offizielle Kooperation nötig)
- [ ] **Rewe-Partnerschaft** – Offizielle API-Integration. Rewe-Angebote live in der App.
  Revenue-Share: Rewe zahlt pro Click-Through oder Einkauf-Attribution.
- [ ] **Edeka-Partnerschaft** – Analog Rewe. Edeka hat eigene App-Infrastruktur (meine-edeka API).
- [ ] **Lidl/Aldi-Partnerschaft** – Discount-Ketten besonders attraktiv für preisbewusste User.
- [ ] **Markenhersteller-Deals** – Dr. Oetker, Knorr, Maggi etc. zahlen für rezept-native
  Produktplatzierung: „Für dieses Rezept empfehlen wir: [Marke X]".
- [ ] **Sponsored Rezepte** – Marken können Rezepte sponsoren die in der App erscheinen.
  Klar als „Gesponsert" gekennzeichnet. CPC oder Flat-Fee Modell.

### Langfristig (Plattform-Strategie)
- [ ] **Foody-Marktplatz** – User können Einkäufe direkt über die App bei Kooperationspartnern
  bestellen (Click & Collect oder Lieferung). Foody erhält Provision pro Bestellung.
- [ ] **Loyalty-Integration** – Payback/DeutschlandCard Punkte direkt über Foody sammeln.
  Starkes Argument für Supermarkt-Kooperation (Daten-Sharing im Austausch).
- [ ] **Regionaler Preisvergleich** – User sieht welcher Supermarkt in seiner PLZ das günstigste
  Angebot hat. Monetarisierung durch Affiliate/CPC.

---

## 🐛 Bugs & Fixes

| Status | Beschreibung | Datei |
|--------|-------------|-------|
| ✅ | `BoxConstraints forces infinite width` beim Einkaufsliste `+` Button | `app_theme.dart` |
| ✅ | `CardTheme` → `CardThemeData` Kompilierfehler | `app_theme.dart` |
| ✅ | Bottom overflow beim Hinzufügen von Zutaten (27px) | `add_inventory_item_sheet.dart` |
| ✅ | Right overflow bei Rezept-Tags (33px) | `recipe_detail_screen.dart` |
| ✅ | Bottom overflow beim „Zutaten einkaufen" Sheet (252px) | `recipe_detail_screen.dart` |
| ✅ | Einkaufsliste `+` Button → RenderBox not laid out Exception | `shopping_list_screen.dart` |
| ✅ | OpenAI 401-Fehler → unklare Fehlermeldung | `openai_service.dart` |
| ✅ | Scanner Verlauf: nur 1 Item mit Stern markierbar | `scanned_products_provider.dart` |
| ✅ | Kassenbon-Scanner gibt zu viel unstrukturierten Text aus | `receipt_ocr_service.dart` |
| ✅ | Online-Rezepte nur auf Englisch (TheMealDB) | `online_recipe_service.dart` |
| ✅ | Vorrat: zu viele Tags → Tag-Suche unübersichtlich, Mehrfachauswahl fehlt | `inventory_screen.dart` |
| ✅ | Einkaufsliste kann nicht erstellt werden (`+` Kreis-Button) | `shopping_list_screen.dart` |
| ✅ | Vorrat-Items ohne Ablaufdatum tauchen nicht im Ablauf-Banner auf (korrekt, aber kein Hinweis) | `inventory_screen.dart` |
| ✅ | KI generiert immer dieselben 3 Rezepte (Cache-Problem) | `recipe_cache_service.dart`, `recipe_repository_impl.dart` |
| ✅ | Community Wochenpläne: teilen, entdecken, liken, übernehmen | `community_meal_plan_*` |
| 💡 | Online-Rezepte: Zutaten und Schritte in Systemsprache anzeigen | `online_recipe_service.dart` |
| ✅ | Settings: Right overflow 72px bei Ablauf-Erinnerung (SegmentedButton) | `settings_screen.dart` |
| ✅ | Haushalt: PostgreSQL 500 Error (RLS INSERT-Policy fehlte) | `supabase_setup.sql` |
| ✅ | KI-Rezepte: Immer gleiche 3 Rezepte (Temperatur 1.8 → 1.3, bessere Prompts) | `groq_service.dart` |

---

## ✅ Zuletzt implementiert

- ✅ Scanner → „Zur Einkaufsliste" Button direkt nach dem Scan
- ✅ Scanner → Manuelle Eingabe wenn Barcode nicht gefunden (mit Ziel-Auswahl: Vorrat / Einkaufsliste)
- ✅ Einkaufsliste → Artikel per Barcode-Scan hinzufügen
- ✅ Rezepte → Sterne-Bewertung (1–5) in Detail-Screen & Gespeichert-Tab
- ✅ Rezepte → Gewürze & Basics beim KI-Prompt filtern (Salz, Pfeffer, Öl etc.)
- ✅ Rezepte → „Überrasch mich!" 🔀 Button
- ✅ Rezepte → Tipp-Chips auf leerem Tab (Vegetarisch, Pasta, High Protein...)
- ✅ Vorrat → Ablauf-Warnbanner (rot = abgelaufen, orange = bald ablaufend)
- ✅ Vorrat → Onboarding-Anleitung bei erstem Start (leerer Vorrat)
- ✅ Vorrat → „Rezepte generieren" Shortcut-Link wenn Vorrat befüllt
- ✅ KI → Auf Groq umgestellt (kostenlos, llama3-8b) mit lokalem Fallback (10 Rezept-Vorlagen)
- ✅ Kassenbon-Scanner → KI-gestützte Bereinigung (Groq extrahiert nur Produktnamen aus OCR-Text)
- ✅ Online-Rezepte → Vollständige Groq-Übersetzung (Titel, Zutaten, Schritte ins Deutsche)
- ✅ Vorrat → Mehrfach-Tag-Auswahl mit „X Filter"-Chip zum Zurücksetzen
- ✅ Vorrat → Suchfeld in der AppBar (filtert live nach Name/Kategorie)
- ✅ Vorrat → 5 Sortieroptionen (Ablaufdatum, Name A-Z/Z-A, Neueste, Kategorie)
- ✅ Vorrat → Swipe-to-Edit (Links-Swipe = Bearbeiten, Rechts-Swipe = Löschen)
- ✅ Scanner → Haptisches Feedback + Torch-Status sichtbar
- ✅ Rezepte → Portionen anpassen (+/- Buttons, Zutatenmengen skalieren)
- ✅ Rezepte → Persönliche Kochnotizen (SharedPreferences)
- ✅ Rezepte → Teilen via System-Share-Dialog
- ✅ Rezepte → Schritt-für-Schritt Kochmodus (Fullscreen, Wakelock, Wisch-Navigation)
- ✅ Rezepte → Mahlzeit-Kategorien (Frühstück/Mittag/Abend/Snack/Dessert)
- ✅ Einkaufsliste → Teilen als Text
- ✅ Einkaufsliste → Erledigte Items ausblenden/einblenden
- ✅ Einkaufsliste → Drag & Drop Sortierung
- ✅ Überall → Haptisches Feedback (Scanner, Shopping, Portionen)
- ✅ Rezepte → Lieblingsrezepte (Herzchen-Icon, Favoriten-Filter im Gespeichert-Tab)
- ✅ Rezepte → Kochzeit-Filter (< 20 Min. / 20–45 Min. / > 45 Min.)
- ✅ Rezepte → Mahlzeit-Kategorien mit FilterChips
- ✅ Rezepte → Rezept-Timer im Kochmodus (1–60 Min., Pause/Resume, Alarm)
- ✅ Rezepte → Zuletzt gekochte Rezepte tracken (letzte 20 mit Datum)
- ✅ Rezepte → Online-Rezepte speichern (Bookmark-Status sichtbar)
- ✅ Rezepte → Letzte KI-Prompts als Quick-Repeat-Chips
- ✅ Scanner → Barcode manuell eingeben (Textfeld unter Scanner-View)
- ✅ Einkaufsliste → Stammartikel (Quick-Add-Chips + Verwaltungs-Sheet)
- ✅ Einkaufsliste → Konfetti-Animation wenn alles abgehakt 🎉
- ✅ Einkaufsliste → Vorlagen speichern und laden (Templates)
- ✅ Einkaufsliste → Artikel-Kategorien (Gruppierte Ansicht nach Obst, Milch, Fleisch etc.)
- ✅ Einkaufsliste → Geschätzter Gesamtpreis (optional Preis pro Artikel)
- ✅ Scanner → Bulk-Scan-Modus (mehrere Artikel hintereinander, auto-add)
- ✅ Scanner → Barcode manuell eingeben (Dialog mit Nummernblock)
- ✅ Rezepte → Variationen (Vegetarisch/Vegan/Glutenfrei/Low-Cal/High-Protein Chips)
- ✅ UI → Dark Mode Verbesserungen (Karten, Dialoge, Popups aufgehellt)
- ✅ UI → Skeleton-Loading (Shimmer-Cards statt Spinner)
- ✅ UI → Bottom Sheet Drag Handle (global via Theme)
- ✅ Haushalt → Geteilte Einkaufsliste (Supabase RLS, 👥-Badge)
- ✅ Monetarisierung → KI-Limit Counter (5/Woche Free, lokal via SharedPreferences)
- ✅ Monetarisierung → Supabase `subscriptions`-Tabelle + `subscription_provider`
- ✅ Monetarisierung → Paywall-Screen (Free vs. Pro Karten, Feature-Liste, Upgrade-Button)
- ✅ Monetarisierung → Settings: Plan-Badge, KI-Nutzungsanzeige, Upgrade-Button
- ✅ Ernährung → Ernährungsprofil (Alter, Geschlecht, Gewicht, Größe, Ziel) mit Mifflin-St Jeor BMR
- ✅ Ernährung → Tages-Kalorien-Tracker (Kochmodus „Fertig!" → Nährwerte loggen)
- ✅ Ernährung → Makro-Ring-Chart (Protein/Carbs/Fett Donut via CustomPainter)
- ✅ Ernährung → Wochenauswertung (7-Tage-Balkenchart mit Ziel-Linie & Ø-Wert)
- ✅ Ernährung → Kompakter Kalorien-Fortschrittsbalken auf dem Vorrat-Tab
- ✅ Ernährung → Nutrition-Screen mit Pro-Teaser für Free-User
- ✅ Ernährung → Settings: Menüpunkt „Nährwert-Tracking" mit Pro-Badge
- ✅ Rezepte → Koch-Streak 🔥 (aufeinanderfolgende Tage, Badge in AppBar, Snackbar)
- ✅ Wochenplaner → 7-Tage-Ansicht mit 4 Slots/Tag (Frühstück/Mittag/Abend/Snack)
- ✅ Wochenplaner → Rezept zuweisen aus gespeicherten Rezepten + Kalorien-Anzeige
- ✅ Wochenplaner → Zutaten der Woche auf Einkaufsliste (dedupliziert)
- ✅ Wochenplaner → Plan teilen als Text + Pro-Teaser für Free-User
- ✅ Wochenplaner → Settings: Menüpunkt „Wochenplaner" mit Pro-Badge
- ✅ Ernährung → Wassertracker (Quick-Add +250ml/+500ml, Tagesziel 2.5L, Fortschrittsbalken)
- ✅ Rezepte → Saisonale Rezept-Chips (12 Monate, je 3 saisonale Vorschläge)
- ✅ Allergene → 14 EU-Allergene als Filter-Chips in Settings (Gluten, Milch, Nüsse etc.)
- ✅ Allergene → Keyword-basierte Erkennung in Rezept-Zutaten mit Warnicon + Label
- ✅ Nutri-Score → Bereits in Item-Detail-Screen via OpenFoodFacts integriert (A-E Badge)
- ✅ Einkaufsliste → Autocomplete (Vorschläge aus Inventar + Stammartikel beim Tippen)
- ✅ Onboarding → 3-Screen Flow (Willkommen, Scannen, Features) mit PageView + Skip
- ✅ Vorrat → Mengen-Schnellbearbeitung (+/- Buttons direkt auf Inventarkarte)
- ✅ Vorrat → Statistiken-Dashboard (Frisch/Ablaufend/Abgelaufen-Balken + Top-Kategorien)
- ✅ KI → Wochenplan-Generator (Kompletter 7-Tage-Plan per Groq, passend zum Ernährungsprofil)
- ✅ UI → Onboarding-Flow mit initialLocation-Steuerung im Router
- ✅ KI → Meal-Prep-Assistent (Button auf KI-Tab für vorkochbare Rezepte)
- ✅ KI → Budget-Kochen (Budget-Dialog → KI plant günstige Rezepte)
- ✅ KI → Küchen-Stil-Schnellauswahl (8 Länderküchen als Chips auf KI-Tab)
- ✅ Vorrat → Strichcode-Eigenprodukt (Manuelle Eingabe wenn nicht in OpenFoodFacts)
- ✅ Einkaufsliste → Marktauswahl (8 Supermärkte als ChoiceChips beim Listen-Erstellen)
- ✅ Wochenplaner → Plan-Vorlagen (Speichern & Laden von Wochenplänen als Vorlage)
- ✅ UI → Splash Screen (flutter_native_splash, Foody Grün #2E7D32, Dark Mode Support)
- ✅ UI → Hero-Animationen (Produktbild fliegt auf Detailseite)
- ✅ UI → Sanfte Einblend-Animationen (Items gleiten ein via TweenAnimationBuilder)
- ✅ Rezepte → Eigene Rezepte ohne KI (Manuelles Formular: Titel, Zutaten, Schritte, Kochzeit)
- ✅ Rezepte → Collections (Eigene Ordner mit Emoji-Icon, Filter im Gespeichert-Tab)
- ✅ Rezepte → Einkaufsliste aus Rezept (Button mit Inventar-Vorcheck, bereits vorhanden)
- ✅ Vorrat → MHD per Kamera scannen (ML Kit OCR, erkennt DD.MM.YYYY / MM.YYYY / ISO etc.)
- ✅ Vorrat → Zonen-Filter (🏠 Alle / 🧊 Kühlschrank / ❄️ Tiefkühl / 🏪 Vorratskammer / 🥦 Obst & Gemüse)
- ✅ Einkaufsliste → Prominenter „N Artikel in Vorrat übernehmen"-Banner wenn Items abgehakt
- ✅ Rezepte → KI-Chat-Assistent (4. Tab „Chat", Groq llama3-70b, Vorrat-Kontext, Quick-Chips)
- ✅ Haushalt → Aktivitätslog (wer hat was wann geändert, letzte 50 Einträge, relative Zeitangaben)
- ✅ Vorrat → Stats-Card nur noch anzeigen wenn MHD-Artikel vorhanden (aufgeräumter)
- ✅ Vorrat → Ablauf-Banner entfernt (Info bereits in kompakter StatsCard)
- ✅ Rezepte → KI-Tab radikal aufgeräumt (eine Prompt-Zeile, eine Buttonreihe, eine Chip-Zeile)
- ✅ KI → Anti-Duplikat-Logik: merkt sich letzte 30 Rezept-Titel + stärkere Randomisierung
- ✅ KI → Mehr Küchen (15 statt 10), mehr Stile (14), Zubereitungsarten, höhere Temperature
- ✅ Einkaufsliste → Foto-Import: Einkaufszettel fotografieren → OCR → Auswahl-Sheet → Hinzufügen
- ✅ Haushalt → Mitglieder-Limit: Free max 2, Pro max 6 Mitglieder
- ✅ Dashboard → Neuer Home-Tab mit Hero-Header, Streak, Wasser, Vorrat, Ernährung, Wochenplan-Vorschau, Schnellzugriff
- ✅ Navigation → Bottom-Nav auf 6 Tabs: Home / Vorrat / Scanner / Rezepte / Einkauf / Community
- ✅ Vorrat → Kalorien-Bar entfernt (jetzt auf Dashboard), Vorrat-Tab fokussiert auf Artikel

---

## 👥 Community-Rezepte (Phase 28 – NEU)

> **Vision:** Foody wird zur Rezepte-Community – User teilen ihre Lieblingsrezepte, liken und kommentieren.
> Die Community-DB wächst organisch und bindet User langfristig. KI bleibt als Assistenz-Feature erhalten,
> Community-Rezepte rücken in den Vordergrund.

### Free vs. Pro
| Feature | 🆓 Free | ⭐ Pro |
|---|---|---|
| Community-Feed lesen | ✅ | ✅ |
| Rezepte liken & kommentieren | ✅ | ✅ |
| Eigene Rezepte veröffentlichen | max. **3 Rezepte** | ✅ Unbegrenzt |
| Rezept-Bilder hochladen | ❌ | ✅ (Supabase Storage) |
| Erweiterte Suchfilter / Tags | ❌ | ✅ |
| Spoonacular-Profi-Suche | ❌ | ✅ |

### Supabase-Tabellen (SQL bereit)
```sql
-- community_recipes
create table if not exists community_recipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  author_name text,
  title text not null,
  description text,
  recipe_json jsonb not null,
  image_url text,
  tags text[] default '{}',
  category text,
  difficulty text,
  cooking_time_minutes int default 30,
  servings int default 2,
  is_published bool default true,
  source text default 'community',
  view_count int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table community_recipes enable row level security;
create policy "Feed lesbar" on community_recipes for select using (auth.uid() is not null);
create policy "Eigene verwalten" on community_recipes for all using (auth.uid() = user_id);
create index idx_cr_created on community_recipes(created_at desc);
create index idx_cr_user on community_recipes(user_id);

-- recipe_likes
create table if not exists recipe_likes (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid references community_recipes on delete cascade not null,
  user_id uuid references auth.users not null,
  created_at timestamptz default now(),
  unique(recipe_id, user_id)
);
alter table recipe_likes enable row level security;
create policy "Likes lesbar" on recipe_likes for select using (auth.uid() is not null);
create policy "Eigene Likes" on recipe_likes for all using (auth.uid() = user_id);

-- recipe_comments
create table if not exists recipe_comments (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid references community_recipes on delete cascade not null,
  user_id uuid references auth.users not null,
  author_name text,
  content text not null,
  created_at timestamptz default now()
);
alter table recipe_comments enable row level security;
create policy "Kommentare lesbar" on recipe_comments for select using (auth.uid() is not null);
create policy "Eigene Kommentare" on recipe_comments for all using (auth.uid() = user_id);
```

### Implementierungsschritte
- [x] **SQL-Migration** – Tabellen `community_recipes`, `recipe_likes`, `recipe_comments` anlegen (in `supabase_setup.sql` ergänzt)
- [x] **Dart-Model** `CommunityRecipe` + `RecipeComment` mit `fromJson`/`toJson`
- [x] **Repository** `CommunityRecipeRepository` – Feed, Like-Toggle, Kommentare, Publish
- [x] **Provider** `communityFeedProvider`, `recipeCommentsProvider`, `recipeLikeProvider`, `myPublishedRecipesProvider`, `publishRecipeProvider`
- [x] **CommunityScreen** – Feed + Meine + **Entdecken (Spoonacular)** 3 Tabs
- [x] **CommunityRecipeCard** – Titel, Autor, Like-Count, Kommentar-Count, Kochzeit, Tags
- [x] **PublishRecipeSheet** – Rezept teilen (aus gespeicherten Rezepten, Kategorie, Tags)
- [x] **CommunityRecipeDetailScreen** – Zutaten, Schritte, Like, Kommentare, FABs (Kochmodus / Einkaufsliste mit Inventar-Vergleich / Wochenplan), Teilen
- [x] **Navigation** – Community als 4. Tab in BottomNav (`/community`)
- [x] **Free/Pro Gate** – Max. 3 eigene Rezepte Free
- [x] **FoodRecipe.copyWith()** hinzugefügt
- [x] **SpoonacularService** – `lib/core/services/spoonacular_service.dart`
- [x] **SpoonacularProvider** – Suche, Zufalls-Rezepte, Diät-Filter, Zutaten-Suche
- [x] **_DiscoverTab** – mit Suche, Diät-Filter, Quick-Searches, graceful Fallback
- [x] **Build erfolgreich** ✅
- [ ] **Spoonacular-Key** – `SPOONACULAR_API_KEY=xxx` in `.env` (kostenlos: spoonacular.com)
- [ ] **Bild-Upload** – Supabase Storage Bucket `recipe-images` (Pro-Feature)

### Deutsche Rezept-Datenbanken
| Quelle | Kosten | Anmerkung |
|---|---|---|
| **Spoonacular** (`language=de`) | 150 Calls/Tag kostenlos | Beste API, DE-Übersetzung |
| **TheMealDB** (aktuell) | Kostenlos | Nur EN, Groq-Übersetzung aktiv |
| **Community selbst** | Kostenlos | Wächst mit App-Nutzung |
| **Open Recipes (GitHub)** | Kostenlos (CC) | Manueller Import möglich |
| ~~Chefkoch~~ | Keine API | Scraping = rechtl. Grauzone |

---

## 🔥 Nächste Implementierungsschritte (Reihenfolge)

```
Nr   Prio       Beschreibung                                        Aufwand   Status
─────────────────────────────────────────────────────────────────────────────────────
 1.  💰 Mono    KI-Limit 5/Woche (ai_usage_provider)               Klein     ✅
 2.  💰 Mono    Supabase subscriptions-Tabelle + SQL               Klein     ✅
 3.  💰 Mono    subscription_provider (isPro, plan)                Klein     ✅
 4.  💰 Mono    Paywall-Screen (Free/Pro Karten, Upgrade-Button)   Mittel    ✅
 5.  💰 Mono    Settings: Plan-Sektion, KI-Nutzungsanzeige         Klein     ✅
 6.  💰 Mono    recipe_provider: Free-Gate einbauen                Klein     ✅
─────────────────────────────────────────────────────────────────────────────────────
 7.  🔥 High    Nährwert-Tracker (Tages-Kalorien + Makros)        Mittel    ✅
 8.  🔥 High    Ernährungsprofil (BMI, Tagesziel auto)            Klein     ✅
 9.  🔥 High    Makro-Übersicht (Protein/Carbs/Fett Ring-Chart)   Mittel    ✅
10.  🔥 High    Wochenauswertung Kalorien (Balken-Chart)          Mittel    ✅
11.  🔥 High    Mahlzeiten-Wochenplaner (7 Tage, 3 Slots/Tag)     Groß      ✅
12.  🔥 High    Wochenplan → Einkaufsliste (Zutaten dedupliziert)  Mittel    ✅
13.  💡 Mid     Supermarkt-Angebote (Scraper/inoffizielle APIs)    Groß
14.  💡 Mid     „Aus Angeboten kochen" KI-Button                   Klein
15.  💡 Mid     Allergen-Filter (Laktose, Gluten, Nüsse)          Mittel    ✅
16.  💡 Mid     Nutri-Score im Vorrat (OpenFoodFacts)              Klein     ✅
17.  💡 Mid     Wassertracker                                       Klein     ✅
18.  💡 Mid     Streak-System 🔥 (Tage in Folge gekocht)          Klein     ✅
19.  💡 Mid     Saisonale Rezept-Chips (nach Monat)                Klein     ✅
20.  🎨 UI      App-Icon + Splash Screen                           Mittel    ✅
21.  🎨 UI      Onboarding-Flow (3 Screens, interaktiv)            Mittel    ✅
22.  🤝 Koop    Rewe/Edeka Angebots-Integration (Proof of Concept) Groß
23.  🔧 Tech    Supabase Edge Function als Groq-API-Proxy          Groß
24.  🔧 Tech    Supabase Realtime (Haushalt live sync)             Groß
25.  🔧 Tech    RevenueCat-Integration (Phase 2 IAP)               Groß
26.  🚀 Rel     Play Store / App Store Vorbereitung                Groß
```

---

## 📊 Nährwerte & Gesundheit (Pro-Feature)

### Geplante Features
- [x] **Ernährungsprofil** – Alter, Geschlecht, Gewicht, Ziel (abnehmen/halten/aufbauen) eingeben.
  Tagesziel wird automatisch berechnet (Harris-Benedict-Formel). Manuell überschreibbar.
- [x] **Tages-Kalorien-Tracker** – Beim „Fertig gekocht"-Button im Kochmodus: Kalorien des Rezepts
  (pro Portion × Portionsanzahl) für heute summieren. Kompakter Fortschrittsbalken auf Vorrat-Tab.
- [x] **Makro-Übersicht** – Donut-Chart: Protein (blau) / Kohlenhydrate (orange) / Fett (gelb).
  Tageswerte + Zielwerte. Tippen auf Segment zeigt Details.
- [x] **Wochenauswertung Kalorien** – Balkendiagramm: letzte 7 Tage. Tagesziel als gestrichelte
  Linie. Ø-Wert wird angezeigt.
- [ ] **Nutri-Score im Vorrat** – OpenFoodFacts liefert bereits `nutriscore_grade`. Badge
  auf Inventar-Karte (A=grün bis E=rot). Vorrat-Gesundheits-Score als Gesamtwert.
- [x] **Allergen-Filter** – User wählt Allergene in Einstellungen. Rezepte + Vorrats-Items
  werden entsprechend markiert oder ausgeblendet. Zutaten mit Allergen = rote Warnung.
- [x] **Wassertracker** – Tägliches Ziel (Standard 2,5L). +250ml / +500ml Quick-Buttons.
  Kleines Widget in der Nährwert-Übersicht.
- [x] **Supabase `nutrition_log`-Tabelle** – Pro-User: Tages-Log in der Cloud, anonym auswertbar
  für Produktverbesserungen (mit Opt-in). Free-User: nur lokal via SharedPreferences.

### SQL (bereits vorbereitet)
```sql
-- nutrition_log: Tages-Kalorien-Tracking
create table if not exists nutrition_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  logged_at date not null default current_date,
  recipe_title text,
  calories int not null,
  protein float default 0,
  carbs float default 0,
  fat float default 0,
  fiber float default 0,
  servings float default 1,
  created_at timestamptz default now()
);
```

---

## 📅 Mahlzeiten-Wochenplaner (Pro-Feature)

### Geplante Features
- [x] **7-Tages-Ansicht** – Horizontale Scroll-Cards Mo bis So. Jede Karte hat 3 Slots:
  Frühstück 🌅 / Mittagessen ☀️ / Abendessen 🌙. Optional: Snack-Slot.
- [x] **Rezept zuweisen** – Tap auf Slot → Bottom Sheet mit gespeicherten Rezepten + KI-Vorschlag.
  Rezept-Karte zeigt Kalorien + Kochzeit direkt im Plan.
- [x] **Tages-Kalorien im Plan** – Summe der geplanten Mahlzeiten pro Tag direkt sichtbar.
  Farbkodiert: unter Ziel (grün), im Ziel (blau), über Ziel (orange).
- [x] **Wochenplan → Einkaufsliste** – Button „Alle Zutaten einkaufen": sammelt alle Rezept-Zutaten
  der Woche, dedupliziert (500g Mehl + 200g Mehl = 700g Mehl), fügt zur aktiven Liste hinzu.
- [x] **Wochenplan teilen** – Als Text oder Bild teilen. Pro-Feature.
- [x] **Plan-Vorlagen** – ✅ Wochenpläne als Vorlage speichern und wiederverwenden.
  Zb „Muskelaufbau-Woche" oder „Diät-Woche".
- [x] **KI-Wochenplan generieren** – ✅ Ein-Klick: KI erstellt kompletten 7-Tage-Plan passend
  zum Ernährungsprofil (Kalorien, Ziel, verfügbare Zutaten im Vorrat).

### SQL (bereits vorbereitet)
```sql
-- meal_plans: Mahlzeiten-Wochenplaner
create table if not exists meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  week_start date not null,
  day_index int not null check (day_index between 0 and 6),
  slot text not null check (slot in ('breakfast', 'lunch', 'dinner', 'snack')),
  recipe_json jsonb not null,
  created_at timestamptz default now(),
  unique(user_id, week_start, day_index, slot)
);
```

---

## 🔥 Hohe Priorität

### ✨ UX-Verbesserungen

- [x] **Vorrat: Sortier-Optionen** – ✅ 5 Optionen: Ablaufdatum, Name A→Z, Name Z→A, Neueste, Kategorie
- [x] **Vorrat: Suchfeld** – ✅ Suchleiste in der AppBar, filtert live
- [x] **Vorrat: Swipe-to-Edit** – ✅ Links = Bearbeiten, Rechts = Löschen
- [x] **Scanner: Torch-Status sichtbar** – ✅ Icon wechselt flash_on/off
- [x] **Scanner: Haptik** – ✅ HapticFeedback bei Barcode-Erkennung
- [x] **Einkaufsliste: Drag & Drop** – ✅ ReorderableListView
- [x] **Rezepte: Letzte Prompts** – ✅ 5 Quick-Repeat-Chips (recent_prompts_provider)
- [x] **Testdaten-Generator** – ✅ 32 Haushaltszutaten + 2 Einkaufslisten per Knopfdruck
- [ ] **Einstellungen: Sprache wählen** – Deutsch / Englisch (App-Texte + KI-Prompts)
- [x] **Streak-System** – ✅ Koch-Streak mit Badge + Snackbar
- [x] **Saisonale Rezept-Chips** – ✅ 12 Monate × 3 saisonale Vorschläge

### 🆕 Neue Features (hoch priorisiert)

- [x] **Mahlzeiten-Wochenplaner** – ✅ Siehe eigener Abschnitt oben. Pro-Feature.
- [x] **Einkaufsliste aus Wochenplan** – ✅ Zutaten dedupliziert auf aktive Liste setzen
- [x] **Vorrat-Ablauf-Dashboard** – ✅ Stats-Card mit Frisch/Ablaufend/Abgelaufen-Balken
- [x] **Erinnerungen für Mahlzeiten** – ✅ Push: „Heute auf dem Plan: Pasta Bolognese · Salat"

---

## 💡 Mittlere Priorität

### 🍳 Rezepte

- [x] **Portionen anpassen** – ✅ Mengen automatisch skaliert
- [x] **Rezept-Notizen** – ✅ Freitext (lokal)
- [x] **Rezept-Kategorien** – ✅ Frühstück/Mittag/Abend/Snack/Dessert
- [x] **Lieblingsrezepte** – ✅ Herzchen-Icon + Favoriten-Filter
- [x] **Kochzeit-Filter** – ✅ < 20 / 20–45 / > 45 Min.
- [x] **Kochmodus** – ✅ Vollbild, Wisch-Navigation, Wakelock
- [x] **Rezept-Timer** – ✅ Countdown, Pause/Resume, Alarm
- [x] **Zuletzt gekochte Rezepte** – ✅ letzte 20 mit Datum
- [x] **Rezept teilen** – ✅ System-Share-Dialog
- [x] **Online-Rezepte speichern** – ✅ Bookmark-Button
- [x] **Einkaufsliste aus Rezept** – ✅ Button „Zutaten auf Einkaufsliste" mit Inventar-Check
- [ ] **Rezept-Skalierung in Einkaufsliste** – Portionen wählen beim Übertragen
- [ ] **Rezeptbuch exportieren** – Alle gespeicherten Rezepte als PDF
- [ ] **Küche / Landesküche Filter** – Beim Generieren + im Gespeichert-Tab
- [x] **Rezept-Collections** – ✅ Eigene Ordner mit Emoji-Icon (erstellen, löschen, Rezepte zuordnen)
- [x] **Eigene Rezepte ohne KI** – ✅ Manuelles Rezept-Formular (Titel, Zutaten, Schritte, Kochzeit)
- [x] **KI-Küchen-Stil-Auswahl** – ✅ Chip-Auswahl: Italienisch / Asiatisch / Deutsch / Mexikanisch / Indisch / Griechisch / Französisch / Thai

### 🥕 Scanner & Vorrat

- [x] **Bulk-Scan-Modus** – ✅ Mehrere Artikel, Scanner bleibt aktiv
- [x] **Barcode manuell eingeben** – ✅ Textfeld + Nummernblock
- [x] **Vorrat durchsuchen** – ✅ Suchfeld nach Name + Kategorie
- ✅ MHD per Kamera erkennen – ML Kit OCR scannt Ablaufdatum direkt aus Kamera-Foto
- ✅ Vorrat-Kategorien als Tabs – Zonen-Filter: 🏠 Alle / 🧊 Kühlschrank / ❄️ Tiefkühl / 🏪 Vorratskammer / 🥦 Obst & Gemüse
- ✅ Import aus Einkaufsliste prominenter – Floating-Banner „N Artikel in Vorrat übernehmen" erscheint sobald Items abgehakt
- ✅ KI-Kochassistent (Chat) – 4. Tab „Chat" im Rezepte-Screen, Groq llama3-70b, kennt Vorrat, Quick-Chips
- ✅ Haushaltsmitglieder-Aktivität – Log wer wann was hinzugefügt/bearbeitet/gelöscht hat, sichtbar im Haushalt-Screen- [x] **Vorrat-Statistiken Dashboard** – ✅ Frisch/Ablaufend/Abgelaufen-Balken + Top-Kategorien
- [x] **Import aus Einkaufsliste prominenter** – ✅ „Eingekaufte Items in Vorrat" Banner-Button
- [x] **Strichcode-Eigenprodukt** – ✅ Manuelle Produkteingabe wenn nicht in DB
- [x] **Ablaufdatum-Badge auf Karte** – ✅ Farbiger Indikator direkt auf der Karte
- [x] **Mengen-Schnellbearbeitung** – ✅ +/– Buttons direkt auf Inventarkarte
- [x] **Vorrat-Kategorien als Tabs** – ✅ Alle / Kühlschrank / Tiefkühl / Vorratskammer / Obst & Gemüse

### 🛒 Einkaufsliste

- [x] **Stammartikel** – ✅ Quick-Add-Chips + Verwaltungs-Sheet
- [x] **Gesamtpreis schätzen** – ✅ Preis pro Artikel, Summe unten
- [x] **Artikel-Kategorien** – ✅ Gruppierte Ansicht nach Kategorie
- [x] **Liste teilen** – ✅ Formatierter Text (WhatsApp etc.)
- [x] **Erledigte ausblenden** – ✅ Toggle-Button
- [x] **Templates** – ✅ Liste als Vorlage speichern + laden
- [x] **Marktauswahl pro Liste** – ✅ 8 Supermärkte als ChoiceChips beim Erstellen
- [x] **Autocomplete beim Tippen** – ✅ Vorschläge aus Inventar + Stammartikel
- [ ] **Listen-Statistiken** – Wocheneinkauf-Übersicht, häufigste Artikel
- [x] **Artikel aus Foto** – ✅ Foto von Einkaufszettel (Kamera/Galerie) → OCR → Artikel-Auswahl-Sheet → Hinzufügen
- [ ] **Supermarkt-Layout-Sortierung** – Sortiert nach echtem Markt-Gang-Schema

### 🏠 Haushalt

- [x] **Geteilte Einkaufsliste** – ✅ Haushalt-Listen mit 👥-Badge
- [x] **Haushaltsmitglieder-Aktivität** – ✅ Wer hat wann was geändert? Log im Haushalt-Screen (letzte 50 Einträge, relative Zeit)
- [ ] **Rollen-Berechtigungen** – Admin kann Mitglieder verwalten
- [x] **Haushalt-Chat / Notizen** – ✅ Chat mit Realtime, Schnellnachrichten, Push bei neuer Nachricht
- [ ] **Push bei Haushalt-Änderungen** – Realtime-Benachrichtigung an Mitglieder
- [x] **Haushalt-Mitglieder-Limit Free** – ✅ Max. 2 Personen Free → Pro für bis zu 6 Mitglieder
- [x] **Geteilter Haushalt-Wochenplan** – ✅ Opt-in Dialog beim Haushalt-Beitritt/Erstellen.
  „Nein" = persönlicher Plan bleibt, Haushalt-Mitglied ohne Wochenplan-Sharing.
  „Ja" = `household_id` in `meal_plans`, alle Mitglieder sehen + bearbeiten denselben Plan.
  Jederzeit umschaltbar über Switch im Haushalt-Tab. Banner im Wochenplaner zeigt den aktiven Modus.
  Supabase: `meal_plans.household_id` + `meal_plan_preferences`-Tabelle + neue RLS-Policies.
  → SQL: `supabase_migration_09_household_meal_plan.sql`

---

## 🤖 KI-Erweiterungen

- [x] **Rezept-Variationen** – ✅ Vegetarisch/Vegan/Glutenfrei/Kalorienärmer/High-Protein
- [x] **Gewürze filtern** – ✅ Standardzutaten aus KI-Prompt herausgefiltert
- [x] **KI-Kochassistent (Chat)** – ✅ Freitextchat im Rezepte-Tab (4. Tab „Chat"), Groq llama3-70b,
  Vorrat-Kontext eingebaut, Quick-Chips: „Was koche ich heute?", „Reste verwerten" etc. Pro-Feature.
- [ ] **Intelligente Einkaufsvorschläge** – KI analysiert Kochgewohnheiten,
  schlägt proaktiv vor was fehlt oder regelmäßig gebraucht wird.
- [ ] **„Aus Angeboten kochen"** – KI-Prompt mit aktuellen Supermarkt-Angeboten
  als Hauptzutaten. Pro-Feature + Kooperation.
- [ ] **Kühlschrank-Foto-Analyse** – Foto → KI erkennt automatisch Produkte → Vorrat befüllen.
  Sehr attraktives Marketing-Feature.
- [x] **Meal-Prep-Assistent** – ✅ Meal-Prep-Button auf KI-Tab für vorkochbare Rezepte.
- [x] **Einkaufsbudget-KI** – ✅ Budget-Dialog → KI plant günstige Rezepte.
- [x] **KI-Wochenplan-Generator** – ✅ Kompletter Plan per Ein-Klick, passend zum Profil.
- [ ] **Groq-Proxy via Supabase Edge Function** – API-Key nie im App-Bundle.
  Rate-Limit serverseitig (1 Req/2 Sek. pro User). Dringend vor Store-Release!

---

## 🔔 Push Notifications (Phase 34)

> **Status:** `flutter_local_notifications` bereits eingebunden. Firebase Cloud Messaging (FCM) fehlt noch.
> Push Notifications sind ein starker Retention-Hebel – besonders MHD-Warnungen und Haushalt-Events.

### Notification-Typen (priorisiert)

| Typ | Trigger | Prio | Plan |
|---|---|---|---|
| **MHD-Warnung** | Artikel läuft in X Tagen ab (konfigurierbar: 1/2/3 Tage) | 🔥 Must-Have | Free |
| **Haushalt-Änderung** | Mitglied hat Vorrat oder Einkaufsliste geändert | 🔥 Must-Have | Free |
| **Neue Chat-Nachricht** | Supabase Realtime → FCM Webhook | 🔥 Must-Have | Free |
| **Wochenplan-Erinnerung** | Täglich 17:00: „Heute auf dem Plan: [Rezept]" | 🔥 Must-Have | Free |
| **Neuer Follower** | Social-Event aus `user_follows`-Tabelle | ⭐ Nice-to-have | Free |
| **Neues Like / Kommentar** | Community-Event | ⭐ Nice-to-have | Pro |
| **Wochenzusammenfassung** | Sonntags: „Du hast 4x gekocht, ~12€ gespart" | 💡 Nice-to-have | Pro |
| **KI-Limit-Warnung** | Noch 1 KI-Rezept verbleibend diese Woche | 💡 Nice-to-have | Free |

### Technischer Plan

**Pakete in `pubspec.yaml` ergänzen:**
```yaml
firebase_core: ^3.0.0
firebase_messaging: ^15.0.0
```

**Android:** `google-services.json` → `android/app/`
**iOS:** `GoogleService-Info.plist` + APNs-Zertifikat in Apple Developer Console

**Neue Supabase-Migration `supabase_migration_20_push_tokens.sql`:**
```sql
-- FCM-Token pro User/Device speichern
create table push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  token text not null,
  platform text check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz default now(),
  unique(user_id, token)
);
alter table push_tokens enable row level security;
create policy "Eigene Tokens" on push_tokens for all using (auth.uid() = user_id);

-- Notification-Einstellungen pro User
create table notification_settings (
  user_id uuid primary key references auth.users,
  mhd_warnings bool default true,
  household_changes bool default true,
  chat_messages bool default true,
  meal_reminders bool default true,
  community_events bool default false,
  weekly_summary bool default false,
  meal_reminder_time time default '17:00',
  mhd_warning_days_before int default 2
);
alter table notification_settings enable row level security;
create policy "Eigene Settings" on notification_settings for all using (auth.uid() = user_id);
```

**Neue Supabase Edge Function `send-push`:**
- Empfängt Events aus DB-Triggern (MHD-Check täglich via pg_cron)
- Empfängt Realtime-Webhooks für Haushalt-Änderungen, Chat-Messages
- Sendet FCM-Benachrichtigungen via Firebase Admin SDK

**Neuer Dart-Service `lib/core/services/push_notification_service.dart`:**
- FCM-Token beim Login in `push_tokens` Supabase-Tabelle speichern
- `flutter_local_notifications` für Foreground-Nachrichten
- `firebase_messaging` für Background/Terminated State

### Implementierungs-Reihenfolge
1. Firebase-Projekt anlegen (console.firebase.google.com)
2. `google-services.json` + `GoogleService-Info.plist` in Projekt einfügen
3. `firebase_core` + `firebase_messaging` in pubspec.yaml
4. `push_notification_service.dart` implementieren
5. Supabase-Migration ausführen
6. Edge Function deployen
7. Settings-Screen: Notification-Einstellungen UI

---

## 💳 RevenueCat – Echte In-App Purchases (Phase 33 Update)

> **Status:** Phase 1 Monetarisierung ✅ (lokales Limit + Supabase `subscriptions`-Tabelle)
> Phase 2 (echte IAP via RevenueCat) – ❌ **Blocker für Store-Release!**
> Ohne RevenueCat können keine echten Zahlungen verarbeitet werden.

### Warum RevenueCat statt direktes Google/Apple Billing
- Ein SDK für Android (Google Play Billing) + iOS (StoreKit/IAP) + Web
- Automatische Abo-Verlängerung, Kündigung, Wiederherstellung (Restore Purchases)
- Webhook → Supabase automatisch aktualisieren (kein manuelles Sync nötig)
- Kostenloses Tier bis 2.500 $/MTR (reicht für den Start)
- Exzellentes Flutter-SDK: `purchases_flutter`

### Schritt-für-Schritt Implementierung

#### 1. RevenueCat Dashboard konfigurieren (app.revenuecat.com)
- [ ] App anlegen: Android (`de.foodyapp.app`) + iOS Bundle-ID
- [ ] Entitlement `pro` erstellen
- [ ] Products anlegen:
  - `foody_pro_monthly` (2,99 €/Monat, Abo)
  - `foody_pro_yearly` (19,99 €/Jahr, Abo)
- [ ] Google Play Billing API-Key eintragen (aus Google Play Console → Setup → API access)
- [ ] App Store Connect API-Key eintragen
- [ ] Webhook-URL setzen: `https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook`

#### 2. Flutter-Pakete hinzufügen
```yaml
# pubspec.yaml → dependencies
purchases_flutter: ^8.0.0
```

#### 3. `subscription_provider.dart` anpassen
```dart
// Initialisierung in main.dart (nach Supabase.initialize)
await Purchases.configure(
  PurchasesConfiguration(
    Platform.isIOS ? 'appl_...' : 'goog_...',
  ),
);
// User-ID setzen damit Käufe dem Supabase-User zugeordnet werden
await Purchases.logIn(userId);

// Subscription-Status prüfen
final customerInfo = await Purchases.getCustomerInfo();
final isPro = customerInfo.entitlements['pro']?.isActive ?? false;

// Kauf auslösen (in paywall_screen.dart)
final offerings = await Purchases.getOfferings();
await Purchases.purchasePackage(offerings.current!.monthly!);

// Restore Purchases
await Purchases.restorePurchases();
```

#### 4. Supabase Edge Function `revenuecat-webhook`
```typescript
// supabase/functions/revenuecat-webhook/index.ts
// Empfängt: INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION
// Aktualisiert: subscriptions-Tabelle automatisch
// Authentifizierung: RevenueCat Webhook-Secret als Supabase-Secret
```

#### 5. Supabase `subscriptions`-Tabelle aktualisieren
- Neue Spalten: `revenuecat_user_id`, `original_purchase_date`, `cancellation_date`, `renewal_date`
- Webhook trägt diese automatisch ein

#### 6. Paywall-Screen (`paywall_screen.dart`) anpassen
- Echte Preise via `Purchases.getOfferings()` statt hardcodierte 2,99/19,99
- „Kaufen"-Buttons mit `Purchases.purchasePackage()`
- „Käufe wiederherstellen"-Button (`Purchases.restorePurchases()`)
- Fehlerbehandlung: UserCancelledPurchasesError, PurchasesErrorCode

#### 7. Google Play Console konfigurieren
- Abos anlegen: `foody_pro_monthly` + `foody_pro_yearly`
- Billing API aktivieren, Service-Account mit RevenueCat verknüpfen

#### 8. App Store Connect konfigurieren
- Abos anlegen: In-App Purchases → Subscriptions → Neue Abo-Gruppe
- Sandbox-Tester anlegen für Tests

### Test-Checkliste
- [ ] Kauf Monthly via Google Play Sandbox testen
- [ ] Kauf Yearly via App Store Sandbox testen
- [ ] Kündigung → Webhook aktualisiert Supabase
- [ ] Restore Purchases funktioniert
- [ ] Pro-Features nach Kauf sofort verfügbar
- [ ] Downgrade nach Ablauf funktioniert

---

## 🚨 Pre-Launch Blocker – Kritischer Pfad

> Diese Punkte **müssen** vor dem ersten Store-Upload erledigt sein. Alles andere kann nach Launch nachgezogen werden.

### 🔴 BLOCKER (ohne diese kein Store-Upload)

| # | Task | Aufwand | Status |
|---|---|---|---|
| 1 | **Groq-Proxy via Supabase Edge Function** – API-Key aktuell im App-Bundle (`.env` als Asset = unsicher in Produktion!) | Mittel | ⚠️ Prüfen ob wirklich deployed |
| 2 | **RevenueCat-Integration** (echte IAP, kein Fake-Abo) | Groß | ❌ Offen |
| 3 | **App-Icon** alle Auflösungen Android + iOS | Klein | ❌ Offen |
| 4 | **Datenschutzerklärung + AGB + Impressum** (DSGVO, Pflicht im Store) | Mittel | ❌ Offen |
| 5 | **Android Signing-Keystore** + iOS Provisioning Profile | Klein | ❌ Offen |
| 6 | **App-Name final festlegen** (vor erstem Listing!) | Klein | ❌ Offen |

### 🟡 WICHTIG (sollte vor Launch fertig sein)

| # | Task | Aufwand | Status |
|---|---|---|---|
| 7 | **Sentry Crash-Monitoring** einbinden | Klein | ❌ Offen |
| 8 | **RLS Security Audit** (alle Tabellen, kein fremder Datenzugriff) | Mittel | ❌ Offen |
| 9 | **Play Store + App Store Listing** (Screenshots, Texte, Kategorie) | Mittel | ❌ Offen |
| 10 | **Push Notifications** (FCM + flutter_local_notifications) | Groß | ❌ Offen |

### 🟢 NACH LAUNCH (Post-Launch Backlog)

| # | Task |
|---|---|
| 11 | Offline-Caching (Drift DB lokal, Sync bei Reconnect) |
| 12 | CI/CD Pipeline (GitHub Actions) |
| 13 | Unit- & Widget-Tests |
| 14 | Deep Links (`foody://recipe/123`) |
| 15 | Supermarkt-Kooperationen (Rewe/Edeka API) |
| 16 | A/B-Testing Paywall |
| 17 | Referral-Programm |

---

## 📦 Sentry Crash-Monitoring (Schnell-Integration)

> Kostenloses Tier: bis 5.000 Events/Monat. Reicht für den Start mehr als ausreichend.

```yaml
# pubspec.yaml → dependencies
sentry_flutter: ^8.0.0
```

```dart
// main.dart
await SentryFlutter.init(
  (options) {
    options.dsn = dotenv.env['SENTRY_DSN']!;
    options.tracesSampleRate = 0.3; // 30% Performance-Traces
    options.environment = kDebugMode ? 'development' : 'production';
  },
  appRunner: () => runApp(
    ProviderScope(child: FoodyApp()),
  ),
);
```

**`.env` ergänzen:**
```
SENTRY_DSN=https://xxx@sentry.io/xxx
```

---

## 🎨 UI / Design

### Must-Have vor Release
- [ ] **App-Icon** – Konzept B „Fork & Leaf" empfohlen, alle Auflösungen via `flutter_launcher_icons`
- [x] **Splash Screen** – ✅ flutter_native_splash konfiguriert (Foody Grün #2E7D32)
- [x] **Onboarding-Flow** – ✅ 3 Screens (Willkommen, Scannen, Features) mit Skip + PageView
- [ ] **Empty State Illustrationen** – undraw.co Grafiken statt leerer Icons

### Nice-to-Have
- [ ] **Lottie-Animationen** – Leerer Kühlschrank, Erfolgs-Animation
- [x] **Konfetti** – ✅ Wenn alle Einkaufslisten-Items abgehakt 🎉
- [x] **Haptisches Feedback** – ✅ Scanner, Shopping, Portionen
- [x] **Hero-Animationen** – ✅ Produktbild fliegt auf Detailseite
- [x] **Skeleton-Loading** – ✅ Shimmer statt Spinner
- [x] **Sanfte Einblend-Animationen** – ✅ Items gleiten ein (TweenAnimationBuilder)
- [x] **Bottom Sheet Drag Handle** – ✅ Global aktiviert
- [x] **Dark Mode** – ✅ Verbessert
- [x] **Chip-Redesign Vorrat** – ✅ Kategorie-Chips mit Füllfarbe + Icon wenn aktiv
- [ ] **Adaptive Icons** – Android 13+ modernes Icon-Design
- [ ] **Wochenzusammenfassung (Push)** – Sonntags: „Du hast 4x gekocht, ~X€ gespart"

---

## 🔧 Technische Verbesserungen

### Dringend (vor Store-Release)
- [ ] **Groq-Proxy (Edge Function)** – API-Key nie im Client. Pflicht für Produktion!
- [ ] **Supabase RLS testen** – Kein User liest fremde Daten. Security Audit.
- [ ] **Fehler-Monitoring** – Sentry einbinden (kostenloser Tier reicht für Start)
- [ ] **API-Rate-Limiting** – Groq-Calls pro User drosseln (serverseitig via Proxy)
- [ ] **RevenueCat-Integration** – Phase 2: echte IAP für Android + iOS

### Wichtig
- [x] **Supabase Realtime** – ✅ Einkaufslisten-Sync für Haushaltsmitglieder (WebSocket live)
- [ ] **Offline-Caching** – Riverpod `keepAlive` + lokale Kopie (Hive/SQLite) für Kernfunktionen
- [ ] **CI/CD Pipeline** – GitHub Actions: Tests + Build bei jedem Push
- [ ] **Automatische Supabase-Backups** – Tägliche DB-Backups aktivieren

### Code-Qualität
- [ ] **Unit Tests** – InventoryRepositoryImpl, ShoppingListRepositoryImpl
- [ ] **Widget Tests** – InventoryScreen, ShoppingListScreen, ScannerScreen
- [ ] **Integration Tests** – Login → Scan → Vorrat → Rezept generieren
- [ ] **Performance** – `ListView.builder` überall prüfen
- [ ] **Deep Links** – `foody://recipe/123` oder `foody://inventory`
- [ ] **Accessibility** – Semantik-Labels, Mindestgröße 48×48px

---

## 🚀 Release-Vorbereitung

- [ ] **App-Icon** (alle Auflösungen Android + iOS)
- [ ] **Splash Screen** (flutter_native_splash)
- [ ] **Onboarding** (3 Screens, interaktiv)
- [ ] **Datenschutzerklärung** (DSGVO-konform, Abo-Daten + KI-Nutzung)
- [ ] **Nutzungsbedingungen** (AGB für Abo-Modell)
- [ ] **Impressum** (Pflicht für App-Store)
- [ ] **Play Store Listing** (Screenshots, Kurzbeschreibung, Keywords)
- [ ] **App Store Listing** (analog Play Store)
- [ ] **RevenueCat-Integration** (vor Store-Release zwingend)
- [ ] **Groq-Proxy** (vor Store-Release zwingend)

---

## 📊 Feature-Übersicht (Fortschritt)

| Bereich | Gesamt | Erledigt | Offen |
|---------|--------|----------|-------|
| 🐛 Bugs | 15 | 15 | 0 |
| 💰 Monetarisierung | 6 | 6 | 0 |
| ✨ Einkaufsliste | 14 | 12 | 2 |
| 🥕 Scanner & Vorrat | 14 | 13 | 1 |
| 🍳 Rezepte | 19 | 16 | 3 |
| 🏠 Haushalt | 6 | 3 | 3 |
| 📊 Nährwerte & Gesundheit | 8 | 7 | 1 |
| 📅 Wochenplaner | 7 | 7 | 0 |
| 🏠 Dashboard & Navigation | 4 | 4 | 0 |
| 🤝 Kooperationen | 8 | 0 | 8 |
| 🤖 KI-Erweiterungen | 9 | 7 | 2 |
| 🎨 UI/Design | 13 | 11 | 2 |
| 🔧 Technik | 12 | 0 | 12 |
| 🚀 Release | 10 | 0 | 10 |
| **Gesamt** | **145** | **101** | **44** |

---

## 📊 Feature-Status (Phasen)

| Feature | Status | Phase |
|---------|--------|-------|
| Authentifizierung | ✅ Fertig | 2 |
| Inventar-System | ✅ Fertig | 3 |
| Barcode-Scanner | ✅ Fertig | 4 |
| KI-Rezepte (Groq) | ✅ Fertig | 5 |
| Einkaufsliste | ✅ Fertig | 6 |
| Themes & Settings | ✅ Fertig | 7 |
| Kategorien & Tags | ✅ Fertig | 8 |
| Produkt-Detailseite | ✅ Fertig | 9 |
| Multi-Einkaufslisten | ✅ Fertig | 10 |
| Auto-Nachkauf | ✅ Fertig | 11 |
| Rezepte (Vollständig) | ✅ Fertig | 12 |
| Einkauf → Inventar | ✅ Fertig | 13 |
| Ablauf-Erinnerungen | ✅ Fertig | 14 |
| Barcode-History | ✅ Fertig | 15 |
| Geteilter Haushalt | ✅ Fertig | 16 |
| Kassenbon-Scanner | ✅ Fertig | 17 |
| Monetarisierung (Phase 1 lokal) | ✅ Fertig | 18 |
| Nährwert-Tracking | ✅ Fertig | 19 |
| Mahlzeiten-Wochenplaner | ✅ Fertig | 20 |
| Supermarkt-Kooperationen | ❌ Offen (Post-Launch) | 21 |
| KI-Chat-Assistent | ✅ Fertig | 22 |
| App-Icon / Splash | 🔄 Splash ✅, Icon ❌ | 23 |
| Onboarding | ✅ Fertig | 24 |
| RevenueCat (echte IAP) | ❌ **Blocker vor Launch** | 25 |
| Groq-Proxy (Edge Function) | ⚠️ Prüfen ob deployed | 26 |
| Offline-Modus | 🔄 Infrastruktur ✅, Sync ❌ | 27 |
| Community Wochenpläne | ✅ Fertig | 28 |
| KI-Rezept Cache-Fix | ✅ Fertig | 29 |
| Wochenplan → Community teilen | ✅ Fertig | 30 |
| Groq-Proxy Edge Function | ⚠️ Prüfen ob deployed | 31 |
| Offline-Modus Infrastruktur (Drift) | ✅ Fertig | 32 |
| RevenueCat In-App Purchases | ❌ **Blocker vor Launch** | 33 |
| Push Notifications (FCM) | ❌ Offen (wichtig vor Launch) | 34 |
| Sentry Crash-Monitoring | ❌ Offen (vor Launch) | 35 |
| App-Name Entscheidung | ❌ **Vor erstem Listing!** | 36 |
| App-Icon alle Auflösungen | ❌ **Blocker vor Launch** | 37 |
| Datenschutz/AGB/Impressum | ❌ **Blocker vor Launch** | 38 |
| RLS Security Audit | ❌ Offen (vor Launch) | 39 |
