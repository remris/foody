-- ============================================================
-- FOODY – Test-User mit Social-Profil-Daten
-- Legt bis zu 5 Test-User an mit Profilen, Rezepten, Plänen.
-- ⚠️  Nur in Entwicklung / Staging verwenden!
--
-- Vorher im Dashboard anlegen:
--   Authentication → Users → Add user
--   marco@foody.test  / Test1234!
--   lena@foody.test   / Test1234!
--   thomas@foody.test / Test1234!
--   sara@foody.test   / Test1234!
--   family@foody.test / Test1234!
--
-- Dann dieses Script ausführen – fertig!
-- ============================================================

DO $$
DECLARE
  v_chef      UUID;
  v_veggi     UUID;
  v_baker     UUID;
  v_fitness   UUID;
  v_family    UUID;

  v_recipe1   UUID := gen_random_uuid();
  v_recipe2   UUID := gen_random_uuid();
  v_recipe3   UUID := gen_random_uuid();
  v_recipe4   UUID := gen_random_uuid();
  v_recipe5   UUID := gen_random_uuid();
  v_recipe6   UUID := gen_random_uuid();
  v_recipe7   UUID := gen_random_uuid();
  v_recipe8   UUID := gen_random_uuid();

BEGIN
  -- User der Reihe nach holen – NULL wenn nicht vorhanden
  SELECT id INTO v_chef    FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 0;
  SELECT id INTO v_veggi   FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 1;
  SELECT id INTO v_baker   FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 2;
  SELECT id INTO v_fitness FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 3;
  SELECT id INTO v_family  FROM auth.users ORDER BY created_at ASC LIMIT 1 OFFSET 4;

  IF v_chef IS NULL THEN
    RAISE EXCEPTION 'Keine User gefunden! Bitte zuerst Test-User im Dashboard anlegen.';
  END IF;

  RAISE NOTICE 'User gefunden: % % % % %', v_chef, v_veggi, v_baker, v_fitness, v_family;

  -- ── PROFILE ────────────────────────────────────────────────────────────────

  INSERT INTO public.user_profiles (id, display_name, bio, avatar_url, social_links, updated_at)
  VALUES (
    v_chef, 'Marco Küchenchef',
    'Leidenschaftlicher Koch aus München 🍳 Ich liebe italienische und mediterrane Küche.',
    NULL,
    '{"instagram":"@marco_kocht","youtube":"https://youtube.com/@marcokocht","tiktok":"@marcokocht","website":"https://marco-kocht.de"}',
    NOW()
  ) ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name, bio = EXCLUDED.bio,
    social_links = EXCLUDED.social_links, updated_at = NOW();

  IF v_veggi IS NOT NULL THEN
    INSERT INTO public.user_profiles (id, display_name, bio, avatar_url, social_links, updated_at)
    VALUES (
      v_veggi, 'Lena Grünzeug',
      'Vegane Köchin & Food-Bloggerin 🌱 Pflanzliche Küche die wirklich satt macht.',
      NULL,
      '{"instagram":"@lena_vegan","tiktok":"@greenfoodlena","website":"https://lena-vegan.de"}',
      NOW()
    ) ON CONFLICT (id) DO UPDATE SET
      display_name = EXCLUDED.display_name, bio = EXCLUDED.bio,
      social_links = EXCLUDED.social_links, updated_at = NOW();
  END IF;

  IF v_baker IS NOT NULL THEN
    INSERT INTO public.user_profiles (id, display_name, bio, avatar_url, social_links, updated_at)
    VALUES (
      v_baker, 'Thomas Backstube',
      'Bäcker-Meister & Hobbykoch 🥖 Sauerteig, Croissants und alles was aus dem Ofen kommt.',
      NULL,
      '{"instagram":"@thomas_baeckt","youtube":"https://youtube.com/@thomasbackt"}',
      NOW()
    ) ON CONFLICT (id) DO UPDATE SET
      display_name = EXCLUDED.display_name, bio = EXCLUDED.bio,
      social_links = EXCLUDED.social_links, updated_at = NOW();
  END IF;

  IF v_fitness IS NOT NULL THEN
    INSERT INTO public.user_profiles (id, display_name, bio, avatar_url, social_links, updated_at)
    VALUES (
      v_fitness, 'Sara FitFood',
      'Personal Trainerin & Meal-Prep Queen 💪 Gesunde Rezepte die schnell gehen.',
      NULL,
      '{"instagram":"@sara_fitfood","tiktok":"@sarafitfood"}',
      NOW()
    ) ON CONFLICT (id) DO UPDATE SET
      display_name = EXCLUDED.display_name, bio = EXCLUDED.bio,
      social_links = EXCLUDED.social_links, updated_at = NOW();
  END IF;

  IF v_family IS NOT NULL THEN
    INSERT INTO public.user_profiles (id, display_name, bio, avatar_url, social_links, updated_at)
    VALUES (
      v_family, 'Familie Müller',
      'Kochen für die ganze Familie 👨‍👩‍👧‍👦 Alltagstauglich & budgetfreundlich.',
      NULL,
      '{"instagram":"@familie_isst"}',
      NOW()
    ) ON CONFLICT (id) DO UPDATE SET
      display_name = EXCLUDED.display_name, bio = EXCLUDED.bio,
      social_links = EXCLUDED.social_links, updated_at = NOW();
  END IF;

  -- ── REZEPTE (Marco) ────────────────────────────────────────────────────────

  INSERT INTO public.community_recipes (
    id, user_id, author_name, title, description, category, tags, difficulty,
    cooking_time_minutes, servings, recipe_json, is_published, avg_rating, rating_count, view_count
  ) VALUES
  (
    v_recipe1, v_chef, 'Marco Küchenchef', 'Echte Pasta Carbonara',
    'Das Original aus Rom – ohne Sahne, nur Ei, Pecorino und Guanciale.',
    'Abendessen', ARRAY['Pasta','Italienisch','Klassiker','Schnell'], 'Mittel', 25, 2,
    '{"ingredients":[{"name":"Spaghetti","amount":"200g"},{"name":"Guanciale","amount":"100g"},{"name":"Pecorino Romano","amount":"60g"},{"name":"Eier","amount":"2+2 Eigelb"},{"name":"Schwarzer Pfeffer","amount":"reichlich"}],"steps":["Nudelwasser salzen, Spaghetti al dente kochen.","Guanciale ohne Öl knusprig braten, Pfanne vom Herd.","Eier + Eigelb mit Pecorino und Pfeffer verquirlen.","Nudeln zum Guanciale, Ei-Mix unterheben, mit Kochwasser cremig rühren.","Sofort mit extra Pecorino servieren."]}'::jsonb,
    true, 4.7, 23, 412
  ),
  (
    v_recipe2, v_chef, 'Marco Küchenchef', 'Tiramisu – Das Original',
    'Omas Rezept aus Venetien. Echter Mascarpone, frischer Espresso, kein Ersatz.',
    'Dessert', ARRAY['Dessert','Italienisch','No-Bake','Klassiker'], 'Einfach', 30, 6,
    '{"ingredients":[{"name":"Mascarpone","amount":"500g"},{"name":"Eier","amount":"4"},{"name":"Zucker","amount":"100g"},{"name":"Espresso","amount":"300ml"},{"name":"Amaretto","amount":"4 EL"},{"name":"Löffelbiskuits","amount":"200g"},{"name":"Kakao","amount":"zum Bestäuben"}],"steps":["Eigelb mit Zucker cremig schlagen.","Mascarpone unterheben, Eiweiß steif schlagen und unterheben.","Biskuits kurz in Espresso-Amaretto tauchen.","Schichten: Biskuits, Creme, Biskuits, Creme – 4h kühlen.","Mit Kakao bestäuben und servieren."]}'::jsonb,
    true, 4.9, 41, 638
  )
  ON CONFLICT (id) DO NOTHING;

  -- ── REZEPTE (Lena) ─────────────────────────────────────────────────────────

  IF v_veggi IS NOT NULL THEN
    INSERT INTO public.community_recipes (
      id, user_id, author_name, title, description, category, tags, difficulty,
      cooking_time_minutes, servings, recipe_json, is_published, avg_rating, rating_count, view_count
    ) VALUES
    (
      v_recipe3, v_veggi, 'Lena Grünzeug', 'Rainbow Buddha Bowl',
      'Bunt, gesund und sättigend! Protein, Fette und Vitamine in einer Schüssel.',
      'Mittagessen', ARRAY['Vegan','Gesund','Bowl','Schnell','Meal Prep'], 'Einfach', 20, 2,
      '{"ingredients":[{"name":"Kichererbsen","amount":"1 Dose"},{"name":"Quinoa","amount":"150g"},{"name":"Avocado","amount":"1"},{"name":"Spinat","amount":"100g"},{"name":"Tahini","amount":"3 EL"},{"name":"Zitrone","amount":"1"}],"steps":["Quinoa kochen.","Kichererbsen rösten.","Tahini-Dressing anrühren.","Alles anrichten.","Mit Dressing beträufeln."]}'::jsonb,
      true, 4.5, 18, 287
    ),
    (
      v_recipe4, v_veggi, 'Lena Grünzeug', 'Rote Linsensuppe mit Kokosmilch',
      'Wärmend, cremig und in 30 Minuten fertig. Perfekt fürs Meal-Prep.',
      'Mittagessen', ARRAY['Vegan','Suppe','Meal Prep','Günstig'], 'Einfach', 30, 4,
      '{"ingredients":[{"name":"Rote Linsen","amount":"300g"},{"name":"Kokosmilch","amount":"400ml"},{"name":"Gemüsebrühe","amount":"800ml"},{"name":"Zwiebel","amount":"1"},{"name":"Ingwer","amount":"2cm"},{"name":"Kreuzkümmel","amount":"2 TL"},{"name":"Kurkuma","amount":"1 TL"}],"steps":["Zwiebel und Ingwer anschwitzen.","Gewürze rösten.","Linsen und Brühe zugeben, 20 Min köcheln.","Kokosmilch einrühren, teilweise pürieren.","Abschmecken."]}'::jsonb,
      true, 4.6, 32, 445
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- ── REZEPTE (Thomas) ───────────────────────────────────────────────────────

  IF v_baker IS NOT NULL THEN
    INSERT INTO public.community_recipes (
      id, user_id, author_name, title, description, category, tags, difficulty,
      cooking_time_minutes, servings, recipe_json, is_published, avg_rating, rating_count, view_count
    ) VALUES (
      v_recipe5, v_baker, 'Thomas Backstube', 'Echtes Sauerteigbrot',
      'Knackige Kruste, luftige Krume. Mein Lieblingsrezept.',
      'Backen', ARRAY['Backen','Brot','Sauerteig','Vegan'], 'Schwer', 60, 1,
      '{"ingredients":[{"name":"Weizenmehl 550","amount":"400g"},{"name":"Roggenmehl","amount":"100g"},{"name":"Wasser","amount":"350ml"},{"name":"Sauerteig-Starter","amount":"100g"},{"name":"Salz","amount":"10g"}],"steps":["Alles vermengen, 30 Min ruhen.","4x dehnen und falten alle 30 Min.","Über Nacht im Kühlschrank.","Formen, 1h akklimatisieren.","250°C: 20 Min mit Deckel, 25 Min ohne."]}'::jsonb,
      true, 4.8, 56, 892
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- ── REZEPTE (Sara) ─────────────────────────────────────────────────────────

  IF v_fitness IS NOT NULL THEN
    INSERT INTO public.community_recipes (
      id, user_id, author_name, title, description, category, tags, difficulty,
      cooking_time_minutes, servings, recipe_json, is_published, avg_rating, rating_count, view_count
    ) VALUES (
      v_recipe6, v_fitness, 'Sara FitFood', 'High-Protein Hähnchen-Meal-Prep',
      '45g Protein pro Portion, minimaler Aufwand. Meine wöchentliche Basis.',
      'Mittagessen', ARRAY['High Protein','Meal Prep','Gesund','Low Carb'], 'Einfach', 35, 4,
      '{"ingredients":[{"name":"Hähnchenbrust","amount":"800g"},{"name":"Brokkoli","amount":"500g"},{"name":"Süßkartoffeln","amount":"600g"},{"name":"Paprikapulver","amount":"2 TL"},{"name":"Knoblauchpulver","amount":"1 TL"}],"steps":["Hähnchen würzen.","Süßkartoffeln auf Blech.","200°C: Hähnchen 25 Min, Gemüse 30 Min.","In 4 Boxen aufteilen."]}'::jsonb,
      true, 4.4, 28, 503
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- ── REZEPTE (Familie) ──────────────────────────────────────────────────────

  IF v_family IS NOT NULL THEN
    INSERT INTO public.community_recipes (
      id, user_id, author_name, title, description, category, tags, difficulty,
      cooking_time_minutes, servings, recipe_json, is_published, avg_rating, rating_count, view_count
    ) VALUES
    (
      v_recipe7, v_family, 'Familie Müller', 'Familien-Bolognese für 4 Personen',
      'Unser Sonntagsklassiker. Langsam geschmort, die Kinder lieben es.',
      'Abendessen', ARRAY['Pasta','Familie','Klassiker','Für Kinder'], 'Mittel', 90, 4,
      '{"ingredients":[{"name":"Rinderhack","amount":"500g"},{"name":"Spaghetti","amount":"400g"},{"name":"Tomaten Dose","amount":"2x400g"},{"name":"Zwiebel","amount":"2"},{"name":"Karotte","amount":"2"},{"name":"Rotwein","amount":"150ml"}],"steps":["Soffritto 10 Min anschwitzen.","Hack braten.","Rotwein ablöschen, Tomaten zugeben.","60 Min schmoren.","Mit Parmesan servieren."]}'::jsonb,
      true, 4.6, 19, 334
    ),
    (
      v_recipe8, v_family, 'Familie Müller', 'Fluffige Sonntags-Pfannkuchen',
      'Unser Sonntagmorgen-Ritual. Einfach, günstig, alle sind glücklich.',
      'Frühstück', ARRAY['Frühstück','Familie','Für Kinder','Schnell'], 'Einfach', 20, 4,
      '{"ingredients":[{"name":"Mehl","amount":"200g"},{"name":"Milch","amount":"300ml"},{"name":"Eier","amount":"2"},{"name":"Butter","amount":"20g"},{"name":"Zucker","amount":"1 EL"}],"steps":["Teig glatt rühren, 10 Min ruhen.","Butter erhitzen.","Goldbraun backen.","Mit Ahornsirup servieren."]}'::jsonb,
      true, 4.3, 12, 198
    )
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- ── WOCHENPLÄNE ────────────────────────────────────────────────────────────

  INSERT INTO public.community_meal_plans (user_id, author_name, title, description, tags, plan_json, is_published)
  VALUES (
    v_chef, 'Marco Küchenchef', 'Mediterrane Woche 🌊',
    'Eine Woche voller Mittelmeer-Aromen.',
    ARRAY['Mediterran','Leicht','Sommer'],
    '[{"day":"Mo","mealType":"Abendessen","recipeTitle":"Pasta Carbonara"},{"day":"Di","mealType":"Mittagessen","recipeTitle":"Griechischer Salat"},{"day":"Mi","mealType":"Abendessen","recipeTitle":"Gegrillter Fisch"},{"day":"Do","mealType":"Mittagessen","recipeTitle":"Hummus mit Fladenbrot"},{"day":"Fr","mealType":"Abendessen","recipeTitle":"Pizza Margherita"},{"day":"Sa","mealType":"Abendessen","recipeTitle":"Meeresfrüchte-Risotto"},{"day":"So","mealType":"Abendessen","recipeTitle":"Tiramisu"}]'::jsonb,
    true
  );

  IF v_veggi IS NOT NULL THEN
    INSERT INTO public.community_meal_plans (user_id, author_name, title, description, tags, plan_json, is_published)
    VALUES (
      v_veggi, 'Lena Grünzeug', 'Vegane Power-Woche 🌱',
      'Pflanzlich, sättigend und voller Farben.',
      ARRAY['Vegan','Gesund','High Protein'],
      '[{"day":"Mo","mealType":"Mittagessen","recipeTitle":"Rainbow Buddha Bowl"},{"day":"Di","mealType":"Mittagessen","recipeTitle":"Rote Linsensuppe"},{"day":"Mi","mealType":"Abendessen","recipeTitle":"Tofu-Curry"},{"day":"Do","mealType":"Mittagessen","recipeTitle":"Quinoa-Salat"},{"day":"Fr","mealType":"Abendessen","recipeTitle":"Vegane Pasta"},{"day":"Sa","mealType":"Abendessen","recipeTitle":"Jackfruit-Tacos"},{"day":"So","mealType":"Mittagessen","recipeTitle":"Gemüse-Paella"}]'::jsonb,
      true
    );
  END IF;

  IF v_fitness IS NOT NULL THEN
    INSERT INTO public.community_meal_plans (user_id, author_name, title, description, tags, plan_json, is_published)
    VALUES (
      v_fitness, 'Sara FitFood', 'Fitness Meal-Prep Woche 💪',
      'Hoher Proteingehalt, ausgewogene Makros, wenig Aufwand.',
      ARRAY['High Protein','Meal Prep','Fitness','Low Carb'],
      '[{"day":"Mo","mealType":"Frühstück","recipeTitle":"Protein-Porridge"},{"day":"Mo","mealType":"Mittagessen","recipeTitle":"Hähnchen-Meal-Prep"},{"day":"Di","mealType":"Mittagessen","recipeTitle":"Thunfisch-Salat"},{"day":"Mi","mealType":"Abendessen","recipeTitle":"Lachs mit Gemüse"},{"day":"Do","mealType":"Mittagessen","recipeTitle":"Hähnchen-Meal-Prep"},{"day":"Fr","mealType":"Abendessen","recipeTitle":"Turkey-Bowl"},{"day":"So","mealType":"Abendessen","recipeTitle":"Steak mit Süßkartoffel"}]'::jsonb,
      true
    );
  END IF;

  IF v_family IS NOT NULL THEN
    INSERT INTO public.community_meal_plans (user_id, author_name, title, description, tags, plan_json, is_published)
    VALUES (
      v_family, 'Familie Müller', 'Familienplan für die ganze Woche 👨‍👩‍👧‍👦',
      'Alltagstauglich, budgetfreundlich, alle mögen es.',
      ARRAY['Familie','Günstig','Für Kinder'],
      '[{"day":"Mo","mealType":"Abendessen","recipeTitle":"Spaghetti Bolognese"},{"day":"Di","mealType":"Abendessen","recipeTitle":"Hähnchen-Nuggets"},{"day":"Mi","mealType":"Abendessen","recipeTitle":"Gemüsesuppe"},{"day":"Do","mealType":"Abendessen","recipeTitle":"Pizza selbst gemacht"},{"day":"Fr","mealType":"Abendessen","recipeTitle":"Fischstäbchen"},{"day":"Sa","mealType":"Frühstück","recipeTitle":"Sonntags-Pfannkuchen"},{"day":"So","mealType":"Mittagessen","recipeTitle":"Sonntagsbraten"}]'::jsonb,
      true
    );
  END IF;

  -- ── FOLLOWS ────────────────────────────────────────────────────────────────

  IF v_veggi IS NOT NULL THEN
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_veggi,   v_chef)    ON CONFLICT DO NOTHING;
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_chef,    v_veggi)   ON CONFLICT DO NOTHING;
  END IF;
  IF v_baker IS NOT NULL THEN
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_baker,   v_chef)    ON CONFLICT DO NOTHING;
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_chef,    v_baker)   ON CONFLICT DO NOTHING;
  END IF;
  IF v_fitness IS NOT NULL THEN
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_fitness, v_chef)    ON CONFLICT DO NOTHING;
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_chef,    v_fitness) ON CONFLICT DO NOTHING;
  END IF;
  IF v_family IS NOT NULL THEN
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_family,  v_chef)    ON CONFLICT DO NOTHING;
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_chef,    v_family)  ON CONFLICT DO NOTHING;
  END IF;
  IF v_veggi IS NOT NULL AND v_fitness IS NOT NULL THEN
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_veggi,   v_fitness) ON CONFLICT DO NOTHING;
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_fitness, v_veggi)   ON CONFLICT DO NOTHING;
  END IF;
  IF v_baker IS NOT NULL AND v_veggi IS NOT NULL THEN
    INSERT INTO public.user_follows (follower_id, followee_id) VALUES (v_baker,   v_veggi)   ON CONFLICT DO NOTHING;
  END IF;

  -- ── LIKES ──────────────────────────────────────────────────────────────────

  IF v_veggi IS NOT NULL THEN
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe1, v_veggi)   ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe2, v_veggi)   ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe3, v_chef)    ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe4, v_chef)    ON CONFLICT DO NOTHING;
  END IF;
  IF v_baker IS NOT NULL THEN
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe1, v_baker)   ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe5, v_chef)    ON CONFLICT DO NOTHING;
  END IF;
  IF v_fitness IS NOT NULL THEN
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe1, v_fitness) ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe6, v_chef)    ON CONFLICT DO NOTHING;
  END IF;
  IF v_family IS NOT NULL THEN
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe2, v_family)  ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_likes (recipe_id, user_id) VALUES (v_recipe7, v_chef)    ON CONFLICT DO NOTHING;
  END IF;

  -- ── BEWERTUNGEN ────────────────────────────────────────────────────────────

  IF v_veggi IS NOT NULL THEN
    INSERT INTO public.recipe_ratings (recipe_id, user_id, stars) VALUES (v_recipe1, v_veggi,   5) ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_ratings (recipe_id, user_id, stars) VALUES (v_recipe3, v_chef,    4) ON CONFLICT DO NOTHING;
  END IF;
  IF v_baker IS NOT NULL THEN
    INSERT INTO public.recipe_ratings (recipe_id, user_id, stars) VALUES (v_recipe1, v_baker,   4) ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_ratings (recipe_id, user_id, stars) VALUES (v_recipe5, v_chef,    5) ON CONFLICT DO NOTHING;
  END IF;
  IF v_fitness IS NOT NULL THEN
    INSERT INTO public.recipe_ratings (recipe_id, user_id, stars) VALUES (v_recipe1, v_fitness, 5) ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_ratings (recipe_id, user_id, stars) VALUES (v_recipe6, v_chef,    4) ON CONFLICT DO NOTHING;
  END IF;
  IF v_family IS NOT NULL THEN
    INSERT INTO public.recipe_ratings (recipe_id, user_id, stars) VALUES (v_recipe2, v_family,  5) ON CONFLICT DO NOTHING;
    INSERT INTO public.recipe_ratings (recipe_id, user_id, stars) VALUES (v_recipe7, v_chef,    5) ON CONFLICT DO NOTHING;
  END IF;

  RAISE NOTICE '✅ Fertig! User angelegt: %', (
    CASE WHEN v_chef    IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN v_veggi   IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN v_baker   IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN v_fitness IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN v_family  IS NOT NULL THEN 1 ELSE 0 END
  );

END;
$$;

-- ── Ergebnis prüfen ────────────────────────────────────────────────────────────
SELECT
  up.display_name,
  (SELECT COUNT(*) FROM public.community_recipes  cr WHERE cr.user_id = up.id) AS rezepte,
  (SELECT COUNT(*) FROM public.user_follows       uf WHERE uf.followee_id = up.id) AS follower
FROM public.user_profiles up
ORDER BY rezepte DESC;
