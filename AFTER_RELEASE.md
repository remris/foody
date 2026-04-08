# 🚀 Foody – After Release Strategie

> Stand: April 2026  
> Dokument für: Vermarktung · Revenue · Nutzerdaten · Kooperationen · Wachstum

---

## 📋 Inhaltsverzeichnis

1. [Go-To-Market – Launch-Strategie](#1-go-to-market--launch-strategie)
2. [Marketing & Wachstum](#2-marketing--wachstum)
3. [Revenue-Strategie](#3-revenue-strategie)
4. [Nutzerdaten – Ethisch & Legal korrekt nutzen](#4-nutzerdaten--ethisch--legal-korrekt-nutzen)
5. [Supermarkt-Kooperationen](#5-supermarkt-kooperationen)
6. [Marken & Hersteller-Deals](#6-marken--hersteller-deals)
7. [KPIs & Metriken](#7-kpis--metriken)
8. [Roadmap Post-Launch](#8-roadmap-post-launch)

---

## 1. Go-To-Market – Launch-Strategie

### Phase 0 – Soft Launch (Woche 1–4)
> Ziel: Erstes Feedback ohne großen Mediendruck, Bugs finden, Onboarding optimieren.

- [ ] **Beta-Tester rekrutieren** – 50–100 Personen über persönliches Netzwerk, Reddit (r/kochen, r/mealprep), Discord-Kochgruppen
- [ ] **TestFlight (iOS) + offene Beta (Android)** – Links in einschlägigen Facebook-Gruppen (Meal Prep, Lebensmittelretten, Zero Waste)
- [ ] **Feedback-Kanal einrichten** – Discord-Server oder Telegram-Gruppe für Betatester, direktes Feedback schnell umsetzen
- [ ] **Crash-Monitoring aktivieren** – Sentry.io (kostenlos bis 5k Events/Monat), Firebase Crashlytics als Backup
- [ ] **Retention-Messung** – Day-1, Day-7, Day-30 Retention tracken (Firebase Analytics oder Mixpanel)

### Phase 1 – Public Launch (Woche 5–8)
> Ziel: Erste 1.000 Downloads, erste zahlende User, erste Community-Rezepte.

- [ ] **Play Store + App Store gleichzeitig** – Store-Listing optimiert (ASO), 5+ Screenshots, gutes Icon
- [ ] **Product Hunt Launch** – Dienstag oder Mittwoch, 6 Uhr morgens US-Zeit. Vorab: Hunter suchen (jemand mit Follower), Assets vorbereiten
- [ ] **Betapage / Indie Hackers** – Listing auf Betapage, Post auf Indie Hackers „My first launch"
- [ ] **Deutsche App-Blogs** – AndroidPIT, Caschys Blog, t3n (Pressemitteilung per E-Mail)
- [ ] **Reddit-Posts** – r/kochen, r/mealprep, r/de, r/lebensmittel – organisch, kein Spam, echten Mehrwert kommunizieren
- [ ] **Launch-Angebot** – Erste 500 Downloads: 3 Monate Pro kostenlos (Code im Post)

### Phase 2 – Wachstum (Monat 2–6)
> Ziel: 10.000 MAU, 5% Conversion Free → Pro, erste Kooperationen.

- [ ] **Content-Marketing starten** (siehe Abschnitt 2)
- [ ] **ASO kontinuierlich optimieren** – Keywords, Screenshot A/B-Tests, Bewertungen aktiv einfordern
- [ ] **Referral-Programm** – „Lade einen Freund ein → beide bekommen 1 Monat Pro gratis"
- [ ] **PR-Outreach** – CHIP, Computer Bild, Focus Online, ZDFheute (Lebensmittelverschwendung-Thema)

---

## 2. Marketing & Wachstum

### Content-Marketing (organisch, kostenlos)

#### TikTok / Instagram Reels – Hauptkanal
> Ziel: Food-Content mit App-Integration, virales Potential ist hier am höchsten.

**Content-Formate:**
| Format | Beschreibung | Posting-Frequenz |
|---|---|---|
| **„Was koche ich heute?"** | Vorrat zeigen → App macht Vorschlag → Rezept kochen | 3x/Woche |
| **„Reste-Retter"** | Alte Zutaten → KI-Rezept → überraschend gut | 2x/Woche |
| **„Wocheneinkauf unter 30€"** | Einkaufen → Vorrat einbuchen → Wochenplan | 1x/Woche |
| **„Vor vs. Nach Foody"** | Kühlschrank-Chaos → Übersicht → Weniger Lebensmittelmüll | 1x/Woche |
| **App-Features zeigen** | Screen-Recordings der coolsten Features | 1x/Woche |

**Hashtags:** #mealprep #kochen #lebensmittelretten #zerowaste #foodapp #küche #rezepte #foodwaste #gesundkochen #wocheneinkauf

**Tipp:** Keine perfekte Kameraqualität nötig – authentischer Alltagskontent funktioniert auf TikTok besser als hochproduzierter Content. Smartphone reicht.

#### YouTube (mittelfristig)
- Wöchentliche Meal-Prep-Videos mit Foody als Werkzeug
- „App erklärt in 5 Minuten" Tutorial
- „Mein Vorrat für einen Monat" – großes Format, gute SEO

#### Blog / SEO
- Zielseite: `foodyapp.de/blog`
- Themen: „Lebensmittelverschwendung reduzieren", „Meal Prep für Anfänger", „Gesund essen mit wenig Budget"
- Long-Tail-SEO: „Was kann ich mit Kartoffeln und Hackfleisch kochen?" → App als Antwort

### Paid Marketing (wenn Budget vorhanden)

| Kanal | Budget-Empfehlung | Ziel-CPI |
|---|---|---|
| **TikTok Ads** | 500–1.000 €/Monat | < 1,50 € |
| **Instagram / Meta** | 300–700 €/Monat | < 2,00 € |
| **Google UAC** | 300–500 €/Monat | < 2,50 € |
| **Apple Search Ads** | 200–400 €/Monat | < 3,00 € |

> **Empfehlung:** Erst organisch auf 2.000+ Downloads kommen, dann Paid skalieren. Paid ohne gutes Onboarding und Retention verbrennt Geld.

### Virales Wachstum (In-App)

| Feature | Viralitätsfaktor |
|---|---|
| **Haushalt teilen** | Jeder neue Mitbewohner bringt einen potenziellen neuen User |
| **Rezept teilen** | Share-Button → Link mit App-Download-Prompt |
| **Wochenplan teilen** | Screenshot mit Foody-Watermark → Social Media |
| **Referral-Code** | „Gib deinen Code weiter → beide bekommen Pro" |
| **Community-Rezepte** | User veröffentlichen → teilen auf Social Media → neuer Traffic |

### Community aufbauen

- [ ] **Discord-Server** „Foody Community" – Channels: #rezepte-teilen, #meal-prep, #feedback, #features
- [ ] **Reddit Community** r/foodyapp – eigenes Subreddit sobald 500+ User
- [ ] **In-App Challenges** – „KW15: Koche 5x mit Resten → Badge" – Gamification für Retention
- [ ] **Creator-Programm** – Top-Rezepteersteller bekommen Pro-Abo kostenlos + Badge → incentiviert hochwertige Inhalte

---

## 3. Revenue-Strategie

### 3.1 Abonnement (Haupt-Revenue)

#### Aktuelles Modell
| Plan | Preis | Features |
|---|---|---|
| **Free** | 0 € | Basis-Features, 5 KI-Rezepte/Woche, 2 Haushaltsmitglieder |
| **Pro Monatlich** | 2,99 €/Monat | Alles unlimitiert |
| **Pro Jährlich** | 19,99 €/Jahr | = 1,67 €/Monat, **44% günstiger** |

#### Conversion-Optimierung
- [ ] **Paywall-Trigger** optimieren – nicht sofort beim Start, sondern wenn User auf ein Pro-Feature trifft
- [ ] **Free Trial** einführen – 7 Tage Pro gratis, dann Kauf-Entscheidung (erhöht Conversion nachweislich um 30–50%)
- [ ] **Social Proof auf Paywall** – „127 Familien kochen bereits mit Pro"
- [ ] **Jährlich als Standard vorherchecken** – Jährlich als vorausgewählte Option zeigen (höherer ARPU)
- [ ] **Abo-Kündigung mit Retention-Offer** – Bei Kündigung: „Bleib für 1,49 €/Monat" Angebot

#### RevenueCat Integration (vor Store-Launch Pflicht)
```
purchases_flutter – Google Play Billing + Apple IAP in einem SDK
Webhook → Supabase: subscription_status automatisch aktualisieren
Offerings: Monthly, Annual, Trial
```

#### Langfristige Modell-Erweiterung (12+ Monate)
| Plan | Preis | Zielgruppe |
|---|---|---|
| **Free** | 0 € | Einzelpersonen, Studenten |
| **Pro** | 2,99 €/Monat | Einzelpersonen, Paare |
| **Familie** | 4,99 €/Monat | Familien (bis 6 Mitglieder, eigene Kinder-Profile) |
| **Creator** | 9,99 €/Monat | Food-Blogger, Recipe Creators (erweiterte Analytics, Branded Profile) |

#### Umsatz-Projektion (konservativ)
| Monat | MAU | Conversion | MRR |
|---|---|---|---|
| M3 | 500 | 3% | ~45 € |
| M6 | 2.000 | 4% | ~240 € |
| M12 | 10.000 | 5% | ~1.500 € |
| M18 | 30.000 | 6% | ~5.400 € |
| M24 | 80.000 | 7% | ~16.800 € |

> Realistisch wenn organisches Wachstum + eine virale Kampagne zusammenkommen.

### 3.2 Werbung (sekundär, optional)

> **Philosophie:** Keine klassischen Banner-Ads. Nur native, kontextrelevante Werbung die echten Mehrwert bietet.

| Format | Beschreibung | Einnahmen |
|---|---|---|
| **Sponsored Recipes** | Marke sponsert ein Rezept (z.B. Knorr: „Tortilla-Suppe mit Knorr Fix") – als „Gesponsert" markiert | CPC oder Flat Fee |
| **Angebots-Feed** | Supermarkt bezahlt für Platzierung seiner Wochenangebote in der App | CPM oder Flat Fee/Woche |
| **Sponsored Wochenplan** | Ernährungsberater / Fitness-Influencer bezahlt für Featured-Plan | Flat Fee |
| **In-App-Gutscheine** | Supermarkt gibt Coupon für bestimmte Produkte → User scannt Barcode → löst ein | Revenue-Share |

> **Wichtig:** Werbung erst ab 10.000 MAU einführen. Vorher stört es mehr als es bringt.

### 3.3 Daten & Aggregat-Insights (langfristig, opt-in)

> Vollständig anonymisiert, aggregiert, opt-in. Siehe Abschnitt 4 für Details.

| Produkt | Käufer | Wert |
|---|---|---|
| **Trend-Reports** | Lebensmittelhersteller, Marktforschung | Welche Zutaten werden aktuell viel eingekauft? |
| **Rezept-Trend-API** | Food-Blogs, Koch-Plattformen | Was kochen Deutsche gerade am liebsten? |
| **Allergen-Insight** | Hersteller, Einzelhandel | Wie viele User meiden Gluten/Laktose in welcher Region? |

> **Rechtlicher Rahmen:** Nur mit explizitem Opt-in, DSGVO-konform, keine personenbezogenen Daten.

### 3.4 B2B / White Label (sehr langfristig)

- **Unternehmens-Version** – Foody für Betriebskantinen, Schulen, Krankenhäuser (eigene Produktlisten, Budget-Tracking)
- **White Label** – Supermarktkette kauft Foody-Technologie als eigene App (z.B. „REWE Küchen-Assistent")
- **API-Zugang** – Drittentwickler können auf anonymisierte Rezept- und Trending-Daten zugreifen (Freemium API)

---

## 4. Nutzerdaten – Ethisch & Legal korrekt nutzen

> **Grundprinzip:** Nutzerdaten gehören dem User. Wir nutzen sie nur um das Produkt zu verbessern und mit explizitem Opt-in für Insights. DSGVO ist Pflicht, nicht Option.

### 4.1 Was wir sammeln (technisch notwendig)

| Datentyp | Zweck | Speicherort | Löschbar? |
|---|---|---|---|
| E-Mail-Adresse | Login, Passwort-Reset | Supabase Auth | ✅ Account löschen |
| Vorratsinhalte | App-Funktion | Supabase DB (user-owned) | ✅ |
| Einkaufslisten | App-Funktion | Supabase DB (user-owned) | ✅ |
| Gespeicherte Rezepte | App-Funktion | Supabase DB (user-owned) | ✅ |
| Wochenpläne | App-Funktion | Supabase DB (user-owned) | ✅ |
| Ernährungslog | Kalorien-Tracking | Supabase (opt-out möglich) | ✅ |
| Crash-Logs | Bug-Fixing | Sentry (anonymisiert) | Automatisch nach 90 Tagen |
| App-Nutzung (Events) | Produkt-Verbesserung | Firebase/Mixpanel | Aggregiert, kein PII |

### 4.2 Was wir NICHT sammeln / nicht tun

- ❌ Kein Verkauf von personenbezogenen Daten an Dritte
- ❌ Kein Tracking über App hinaus
- ❌ Kein Profilbuilding für Werbenetze (kein Meta Pixel, kein Google Ads Conversion-Tracking auf User-Ebene)
- ❌ Keine Weitergabe von Einkaufshistorie an Supermärkte ohne Opt-in
- ❌ Keine Kinder-Daten (unter 16 → Eltern-Consent nötig, wir erlauben es einfach erst ab 16)

### 4.3 Opt-in Analytics (für User die helfen wollen)

Beim Onboarding oder in den Settings: **„Möchtest du Foody verbessern helfen?"**

```
✅ Anonyme Nutzungsdaten teilen
   → Hilft uns zu verstehen welche Features beliebt sind.
   → Keine personenbezogenen Daten. Jederzeit deaktivierbar.
```

Was damit passiert:
- Welche Features werden genutzt (Screens, Button-Klicks)
- Welche Rezept-Kategorien sind populär
- Wo brechen User ab (Funnel-Analyse)
- Durchschnittliche Session-Dauer

### 4.4 Aggregierte Insights (anonymisiert, opt-in Basis)

> Nur wenn ausreichend Nutzerbasis (>5.000 opt-in User), vollständig anonymisiert, k-Anonymität ≥ 5.

**Interne Nutzung:**
- Welche Zutaten werden am häufigsten gescannt → Katalog verbessern
- Welche KI-Rezepte werden am meisten gespeichert → Prompt-Verbesserung
- Wann brechen User den Kauf ab → Paywall optimieren

**Externe Nutzung (B2B, aggregiert, opt-in):**
| Insight | Potentieller Käufer | Beispiel |
|---|---|---|
| „Top 10 gekaufte Zutaten diese Woche, Region Bayern" | Großhändler, Einzelhandel | Saisonale Bestellplanung |
| „Beliebteste Diäten nach PLZ" | Lebensmittelhersteller | Produktentwicklung Vegan/Laktosefrei |
| „Durchschnittlicher Einkaufswert nach Haushaltsgröße" | Marktforschung | Konsumtrends |

**Rechtlicher Rahmen für B2B-Daten:**
1. Explizites Opt-in im Onboarding mit klarer Erklärung
2. Datenschutzfolgenabschätzung (DSFA) durchführen
3. Auftragsverarbeitungsvertrag (AVV) mit jedem B2B-Abnehmer
4. Anonymisierung verifizieren (Differential Privacy oder k-Anonymität)
5. User kann Opt-in jederzeit widerrufen

### 4.5 Datenschutz-Maßnahmen (technisch)

- [ ] **Account löschen** – Button in Settings → alle Daten in Supabase gelöscht (DSGVO Art. 17)
- [ ] **Daten exportieren** – „Meine Daten herunterladen" als JSON-Export (DSGVO Art. 20)
- [ ] **Datenschutzerklärung** – Klar, verständlich, auf Deutsch. Link im App-Store + in der App
- [ ] **Cookie/Tracking-Consent** – Beim ersten Start für Analytics (nicht für App-Funktion)
- [ ] **Supabase EU-Region** – Daten in Frankfurt (eu-central-1) ← bereits sichergestellt wenn EU-Region gewählt
- [ ] **Passwort-Hashing** – Supabase Auth macht das automatisch (bcrypt)
- [ ] **RLS überall** – Kein User sieht fremde Daten (Security Audit vor Launch!)

---

## 5. Supermarkt-Kooperationen

### 5.1 Strategie – Drei-Stufen-Modell

```
Stufe 1: Inoffiziell / Scraping   → Proof of Concept, keine Einnahmen, kein Risiko
Stufe 2: Affiliate / API           → Erste Einnahmen, keine echte Kooperation nötig
Stufe 3: Offizielle Partnerschaft  → Große Einnahmen, gemeinsames Marketing
```

### 5.2 Stufe 1 – Sofort umsetzbar (ohne Kooperation)

**Inoffizielle APIs (rechtliche Grauzone – nur intern nutzen, nicht öffentlich bewerben):**

| Supermarkt | Inoffizielle Datenquelle | Was verfügbar |
|---|---|---|
| **REWE** | `rewe.de` API (Web-Scraping oder inoffizielle Docs) | Wochenangebote, Preise, Produkte |
| **Edeka** | `edeka.de/angebote` | Angebote nach PLZ |
| **Lidl** | `kaufda.de` / `marktspiegel.de` | Prospekte als PDF/JSON |
| **Aldi** | `aldi-sued.de/angebote` | Wöchentliche Angebote |
| **Penny** | `penny.de/angebote` | Angebote |

> **Empfehlung:** Eigenen Scraper-Microservice auf kleinem VPS (5 €/Monat) hosten.
> Daten in Supabase cachen, täglich aktualisieren. Falls Supermarkt protestiert → sofort abschalten.

**Was damit in der App möglich ist:**
- „Diese Woche im Angebot" Sektion im Einkauf-Tab
- „Aus Angeboten kochen" → KI generiert Rezept mit aktuellen Angebotsprodukten
- Push: „Hühnerbrust heute 30% günstiger bei REWE – Rezept gefällig?"

### 5.3 Stufe 2 – Affiliate ohne Kooperation

**Kaufda / Marktjagd / smhaggle Affiliate:**
- Diese Plattformen aggregieren Supermarkt-Prospekte und haben offizielle APIs + Affiliate-Programme
- Integration in Foody: Angebot anklicken → Weiterleitung zu Kaufda → Provision

**Amazon Fresh / Picnic Affiliate:**
- Zutaten aus Rezept/Wochenplan → „Online bestellen bei Amazon Fresh" Button
- Amazon Affiliate: 1–4% auf jeden Einkauf
- Picnic: Anfragen ob Kooperation möglich (junges Unternehmen, kooperationsbereit)

### 5.4 Stufe 3 – Offizielle Partnerschaft (ab 10.000 MAU sinnvoll)

#### Erstansprache – Wen kontaktieren?

| Supermarkt | Richtiger Ansprechpartner | Kontaktweg |
|---|---|---|
| **REWE** | Digital-Abteilung / Partnership Manager | partnerships@rewe-group.com oder LinkedIn |
| **Edeka** | Marketing / Digital Innovation | Über EDEKA-Zentrale Hamburg, LinkedIn |
| **Kaufland** | Digital Marketing | Über Karriere/Presse-Kontakte auf kaufland.de |
| **Lidl** | E-Commerce / App-Abteilung | Über corporate.lidl.de Kontaktformular |
| **Netto/Penny** | Kleiner, zugänglicher → gut für erste Partnerschaft | Direkt an Marketing-Leiter |

#### Was wir ihnen bieten (Value Proposition)

```
🎯 Wir bringen Rezept-Inspiration direkt zur Einkaufsentscheidung.

User sieht: Hühnenbrust im Angebot → App schlägt Rezept vor →
User kauft Hühnenbrust + alle Zutaten → Umsatz für Supermarkt steigt.

Messbar über: Coupon-Codes, QR-Codes in der App die beim Einkauf gescannt werden.
```

**Konkrete Kooperationsmodelle:**

| Modell | Was Supermarkt bekommt | Was wir bekommen |
|---|---|---|
| **CPC (Cost per Click)** | Klicks auf ihre Angebote | 0,05–0,20 € pro Klick |
| **CPA (Cost per Action)** | Nachgewiesene Käufe über Coupon | 0,50–2,00 € pro Kauf |
| **Flat Fee Placement** | Wochenlanges Feature ihrer Angebote | 500–5.000 €/Monat |
| **Data Partnership** | Anonymisierte Einblicke in Kochtrends | Monatliche Zahlungen |
| **Co-Marketing** | Foody wird in Supermarkt-App/Newsletter erwähnt | Reichweite + Geld |

#### Pitch-Deck Inhalte (für Investor- oder Kooperationsgespräche)

1. **Problem:** 12 Mio. Tonnen Lebensmittel werden jährlich in Deutschland weggeworfen
2. **Lösung:** Foody verbindet Vorrat, Rezepte und Einkauf intelligent
3. **Markt:** 40M Haushalte in Deutschland, jeder kauft ~150€/Woche ein
4. **Traction:** X Downloads, Y MAU, Z Rezepte erstellt (echte Zahlen einfügen)
5. **Kooperationsmodell:** Wie der Supermarkt profitiert
6. **Nächste Schritte:** Pilotprogramm, 3 Monate, messbare KPIs

### 5.5 Technische Implementierung der Kooperation

```dart
// Beispiel: Angebots-Integration in die App

// 1. Supermarkt-Angebote aus Cache laden
final offersProvider = FutureProvider<List<SupermarketOffer>>((ref) async {
  return ref.read(offersRepositoryProvider).fetchCurrentOffers(
    supermarket: userPreferredSupermarket,
    postalCode: userPostalCode,
  );
});

// 2. KI-Rezept aus Angeboten generieren
// Prompt: "Generiere ein Rezept mit diesen Angebotsprodukten: {offers}"

// 3. Tracking für Kooperationsabrechnung
// Jeder Klick auf ein Angebot → Event in Analytics + Supabase
```

---

## 6. Marken & Hersteller-Deals

### 6.1 Sponsored Recipes

**Konzept:** Marke bezahlt dafür dass ihr Produkt in einem Rezept als Markennamen erscheint.

```
Beispiel: Knorr bezahlt für 5 Rezepte in denen "Knorr Fix für Tortilla" als Zutat gelistet ist.
         → Rezept erscheint oben in der KI-Suche wenn "mexikanisch" gesucht wird.
         → Klar als "Gesponsert" gekennzeichnet.
```

**Preisgestaltung:**
- Einmalige Rezept-Platzierung: 200–500 €
- Monatliches Featured-Paket (10 Rezepte): 1.000–3.000 €
- Jahres-Deal mit Analytics-Report: 10.000–30.000 €

**Ansprechpartner:**
- Dr. Oetker → Marketing-Abteilung, Bielefeld
- Knorr (Unilever) → Brand Marketing Germany
- Maggi (Nestlé) → Digital Marketing
- Bonduelle, Iglo, Birds Eye → Convenience/TK-Hersteller

### 6.2 Branded Content / Promotions

| Format | Beschreibung | Preis |
|---|---|---|
| **Wochenplan-Sponsoring** | „Diese Woche: Low-Carb Woche mit [Marke X]" | 500–2.000 €/Woche |
| **KI-Rezept-Bundle** | Marke kauft 50 KI-generierte Rezepte mit ihren Produkten | 2.000–5.000 € |
| **Push-Notification** | Einmalige thematische Push an alle User | 500–1.500 € |
| **In-App Banner** | Native Banner auf Startseite (kein klassischer Ad) | CPM-basiert |

---

## 7. KPIs & Metriken

### App-Health

| Metrik | Ziel M6 | Ziel M12 | Ziel M24 |
|---|---|---|---|
| **DAU/MAU Ratio** | > 20% | > 25% | > 30% |
| **Day-1 Retention** | > 40% | > 50% | > 55% |
| **Day-7 Retention** | > 20% | > 25% | > 30% |
| **Day-30 Retention** | > 10% | > 15% | > 20% |
| **Session-Dauer** | > 3 Min. | > 4 Min. | > 5 Min. |
| **Sessions/Tag** | > 1,2 | > 1,5 | > 2,0 |

### Revenue

| Metrik | Ziel M6 | Ziel M12 | Ziel M24 |
|---|---|---|---|
| **MAU** | 2.000 | 10.000 | 80.000 |
| **Paying Users** | 80 | 500 | 5.600 |
| **MRR** | 240 € | 1.500 € | 16.800 € |
| **ARR** | 2.900 € | 18.000 € | 201.600 € |
| **ARPU** | 3 € | 3 € | 3 € |
| **LTV (12 Mon.)** | ~24 € | ~30 € | ~36 € |
| **CAC** | < 5 € | < 8 € | < 10 € |

### Community & Viral

| Metrik | Ziel M6 | Ziel M12 |
|---|---|---|
| **Geteilte Rezepte** | 500 | 5.000 |
| **Community-Rezepte** | 200 | 2.000 |
| **Referral-Rate** | > 5% | > 10% |
| **App-Store Rating** | > 4,2 ⭐ | > 4,5 ⭐ |
| **Rezensionen** | 50 | 500 |

---

## 8. Roadmap Post-Launch

### Q2 2026 (Launch + erste Monate)
- [ ] RevenueCat Integration abschließen
- [ ] Groq API Proxy via Supabase Edge Function (Security)
- [ ] Sentry Crash-Monitoring einbinden
- [ ] Push-Notifications (Firebase Cloud Messaging)
- [ ] Referral-Programm implementieren
- [ ] Supermarkt-Angebote (inoffiziell/Scraping) als Proof of Concept
- [ ] Product Hunt Launch
- [ ] Erste TikTok-Videos

### Q3 2026
- [ ] Affiliate-Integration (Amazon Fresh, Kaufda)
- [ ] Creator-Programm starten (Top-User bekommen Pro kostenlos)
- [ ] Analytics Dashboard für eigene Auswertung (Mixpanel/Firebase)
- [ ] A/B-Testing Paywall
- [ ] Erste Gespräche mit Supermarkt-Marketing-Abteilungen
- [ ] iOS-Launch (falls noch nicht passiert)
- [ ] App-Store Optimierung (ASO) iterieren

### Q4 2026
- [ ] Erste bezahlte Supermarkt-Kooperation (Pilot, 1 Monat)
- [ ] Sponsored Recipes Feature live
- [ ] B2B-Insights Produkt konzipieren
- [ ] Familien-Abo einführen
- [ ] Influencer-Kooperationen (Food-Creator, 50k–500k Follower)
- [ ] Web-App (Flutter Web) für Desktop-Nutzung

### Q1 2027
- [ ] Offizielle Supermarkt-Partnerschaft (Ziel: 1 großer Partner)
- [ ] RevenueCat Webhooks → automatische Subscription-Verwaltung
- [ ] B2B Insights Pilot mit erstem Lebensmittelhersteller
- [ ] Internationalisierung (Österreich, Schweiz – gleiches DACH-Sprachraum)
- [ ] Apple Watch / Widget Integration

---

## 📎 Anhang

### Wichtige rechtliche Checkliste vor Revenue-Start

- [ ] **Impressum** in der App + auf Website (§5 TMG)
- [ ] **Datenschutzerklärung** DSGVO-konform (Pflicht bei Account-Registrierung)
- [ ] **AGB** für Abo-Modell (Widerrufsrecht, Laufzeiten, Kündigung)
- [ ] **In-App-Kauf Compliance** – Apple: 30% Gebühr auf Abo. Google: 15% nach 1 Jahr. Kein externer Checkout über App erlaubt (außer Web)
- [ ] **DSGVO Art. 13** – User beim Signup informieren was mit Daten passiert
- [ ] **Cookie-Consent** für Web-Version
- [ ] **Steuer** – Umsatzsteuer auf digitale Produkte (19% DE), OSS-Verfahren für EU-weite Abos
- [ ] **Affiliate-Kennzeichnung** – Affiliate-Links als „Werbung" kennzeichnen

### Nützliche Tools & Services

| Tool | Zweck | Kosten |
|---|---|---|
| **RevenueCat** | In-App Purchases | Kostenlos bis 2.500 $/Monat MTR |
| **Sentry** | Crash-Monitoring | Kostenlos bis 5k Events |
| **Mixpanel** | Analytics | Kostenlos bis 20M Events |
| **Firebase** | Analytics, Push, Crashlytics | Kostenlos (großzügig) |
| **AppFollow** | App-Store Reviews, ASO | ~30 €/Monat |
| **Adjust / AppsFlyer** | Mobile Attribution | Ab 0 € (Freemium) |
| **Webflow / Next.js** | Marketing-Website | Variabel |
| **Stripe** | Web-Zahlungen (falls Web-App) | 1,5% + 0,25 € pro Transaktion EU |
| **PostHog** | Open-Source Analytics, selbst gehostet | Kostenlos |

### Kontakte für Kooperationen (Recherche-Startpunkte)

| Organisation | LinkedIn-Suche | E-Mail-Pattern |
|---|---|---|
| REWE Group | „REWE Digital Partnership" | vorname.nachname@rewe-group.com |
| EDEKA Zentrale | „EDEKA Digital Marketing" | info@edeka.de (dann weiterleiten lassen) |
| Unilever DACH | „Unilever Brand Manager Germany" | vorname.nachname@unilever.com |
| Nestlé Deutschland | „Nestlé Digital Marketing DE" | – (über Website) |
| Picnic | „Picnic Partnership" | partnerships@picnic.app |

---

*Dieses Dokument ist ein lebendiges Strategiepapier – regelmäßig aktualisieren wenn sich Zahlen, Partner oder Pläne ändern.*

1. 🚀 Go-To-Market
   Phase 0 (Soft Launch): Beta über Reddit/Discord, Sentry, Crash-Monitoring
   Phase 1 (Public Launch): Product Hunt, deutsche App-Blogs, Reddit, Launch-Angebot 3 Monate Pro gratis für erste 500 User
   Phase 2 (Wachstum): ASO, Referral-Programm, PR-Outreach
2. 📱 Marketing & Wachstum
   TikTok/Reels als Hauptkanal – konkrete Content-Formate, Posting-Frequenz, Hashtags
   Paid-Marketing mit Budget-Empfehlungen und Ziel-CPI pro Kanal
   Virale In-App-Features (Teilen, Referral, Community)
   Creator-Programm für Top-Rezepte-Ersteller
3. 💰 Revenue-Strategie
   Abo-Modell mit Conversion-Tricks (Free Trial, Jährlich vorauswählen, Retention-Offer bei Kündigung)
   Umsatz-Projektion bis Monat 24 (konservativ: ~16.800 € MRR)
   Langfristig: Familien-Abo, Creator-Abo, B2B White Label
4. 🔒 Nutzerdaten (DSGVO-konform)
   Was gesammelt werden darf, was nicht
   Opt-in Analytics mit klarer Erklärung
   Aggregierte B2B-Insights (anonymisiert) als Einnahmequelle
   Rechtliche Checkliste: Account löschen, Daten exportieren, EU-Region
5. 🏪 Supermarkt-Kooperationen
   3-Stufen-Modell: Scraping → Affiliate → offizielle Partnerschaft
   Konkrete inoffizielle APIs für REWE, Edeka, Lidl, Aldi
   Pitch-Deck Inhalte + Kooperationsmodelle mit konkreten Preisen
   Wen kontaktieren (LinkedIn-Suchbegriffe, E-Mail-Patterns)
6. 🏷️ Marken-Deals
   Sponsored Recipes (Knorr, Dr. Oetker, Maggi)
   Preise: 200–30.000 € je nach Format
7. 📊 KPIs & Metriken
   Retention-Ziele, Revenue-Ziele, Community-Metriken
8. 🗓️ Roadmap Q2 2026 – Q1 2027