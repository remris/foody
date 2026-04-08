-- ============================================================
-- FOODY – Testdaten / Seed-Script
-- ============================================================
-- Erstellt 3 Dummy-User mit realistischen Haushalten,
-- Vorräten, Einkaufslisten, gespeicherten Rezepten,
-- Wochenplänen und Community-Inhalten.
--
-- ⚠️  WICHTIG: Diese Funktion nutzt auth.users direkt.
--     Führe es im Supabase SQL Editor aus.
--     Die User werden NICHT in Supabase Auth registriert
--     (kein Login möglich) – sie dienen nur als Seed-Daten
--     für Community-Content, den echte User sehen.
--
--     Für eigene Testdaten: Nutze den "Testdaten generieren"
--     Button in den App-Einstellungen.
-- ============================================================

-- ── Hilfsfunktion: Zufälligen UUID erzeugen ────────────────
-- (gen_random_uuid() ist bereits in Postgres 13+ verfügbar)

DO $$
DECLARE
  -- Seed-User IDs (feste UUIDs für Reproduzierbarkeit)
  uid_anna    UUID := 'aaaaaaaa-0001-0001-0001-000000000001';
  uid_ben     UUID := 'bbbbbbbb-0002-0002-0002-000000000002';
  uid_clara   UUID := 'cccccccc-0003-0003-0003-000000000003';

  -- Haushalt IDs
  hh_anna     UUID := 'dddddddd-0001-0001-0001-000000000001';
  hh_shared   UUID := 'eeeeeeee-0002-0002-0002-000000000002';

  -- Shopping List IDs
  sl_anna1    UUID := gen_random_uuid();
  sl_anna2    UUID := gen_random_uuid();
  sl_ben1     UUID := gen_random_uuid();

  -- Meal Plan Template IDs
  mp_week1    DATE := date_trunc('week', current_date)::date;
  mp_week2    DATE := (date_trunc('week', current_date) + interval '7 days')::date;

  -- Community Recipe IDs
  cr1         UUID := gen_random_uuid();
  cr2         UUID := gen_random_uuid();
  cr3         UUID := gen_random_uuid();
  cr4         UUID := gen_random_uuid();
  cr5         UUID := gen_random_uuid();

  -- Community Meal Plan IDs
  cmp1        UUID := gen_random_uuid();
  cmp2        UUID := gen_random_uuid();

BEGIN

  -- ══════════════════════════════════════════════════════════
  -- 1. DUMMY-USER in auth.users eintragen
  --    (Nur für Seed-Zwecke – kein echter Auth-User)
  -- ══════════════════════════════════════════════════════════
  INSERT INTO auth.users (
    id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at,
    raw_user_meta_data, raw_app_meta_data,
    is_super_admin, confirmation_token, recovery_token,
    email_change_token_new, email_change
  )
  VALUES
    (
      uid_anna, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'anna@foody-demo.de', crypt('DemoPasswort123!', gen_salt('bf')),
      now(), now(), now(),
      '{"name":"Anna Müller"}'::jsonb, '{"provider":"email","providers":["email"]}'::jsonb,
      false, '', '', '', ''
    ),
    (
      uid_ben, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'ben@foody-demo.de', crypt('DemoPasswort123!', gen_salt('bf')),
      now(), now(), now(),
      '{"name":"Ben Schmidt"}'::jsonb, '{"provider":"email","providers":["email"]}'::jsonb,
      false, '', '', '', ''
    ),
    (
      uid_clara, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'clara@foody-demo.de', crypt('DemoPasswort123!', gen_salt('bf')),
      now(), now(), now(),
      '{"name":"Clara Weber"}'::jsonb, '{"provider":"email","providers":["email"]}'::jsonb,
      false, '', '', '', ''
    )
  ON CONFLICT (id) DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 2. HAUSHALTE
  -- ══════════════════════════════════════════════════════════
  INSERT INTO households (id, name, created_by, invite_code, created_at)
  VALUES
    (hh_anna,   'Familie Müller',  uid_anna,  'ANNA01', now() - interval '30 days'),
    (hh_shared, 'WG Schillerstr.', uid_ben,   'BEN001', now() - interval '20 days')
  ON CONFLICT (id) DO NOTHING;

  -- Mitglieder in Haushalte eintragen
  INSERT INTO household_members (household_id, user_id, role, display_name, joined_at)
  VALUES
    -- Familie Müller: Anna (Admin) + Clara
    (hh_anna,   uid_anna,  'admin',  'Anna',  now() - interval '30 days'),
    (hh_anna,   uid_clara, 'member', 'Clara', now() - interval '25 days'),
    -- WG Schillerstr.: Ben (Admin) + Clara
    (hh_shared, uid_ben,   'admin',  'Ben',   now() - interval '20 days'),
    (hh_shared, uid_clara, 'member', 'Clara', now() - interval '18 days')
  ON CONFLICT (household_id, user_id) DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 3. VORRAT (user_inventory) für Anna
  -- ══════════════════════════════════════════════════════════
  INSERT INTO user_inventory (user_id, ingredient_id, ingredient_name, ingredient_category, quantity, unit, expiry_date, min_threshold, tags)
  VALUES
    -- Kühlschrank
    (uid_anna, 'milk',         'Vollmilch',           'Milchprodukte',      2,    'l',      now() + interval '5 days',  1,   '{Kühlschrank}'),
    (uid_anna, 'butter',       'Butter',              'Milchprodukte',      250,  'g',      now() + interval '14 days', 100, '{Kühlschrank}'),
    (uid_anna, 'eggs',         'Eier',                'Milchprodukte',      6,    'Stück',  now() + interval '10 days', 3,   '{Kühlschrank}'),
    (uid_anna, 'yoghurt',      'Naturjoghurt',        'Milchprodukte',      400,  'g',      now() + interval '3 days',  0,   '{Kühlschrank}'),
    (uid_anna, 'cheese',       'Gouda',               'Milchprodukte',      300,  'g',      now() + interval '21 days', 0,   '{Kühlschrank}'),
    (uid_anna, 'chicken',      'Hähnchenbrust',       'Fleisch & Fisch',    500,  'g',      now() + interval '2 days',  0,   '{Kühlschrank,Bald ablaufend}'),
    (uid_anna, 'carrots',      'Karotten',            'Gemüse',             500,  'g',      now() + interval '14 days', 0,   '{Kühlschrank}'),
    (uid_anna, 'broccoli',     'Brokkoli',            'Gemüse',             400,  'g',      now() + interval '4 days',  0,   '{Kühlschrank}'),
    (uid_anna, 'lemons',       'Zitronen',            'Obst',               3,    'Stück',  now() + interval '14 days', 0,   '{Kühlschrank}'),
    -- Tiefkühl
    (uid_anna, 'frozen_peas',  'Erbsen TK',           'Tiefkühl',           500,  'g',      now() + interval '90 days', 0,   '{Tiefkühl}'),
    (uid_anna, 'frozen_pizza', 'Pizza Margherita TK', 'Tiefkühl',           1,    'Stück',  now() + interval '60 days', 0,   '{Tiefkühl}'),
    -- Vorratskammer
    (uid_anna, 'pasta',        'Spaghetti',           'Getreide & Nudeln',  500,  'g',      now() + interval '365 days',200, '{Vorratskammer}'),
    (uid_anna, 'rice',         'Basmati Reis',        'Getreide & Nudeln',  1000, 'g',      now() + interval '365 days',300, '{Vorratskammer}'),
    (uid_anna, 'flour',        'Weizenmehl Type 405', 'Getreide & Nudeln',  1000, 'g',      now() + interval '365 days',250, '{Vorratskammer}'),
    (uid_anna, 'olive_oil',    'Olivenöl',            'Öle & Soßen',        500,  'ml',     now() + interval '365 days',100, '{Vorratskammer}'),
    (uid_anna, 'canned_toms',  'Tomaten (Dose)',       'Konserven',          400,  'g',      now() + interval '365 days',0,   '{Vorratskammer}'),
    (uid_anna, 'onions',       'Zwiebeln',            'Gemüse',             1000, 'g',      now() + interval '30 days', 0,   '{Vorratskammer}'),
    (uid_anna, 'garlic',       'Knoblauch',           'Gewürze & Kräuter',  3,    'Zehen',  now() + interval '30 days', 0,   '{Vorratskammer}'),
    (uid_anna, 'salt',         'Meersalz',            'Gewürze & Kräuter',  500,  'g',      null,                       0,   '{Vorratskammer}'),
    (uid_anna, 'pepper',       'Schwarzer Pfeffer',   'Gewürze & Kräuter',  50,   'g',      null,                       0,   '{Vorratskammer}'),
    (uid_anna, 'sugar',        'Zucker',              'Süßigkeiten',        500,  'g',      now() + interval '365 days',0,   '{Vorratskammer}'),
    (uid_anna, 'honey',        'Blütenhonig',         'Süßigkeiten',        250,  'g',      now() + interval '365 days',0,   '{Vorratskammer}'),
    (uid_anna, 'bread',        'Vollkornbrot',        'Backwaren',          500,  'g',      now() + interval '5 days',  0,   NULL),
    (uid_anna, 'potatoes',     'Kartoffeln',          'Gemüse',             2000, 'g',      now() + interval '20 days', 500, '{Vorratskammer}'),
    (uid_anna, 'tomatoes',     'Rispentomaten',       'Gemüse',             500,  'g',      now() + interval '5 days',  0,   NULL),
    (uid_anna, 'cucumber',     'Salatgurke',          'Gemüse',             1,    'Stück',  now() + interval '7 days',  0,   '{Kühlschrank}'),
    (uid_anna, 'spinach',      'Babyspinat',          'Gemüse',             200,  'g',      now() + interval '3 days',  0,   '{Kühlschrank}'),
    (uid_anna, 'apple',        'Äpfel',               'Obst',               6,    'Stück',  now() + interval '14 days', 0,   NULL),
    (uid_anna, 'banana',       'Bananen',             'Obst',               5,    'Stück',  now() + interval '5 days',  0,   NULL),
    (uid_anna, 'lentils',      'Rote Linsen',         'Getreide & Nudeln',  500,  'g',      now() + interval '365 days',0,   '{Vorratskammer}'),
    (uid_anna, 'chickpeas',    'Kichererbsen (Dose)', 'Konserven',          400,  'g',      now() + interval '365 days',0,   '{Vorratskammer}'),
    (uid_anna, 'coconut_milk', 'Kokosmilch (Dose)',   'Konserven',          400,  'ml',     now() + interval '365 days',0,   '{Vorratskammer}')
  ON CONFLICT DO NOTHING;

  -- Vorrat für Ben (WG)
  INSERT INTO user_inventory (user_id, ingredient_id, ingredient_name, ingredient_category, quantity, unit, expiry_date, min_threshold)
  VALUES
    (uid_ben, 'pasta',      'Penne',          'Getreide & Nudeln', 500,  'g',  now() + interval '365 days', 0),
    (uid_ben, 'eggs',       'Eier',           'Milchprodukte',     12,   'Stück', now() + interval '14 days', 4),
    (uid_ben, 'milk',       'Hafermilch',     'Getränke',          1,    'l',  now() + interval '10 days',  0),
    (uid_ben, 'bread',      'Toastbrot',      'Backwaren',         500,  'g',  now() + interval '4 days',   0),
    (uid_ben, 'ham',        'Kochschinken',   'Fleisch & Fisch',   200,  'g',  now() + interval '3 days',   0),
    (uid_ben, 'cheese2',    'Mozzarella',     'Milchprodukte',     125,  'g',  now() + interval '5 days',   0),
    (uid_ben, 'olive_oil2', 'Olivenöl',       'Öle & Soßen',       250,  'ml', now() + interval '365 days', 0),
    (uid_ben, 'rice2',      'Jasminreis',     'Getreide & Nudeln', 500,  'g',  now() + interval '365 days', 0),
    (uid_ben, 'soy_sauce',  'Sojasoße',       'Öle & Soßen',       150,  'ml', now() + interval '365 days', 0),
    (uid_ben, 'ginger',     'Ingwer',         'Gewürze & Kräuter', 100,  'g',  now() + interval '14 days',  0)
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 4. EINKAUFSLISTEN
  -- ══════════════════════════════════════════════════════════
  INSERT INTO shopping_lists (id, user_id, name, icon, created_at)
  VALUES
    (sl_anna1, uid_anna, 'Wocheneinkauf Rewe',    'shopping_cart',   now() - interval '2 days'),
    (sl_anna2, uid_anna, 'Drogerie',              'local_pharmacy',  now() - interval '1 day'),
    (sl_ben1,  uid_ben,  'WG Einkauf Kaufland',   'store',           now() - interval '3 days')
  ON CONFLICT (id) DO NOTHING;

  -- Einkaufslisten-Items für Anna (Wocheneinkauf)
  INSERT INTO shopping_list_items (list_id, user_id, name, quantity, is_checked, sort_order)
  VALUES
    (sl_anna1, uid_anna, 'Hähnchenbrust',        '600g',    false, 1),
    (sl_anna1, uid_anna, 'Lachsfilet',           '400g',    false, 2),
    (sl_anna1, uid_anna, 'Brokkoli',             '1 Kopf',  false, 3),
    (sl_anna1, uid_anna, 'Paprika (rot)',         '3 Stück', false, 4),
    (sl_anna1, uid_anna, 'Zucchini',             '2 Stück', false, 5),
    (sl_anna1, uid_anna, 'Vollmilch',            '2l',      true,  6),
    (sl_anna1, uid_anna, 'Griechischer Joghurt', '400g',    true,  7),
    (sl_anna1, uid_anna, 'Eier (10er)',          '1 Pack',  false, 8),
    (sl_anna1, uid_anna, 'Parmesan',             '100g',    false, 9),
    (sl_anna1, uid_anna, 'Ciabatta',             '1 Stück', false, 10),
    (sl_anna1, uid_anna, 'Kirschtomaten',        '250g',    false, 11),
    (sl_anna1, uid_anna, 'Avocado',              '2 Stück', false, 12)
  ON CONFLICT DO NOTHING;

  -- Drogerie-Liste
  INSERT INTO shopping_list_items (list_id, user_id, name, quantity, is_checked, sort_order)
  VALUES
    (sl_anna2, uid_anna, 'Shampoo',             '1 Flasche', false, 1),
    (sl_anna2, uid_anna, 'Zahnpasta',           '2x',        false, 2),
    (sl_anna2, uid_anna, 'Waschmittel',         '1 Packung', false, 3),
    (sl_anna2, uid_anna, 'Spülmittel',          '2 Flaschen',false, 4)
  ON CONFLICT DO NOTHING;

  -- Ben WG-Liste
  INSERT INTO shopping_list_items (list_id, user_id, name, quantity, is_checked, sort_order)
  VALUES
    (sl_ben1, uid_ben, 'Toastbrot',       '2 Packungen', false, 1),
    (sl_ben1, uid_ben, 'Nudeln',          '1kg',         true,  2),
    (sl_ben1, uid_ben, 'Hackfleisch',     '500g',        false, 3),
    (sl_ben1, uid_ben, 'Tomatensoße',     '2 Gläser',    false, 4),
    (sl_ben1, uid_ben, 'Bier (Kasten)',   '1 Kasten',    false, 5),
    (sl_ben1, uid_ben, 'Cola',            '2 Flaschen',  true,  6),
    (sl_ben1, uid_ben, 'Chips',           '2 Tüten',     false, 7)
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 5. GESPEICHERTE REZEPTE (saved_recipes)
  -- ══════════════════════════════════════════════════════════
  INSERT INTO saved_recipes (user_id, title, recipe_json, source, created_at)
  VALUES
    -- Anna: KI-Rezept
    (
      uid_anna,
      'Hähnchen-Gemüse-Pfanne',
      '{
        "id": "seed_r1",
        "title": "Hähnchen-Gemüse-Pfanne",
        "cookTime": 25,
        "servings": 2,
        "difficulty": "Einfach",
        "ingredients": [
          {"name": "Hähnchenbrust", "amount": "400g"},
          {"name": "Brokkoli", "amount": "300g"},
          {"name": "Karotten", "amount": "2 Stück"},
          {"name": "Sojasoße", "amount": "3 EL"},
          {"name": "Knoblauch", "amount": "2 Zehen"},
          {"name": "Olivenöl", "amount": "2 EL"}
        ],
        "steps": [
          "Hähnchenbrust in Streifen schneiden und mit Sojasoße marinieren.",
          "Brokkoli in Röschen teilen, Karotten in Scheiben schneiden.",
          "Öl in der Pfanne erhitzen, Hähnchen anbraten bis goldbraun.",
          "Gemüse hinzufügen und 5-7 Minuten mitbraten.",
          "Mit Salz und Pfeffer abschmecken. Mit Reis servieren."
        ],
        "nutrition": {"calories": 380, "protein": 42, "carbs": 18, "fat": 12},
        "tags": ["Gesund", "Proteinreich", "Schnell"]
      }'::jsonb,
      'ai',
      now() - interval '5 days'
    ),
    -- Anna: Manuelles Rezept
    (
      uid_anna,
      'Omas Kartoffelsuppe',
      '{
        "id": "seed_r2",
        "title": "Omas Kartoffelsuppe",
        "cookTime": 45,
        "servings": 4,
        "difficulty": "Mittel",
        "ingredients": [
          {"name": "Kartoffeln", "amount": "800g"},
          {"name": "Karotten", "amount": "3 Stück"},
          {"name": "Zwiebel", "amount": "1 Stück"},
          {"name": "Gemüsebrühe", "amount": "1 Liter"},
          {"name": "Sahne", "amount": "100ml"},
          {"name": "Butter", "amount": "2 EL"},
          {"name": "Petersilie", "amount": "nach Geschmack"}
        ],
        "steps": [
          "Kartoffeln und Karotten schälen und würfeln.",
          "Zwiebel fein hacken und in Butter glasig dünsten.",
          "Kartoffeln und Karotten hinzufügen, kurz mitdünsten.",
          "Mit Brühe aufgießen und 25 Minuten köcheln lassen.",
          "Hälfte der Suppe pürieren, Sahne unterrühren.",
          "Mit Salz, Pfeffer und Petersilie abschmecken."
        ],
        "nutrition": {"calories": 280, "protein": 6, "carbs": 45, "fat": 9},
        "tags": ["Klassisch", "Deutsch", "Vegetarisch"]
      }'::jsonb,
      'manual',
      now() - interval '10 days'
    ),
    -- Ben: Rezept
    (
      uid_ben,
      'Schnelle Pasta Carbonara',
      '{
        "id": "seed_r3",
        "title": "Schnelle Pasta Carbonara",
        "cookTime": 20,
        "servings": 2,
        "difficulty": "Einfach",
        "ingredients": [
          {"name": "Spaghetti", "amount": "200g"},
          {"name": "Speck (Pancetta)", "amount": "150g"},
          {"name": "Eier", "amount": "3 Stück"},
          {"name": "Parmesan", "amount": "80g"},
          {"name": "Schwarzer Pfeffer", "amount": "nach Geschmack"}
        ],
        "steps": [
          "Spaghetti nach Packungsanweisung al dente kochen.",
          "Pancetta in der Pfanne knusprig anbraten.",
          "Eier mit geriebenem Parmesan verquirlen.",
          "Heiße (nicht kochende!) Pasta vom Herd nehmen.",
          "Ei-Parmesan-Mischung schnell unterrühren.",
          "Pancetta hinzufügen, mit viel Pfeffer abschmecken."
        ],
        "nutrition": {"calories": 620, "protein": 32, "carbs": 68, "fat": 22},
        "tags": ["Pasta", "Italienisch", "Schnell"]
      }'::jsonb,
      'ai',
      now() - interval '3 days'
    ),
    -- Clara: Rezept
    (
      uid_clara,
      'Linsen-Dahl mit Kokosmilch',
      '{
        "id": "seed_r4",
        "title": "Linsen-Dahl mit Kokosmilch",
        "cookTime": 35,
        "servings": 3,
        "difficulty": "Einfach",
        "ingredients": [
          {"name": "Rote Linsen", "amount": "250g"},
          {"name": "Kokosmilch", "amount": "400ml"},
          {"name": "Tomaten (Dose)", "amount": "400g"},
          {"name": "Zwiebel", "amount": "1 Stück"},
          {"name": "Knoblauch", "amount": "3 Zehen"},
          {"name": "Ingwer", "amount": "2cm"},
          {"name": "Kurkuma", "amount": "1 TL"},
          {"name": "Kreuzkümmel", "amount": "1 TL"},
          {"name": "Koriander", "amount": "nach Geschmack"}
        ],
        "steps": [
          "Zwiebel, Knoblauch und Ingwer fein hacken.",
          "In Öl anbraten, Gewürze hinzufügen und 1 Minute rösten.",
          "Linsen, Tomaten und Kokosmilch hinzufügen.",
          "30 Minuten köcheln lassen bis Linsen weich sind.",
          "Mit Salz abschmecken und mit Reis oder Naan servieren."
        ],
        "nutrition": {"calories": 420, "protein": 18, "carbs": 55, "fat": 14},
        "tags": ["Vegan", "Indisch", "Proteinreich"]
      }'::jsonb,
      'ai',
      now() - interval '7 days'
    )
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 6. WOCHENPLÄNE (meal_plans)
  -- ══════════════════════════════════════════════════════════
  -- Anna: Aktuelle Woche
  INSERT INTO meal_plans (user_id, week_start, day_index, slot, recipe_json, created_at)
  VALUES
    -- Montag
    (uid_anna, mp_week1, 0, 'breakfast',
     '{"id":"mp1","title":"Haferflocken mit Banane","cookTime":5,"servings":1,"ingredients":[{"name":"Haferflocken","amount":"80g"},{"name":"Banane","amount":"1 Stück"},{"name":"Milch","amount":"200ml"}],"steps":["Haferflocken mit Milch aufkochen","Banane in Scheiben schneiden und obenauf geben"],"nutrition":{"calories":320,"protein":10,"carbs":58,"fat":5}}'::jsonb,
     now()
    ),
    (uid_anna, mp_week1, 0, 'lunch',
     '{"id":"mp2","title":"Hähnchen-Gemüse-Pfanne","cookTime":25,"servings":2,"ingredients":[{"name":"Hähnchenbrust","amount":"400g"},{"name":"Brokkoli","amount":"300g"}],"steps":["Hähnchen anbraten","Gemüse hinzufügen"],"nutrition":{"calories":380,"protein":42,"carbs":18,"fat":12}}'::jsonb,
     now()
    ),
    (uid_anna, mp_week1, 0, 'dinner',
     '{"id":"mp3","title":"Omas Kartoffelsuppe","cookTime":45,"servings":4,"ingredients":[{"name":"Kartoffeln","amount":"800g"}],"steps":["Kartoffeln kochen","Pürieren"],"nutrition":{"calories":280,"protein":6,"carbs":45,"fat":9}}'::jsonb,
     now()
    ),
    -- Dienstag
    (uid_anna, mp_week1, 1, 'breakfast',
     '{"id":"mp4","title":"Joghurt mit Beeren","cookTime":3,"servings":1,"ingredients":[{"name":"Joghurt","amount":"200g"},{"name":"Beeren","amount":"100g"}],"steps":["Joghurt in Schüssel","Beeren drauf"],"nutrition":{"calories":180,"protein":8,"carbs":25,"fat":4}}'::jsonb,
     now()
    ),
    (uid_anna, mp_week1, 1, 'lunch',
     '{"id":"mp5","title":"Linsensalat mit Feta","cookTime":20,"servings":2,"ingredients":[{"name":"Rote Linsen","amount":"200g"},{"name":"Feta","amount":"100g"}],"steps":["Linsen kochen","Abkühlen lassen","Mit Feta mischen"],"nutrition":{"calories":340,"protein":20,"carbs":42,"fat":10}}'::jsonb,
     now()
    ),
    -- Mittwoch
    (uid_anna, mp_week1, 2, 'dinner',
     '{"id":"mp6","title":"Pasta mit Tomatensoße","cookTime":20,"servings":2,"ingredients":[{"name":"Spaghetti","amount":"200g"},{"name":"Tomaten (Dose)","amount":"400g"}],"steps":["Pasta kochen","Soße zubereiten","Kombinieren"],"nutrition":{"calories":480,"protein":14,"carbs":88,"fat":6}}'::jsonb,
     now()
    ),
    -- Donnerstag
    (uid_anna, mp_week1, 3, 'lunch',
     '{"id":"mp7","title":"Hähnchen-Wrap","cookTime":15,"servings":1,"ingredients":[{"name":"Tortilla","amount":"1 Stück"},{"name":"Hähnchen","amount":"150g"},{"name":"Salat","amount":"nach Geschmack"}],"steps":["Hähnchen grillen","In Tortilla wickeln"],"nutrition":{"calories":420,"protein":35,"carbs":38,"fat":10}}'::jsonb,
     now()
    ),
    -- Freitag
    (uid_anna, mp_week1, 4, 'breakfast',
     '{"id":"mp8","title":"Avocado Toast","cookTime":5,"servings":1,"ingredients":[{"name":"Vollkornbrot","amount":"2 Scheiben"},{"name":"Avocado","amount":"1 Stück"},{"name":"Zitronen","amount":"1/2 Stück"}],"steps":["Brot toasten","Avocado zerdrücken","Mit Zitrone beträufeln"],"nutrition":{"calories":290,"protein":7,"carbs":30,"fat":16}}'::jsonb,
     now()
    ),
    (uid_anna, mp_week1, 4, 'dinner',
     '{"id":"mp9","title":"Linsen-Dahl mit Kokosmilch","cookTime":35,"servings":3,"ingredients":[{"name":"Rote Linsen","amount":"250g"},{"name":"Kokosmilch","amount":"400ml"}],"steps":["Zwiebeln dünsten","Linsen kochen","Kokosmilch hinzufügen"],"nutrition":{"calories":420,"protein":18,"carbs":55,"fat":14}}'::jsonb,
     now()
    )
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 7. COMMUNITY REZEPTE (community_recipes)
  -- ══════════════════════════════════════════════════════════
  INSERT INTO community_recipes (
    id, user_id, author_name, title, description,
    recipe_json, tags, category, difficulty,
    cooking_time_minutes, servings, is_published,
    view_count, created_at
  ) VALUES
    -- Anna: Klassisches deutsches Rezept
    (
      cr1, uid_anna, 'Anna M.',
      'Sauerbraten mit Rotkohl',
      'Das klassische deutsche Schmorbraten-Rezept nach Omas Art. Perfekt für Sonntage.',
      '{
        "id": "cr1",
        "title": "Sauerbraten mit Rotkohl",
        "cookTime": 180,
        "servings": 4,
        "ingredients": [
          {"name": "Rinderbraten", "amount": "1kg"},
          {"name": "Rotkohl", "amount": "500g"},
          {"name": "Rotweinessig", "amount": "200ml"},
          {"name": "Zwiebeln", "amount": "2 Stück"},
          {"name": "Lorbeerblätter", "amount": "3 Stück"},
          {"name": "Nelken", "amount": "5 Stück"},
          {"name": "Zucker", "amount": "2 EL"}
        ],
        "steps": [
          "Fleisch 2 Tage in Marinade aus Essig, Wasser, Lorbeer und Nelken einlegen.",
          "Fleisch herausnehmen, trocken tupfen und von allen Seiten anbraten.",
          "Marinade und Gemüse hinzufügen, 2-3 Stunden schmoren.",
          "Rotkohl mit Äpfeln und Zucker separat garen.",
          "Soße abschmecken und mit Kartoffelknödeln servieren."
        ],
        "nutrition": {"calories": 520, "protein": 48, "carbs": 22, "fat": 28}
      }'::jsonb,
      ARRAY['Deutsch', 'Klassisch', 'Sonntagsessen', 'Fleisch'],
      'Hauptgericht', 'Fortgeschritten',
      180, 4, true, 47,
      now() - interval '15 days'
    ),
    -- Ben: Veganes Rezept
    (
      cr2, uid_ben, 'Ben S.',
      'Vegane Buddha Bowl',
      'Gesund, bunt und sättigend! Diese Buddha Bowl ist voller Nährstoffe.',
      '{
        "id": "cr2",
        "title": "Vegane Buddha Bowl",
        "cookTime": 30,
        "servings": 2,
        "ingredients": [
          {"name": "Quinoa", "amount": "150g"},
          {"name": "Kichererbsen (Dose)", "amount": "400g"},
          {"name": "Süßkartoffel", "amount": "1 Stück"},
          {"name": "Babyspinat", "amount": "100g"},
          {"name": "Avocado", "amount": "1 Stück"},
          {"name": "Tahini", "amount": "3 EL"},
          {"name": "Zitrone", "amount": "1 Stück"}
        ],
        "steps": [
          "Quinoa kochen und abkühlen lassen.",
          "Kichererbsen mit Olivenöl und Gewürzen im Ofen rösten (20 Min, 200°C).",
          "Süßkartoffel würfeln und ebenfalls rösten.",
          "Tahini mit Zitronensaft und Wasser zu Dressing rühren.",
          "Alles in einer Schüssel anrichten und mit Dressing beträufeln."
        ],
        "nutrition": {"calories": 580, "protein": 22, "carbs": 72, "fat": 20}
      }'::jsonb,
      ARRAY['Vegan', 'Gesund', 'Bowl', 'Meal-Prep'],
      'Hauptgericht', 'Einfach',
      30, 2, true, 123,
      now() - interval '10 days'
    ),
    -- Clara: Schnelles Rezept
    (
      cr3, uid_clara, 'Clara W.',
      'Pfannkuchen wie bei Oma',
      'Der einfachste und leckerste Pfannkuchen-Teig der Welt. Gelingt immer!',
      '{
        "id": "cr3",
        "title": "Pfannkuchen wie bei Oma",
        "cookTime": 20,
        "servings": 4,
        "ingredients": [
          {"name": "Mehl", "amount": "200g"},
          {"name": "Eier", "amount": "3 Stück"},
          {"name": "Milch", "amount": "400ml"},
          {"name": "Butter", "amount": "2 EL"},
          {"name": "Zucker", "amount": "1 EL"},
          {"name": "Salz", "amount": "1 Prise"}
        ],
        "steps": [
          "Mehl, Eier, Milch, Zucker und Salz zu glattem Teig verrühren.",
          "30 Minuten ruhen lassen.",
          "Butter in Pfanne erhitzen, Teig portionsweise hineingebern.",
          "Von jeder Seite 2-3 Minuten backen bis goldbraun.",
          "Mit Zucker, Zimt, Nutella oder Marmelade servieren."
        ],
        "nutrition": {"calories": 260, "protein": 9, "carbs": 38, "fat": 8}
      }'::jsonb,
      ARRAY['Frühstück', 'Klassisch', 'Süß', 'Kinder'],
      'Frühstück', 'Einfach',
      20, 4, true, 89,
      now() - interval '8 days'
    ),
    -- Anna: Asiatisches Rezept
    (
      cr4, uid_anna, 'Anna M.',
      'Schnelles Thai Green Curry',
      'Aromatisches Thai-Curry in unter 30 Minuten. Mit Kokosmilch und frischem Gemüse.',
      '{
        "id": "cr4",
        "title": "Schnelles Thai Green Curry",
        "cookTime": 25,
        "servings": 3,
        "ingredients": [
          {"name": "Hähnchenbrust", "amount": "400g"},
          {"name": "Kokosmilch (Dose)", "amount": "400ml"},
          {"name": "Green Curry Paste", "amount": "2 EL"},
          {"name": "Paprika", "amount": "1 Stück"},
          {"name": "Zucchini", "amount": "1 Stück"},
          {"name": "Fischsoße", "amount": "2 EL"},
          {"name": "Ingwer", "amount": "2cm"},
          {"name": "Basilikum", "amount": "nach Geschmack"}
        ],
        "steps": [
          "Hähnchen in Würfel schneiden.",
          "Curry-Paste in Öl anbraten bis sie duftet.",
          "Hähnchen hinzufügen und 5 Minuten braten.",
          "Kokosmilch und Gemüse hinzufügen.",
          "15 Minuten köcheln, mit Fischsoße abschmecken.",
          "Mit Jasminreis und frischem Basilikum servieren."
        ],
        "nutrition": {"calories": 440, "protein": 36, "carbs": 18, "fat": 24}
      }'::jsonb,
      ARRAY['Asiatisch', 'Thai', 'Curry', 'Schnell'],
      'Hauptgericht', 'Einfach',
      25, 3, true, 201,
      now() - interval '5 days'
    ),
    -- Ben: Frühstück
    (
      cr5, uid_ben, 'Ben S.',
      'Overnight Oats mit Erdbeeren',
      'Super gesundes und schnelles Frühstück. Abends vorbereiten, morgens genießen!',
      '{
        "id": "cr5",
        "title": "Overnight Oats mit Erdbeeren",
        "cookTime": 5,
        "servings": 1,
        "ingredients": [
          {"name": "Haferflocken", "amount": "80g"},
          {"name": "Joghurt", "amount": "150g"},
          {"name": "Mandelmilch", "amount": "100ml"},
          {"name": "Erdbeeren", "amount": "100g"},
          {"name": "Honig", "amount": "1 EL"},
          {"name": "Chiasamen", "amount": "1 EL"}
        ],
        "steps": [
          "Haferflocken, Joghurt, Milch und Chiasamen in Glas schichten.",
          "Honig einrühren.",
          "Mindestens 6 Stunden (oder über Nacht) im Kühlschrank lassen.",
          "Morgens mit frischen Erdbeeren toppen und genießen."
        ],
        "nutrition": {"calories": 380, "protein": 14, "carbs": 58, "fat": 9}
      }'::jsonb,
      ARRAY['Frühstück', 'Gesund', 'Meal-Prep', 'Schnell'],
      'Frühstück', 'Einfach',
      5, 1, true, 156,
      now() - interval '3 days'
    )
  ON CONFLICT (id) DO NOTHING;

  -- Likes für Community-Rezepte
  INSERT INTO recipe_likes (recipe_id, user_id, created_at)
  VALUES
    (cr1, uid_ben,   now() - interval '14 days'),
    (cr1, uid_clara, now() - interval '12 days'),
    (cr2, uid_anna,  now() - interval '9 days'),
    (cr2, uid_clara, now() - interval '8 days'),
    (cr3, uid_anna,  now() - interval '7 days'),
    (cr3, uid_ben,   now() - interval '6 days'),
    (cr4, uid_ben,   now() - interval '4 days'),
    (cr4, uid_clara, now() - interval '3 days'),
    (cr5, uid_anna,  now() - interval '2 days'),
    (cr5, uid_clara, now() - interval '1 day')
  ON CONFLICT DO NOTHING;

  -- Kommentare
  INSERT INTO recipe_comments (recipe_id, user_id, author_name, content, created_at)
  VALUES
    (cr1, uid_ben,   'Ben S.',   'Hammer Rezept! Genau wie ich es als Kind kannte 😍', now() - interval '13 days'),
    (cr1, uid_clara, 'Clara W.', 'Habe es gestern gemacht – absolut perfekt für den Sonntag!', now() - interval '11 days'),
    (cr2, uid_anna,  'Anna M.',  'Die Tahini-Soße macht alles aus! Super Rezept 🌿', now() - interval '8 days'),
    (cr3, uid_ben,   'Ben S.',   'Beste Pfannkuchen ever!! Mache ich jetzt jeden Sonntag', now() - interval '5 days'),
    (cr4, uid_clara, 'Clara W.', 'Sehr lecker! Ich habe noch etwas Chili hinzugefügt 🔥', now() - interval '2 days')
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 8. COMMUNITY WOCHENPLÄNE (community_meal_plans)
  -- ══════════════════════════════════════════════════════════
  INSERT INTO community_meal_plans (
    id, user_id, author_name, title, description,
    plan_json, tags, is_published, view_count, created_at
  ) VALUES
    (
      cmp1, uid_anna, 'Anna M.',
      'Ausgewogene Familienwoche 🥗',
      'Eine gesunde und abwechslungsreiche Woche für die ganze Familie. Viel Gemüse, gutes Protein.',
      '[
        {"dayIndex": 0, "slot": "breakfast", "recipe": {"title": "Haferflocken mit Banane", "cookTime": 5, "nutrition": {"calories": 320}}},
        {"dayIndex": 0, "slot": "lunch",     "recipe": {"title": "Hähnchen-Gemüse-Pfanne", "cookTime": 25, "nutrition": {"calories": 380}}},
        {"dayIndex": 0, "slot": "dinner",    "recipe": {"title": "Kartoffelsuppe",          "cookTime": 45, "nutrition": {"calories": 280}}},
        {"dayIndex": 1, "slot": "breakfast", "recipe": {"title": "Joghurt mit Beeren",      "cookTime": 3,  "nutrition": {"calories": 180}}},
        {"dayIndex": 1, "slot": "lunch",     "recipe": {"title": "Quinoa-Bowl",              "cookTime": 25, "nutrition": {"calories": 420}}},
        {"dayIndex": 1, "slot": "dinner",    "recipe": {"title": "Pasta mit Pesto",          "cookTime": 15, "nutrition": {"calories": 460}}},
        {"dayIndex": 2, "slot": "lunch",     "recipe": {"title": "Gemüsewrap",               "cookTime": 15, "nutrition": {"calories": 340}}},
        {"dayIndex": 2, "slot": "dinner",    "recipe": {"title": "Lachs mit Brokkoli",       "cookTime": 25, "nutrition": {"calories": 390}}},
        {"dayIndex": 3, "slot": "breakfast", "recipe": {"title": "Avocado Toast",            "cookTime": 5,  "nutrition": {"calories": 290}}},
        {"dayIndex": 3, "slot": "dinner",    "recipe": {"title": "Linsen-Dahl",              "cookTime": 35, "nutrition": {"calories": 420}}},
        {"dayIndex": 4, "slot": "lunch",     "recipe": {"title": "Hähnchen-Wrap",            "cookTime": 15, "nutrition": {"calories": 420}}},
        {"dayIndex": 4, "slot": "dinner",    "recipe": {"title": "Rührei mit Gemüse",        "cookTime": 10, "nutrition": {"calories": 290}}},
        {"dayIndex": 5, "slot": "breakfast", "recipe": {"title": "Pfannkuchen",              "cookTime": 20, "nutrition": {"calories": 260}}},
        {"dayIndex": 5, "slot": "dinner",    "recipe": {"title": "Sauerbraten",              "cookTime": 180,"nutrition": {"calories": 520}}},
        {"dayIndex": 6, "slot": "breakfast", "recipe": {"title": "Overnight Oats",           "cookTime": 5,  "nutrition": {"calories": 380}}},
        {"dayIndex": 6, "slot": "lunch",     "recipe": {"title": "Tomatensuppe",             "cookTime": 30, "nutrition": {"calories": 180}}},
        {"dayIndex": 6, "slot": "dinner",    "recipe": {"title": "Thai Green Curry",         "cookTime": 25, "nutrition": {"calories": 440}}}
      ]'::jsonb,
      ARRAY['Ausgewogen', 'Familie', 'Gesund', 'Abwechslungsreich'],
      true, 34,
      now() - interval '12 days'
    ),
    (
      cmp2, uid_ben, 'Ben S.',
      'Vegane Power-Woche 💪',
      'Komplett vegan, proteinreich und köstlich! Beweise dass vegan auch sättigt.',
      '[
        {"dayIndex": 0, "slot": "breakfast", "recipe": {"title": "Overnight Oats",       "cookTime": 5,  "nutrition": {"calories": 380}}},
        {"dayIndex": 0, "slot": "lunch",     "recipe": {"title": "Buddha Bowl",           "cookTime": 30, "nutrition": {"calories": 580}}},
        {"dayIndex": 0, "slot": "dinner",    "recipe": {"title": "Linsen-Dahl",           "cookTime": 35, "nutrition": {"calories": 420}}},
        {"dayIndex": 1, "slot": "breakfast", "recipe": {"title": "Smoothie Bowl",         "cookTime": 5,  "nutrition": {"calories": 310}}},
        {"dayIndex": 1, "slot": "lunch",     "recipe": {"title": "Kichererbsen-Salat",    "cookTime": 15, "nutrition": {"calories": 360}}},
        {"dayIndex": 1, "slot": "dinner",    "recipe": {"title": "Tofu-Stir-Fry",         "cookTime": 20, "nutrition": {"calories": 440}}},
        {"dayIndex": 2, "slot": "dinner",    "recipe": {"title": "Vegane Bolognese",      "cookTime": 40, "nutrition": {"calories": 480}}},
        {"dayIndex": 3, "slot": "lunch",     "recipe": {"title": "Avocado-Toast mit Ei",  "cookTime": 10, "nutrition": {"calories": 290}}},
        {"dayIndex": 3, "slot": "dinner",    "recipe": {"title": "Rotes Thai-Curry vegan","cookTime": 30, "nutrition": {"calories": 480}}}
      ]'::jsonb,
      ARRAY['Vegan', 'Proteinreich', 'Sportler', 'Pflanzlich'],
      true, 67,
      now() - interval '7 days'
    )
  ON CONFLICT (id) DO NOTHING;

  -- Likes für Community-Wochenpläne
  INSERT INTO meal_plan_likes (plan_id, user_id, created_at)
  VALUES
    (cmp1, uid_ben,   now() - interval '11 days'),
    (cmp1, uid_clara, now() - interval '10 days'),
    (cmp2, uid_anna,  now() - interval '6 days'),
    (cmp2, uid_clara, now() - interval '5 days')
  ON CONFLICT DO NOTHING;

  RAISE NOTICE '✅ Seed-Daten erfolgreich eingefügt!';
  RAISE NOTICE '   👤 3 Demo-User: anna@foody-demo.de, ben@foody-demo.de, clara@foody-demo.de';
  RAISE NOTICE '   🏠 2 Haushalte: Familie Müller (Anna+Clara), WG Schillerstr. (Ben+Clara)';
  RAISE NOTICE '   🥦 32 Vorrats-Artikel (Anna) + 10 (Ben)';
  RAISE NOTICE '   🛒 3 Einkaufslisten mit Items';
  RAISE NOTICE '   🍽️ 4 gespeicherte Rezepte (private)';
  RAISE NOTICE '   📅 9 Wochenplan-Einträge für Anna';
  RAISE NOTICE '   🌍 5 Community-Rezepte mit Likes & Kommentaren';
  RAISE NOTICE '   📋 2 Community-Wochenpläne mit Likes';

END $$;

