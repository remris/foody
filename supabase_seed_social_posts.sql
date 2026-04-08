-- ============================================================
-- FOODY – Seed: Social Posts (Test-Daten) v2
-- 20 Posts – davon 8 mit echten Rezept- / Plan-Attachments.
-- Voraussetzung: supabase_seed_social_testusers.sql ausgeführt.
-- Zum Neustart erst löschen: DELETE FROM public.social_posts;
-- ============================================================

DO $$
DECLARE
  v_chef      UUID;
  v_veggi     UUID;
  v_baker     UUID;
  v_fitness   UUID;
  v_family    UUID;

  -- Rezept-IDs dynamisch aus DB laden
  r_carbonara   UUID;
  r_tiramisu    UUID;
  r_buddha      UUID;
  r_linsen      UUID;
  r_sauerteig   UUID;
  r_mealprep    UUID;
  r_bolognese   UUID;
  r_pancakes    UUID;

  -- Plan-IDs dynamisch aus DB laden
  pl_mediterran UUID;
  pl_vegan      UUID;
  pl_fitness    UUID;
  pl_familie    UUID;

  -- Post IDs
  p1  UUID := gen_random_uuid();
  p2  UUID := gen_random_uuid();
  p3  UUID := gen_random_uuid();
  p4  UUID := gen_random_uuid();
  p5  UUID := gen_random_uuid();
  p6  UUID := gen_random_uuid();
  p7  UUID := gen_random_uuid();
  p8  UUID := gen_random_uuid();
  p9  UUID := gen_random_uuid();
  p10 UUID := gen_random_uuid();
  p11 UUID := gen_random_uuid();
  p12 UUID := gen_random_uuid();
  p13 UUID := gen_random_uuid();
  p14 UUID := gen_random_uuid();
  p15 UUID := gen_random_uuid();
  p16 UUID := gen_random_uuid();
  p17 UUID := gen_random_uuid();
  p18 UUID := gen_random_uuid();
  p19 UUID := gen_random_uuid();
  p20 UUID := gen_random_uuid();

BEGIN
  -- ── User laden ───────────────────────────────────────────────────────────
  SELECT id INTO v_chef    FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 0;
  SELECT id INTO v_veggi   FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 1;
  SELECT id INTO v_baker   FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 2;
  SELECT id INTO v_fitness FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 3;
  SELECT id INTO v_family  FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 4;

  IF v_chef IS NULL THEN
    RAISE EXCEPTION 'Keine User gefunden! Bitte zuerst supabase_seed_social_testusers.sql ausführen.';
  END IF;

  -- ── Rezept-IDs aus DB laden (nach Titel) ─────────────────────────────────
  SELECT id INTO r_carbonara FROM public.community_recipes WHERE title ILIKE '%carbonara%'         LIMIT 1;
  SELECT id INTO r_tiramisu  FROM public.community_recipes WHERE title ILIKE '%tiramisu%'          LIMIT 1;
  SELECT id INTO r_buddha    FROM public.community_recipes WHERE title ILIKE '%buddha%'            LIMIT 1;
  SELECT id INTO r_linsen    FROM public.community_recipes WHERE title ILIKE '%linsen%'            LIMIT 1;
  SELECT id INTO r_sauerteig FROM public.community_recipes WHERE title ILIKE '%sauerteig%'         LIMIT 1;
  SELECT id INTO r_mealprep  FROM public.community_recipes WHERE title ILIKE '%meal%prep%'         LIMIT 1;
  SELECT id INTO r_bolognese FROM public.community_recipes WHERE title ILIKE '%bolognese%'         LIMIT 1;
  SELECT id INTO r_pancakes  FROM public.community_recipes WHERE title ILIKE '%pfannkuchen%'       LIMIT 1;

  -- ── Plan-IDs aus DB laden ─────────────────────────────────────────────────
  SELECT id INTO pl_mediterran FROM public.community_meal_plans WHERE title ILIKE '%mediterran%'   LIMIT 1;
  SELECT id INTO pl_vegan      FROM public.community_meal_plans WHERE title ILIKE '%vegan%'        LIMIT 1;
  SELECT id INTO pl_fitness    FROM public.community_meal_plans WHERE title ILIKE '%fitness%'      LIMIT 1;
  SELECT id INTO pl_familie    FROM public.community_meal_plans WHERE title ILIKE '%famili%'       LIMIT 1;

  RAISE NOTICE 'Rezepte gefunden: carbonara=%, tiramisu=%, buddha=%, linsen=%, sauerteig=%, mealprep=%, bolognese=%, pancakes=%',
    r_carbonara, r_tiramisu, r_buddha, r_linsen, r_sauerteig, r_mealprep, r_bolognese, r_pancakes;
  RAISE NOTICE 'Pläne gefunden: mediterran=%, vegan=%, fitness=%, familie=%',
    pl_mediterran, pl_vegan, pl_fitness, pl_familie;

  -- ── POSTS ────────────────────────────────────────────────────────────────

  INSERT INTO public.social_posts
    (id, user_id, author_name, text, attached_recipe_id, attached_plan_id, like_count, comment_count, created_at)
  VALUES

  -- p1: Marco – Fitness-Bowl (kein Attachment, nur Text)
  (p1, v_chef, 'Marco Küchenchef',
   'Heute Morgen den Frühling mit einer frischen Fitness-Bowl begrüßt 🌸🥗
Spinat, Quinoa, Avocado und ein bisschen Sesam-Dressing – ihr müsst das unbedingt ausprobieren!
Was startet ihr mit einem gesunden Morgen?',
   NULL, NULL, 12, 3, NOW() - INTERVAL '2 hours'),

  -- p2: Marco – Pasta Carbonara MIT Rezept-Attachment
  (p2, v_chef, 'Marco Küchenchef',
   'Das Beste was mir je passiert ist: Echte Pasta Carbonara nach dem Originalrezept aus Rom. 🍝
Keine Sahne, kein Schnickschnack – nur Ei, Pecorino und Guanciale.
Mein Rezept dazu findet ihr hier 👇',
   r_carbonara, NULL, 34, 7, NOW() - INTERVAL '5 hours'),

  -- p3: Marco – Tiramisu MIT Rezept-Attachment
  (p3, v_chef, 'Marco Küchenchef',
   'Sonntagsdessert: Tiramisu nach Omas Rezept aus Venetien ☕🍰
Echter Mascarpone, frischer Espresso und ein Schuss Amaretto – so muss das schmecken!
Rezept ist unten – einfach mal ausprobieren!',
   r_tiramisu, NULL, 41, 9, NOW() - INTERVAL '1 day'),

  -- p4: Marco – Mediterrane Woche MIT Plan-Attachment
  (p4, v_chef, 'Marco Küchenchef',
   'Mein neuer Sommer-Wochenplan ist live 🌞
7 Tage voller mediterraner Köstlichkeiten – leicht, frisch und trotzdem sättigend.
Perfekt für den Urlaub zu Hause! 👇',
   NULL, pl_mediterran, 24, 5, NOW() - INTERVAL '2 days'),

  -- p5: Marco – Koch-Hack (nur Text)
  (p5, v_chef, 'Marco Küchenchef',
   'Kleiner Koch-Hack für heute Abend:
Wenn ihr Pasta kocht, gebt einen Schuss Olivenöl ins Kochwasser. Die Nudeln kleben danach nicht zusammen und der Geschmack wird intensiver. 🍝
Probiert es aus und sagt mir wie es euch schmeckt!',
   NULL, NULL, 8, 2, NOW() - INTERVAL '3 days'),

  -- p6: Lena – Buddha Bowl MIT Rezept-Attachment
  (p6, COALESCE(v_veggi, v_chef),
   CASE WHEN v_veggi IS NOT NULL THEN 'Lena Grünzeug' ELSE 'Marco Küchenchef' END,
   'Plant-Based Monday! 🌱
Heute gibt es meine Rainbow Buddha Bowl – bunt, gesund und unglaublich sättigend.
Ihr braucht nur 20 Minuten dafür! Das Rezept findet ihr hier 👇',
   r_buddha, NULL, 28, 6, NOW() - INTERVAL '4 hours'),

  -- p7: Lena – Vegane Power-Woche MIT Plan-Attachment
  (p7, COALESCE(v_veggi, v_chef),
   CASE WHEN v_veggi IS NOT NULL THEN 'Lena Grünzeug' ELSE 'Marco Küchenchef' END,
   'Vegane Ernährung muss nicht langweilig sein! 💚
Ich habe meinen kompletten Wochenplan veröffentlicht – 7 Tage rein pflanzlich, voller Farben und Geschmack.
Schaut rein und lasst euch inspirieren! 👇',
   NULL, pl_vegan, 22, 8, NOW() - INTERVAL '2 days'),

  -- p8: Lena – Linsensuppe MIT Rezept-Attachment
  (p8, COALESCE(v_veggi, v_chef),
   CASE WHEN v_veggi IS NOT NULL THEN 'Lena Grünzeug' ELSE 'Marco Küchenchef' END,
   'Wärmend, cremig und in 30 Minuten fertig 🍲
Meine Rote Linsensuppe mit Kokosmilch ist das perfekte Meal-Prep Rezept.
Einmal kochen – 4 Portionen für die ganze Woche! 👇',
   r_linsen, NULL, 18, 3, NOW() - INTERVAL '4 days'),

  -- p9: Lena – Garten-Update (nur Text)
  (p9, COALESCE(v_veggi, v_chef),
   CASE WHEN v_veggi IS NOT NULL THEN 'Lena Grünzeug' ELSE 'Marco Küchenchef' END,
   'Garten-Update 🌿🍅
Meine Tomaten und Kräuter wachsen prächtig!
Bald kann ich mit frischen Zutaten aus dem eigenen Garten kochen – kein Vergleich zum Supermarkt.
Hat von euch jemand auch einen Küchengarten?',
   NULL, NULL, 27, 5, NOW() - INTERVAL '6 days'),

  -- p10: Thomas – Sauerteigbrot MIT Rezept-Attachment
  (p10, COALESCE(v_baker, v_chef),
   CASE WHEN v_baker IS NOT NULL THEN 'Thomas Backstube' ELSE 'Marco Küchenchef' END,
   'Frisch aus dem Ofen: Sauerteigbrot nach 48-Stunden-Fermentation 🍞
Der Aufwand lohnt sich absolut – knusprige Kruste, weiches Inneres, unglaubliches Aroma.
Das vollständige Rezept mit allen Tipps findet ihr hier 👇',
   r_sauerteig, NULL, 34, 9, NOW() - INTERVAL '3 hours'),

  -- p11: Thomas – Zimtschnecken (nur Text)
  (p11, COALESCE(v_baker, v_chef),
   CASE WHEN v_baker IS NOT NULL THEN 'Thomas Backstube' ELSE 'Marco Küchenchef' END,
   'Backen ist Therapie 🧁
Wenn der Alltag stressig wird, helfe ich mir mit Backen.
Heute: Zimtschnecken nach skandinavischem Rezept.
Das Haus riecht gerade nach Zimt und Kardamom – himmlisch! 🤤',
   NULL, NULL, 41, 11, NOW() - INTERVAL '1 day 6 hours'),

  -- p12: Thomas – Back-Tipp (nur Text)
  (p12, COALESCE(v_baker, v_chef),
   CASE WHEN v_baker IS NOT NULL THEN 'Thomas Backstube' ELSE 'Marco Küchenchef' END,
   'Pro-Tipp für perfekten Kuchenteig:
Alle Zutaten müssen Zimmertemperatur haben – besonders Eier und Butter! 🥚🧈
Kalte Zutaten verhindern dass sich alles gut verbindet.
Klingt simpel, macht aber einen riesigen Unterschied!',
   NULL, NULL, 16, 4, NOW() - INTERVAL '3 days'),

  -- p13: Thomas – Croissants (nur Text)
  (p13, COALESCE(v_baker, v_chef),
   CASE WHEN v_baker IS NOT NULL THEN 'Thomas Backstube' ELSE 'Marco Küchenchef' END,
   'Wochenend-Projekt: Croissants selbst gebacken 🥐
Ja, das ist aufwändig. Ja, es dauert 2 Tage. Ja, es lohnt sich zu 1000%.
Buttrig, flockig, knusprig – nichts geht über frische hausgemachte Croissants!',
   NULL, NULL, 55, 13, NOW() - INTERVAL '5 days'),

  -- p14: Sara – Meal-Prep MIT Rezept-Attachment
  (p14, COALESCE(v_fitness, v_chef),
   CASE WHEN v_fitness IS NOT NULL THEN 'Sara FitFood' ELSE 'Marco Küchenchef' END,
   'Post-Workout Meal 💪
Nach dem Training heute: Hähnchenbrust mit Süßkartoffel und Brokkoli.
Makros: ~650 kcal | 52g Protein | 68g Carbs | 12g Fett
Mein Meal-Prep Rezept für die ganze Woche 👇',
   r_mealprep, NULL, 29, 7, NOW() - INTERVAL '5 hours'),

  -- p15: Sara – Fitness Wochenplan MIT Plan-Attachment
  (p15, COALESCE(v_fitness, v_chef),
   CASE WHEN v_fitness IS NOT NULL THEN 'Sara FitFood' ELSE 'Marco Küchenchef' END,
   'Mein Meal-Prep für die Sommerfigur ist startklar 🏋️‍♀️
Hab heute 5 Gerichte für die Woche vorgekocht – alles proteinreich und kalorienoptimiert.
Den kompletten Wochenplan habe ich auch veröffentlicht – schaut mal rein! 👇',
   NULL, pl_fitness, 38, 10, NOW() - INTERVAL '2 days'),

  -- p16: Sara – Snack-Tipps (nur Text)
  (p16, COALESCE(v_fitness, v_chef),
   CASE WHEN v_fitness IS NOT NULL THEN 'Sara FitFood' ELSE 'Marco Küchenchef' END,
   'Gesunde Snacks die wirklich sättigen 🥜
1. Griechischer Joghurt + Beeren
2. Reiswaffeln mit Mandelmus
3. Hartgekochte Eier
4. Edamame
5. Hummus mit Gemüsesticks
Spart euch die Schokoriegel – ihr werdet euch besser fühlen! 😄',
   NULL, NULL, 47, 12, NOW() - INTERVAL '4 days'),

  -- p17: Familie – Familienpizza (nur Text)
  (p17, COALESCE(v_family, v_chef),
   CASE WHEN v_family IS NOT NULL THEN 'Familie Müller' ELSE 'Marco Küchenchef' END,
   'Familienessen am Sonntag 👨‍👩‍👧‍👦
Heute haben wir gemeinsam Pizza gebacken – jeder durfte seinen eigenen Belag wählen.
Die Kinder hatten riesigen Spaß und am Ende war der Tisch voller Lachen und Pizzareste.
Das beste Rezept: Zeit mit der Familie! ❤️',
   NULL, NULL, 63, 15, NOW() - INTERVAL '1 day 2 hours'),

  -- p18: Familie – Pfannkuchen MIT Rezept-Attachment
  (p18, COALESCE(v_family, v_chef),
   CASE WHEN v_family IS NOT NULL THEN 'Familie Müller' ELSE 'Marco Küchenchef' END,
   'Kinder in die Küche! 👦👧
Heute haben unsere Kleinen zum ersten Mal Pfannkuchen selbst gemacht.
Unser Familienrezept ist super einfach – perfekt auch für Kinder! 👇',
   r_pancakes, NULL, 52, 9, NOW() - INTERVAL '3 days'),

  -- p19: Familie – Bolognese MIT Rezept-Attachment
  (p19, COALESCE(v_family, v_chef),
   CASE WHEN v_family IS NOT NULL THEN 'Familie Müller' ELSE 'Marco Küchenchef' END,
   'Unser Sonntagsklassiker: Familien-Bolognese 🍝❤️
Langsam geschmort, die Kinder lieben es – und der Duft in der Küche macht alle verrückt.
Das Rezept für 4 Personen findet ihr hier 👇',
   r_bolognese, NULL, 44, 8, NOW() - INTERVAL '6 days'),

  -- p20: Familie – Familien-Wochenplan MIT Plan-Attachment
  (p20, COALESCE(v_family, v_chef),
   CASE WHEN v_family IS NOT NULL THEN 'Familie Müller' ELSE 'Marco Küchenchef' END,
   '"Was kochen wir heute?" – diese Frage nervt mich nie wieder! 📅
Unser Familien-Wochenplan macht die ganze Woche entspannt.
30 Minuten am Sonntag planen = glückliche Familie. Den Plan gibt es hier 👇',
   NULL, pl_familie, 71, 16, NOW() - INTERVAL '1 week');

  RAISE NOTICE '20 Posts eingefügt.';

  -- ── KOMMENTARE ───────────────────────────────────────────────────────────

  INSERT INTO public.social_post_comments (post_id, user_id, author_name, text, created_at)
  VALUES
  (p2, COALESCE(v_veggi,   v_chef), CASE WHEN v_veggi   IS NOT NULL THEN 'Lena Grünzeug'    ELSE 'Marco Küchenchef' END, 'Endlich das Original! Ich hab immer Sahne genommen 😅 Muss ich unbedingt ausprobieren!', NOW() - INTERVAL '4 hours'),
  (p2, COALESCE(v_fitness, v_chef), CASE WHEN v_fitness IS NOT NULL THEN 'Sara FitFood'      ELSE 'Marco Küchenchef' END, 'Makros schon berechnet? 😄 Sieht mega aus!', NOW() - INTERVAL '3 hours 30 min'),
  (p2, v_chef,                       'Marco Küchenchef', '@Lena: Nie wieder Sahne – versprochen! 😄 @Sara: ~650 kcal, 28g Protein 💪', NOW() - INTERVAL '3 hours'),

  (p3, COALESCE(v_baker,   v_chef), CASE WHEN v_baker   IS NOT NULL THEN 'Thomas Backstube' ELSE 'Marco Küchenchef' END, 'Tiramisu ist meine absolute Schwäche 😩 Schon nachgemacht!', NOW() - INTERVAL '20 hours'),
  (p3, COALESCE(v_family,  v_chef), CASE WHEN v_family  IS NOT NULL THEN 'Familie Müller'   ELSE 'Marco Küchenchef' END, 'Die Kinder fragen schon täglich wann wir das machen 😂', NOW() - INTERVAL '18 hours'),

  (p4, COALESCE(v_veggi,   v_chef), CASE WHEN v_veggi   IS NOT NULL THEN 'Lena Grünzeug'    ELSE 'Marco Küchenchef' END, 'Gerade gespeichert! Genau das brauche ich für den Sommer 🌊', NOW() - INTERVAL '1 day 20 hours'),
  (p4, COALESCE(v_fitness, v_chef), CASE WHEN v_fitness IS NOT NULL THEN 'Sara FitFood'      ELSE 'Marco Küchenchef' END, 'Perfekte Makros für eine leichte Sommerwoche 👌', NOW() - INTERVAL '1 day 18 hours'),

  (p6, v_chef,                       'Marco Küchenchef',  'Ich mache das jeden Montag mit! Dein Dressing ist legendary 🥗', NOW() - INTERVAL '3 hours'),
  (p6, COALESCE(v_fitness, v_chef), CASE WHEN v_fitness IS NOT NULL THEN 'Sara FitFood'      ELSE 'Marco Küchenchef' END, 'Protein-Gehalt? 😄 Ich brauch das nach dem Training!', NOW() - INTERVAL '2 hours 30 min'),

  (p10, v_chef,                       'Marco Küchenchef',  'Wahnsinn! 48 Stunden Fermentation – das ist echte Hingabe 🙌', NOW() - INTERVAL '2 hours'),
  (p10, COALESCE(v_veggi,   v_chef), CASE WHEN v_veggi   IS NOT NULL THEN 'Lena Grünzeug'    ELSE 'Marco Küchenchef' END, 'Ich kämpfe seit Wochen mit meinem Starter – hast du Tipps?', NOW() - INTERVAL '1 hour 30 min'),
  (p10, COALESCE(v_baker,   v_chef), CASE WHEN v_baker   IS NOT NULL THEN 'Thomas Backstube' ELSE 'Marco Küchenchef' END, '@Lena: Täglich füttern, Zimmertemperatur halten – das ist das Geheimnis! 🍞', NOW() - INTERVAL '1 hour'),

  (p14, v_chef,                       'Marco Küchenchef',  'Solide Makros! Ich koche auch viel mit Süßkartoffel – top für Sport 💪', NOW() - INTERVAL '4 hours'),
  (p14, COALESCE(v_baker,   v_chef), CASE WHEN v_baker   IS NOT NULL THEN 'Thomas Backstube' ELSE 'Marco Küchenchef' END, 'Ich verstehe nicht wie ihr nach dem Sport noch Hähnchen esst 😅 Ich brauche Kuchen!', NOW() - INTERVAL '3 hours 30 min'),

  (p17, COALESCE(v_veggi,   v_chef), CASE WHEN v_veggi   IS NOT NULL THEN 'Lena Grünzeug'    ELSE 'Marco Küchenchef' END, 'Das klingt wie ein perfekter Sonntag ❤️', NOW() - INTERVAL '1 day 1 hour'),
  (p17, COALESCE(v_baker,   v_chef), CASE WHEN v_baker   IS NOT NULL THEN 'Thomas Backstube' ELSE 'Marco Küchenchef' END, 'Pizza-Abend ist bei uns auch Pflicht! Teig selbst gemacht?', NOW() - INTERVAL '23 hours'),
  (p17, COALESCE(v_family,  v_chef), CASE WHEN v_family  IS NOT NULL THEN 'Familie Müller'   ELSE 'Marco Küchenchef' END, '@Thomas: Ja klar! Teig selbst machen ist das halbe Vergnügen 🍕', NOW() - INTERVAL '22 hours');

  RAISE NOTICE 'Kommentare eingefügt.';

  -- ── LIKES ────────────────────────────────────────────────────────────────

  INSERT INTO public.social_post_likes (post_id, user_id)
  VALUES
  (p1,  COALESCE(v_veggi,   v_chef)),
  (p1,  COALESCE(v_fitness, v_chef)),
  (p2,  COALESCE(v_baker,   v_chef)),
  (p2,  COALESCE(v_family,  v_chef)),
  (p2,  COALESCE(v_fitness, v_chef)),
  (p3,  COALESCE(v_veggi,   v_chef)),
  (p3,  COALESCE(v_baker,   v_chef)),
  (p4,  COALESCE(v_family,  v_chef)),
  (p4,  COALESCE(v_fitness, v_chef)),
  (p5,  COALESCE(v_baker,   v_chef)),
  (p6,  v_chef),
  (p6,  COALESCE(v_fitness, v_chef)),
  (p7,  v_chef),
  (p7,  COALESCE(v_baker,   v_chef)),
  (p8,  COALESCE(v_family,  v_chef)),
  (p9,  COALESCE(v_baker,   v_chef)),
  (p10, v_chef),
  (p10, COALESCE(v_veggi,   v_chef)),
  (p11, COALESCE(v_family,  v_chef)),
  (p12, v_chef),
  (p13, COALESCE(v_veggi,   v_chef)),
  (p14, v_chef),
  (p14, COALESCE(v_baker,   v_chef)),
  (p15, COALESCE(v_family,  v_chef)),
  (p15, v_chef),
  (p16, COALESCE(v_veggi,   v_chef)),
  (p17, v_chef),
  (p17, COALESCE(v_veggi,   v_chef)),
  (p18, COALESCE(v_baker,   v_chef)),
  (p19, v_chef),
  (p20, COALESCE(v_fitness, v_chef))
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Likes eingefügt.';
  RAISE NOTICE '✅ Fertig! 20 Posts mit Attachments, Kommentaren und Likes erstellt.';

END $$;

DO $$
DECLARE
  v_chef      UUID;
  v_veggi     UUID;
  v_baker     UUID;
  v_fitness   UUID;
  v_family    UUID;

  -- Post IDs
  p1  UUID := gen_random_uuid();
  p2  UUID := gen_random_uuid();
  p3  UUID := gen_random_uuid();
  p4  UUID := gen_random_uuid();
  p5  UUID := gen_random_uuid();
  p6  UUID := gen_random_uuid();
  p7  UUID := gen_random_uuid();
  p8  UUID := gen_random_uuid();
  p9  UUID := gen_random_uuid();
  p10 UUID := gen_random_uuid();
  p11 UUID := gen_random_uuid();
  p12 UUID := gen_random_uuid();
  p13 UUID := gen_random_uuid();
  p14 UUID := gen_random_uuid();
  p15 UUID := gen_random_uuid();
  p16 UUID := gen_random_uuid();
  p17 UUID := gen_random_uuid();
  p18 UUID := gen_random_uuid();
  p19 UUID := gen_random_uuid();
  p20 UUID := gen_random_uuid();

BEGIN
  -- User laden (gleiche Reihenfolge wie im Test-User-Script)
  SELECT id INTO v_chef    FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 0;
  SELECT id INTO v_veggi   FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 1;
  SELECT id INTO v_baker   FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 2;
  SELECT id INTO v_fitness FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 3;
  SELECT id INTO v_family  FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 4;

  IF v_chef IS NULL THEN
    RAISE EXCEPTION 'Keine User gefunden! Bitte zuerst supabase_seed_social_testusers.sql ausführen.';
  END IF;

  RAISE NOTICE 'Erstelle 20 Social Posts für User: % / % / % / % / %',
    v_chef, v_veggi, v_baker, v_fitness, v_family;

  -- ── POSTS ────────────────────────────────────────────────────────────────

  INSERT INTO public.social_posts (id, user_id, author_name, text, like_count, comment_count, created_at)
  VALUES

  -- Marco (Chef)
  (p1, v_chef, 'Marco Küchenchef',
   'Heute Morgen den Frühling mit einer frischen Fitness-Bowl begrüßt 🌸🥗
Spinat, Quinoa, Avocado und ein bisschen Sesam-Dressing – ihr müsst das unbedingt ausprobieren!
Was startet ihr mit einem gesunden Morgen?',
   12, 3, NOW() - INTERVAL '2 hours'),

  (p2, v_chef, 'Marco Küchenchef',
   'Mein neuer Sommer-Wochenplan ist live 🌞
7 Tage voller mediterraner Köstlichkeiten – leicht, frisch und trotzdem sättigend.
Ich habe ihn gerade in der Community veröffentlicht, schaut mal rein! 👇',
   24, 5, NOW() - INTERVAL '1 day'),

  (p3, v_chef, 'Marco Küchenchef',
   'Kleiner Koch-Hack für heute Abend:
Wenn ihr Pasta kocht, gebt einen Schuss Olivenöl ins Kochwasser. Die Nudeln kleben danach nicht zusammen und der Geschmack wird intensiver. 🍝
Probiert es aus und sagt mir wie es euch schmeckt!',
   8, 2, NOW() - INTERVAL '3 days'),

  (p4, v_chef, 'Marco Küchenchef',
   'Sonntag = Vorkochen-Tag 🥘
Heute 3 Gerichte für die ganze Woche vorbereitet:
✅ Gemüsesuppe
✅ Hähnchen-Marinade
✅ Overnight-Oats für 3 Tage
Wer macht auch Meal-Prep am Wochenende? 🙋',
   19, 7, NOW() - INTERVAL '5 days'),

  (p5, v_chef, 'Marco Küchenchef',
   'Gerade frische Zutaten vom Markt – und schon ist der Kühlschrank wieder voll 🛒❤️
Es gibt nichts Schöneres als frisches, saisonales Gemüse.
Heute gibt es Ratatouille nach dem Originalrezept meiner Oma aus Marseille.',
   31, 4, NOW() - INTERVAL '1 week'),

  -- Lena (Veggi)
  (p6,
   COALESCE(v_veggi, v_chef),
   CASE WHEN v_veggi IS NOT NULL THEN 'Lena Green' ELSE 'Marco Küchenchef' END,
   'Plant-Based Monday! 🌱
Heute starte ich mit einem vollständig veganen Tag.
Frühstück: Açaí-Bowl mit Hanfsamen
Mittag: Linsen-Dal mit Blumenkohlreis
Abend: Zucchini-Pasta mit Cashew-Pesto
Wer macht mit? 🤝',
   15, 6, NOW() - INTERVAL '4 hours'),

  (p7,
   COALESCE(v_veggi, v_chef),
   CASE WHEN v_veggi IS NOT NULL THEN 'Lena Green' ELSE 'Marco Küchenchef' END,
   'Vegane Ernährung muss nicht teuer sein! 💚
Mein Wocheneinkauf für 2 Personen: unter 40€ und trotzdem super vielseitig.
Tipp: Hülsenfrüchte und Getreidekörner in großen Mengen kaufen – spart enorm!
Welche veganen Budget-Tipps habt ihr?',
   22, 8, NOW() - INTERVAL '2 days'),

  (p8,
   COALESCE(v_veggi, v_chef),
   CASE WHEN v_veggi IS NOT NULL THEN 'Lena Green' ELSE 'Marco Küchenchef' END,
   'Habt ihr schon mal Jackfruit als Fleischersatz probiert? 🍖🌱
Ich war anfangs sehr skeptisch, aber pulled Jackfruit Tacos haben mich wirklich überrascht!
Konsistenz und Würzung – kaum ein Unterschied zu echtem Pulled Pork.
Rezept kommt bald! 👀',
   18, 3, NOW() - INTERVAL '4 days'),

  (p9,
   COALESCE(v_veggi, v_chef),
   CASE WHEN v_veggi IS NOT NULL THEN 'Lena Green' ELSE 'Marco Küchenchef' END,
   'Garten-Update 🌿🍅
Meine Tomaten und Kräuter wachsen prächtig!
Bald kann ich mit frischen Zutaten aus dem eigenen Garten kochen – kein Vergleich zum Supermarkt.
Hat von euch jemand auch einen Küchengarten?',
   27, 5, NOW() - INTERVAL '6 days'),

  -- Thomas (Baker)
  (p10,
   COALESCE(v_baker, v_chef),
   CASE WHEN v_baker IS NOT NULL THEN 'Thomas Backt' ELSE 'Marco Küchenchef' END,
   'Frisch aus dem Ofen: Sauerteigbrot nach 48-Stunden-Fermentation 🍞
Der Aufwand lohnt sich absolut – knusprige Kruste, weiches Inneres, unglaubliches Aroma.
Der Duft in der Küche ist einfach unbeschreiblich!',
   34, 9, NOW() - INTERVAL '3 hours'),

  (p11,
   COALESCE(v_baker, v_chef),
   CASE WHEN v_baker IS NOT NULL THEN 'Thomas Backt' ELSE 'Marco Küchenchef' END,
   'Backen ist Therapie 🧁
Wenn der Alltag stressig wird, helfe ich mir mit Backen.
Heute: Zimtschnecken nach skandinavischem Rezept.
Das Haus riecht gerade nach Zimt und Kardamom – himmlisch! 🤤',
   41, 11, NOW() - INTERVAL '1 day 6 hours'),

  (p12,
   COALESCE(v_baker, v_chef),
   CASE WHEN v_baker IS NOT NULL THEN 'Thomas Backt' ELSE 'Marco Küchenchef' END,
   'Pro-Tipp für perfekten Kuchenteig:
Alle Zutaten müssen Zimmertemperatur haben – besonders Eier und Butter! 🥚🧈
Kalte Zutaten verhindern dass sich alles gut verbindet.
Klingt simpel, macht aber einen riesigen Unterschied!',
   16, 4, NOW() - INTERVAL '3 days'),

  (p13,
   COALESCE(v_baker, v_chef),
   CASE WHEN v_baker IS NOT NULL THEN 'Thomas Backt' ELSE 'Marco Küchenchef' END,
   'Wochenend-Projekt: Croissants selbst gebacken 🥐
Ja, das ist aufwändig. Ja, es dauert 2 Tage. Ja, es lohnt sich zu 1000%.
Buttrig, flockig, knusprig – nichts geht über frische hausgemachte Croissants zum Frühstück!',
   55, 13, NOW() - INTERVAL '5 days'),

  -- Sara (Fitness)
  (p14,
   COALESCE(v_fitness, v_chef),
   CASE WHEN v_fitness IS NOT NULL THEN 'Sara Fit' ELSE 'Marco Küchenchef' END,
   'Post-Workout Meal 💪
Nach dem Training heute: Hähnchenbrust mit Süßkartoffel und Brokkoli.
Makros: ~650 kcal | 52g Protein | 68g Carbs | 12g Fett
Ernährung ist 70% des Erfolgs im Sport – nehmt das ernst!',
   29, 7, NOW() - INTERVAL '5 hours'),

  (p15,
   COALESCE(v_fitness, v_chef),
   CASE WHEN v_fitness IS NOT NULL THEN 'Sara Fit' ELSE 'Marco Küchenchef' END,
   'Mein Meal-Prep für die Sommerfigur ist startklar 🏋️‍♀️
Hab heute 5 Gerichte für die Woche vorgekocht – alles proteinreich und kalorienoptimiert.
Wer seine Ernährung kontrollieren will: vorkochen ist das A und O!',
   38, 10, NOW() - INTERVAL '2 days'),

  (p16,
   COALESCE(v_fitness, v_chef),
   CASE WHEN v_fitness IS NOT NULL THEN 'Sara Fit' ELSE 'Marco Küchenchef' END,
   'Gesunde Snacks die wirklich sättigen 🥜
1. Griechischer Joghurt + Beeren
2. Reiswaffeln mit Mandelmus
3. Hartgekochte Eier
4. Edamame
5. Hummus mit Gemüsesticks
Spart euch die Schokoriegel – ihr werdet euch besser fühlen! 😄',
   47, 12, NOW() - INTERVAL '4 days'),

  -- Familie
  (p17,
   COALESCE(v_family, v_chef),
   CASE WHEN v_family IS NOT NULL THEN 'Familie Weber' ELSE 'Marco Küchenchef' END,
   'Familienessen am Sonntag 👨‍👩‍👧‍👦
Heute haben wir gemeinsam Pizza gebacken – jeder durfte seinen eigenen Belag wählen.
Die Kinder hatten riesigen Spaß und am Ende war der Tisch voller Lachen und Pizzareste.
Das beste Rezept: Zeit mit der Familie! ❤️',
   63, 15, NOW() - INTERVAL '1 day 2 hours'),

  (p18,
   COALESCE(v_family, v_chef),
   CASE WHEN v_family IS NOT NULL THEN 'Familie Weber' ELSE 'Marco Küchenchef' END,
   'Kinder in die Küche! 👦👧
Heute haben unsere Kleinen (7 und 9) zum ersten Mal Pfannkuchen selbst gemacht.
Mit ein bisschen Anleitung hat alles super geklappt – und sie waren so stolz!
Frühes Kochen lernen ist eines der besten Geschenke für Kinder.',
   52, 9, NOW() - INTERVAL '3 days'),

  (p19,
   COALESCE(v_family, v_chef),
   CASE WHEN v_family IS NOT NULL THEN 'Familie Weber' ELSE 'Marco Küchenchef' END,
   'Wochenplan für Familien – mein größtes Problem gelöst! 📅
"Was kochen wir heute?" – diese Frage hat mich früher täglich genervt.
Seit ich Foody und Wochenpläne nutze, ist das Geschichte.
30 Minuten am Sonntag planen = entspannte Woche. So einfach!',
   44, 8, NOW() - INTERVAL '6 days'),

  (p20,
   COALESCE(v_family, v_chef),
   CASE WHEN v_family IS NOT NULL THEN 'Familie Weber' ELSE 'Marco Küchenchef' END,
   'Vorrat im Griff mit Foody 🗂️
Endlich kein verschwendetes Essen mehr!
Die App erinnert uns an ablaufende Produkte und schlägt gleich passende Rezepte vor.
Diese Woche haben wir dadurch 3 Mahlzeiten aus Resten gezaubert – Nachhaltigkeit at its best! 🌍',
   71, 16, NOW() - INTERVAL '1 week 1 day');

  RAISE NOTICE '20 Posts eingefügt.';

  -- ── KOMMENTARE ───────────────────────────────────────────────────────────

  INSERT INTO public.social_post_comments (post_id, user_id, author_name, text, created_at)
  VALUES
  -- Kommentare auf Post 1 (Fitness-Bowl)
  (p1, COALESCE(v_veggi,   v_chef), CASE WHEN v_veggi   IS NOT NULL THEN 'Lena Green'     ELSE 'Marco Küchenchef' END, 'Das sieht unglaublich lecker aus! 😍 Welches Sesam-Dressing verwendest du?', NOW() - INTERVAL '1 hour 45 min'),
  (p1, COALESCE(v_fitness, v_chef), CASE WHEN v_fitness IS NOT NULL THEN 'Sara Fit'        ELSE 'Marco Küchenchef' END, 'Perfektes Frühstück! Hast du die Makros schon berechnet?', NOW() - INTERVAL '1 hour 30 min'),
  (p1, v_chef,                       'Marco Küchenchef', '@Lena: Tahini + Zitronensaft + ein bisschen Knoblauch – super einfach! @Sara: ~420 kcal, 18g Protein 💪', NOW() - INTERVAL '1 hour'),

  -- Kommentare auf Post 2 (Sommer-Wochenplan)
  (p2, COALESCE(v_family,  v_chef), CASE WHEN v_family  IS NOT NULL THEN 'Familie Weber'  ELSE 'Marco Küchenchef' END, 'Gerade gespeichert! Genau das was wir für den Sommer gesucht haben 🙏', NOW() - INTERVAL '22 hours'),
  (p2, COALESCE(v_baker,   v_chef), CASE WHEN v_baker   IS NOT NULL THEN 'Thomas Backt'   ELSE 'Marco Küchenchef' END, 'Top Marco! Gibt es auch eine vegane Variante davon?', NOW() - INTERVAL '20 hours'),

  -- Kommentare auf Post 10 (Sauerteigbrot)
  (p10, v_chef,                       'Marco Küchenchef',  'Wahnsinn! 48 Stunden Fermentation – das ist echte Hingabe 🙌 Kannst du das Rezept teilen?', NOW() - INTERVAL '2 hours'),
  (p10, COALESCE(v_veggi,   v_chef), CASE WHEN v_veggi   IS NOT NULL THEN 'Lena Green'     ELSE 'Marco Küchenchef' END, 'Ich versuche seit Wochen mein Sauerteigbrot hinzubekommen – hast du Tipps?', NOW() - INTERVAL '1 hour 30 min'),
  (p10, COALESCE(v_baker,   v_chef), CASE WHEN v_baker   IS NOT NULL THEN 'Thomas Backt'   ELSE 'Marco Küchenchef' END, '@Lena: Der Starter-Teig muss wirklich aktiv sein – fütter ihn jeden Tag! Das ist das Geheimnis 🍞', NOW() - INTERVAL '1 hour'),
  (p10, COALESCE(v_fitness, v_chef), CASE WHEN v_fitness IS NOT NULL THEN 'Sara Fit'        ELSE 'Marco Küchenchef' END, 'Sieht perfekt aus! Wie viele Kalorien hat eine Scheibe ungefähr?', NOW() - INTERVAL '30 min'),

  -- Kommentare auf Post 11 (Zimtschnecken)
  (p11, v_chef,                       'Marco Küchenchef',  'Zimtschnecken sind meine absolute Schwäche 😩 Schick mir bitte das Rezept!', NOW() - INTERVAL '1 day 5 hours'),
  (p11, COALESCE(v_family,  v_chef), CASE WHEN v_family  IS NOT NULL THEN 'Familie Weber'  ELSE 'Marco Küchenchef' END, 'Meine Kinder würden ausrasten wenn ich das backe! 😂 Wie lange hält man die durch?', NOW() - INTERVAL '1 day 4 hours'),

  -- Kommentare auf Post 14 (Post-Workout)
  (p14, v_chef,                       'Marco Küchenchef',  'Solide Makros! Ich koche auch viel mit Süßkartoffel – super für nach dem Sport 💪', NOW() - INTERVAL '4 hours'),
  (p14, COALESCE(v_baker,   v_chef), CASE WHEN v_baker   IS NOT NULL THEN 'Thomas Backt'   ELSE 'Marco Küchenchef' END, 'Ich verstehe nicht wie ihr nach dem Sport noch Hähnchen esst 😅 Ich brauche erstmal Kuchen!', NOW() - INTERVAL '3 hours 30 min'),

  -- Kommentare auf Post 17 (Familienpizza)
  (p17, COALESCE(v_veggi,   v_chef), CASE WHEN v_veggi   IS NOT NULL THEN 'Lena Green'     ELSE 'Marco Küchenchef' END, 'Das klingt wie ein perfekter Sonntag ❤️ So schöne Familienmomente!', NOW() - INTERVAL '1 day 1 hour'),
  (p17, COALESCE(v_baker,   v_chef), CASE WHEN v_baker   IS NOT NULL THEN 'Thomas Backt'   ELSE 'Marco Küchenchef' END, 'Pizza-Abend ist bei uns auch Pflicht! Habt ihr den Teig selbst gemacht?', NOW() - INTERVAL '23 hours'),
  (p17, COALESCE(v_family,  v_chef), CASE WHEN v_family  IS NOT NULL THEN 'Familie Weber'  ELSE 'Marco Küchenchef' END, '@Thomas: Ja klar! Teig selbst machen ist das halbe Vergnügen 🍕', NOW() - INTERVAL '22 hours');

  RAISE NOTICE 'Kommentare eingefügt.';

  -- ── LIKES ────────────────────────────────────────────────────────────────
  -- Gegenseitige Likes zwischen den Usern

  INSERT INTO public.social_post_likes (post_id, user_id)
  VALUES
  -- Likes auf Posts von Marco
  (p1,  COALESCE(v_veggi,   v_chef)),
  (p1,  COALESCE(v_fitness, v_chef)),
  (p2,  COALESCE(v_baker,   v_chef)),
  (p2,  COALESCE(v_family,  v_chef)),
  (p2,  COALESCE(v_fitness, v_chef)),
  (p3,  COALESCE(v_veggi,   v_chef)),
  (p4,  COALESCE(v_family,  v_chef)),
  (p5,  COALESCE(v_baker,   v_chef)),
  -- Likes auf Posts von Lena
  (p6,  v_chef),
  (p6,  COALESCE(v_fitness, v_chef)),
  (p7,  v_chef),
  (p8,  COALESCE(v_family,  v_chef)),
  (p9,  COALESCE(v_baker,   v_chef)),
  -- Likes auf Posts von Thomas
  (p10, v_chef),
  (p10, COALESCE(v_veggi,   v_chef)),
  (p11, COALESCE(v_family,  v_chef)),
  (p11, COALESCE(v_fitness, v_chef)),
  (p12, v_chef),
  (p13, COALESCE(v_veggi,   v_chef)),
  -- Likes auf Posts von Sara
  (p14, v_chef),
  (p14, COALESCE(v_baker,   v_chef)),
  (p15, COALESCE(v_family,  v_chef)),
  (p16, v_chef),
  (p16, COALESCE(v_veggi,   v_chef)),
  -- Likes auf Familien-Posts
  (p17, v_chef),
  (p17, COALESCE(v_veggi,   v_chef)),
  (p17, COALESCE(v_fitness, v_chef)),
  (p18, COALESCE(v_baker,   v_chef)),
  (p19, v_chef),
  (p20, COALESCE(v_fitness, v_chef))
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Likes eingefügt.';
  RAISE NOTICE '✅ Fertig! 20 Posts, Kommentare und Likes erstellt.';

END $$;

