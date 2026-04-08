# Offene Punkte - Foody App

Stand: 2026-04-02

## Erledigte Issues

### 1. ✅ KI-Generierung fuer Wochenplan - Diaetparameter
- [x] Dialog vor KI-Generierung mit 12 Praeferenzen (Vegan, Vegetarisch, High Protein, Low Carb, Zuckerarm, Glutenfrei, Laktosefrei, Pescetarisch, Keto, Kalorienarm, Fitness, Meal Prep)
- [x] `dietaryPreferences` Parameter an `generateMealPlan()` in `groq_proxy_service.dart`
- [x] Prompt im Groq-Service um Ernaehrungsform-Zeile erweitert

### 2. ✅ Wochenplan Rezept-Klick -> Popover statt Wegnavigation
- [x] `onTap` auf befuellte `_MealSlotCard` -> BottomSheet mit Rezept-Kurzinfo
- [x] Aktionen: "Details oeffnen", "Jetzt kochen", "Rezept aendern", "Entfernen"
- [x] User bleibt im Wochenplan

### 3. ✅ Vorrat Item-Klick -> Direkt Edit statt Detail-Screen
- [x] `onTap` oeffnet Edit-Sheet (AddInventoryItemSheet) direkt
- [x] Detail-Screen weiterhin erreichbar ueber Swipe

### 4. ✅ Non-Food Items im Inventar
- [x] Neue FoodCategory: haushalt (Haushalt & Reinigung)
- [x] Neue FoodCategory: hygiene (Hygiene & Pflege)
- [x] Neue FoodCategory: baby (Baby & Kind)
- [x] 25+ Keywords im fromOpenFoodFacts() Mapping ergaenzt

### 5. ✅ Notification Badge beim Avatar
- [x] Badge-Count aus pendingJoinRequestsProvider
- [x] Badge Widget auf CircleAvatar in AppBarMoreButton

### 6. ✅ Kueche Rezepte: Quick-Actions auf Karten
- [x] Kalender-Icon (Wochenplan hinzufuegen) auf jeder RecipeCard
- [x] Warenkorb-Icon (Einkaufsliste hinzufuegen) auf jeder RecipeCard
- [x] Tagesauswahl + Slot-Auswahl BottomSheet fuer Wochenplan

### 7. ✅ KI Rezepte klickbar
- [x] Verifiziert: onTap navigiert korrekt zu /kitchen/detail mit FoodRecipe
- [x] InkWell + onTap Callback korrekt implementiert

### 8. ✅ Rezept gekocht - Zutaten vom Vorrat entfernen
- [x] Dialog nach "Fertig!" im Cooking Mode
- [x] Zutaten-Checkliste (vorselektiert wenn im Vorrat via Fuzzy-Match)
- [x] Bestaetigte Zutaten werden vom Vorrat geloescht

### 9. ✅ FABs Jetzt kochen + Einkaufsliste als Icon-only
- [x] 3 FABs: Kochen (Play), Einkaufsliste (Warenkorb), Wochenplan (Kalender)
- [x] Column-Layout, FloatingActionButton + FloatingActionButton.small
- [x] Wochenplan-Dialog mit Tages-/Slot-Auswahl

### 10. ✅ Projektbeschreibung fuer Lovable
- [x] lovable_brief.md erstellt
- [x] Vollstaendige Feature-Uebersicht, Navigation, Design-System, Datenmodelle, Tech Stack
