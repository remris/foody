# Feature-Requests: Dashboard, Ernährung & KI-Wochenplan

## Verbesserungen

- [x] 1. **Fehlende-Zutaten-Filter** – Im Zutaten-einkaufen-Dialog ein Toggle „Alle / Fehlende" ergänzen; Inventar-Abgleich zeigt nur fehlende Zutaten
- [x] 2. **Einkaufsliste komplett leeren** – Im Drei-Punkte-Menü „Alle Artikel löschen" mit Bestätigungs-Dialog
- [x] 3. **Statistiken-Flow reparieren** – `logCompletedShop()` beim Abschluss aufrufen, Stats-Provider invalidieren
- [x] 4. **„Jetzt kochen" direkt im Dashboard** – Button navigiert zu CookingModeScreen statt nur Rezept anzeigen
- [x] 5. **Fertig-Abhaken + Ernährungsübernahme** – Nach dem Kochen `logMeal()` aufrufen; abgehakte Einträge im Dashboard grün markieren
- [x] 6. **Gewichtsverlaufs-Chart (nur Pro)** – WeightLogNotifier mit Linien-Chart, Gewicht-eintragen-Dialog, nur für Pro-User
- [x] 7. **Kaloriendefizit & Ernährungsziel beim KI-Wochenplan** – Textfeld für kcal-Defizit, Chips für High Protein/Low Carb/Kein Zucker, Rezepte ohne Nährwerte ausschließen bei aktivem Filter
- [x] 8. **Ernährungsfilter in Entdecken** – Gleiche Chips im Community-Filter, Rezepte ohne Nährwerte bei Filter ausschließen
- [x] 9. **feature-request.md** – Dokumentation aller Punkte ✅

## Weitere Überlegungen
- Statistiken langfristig in Supabase speichern (aktuell SharedPreferences)
- fl_chart wird für Gewichtsverlauf benötigt → in pubspec.yaml ergänzen
- Gewichtsverlauf nur für Pro-User sichtbar
- Rezepte ohne Nährwerte bei aktiven Ernährungsfiltern ausschließen

