-- ============================================================
-- FOODY – Erweitertes Testdaten / Seed-Script v2
-- ============================================================
-- 5 Dummy-User, 15 Rezepte, 5 Wochenpläne, Follow-Netzwerk
-- Korrekte Tabellennamen gemäß Migrations 05, 08, 10, 14
-- ============================================================

DO $$
DECLARE
  uid_marco   UUID := 'aaaaaaaa-1111-1111-1111-000000000001';
  uid_lena    UUID := 'bbbbbbbb-2222-2222-2222-000000000002';
  uid_thomas  UUID := 'cccccccc-3333-3333-3333-000000000003';
  uid_sara    UUID := 'dddddddd-4444-4444-4444-000000000004';
  uid_felix   UUID := 'eeeeeeee-5555-5555-5555-000000000005';

  r01 UUID := gen_random_uuid(); r02 UUID := gen_random_uuid();
  r03 UUID := gen_random_uuid(); r04 UUID := gen_random_uuid();
  r05 UUID := gen_random_uuid(); r06 UUID := gen_random_uuid();
  r07 UUID := gen_random_uuid(); r08 UUID := gen_random_uuid();
  r09 UUID := gen_random_uuid(); r10 UUID := gen_random_uuid();
  r11 UUID := gen_random_uuid(); r12 UUID := gen_random_uuid();
  r13 UUID := gen_random_uuid(); r14 UUID := gen_random_uuid();
  r15 UUID := gen_random_uuid();

  mp1 UUID := gen_random_uuid(); mp2 UUID := gen_random_uuid();
  mp3 UUID := gen_random_uuid(); mp4 UUID := gen_random_uuid();
  mp5 UUID := gen_random_uuid();

BEGIN

  -- ── 1. AUTH USERS ─────────────────────────────────────────────────────────
  INSERT INTO auth.users (id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_super_admin)
  VALUES
    (uid_marco,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
     'marco@foody-test.de',crypt('Test1234!',gen_salt('bf')),now(),now(),now(),
     '{"provider":"email"}','{}',false),
    (uid_lena,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
     'lena@foody-test.de',crypt('Test1234!',gen_salt('bf')),now(),now(),now(),
     '{"provider":"email"}','{}',false),
    (uid_thomas,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
     'thomas@foody-test.de',crypt('Test1234!',gen_salt('bf')),now(),now(),now(),
     '{"provider":"email"}','{}',false),
    (uid_sara,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
     'sara@foody-test.de',crypt('Test1234!',gen_salt('bf')),now(),now(),now(),
     '{"provider":"email"}','{}',false),
    (uid_felix,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',
     'felix@foody-test.de',crypt('Test1234!',gen_salt('bf')),now(),now(),now(),
     '{"provider":"email"}','{}',false)
  ON CONFLICT (id) DO NOTHING;

  -- ── 2. USER PROFILES (Trigger legt ggf. schon leere an → UPDATE) ──────────
  INSERT INTO public.user_profiles (id, display_name, bio, avatar_url, social_links, updated_at)
  VALUES
    (uid_marco,'Marco Küchenchef',
     'Leidenschaftlicher Koch aus München 🍳 Liebe italienische und mediterrane Küche.',
     NULL,'{"instagram":"@marco_kocht","youtube":"https://youtube.com/@marcokocht","website":"https://marco-kocht.de"}',now()),
    (uid_lena,'Lena Grünzeug',
     'Vegane Köchin & Food-Bloggerin 🌱 Pflanzliche Küche die begeistert.',
     NULL,'{"instagram":"@lena_vegan","tiktok":"@greenfoodlena","website":"https://lena-vegan.de"}',now()),
    (uid_thomas,'Thomas Backstube',
     'Bäcker-Meister & Hobbykoch 🥖 Sauerteig, Croissants und alles aus dem Ofen.',
     NULL,'{"instagram":"@thomas_bäckt","youtube":"https://youtube.com/@thomasbackt"}',now()),
    (uid_sara,'Sara FitFood',
     'Personal Trainerin & Meal-Prep Queen 💪 Gesunde Rezepte die schnell gehen.',
     NULL,'{"instagram":"@sara_fitfood","tiktok":"@sarafitfood"}',now()),
    (uid_felix,'Felix Weltküche',
     'Auf Weltreise durch Töpfe & Pfannen 🌍 Asiatisch, mexikanisch, arabisch.',
     NULL,'{"instagram":"@felix_weltküche","tiktok":"@felixcooks"}',now())
  ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    bio          = EXCLUDED.bio,
    social_links = EXCLUDED.social_links,
    updated_at   = now();

  -- ── 3. FOLLOWS ────────────────────────────────────────────────────────────
  INSERT INTO public.user_follows (follower_id, followee_id)
  VALUES
    (uid_lena,uid_marco),(uid_thomas,uid_marco),(uid_sara,uid_marco),(uid_felix,uid_marco),
    (uid_marco,uid_lena),(uid_thomas,uid_lena),(uid_felix,uid_lena),
    (uid_marco,uid_thomas),(uid_sara,uid_thomas),
    (uid_marco,uid_sara),(uid_lena,uid_sara),(uid_felix,uid_sara),
    (uid_marco,uid_felix),(uid_lena,uid_felix),(uid_thomas,uid_felix)
  ON CONFLICT DO NOTHING;

  -- ── 4. COMMUNITY REZEPTE ─────────────────────────────────────────────────
  -- Spalten: id, user_id, author_name, title, description, category, tags,
  --          difficulty, cooking_time_minutes, servings, recipe_json,
  --          is_published, avg_rating, rating_count, view_count, created_at
  -- (avg_rating + rating_count via Migration 10 hinzugefügt)
  INSERT INTO public.community_recipes (
    id, user_id, author_name, title, description, category, tags,
    difficulty, cooking_time_minutes, servings,
    recipe_json, is_published, avg_rating, rating_count, view_count, created_at
  ) VALUES
  (r01,uid_marco,'Marco Küchenchef','Echte Pasta Carbonara',
   'Das Original aus Rom – ohne Sahne, nur Ei, Pecorino und Guanciale.',
   'Abendessen',ARRAY['Pasta','Italienisch','Klassiker','Schnell'],'Mittel',25,2,
   '{"ingredients":[{"name":"Spaghetti","amount":"200g"},{"name":"Guanciale","amount":"100g"},{"name":"Pecorino Romano","amount":"60g"},{"name":"Eier","amount":"2 + 2 Eigelb"},{"name":"Schwarzer Pfeffer","amount":"reichlich"}],"steps":["Nudelwasser salzen, Spaghetti al dente kochen.","Guanciale ohne Öl knusprig braten.","Eier + Eigelb mit Pecorino und Pfeffer verquirlen.","Nudeln zum Guanciale, Ei-Mix unterheben mit Kochwasser cremig rühren.","Sofort mit extra Pecorino servieren."]}'::jsonb,
   true,4.7,23,412,now()-interval '5 days'),

  (r02,uid_marco,'Marco Küchenchef','Risotto ai Funghi',
   'Cremiges Pilzrisotto nach klassischer Art – geduldig gerührt.',
   'Abendessen',ARRAY['Risotto','Italienisch','Vegetarisch','Pilze'],'Mittel',40,4,
   '{"ingredients":[{"name":"Risottoreis","amount":"320g"},{"name":"Gemischte Pilze","amount":"400g"},{"name":"Parmesan","amount":"80g"},{"name":"Zwiebel","amount":"1"},{"name":"Weißwein","amount":"100ml"},{"name":"Gemüsebrühe","amount":"1L"}],"steps":["Brühe warm halten.","Zwiebel anschwitzen, Reis glasig rösten.","Mit Wein ablöschen.","Kellenweise heiße Brühe zugeben, stets rühren.","Pilze separat braten und untermengen.","Mit Parmesan und Butter verfeinern."]}'::jsonb,
   true,4.5,18,287,now()-interval '3 days'),

  (r03,uid_marco,'Marco Küchenchef','Tiramisu – Das Original',
   'Omas Rezept aus Venetien. Echter Mascarpone, frischer Espresso.',
   'Dessert',ARRAY['Dessert','Italienisch','No-Bake','Klassiker'],'Einfach',30,6,
   '{"ingredients":[{"name":"Mascarpone","amount":"500g"},{"name":"Eier","amount":"4"},{"name":"Zucker","amount":"100g"},{"name":"Espresso","amount":"300ml"},{"name":"Amaretto","amount":"4 EL"},{"name":"Löffelbiskuits","amount":"200g"}],"steps":["Eigelb mit Zucker cremig schlagen.","Mascarpone unterheben, Eiweiß steif schlagen und unterheben.","Biskuits kurz in Espresso-Amaretto tauchen.","Schichten: Biskuits, Creme, Biskuits, Creme – 4h kühlen.","Mit Kakao bestäuben."]}'::jsonb,
   true,4.9,41,638,now()-interval '8 days'),

  (r04,uid_lena,'Lena Grünzeug','Buddha Bowl mit Tahini',
   'Bunte Bowl mit geröstetem Gemüse, Kichererbsen und cremigem Tahini-Dressing.',
   'Mittagessen',ARRAY['Vegan','Gesund','Bowl','Meal-Prep'],'Einfach',30,2,
   '{"ingredients":[{"name":"Kichererbsen","amount":"400g"},{"name":"Süßkartoffel","amount":"2"},{"name":"Brokkoli","amount":"300g"},{"name":"Quinoa","amount":"150g"},{"name":"Tahini","amount":"3 EL"},{"name":"Zitrone","amount":"1"}],"steps":["Ofen auf 200°C vorheizen.","Kichererbsen und Gemüse mit Öl und Gewürzen mischen.","30 Min rösten bis knusprig.","Quinoa kochen.","Tahini mit Zitrone und Wasser zur Sauce rühren.","Bowl zusammenstellen."]}'::jsonb,
   true,4.6,31,521,now()-interval '2 days'),

  (r05,uid_lena,'Lena Grünzeug','Vegane Bolognese',
   'Herzhafte Bolognese mit Linsen und Walnüssen.',
   'Abendessen',ARRAY['Vegan','Pasta','Linsen','Herzhaft'],'Einfach',45,4,
   '{"ingredients":[{"name":"Rote Linsen","amount":"200g"},{"name":"Walnüsse","amount":"100g"},{"name":"Passierte Tomaten","amount":"800g"},{"name":"Karotten","amount":"2"},{"name":"Sellerie","amount":"2 Stangen"},{"name":"Rotwein","amount":"100ml"},{"name":"Spaghetti","amount":"400g"}],"steps":["Walnüsse hacken und rösten.","Karotten und Sellerie anbraten.","Linsen und Wein zugeben.","Tomaten dazu, 30 Min köcheln.","Walnüsse unterrühren, mit Spaghetti servieren."]}'::jsonb,
   true,4.4,27,398,now()-interval '1 day'),

  (r06,uid_lena,'Lena Grünzeug','Overnight Oats Mango-Kokos',
   'Das perfekte Frühstück – am Abend zubereitet, morgens fertig.',
   'Frühstück',ARRAY['Vegan','Frühstück','Meal-Prep','Schnell'],'Einfach',5,1,
   '{"ingredients":[{"name":"Haferflocken","amount":"80g"},{"name":"Kokosmilch","amount":"200ml"},{"name":"Mango","amount":"1"},{"name":"Chiasamen","amount":"1 EL"},{"name":"Agavensirup","amount":"1 TL"}],"steps":["Haferflocken mit Kokosmilch und Chiasamen vermengen.","Mit Agavensirup süßen.","Über Nacht im Kühlschrank quellen lassen.","Morgens mit Mango-Würfeln toppen."]}'::jsonb,
   true,4.3,15,203,now()-interval '4 hours'),

  (r07,uid_thomas,'Thomas Backstube','Sauerteigbrot',
   'Knuspriges Sauerteigbrot mit langer Fermentation.',
   'Brot',ARRAY['Backen','Sauerteig','Brot','Aufwändig'],'Schwer',60,8,
   '{"ingredients":[{"name":"Weizenmehl 550","amount":"500g"},{"name":"Wasser","amount":"375ml"},{"name":"Sauerteig-Starter","amount":"100g"},{"name":"Salz","amount":"10g"}],"steps":["Mehl und Wasser vermischen (Autolyse 30 Min).","Starter und Salz einarbeiten.","4x Stretch & Fold alle 30 Min.","8-16h kalt gehen lassen.","Auf 250°C im Topf backen (20 Min mit Deckel, 20 Min ohne)."]}'::jsonb,
   true,4.8,34,567,now()-interval '6 days'),

  (r08,uid_thomas,'Thomas Backstube','Flammkuchen Elsässer Art',
   'Hauchdünner Teig mit Schmand, Zwiebeln und Speck.',
   'Abendessen',ARRAY['Flammkuchen','Schnell','Elsässisch','Herzhaft'],'Einfach',20,4,
   '{"ingredients":[{"name":"Flammkuchenteig","amount":"1 Rolle"},{"name":"Schmand","amount":"200g"},{"name":"Zwiebeln","amount":"2"},{"name":"Speck","amount":"150g"},{"name":"Muskat","amount":"Prise"}],"steps":["Ofen auf 250°C vorheizen.","Teig ausrollen, mit Schmand bestreichen.","Zwiebeln und Speck verteilen.","10-12 Min backen bis Rand kross ist.","Sofort servieren."]}'::jsonb,
   true,4.5,22,344,now()-interval '2 days'),

  (r09,uid_sara,'Sara FitFood','Chicken Meal Prep Bowls',
   'Proteinreiche Bowls für die ganze Woche.',
   'Mittagessen',ARRAY['Meal-Prep','Protein','Gesund','Hühnchen'],'Einfach',40,5,
   '{"ingredients":[{"name":"Hühnerbrust","amount":"1kg"},{"name":"Brokkoli","amount":"500g"},{"name":"Süßkartoffel","amount":"600g"},{"name":"Brauner Reis","amount":"400g"},{"name":"Olivenöl","amount":"4 EL"},{"name":"Paprikapulver","amount":"2 TL"}],"steps":["Ofen 200°C vorheizen.","Hühnerbrust würzen und braten.","Gemüse rösten.","Reis kochen.","In 5 Meal-Prep-Boxen aufteilen."]}'::jsonb,
   true,4.7,38,612,now()-interval '3 days'),

  (r10,uid_sara,'Sara FitFood','Protein Pancakes',
   'Fluffige Pancakes mit extra Protein – perfekt nach dem Training.',
   'Frühstück',ARRAY['Proteinreich','Frühstück','Fitness','Schnell'],'Einfach',15,2,
   '{"ingredients":[{"name":"Magerquark","amount":"250g"},{"name":"Eier","amount":"2"},{"name":"Proteinpulver Vanille","amount":"30g"},{"name":"Haferflocken","amount":"50g"},{"name":"Backpulver","amount":"1 TL"},{"name":"Banane","amount":"1"}],"steps":["Alle Zutaten zu einem glatten Teig mixen.","Kleine Portionen in Pfanne geben.","Von beiden Seiten goldbraun backen.","Mit Beeren und Ahornsirup servieren."]}'::jsonb,
   true,4.4,19,289,now()-interval '5 hours'),

  (r11,uid_sara,'Sara FitFood','Quinoa Power Salad',
   'Nährstoffbombe mit Quinoa, Avocado und vielen Vitaminen.',
   'Mittagessen',ARRAY['Vegan','Salat','Quinoa','Gesund'],'Einfach',20,2,
   '{"ingredients":[{"name":"Quinoa","amount":"150g"},{"name":"Avocado","amount":"2"},{"name":"Kirschtomaten","amount":"200g"},{"name":"Gurke","amount":"1"},{"name":"Feta","amount":"100g"},{"name":"Limettensaft","amount":"2 EL"}],"steps":["Quinoa kochen und abkühlen lassen.","Gemüse würfeln, Avocado in Stücke schneiden.","Alles vermengen mit Limette und Olivenöl.","Feta darüber krümeln."]}'::jsonb,
   true,4.2,14,178,now()-interval '7 hours'),

  (r12,uid_felix,'Felix Weltküche','Pad Thai Original',
   'Authentisches Pad Thai wie aus Bangkok.',
   'Abendessen',ARRAY['Asiatisch','Thai','Nudeln','Schnell'],'Mittel',25,2,
   '{"ingredients":[{"name":"Reisnudeln","amount":"200g"},{"name":"Garnelen","amount":"250g"},{"name":"Tofu","amount":"100g"},{"name":"Ei","amount":"2"},{"name":"Tamarindenpaste","amount":"3 EL"},{"name":"Fischsauce","amount":"2 EL"},{"name":"Erdnüsse","amount":"50g"},{"name":"Sojasprossen","amount":"100g"}],"steps":["Nudeln einweichen bis weich.","Wok stark erhitzen, Garnelen und Tofu anbraten.","Nudeln zugeben, Ei aufschlagen.","Tamarinde und Fischsauce zugeben.","Mit Sprossen und Erdnüssen servieren."]}'::jsonb,
   true,4.8,29,487,now()-interval '1 day'),

  (r13,uid_felix,'Felix Weltküche','Shakshuka',
   'Orientalische Eier in Tomatensauce.',
   'Frühstück',ARRAY['Orientalisch','Eier','Vegetarisch','Schnell'],'Einfach',20,2,
   '{"ingredients":[{"name":"Eier","amount":"4"},{"name":"Tomaten (Dose)","amount":"800g"},{"name":"Paprika rot","amount":"2"},{"name":"Zwiebel","amount":"1"},{"name":"Kreuzkümmel","amount":"2 TL"},{"name":"Feta","amount":"100g"}],"steps":["Zwiebeln und Paprika anschwitzen.","Gewürze zugeben.","Tomaten dazu, 10 Min köcheln.","Mulden formen, Eier hineinschlagen.","5-8 Min abgedeckt stocken lassen.","Mit Feta servieren."]}'::jsonb,
   true,4.6,25,395,now()-interval '12 hours'),

  (r14,uid_felix,'Felix Weltküche','Kimchi Fried Rice',
   'Koreanischer Klassiker mit fermentiertem Kimchi.',
   'Abendessen',ARRAY['Koreanisch','Reis','Fermentiert','Schnell'],'Einfach',15,2,
   '{"ingredients":[{"name":"Gekochter Reis","amount":"300g"},{"name":"Kimchi","amount":"150g"},{"name":"Ei","amount":"2"},{"name":"Speck oder Tofu","amount":"100g"},{"name":"Sesamöl","amount":"1 EL"},{"name":"Gochujang","amount":"1 TL"},{"name":"Frühlingszwiebeln","amount":"3"}],"steps":["Speck kross braten.","Kimchi anbraten, Gochujang zugeben.","Reis zugeben und anbraten.","Ei aufschlagen und rühren.","Sesamöl und Frühlingszwiebeln zum Schluss."]}'::jsonb,
   true,4.7,21,334,now()-interval '2 hours'),

  (r15,uid_felix,'Felix Weltküche','Mango Lassi',
   'Erfrischender indischer Mango-Joghurt-Drink.',
   'Getränk',ARRAY['Indisch','Getränk','Vegan','Schnell'],'Einfach',5,2,
   '{"ingredients":[{"name":"Mango","amount":"2 reife"},{"name":"Joghurt","amount":"300ml"},{"name":"Milch","amount":"200ml"},{"name":"Zucker","amount":"2 EL"},{"name":"Kardamom","amount":"Prise"}],"steps":["Alles in einen Mixer geben.","Fein pürieren.","Kalt mit Kardamom servieren."]}'::jsonb,
   true,4.3,12,156,now()-interval '30 minutes')

  ON CONFLICT (id) DO NOTHING;

  -- ── 5. COMMUNITY WOCHENPLÄNE ──────────────────────────────────────────────
  -- Spalten: id, user_id, author_name, title, description, tags,
  --          plan_json, is_published, view_count, created_at
  -- KEIN avg_rating / rating_count in community_meal_plans!
  INSERT INTO public.community_meal_plans (
    id, user_id, author_name, title, description, tags,
    plan_json, is_published, view_count, created_at
  ) VALUES
  (mp1,uid_marco,'Marco Küchenchef','Mediterrane Woche 🌊',
   'Eine Woche voller Mittelmeer-Aromen. Leicht, frisch und mit viel Olivenöl.',
   ARRAY['Mediterran','Leicht','Sommer','Italienisch'],
   '[{"dayIndex":0,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Pasta Carbonara","cookingTimeMinutes":25}},{"dayIndex":1,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Griechischer Salat","cookingTimeMinutes":15}},{"dayIndex":2,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Risotto ai Funghi","cookingTimeMinutes":40}},{"dayIndex":3,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Tiramisu","cookingTimeMinutes":30}},{"dayIndex":4,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Pasta Carbonara","cookingTimeMinutes":25}},{"dayIndex":5,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Risotto","cookingTimeMinutes":40}},{"dayIndex":6,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Tiramisu","cookingTimeMinutes":30}}]'::jsonb,
   true,521,now()-interval '7 days'),

  (mp2,uid_lena,'Lena Grünzeug','Vegane Power-Woche 🌱',
   '7 Tage komplett pflanzlich – voller Energie und Nährstoffe.',
   ARRAY['Vegan','Pflanzlich','Gesund','Meal-Prep'],
   '[{"dayIndex":0,"slot":{"type":"breakfast"},"recipe":{"id":"","title":"Overnight Oats Mango-Kokos","cookingTimeMinutes":5}},{"dayIndex":0,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Buddha Bowl mit Tahini","cookingTimeMinutes":30}},{"dayIndex":0,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Vegane Bolognese","cookingTimeMinutes":45}},{"dayIndex":1,"slot":{"type":"breakfast"},"recipe":{"id":"","title":"Overnight Oats","cookingTimeMinutes":5}},{"dayIndex":1,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Quinoa Power Salad","cookingTimeMinutes":20}},{"dayIndex":2,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Vegane Bolognese","cookingTimeMinutes":45}},{"dayIndex":3,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Buddha Bowl","cookingTimeMinutes":30}}]'::jsonb,
   true,389,now()-interval '4 days'),

  (mp3,uid_sara,'Sara FitFood','Fitness Meal-Prep Plan 💪',
   'Hochprotein-Woche für maximale Performance.',
   ARRAY['Fitness','Protein','Meal-Prep','Gesund'],
   '[{"dayIndex":0,"slot":{"type":"breakfast"},"recipe":{"id":"","title":"Protein Pancakes","cookingTimeMinutes":15}},{"dayIndex":0,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Chicken Meal Prep Bowl","cookingTimeMinutes":40}},{"dayIndex":1,"slot":{"type":"breakfast"},"recipe":{"id":"","title":"Protein Pancakes","cookingTimeMinutes":15}},{"dayIndex":1,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Quinoa Power Salad","cookingTimeMinutes":20}},{"dayIndex":2,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Chicken Meal Prep Bowl","cookingTimeMinutes":40}},{"dayIndex":3,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Quinoa Power Salad","cookingTimeMinutes":20}},{"dayIndex":4,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Chicken Meal Prep Bowl","cookingTimeMinutes":40}}]'::jsonb,
   true,445,now()-interval '2 days'),

  (mp4,uid_felix,'Felix Weltküche','Weltreise auf dem Teller 🌍',
   'Jeden Tag ein anderes Land – Asien, Orient, Korea und mehr.',
   ARRAY['International','Asiatisch','Abwechslung','Weltküche'],
   '[{"dayIndex":0,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Pad Thai Original","cookingTimeMinutes":25}},{"dayIndex":1,"slot":{"type":"breakfast"},"recipe":{"id":"","title":"Shakshuka","cookingTimeMinutes":20}},{"dayIndex":2,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Kimchi Fried Rice","cookingTimeMinutes":15}},{"dayIndex":3,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Pad Thai","cookingTimeMinutes":25}},{"dayIndex":4,"slot":{"type":"breakfast"},"recipe":{"id":"","title":"Shakshuka","cookingTimeMinutes":20}},{"dayIndex":5,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Kimchi Fried Rice","cookingTimeMinutes":15}},{"dayIndex":6,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Mango Lassi + Curry","cookingTimeMinutes":30}}]'::jsonb,
   true,312,now()-interval '1 day'),

  (mp5,uid_thomas,'Thomas Backstube','Gemütliche Hausmannskost 🏡',
   'Deftige, herzerwärmende Gerichte – so wie bei Oma.',
   ARRAY['Deutsch','Deftig','Klassisch','Hausmannskost'],
   '[{"dayIndex":0,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Flammkuchen Elsässer Art","cookingTimeMinutes":20}},{"dayIndex":1,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Pasta Carbonara","cookingTimeMinutes":25}},{"dayIndex":2,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Flammkuchen","cookingTimeMinutes":20}},{"dayIndex":3,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Risotto","cookingTimeMinutes":40}},{"dayIndex":4,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Sauerteigbrot","cookingTimeMinutes":60}},{"dayIndex":5,"slot":{"type":"lunch"},"recipe":{"id":"","title":"Pasta Carbonara","cookingTimeMinutes":25}},{"dayIndex":6,"slot":{"type":"dinner"},"recipe":{"id":"","title":"Tiramisu","cookingTimeMinutes":30}}]'::jsonb,
   true,198,now()-interval '6 days')

  ON CONFLICT (id) DO NOTHING;

  -- ── 6. RECIPE LIKES (Tabelle: recipe_likes, Spalten: recipe_id, user_id) ──
  INSERT INTO public.recipe_likes (recipe_id, user_id)
  VALUES
    (r01,uid_lena),(r01,uid_sara),(r01,uid_felix),
    (r02,uid_thomas),(r02,uid_sara),
    (r03,uid_lena),(r03,uid_thomas),(r03,uid_felix),(r03,uid_sara),
    (r04,uid_marco),(r04,uid_thomas),(r04,uid_felix),
    (r05,uid_marco),(r05,uid_felix),
    (r07,uid_marco),(r07,uid_lena),(r07,uid_sara),(r07,uid_felix),
    (r09,uid_marco),(r09,uid_lena),(r09,uid_thomas),
    (r12,uid_marco),(r12,uid_lena),(r12,uid_sara),
    (r13,uid_marco),(r13,uid_lena),(r13,uid_felix),
    (r14,uid_marco),(r14,uid_thomas)
  ON CONFLICT DO NOTHING;

  -- ── 7. KOMMENTARE (Tabelle: recipe_comments) ─────────────────────────────
  INSERT INTO public.recipe_comments (recipe_id, user_id, author_name, content, created_at)
  VALUES
    (r01,uid_lena,'Lena Grünzeug','Absolut authentisch! Endlich mal ohne Sahne 😍',now()-interval '4 days'),
    (r01,uid_sara,'Sara FitFood','Mein Lieblingsrezept – mache ich jede Woche!',now()-interval '3 days'),
    (r03,uid_thomas,'Thomas Backstube','Besser als jedes Café in der Stadt!',now()-interval '7 days'),
    (r03,uid_felix,'Felix Weltküche','Die Konsistenz ist perfekt. Der Amaretto macht es besonders.',now()-interval '6 days'),
    (r04,uid_marco,'Marco Küchenchef','Hätte nicht gedacht dass das so lecker ist ohne Fleisch!',now()-interval '1 day'),
    (r07,uid_lena,'Lena Grünzeug','Das Ergebnis nach 2 Wochen Übung ist unglaublich!',now()-interval '5 days'),
    (r09,uid_lena,'Lena Grünzeug','Auch als vegane Variante mit Tofu super!',now()-interval '2 days'),
    (r12,uid_lena,'Lena Grünzeug','Die Tamarindenpaste macht den Unterschied 🙌',now()-interval '20 hours'),
    (r12,uid_marco,'Marco Küchenchef','Besseres Pad Thai als im Restaurant. Danke!',now()-interval '18 hours'),
    (r13,uid_thomas,'Thomas Backstube','Morgens, mittags, abends – ich könnte das jeden Tag essen!',now()-interval '10 hours')
  ON CONFLICT DO NOTHING;

  -- ── 8. WOCHENPLAN LIKES (Tabelle: meal_plan_likes, Spalten: plan_id, user_id) ──
  INSERT INTO public.meal_plan_likes (plan_id, user_id)
  VALUES
    (mp1,uid_lena),(mp1,uid_sara),(mp1,uid_felix),(mp1,uid_thomas),
    (mp2,uid_marco),(mp2,uid_felix),
    (mp3,uid_marco),(mp3,uid_lena),(mp3,uid_felix),
    (mp4,uid_marco),(mp4,uid_sara),
    (mp5,uid_thomas),(mp5,uid_marco)
  ON CONFLICT DO NOTHING;

  -- ── 9. WOCHENPLAN SAVES (Tabelle: community_meal_plan_saves, Spalten: plan_id, user_id) ──
  INSERT INTO public.community_meal_plan_saves (plan_id, user_id)
  VALUES
    (mp1,uid_lena),(mp1,uid_sara),(mp1,uid_felix),
    (mp2,uid_marco),(mp2,uid_thomas),
    (mp3,uid_marco),(mp3,uid_lena),(mp3,uid_felix),
    (mp4,uid_marco),(mp4,uid_lena),
    (mp5,uid_marco)
  ON CONFLICT DO NOTHING;

  -- ── 10. LIKE-COUNTS in community_recipes aktualisieren ───────────────────
  UPDATE public.community_recipes r
  SET rating_count = sub.cnt
  FROM (SELECT recipe_id, COUNT(*) AS cnt FROM public.recipe_likes GROUP BY recipe_id) sub
  WHERE r.id = sub.recipe_id;

  RAISE NOTICE '✅ Foody Seed v2 erfolgreich!';
  RAISE NOTICE '📧 marco@foody-test.de | Test1234!';
  RAISE NOTICE '📧 lena@foody-test.de  | Test1234!';
  RAISE NOTICE '📧 felix@foody-test.de | Test1234!';
  RAISE NOTICE '📧 sara@foody-test.de  | Test1234!';
  RAISE NOTICE '📧 thomas@foody-test.de| Test1234!';

END $$;
-- 5 Dummy-User, 3 Haushalte, 20+ Rezepte, 5 Wochenpläne,
-- Follow-Beziehungen, Likes, Kommentare, Vorräte
-- ============================================================

DO $$
DECLARE
  -- Feste User-IDs
  uid_marco   UUID := 'aaaaaaaa-1111-1111-1111-000000000001';
  uid_lena    UUID := 'bbbbbbbb-2222-2222-2222-000000000002';
  uid_thomas  UUID := 'cccccccc-3333-3333-3333-000000000003';
  uid_sara    UUID := 'dddddddd-4444-4444-4444-000000000004';
  uid_felix   UUID := 'eeeeeeee-5555-5555-5555-000000000005';

  -- Haushalt-IDs
  hh1 UUID := gen_random_uuid();
  hh2 UUID := gen_random_uuid();

  -- Recipe IDs
  r01 UUID := gen_random_uuid(); r02 UUID := gen_random_uuid();
  r03 UUID := gen_random_uuid(); r04 UUID := gen_random_uuid();
  r05 UUID := gen_random_uuid(); r06 UUID := gen_random_uuid();
  r07 UUID := gen_random_uuid(); r08 UUID := gen_random_uuid();
  r09 UUID := gen_random_uuid(); r10 UUID := gen_random_uuid();
  r11 UUID := gen_random_uuid(); r12 UUID := gen_random_uuid();
  r13 UUID := gen_random_uuid(); r14 UUID := gen_random_uuid();
  r15 UUID := gen_random_uuid();

  -- Meal Plan IDs
  mp1 UUID := gen_random_uuid(); mp2 UUID := gen_random_uuid();
  mp3 UUID := gen_random_uuid(); mp4 UUID := gen_random_uuid();
  mp5 UUID := gen_random_uuid();

BEGIN

  -- ══════════════════════════════════════════════════════════
  -- 1. AUTH USERS
  -- ══════════════════════════════════════════════════════════
  INSERT INTO auth.users (id, instance_id, aud, role, email,
    encrypted_password, email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_super_admin)
  VALUES
    (uid_marco, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'marco@foody-test.de', crypt('Test1234!', gen_salt('bf')), now(), now(), now(),
     '{"provider":"email"}', '{}', false),
    (uid_lena, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'lena@foody-test.de', crypt('Test1234!', gen_salt('bf')), now(), now(), now(),
     '{"provider":"email"}', '{}', false),
    (uid_thomas, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'thomas@foody-test.de', crypt('Test1234!', gen_salt('bf')), now(), now(), now(),
     '{"provider":"email"}', '{}', false),
    (uid_sara, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'sara@foody-test.de', crypt('Test1234!', gen_salt('bf')), now(), now(), now(),
     '{"provider":"email"}', '{}', false),
    (uid_felix, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'felix@foody-test.de', crypt('Test1234!', gen_salt('bf')), now(), now(), now(),
     '{"provider":"email"}', '{}', false)
  ON CONFLICT (id) DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 2. USER PROFILES
  -- ══════════════════════════════════════════════════════════
  INSERT INTO public.user_profiles (id, display_name, bio, avatar_url, social_links, updated_at)
  VALUES
    (uid_marco, 'Marco Küchenchef',
     'Leidenschaftlicher Koch aus München 🍳 Liebe italienische und mediterrane Küche. Koche täglich frisch!',
     NULL,
     '{"instagram":"@marco_kocht","youtube":"https://youtube.com/@marcokocht","website":"https://marco-kocht.de"}',
     now()),
    (uid_lena, 'Lena Grünzeug',
     'Vegane Köchin & Food-Bloggerin 🌱 Pflanzliche Küche die begeistert. Täglich neue Ideen!',
     NULL,
     '{"instagram":"@lena_vegan","tiktok":"@greenfoodlena","website":"https://lena-vegan.de"}',
     now()),
    (uid_thomas, 'Thomas Backstube',
     'Bäcker-Meister & Hobbykoch 🥖 Sauerteig, Croissants und alles aus dem Ofen.',
     NULL,
     '{"instagram":"@thomas_bäckt","youtube":"https://youtube.com/@thomasbackt"}',
     now()),
    (uid_sara, 'Sara FitFood',
     'Personal Trainerin & Meal-Prep Queen 💪 Gesunde Rezepte die schnell gehen.',
     NULL,
     '{"instagram":"@sara_fitfood","tiktok":"@sarafitfood"}',
     now()),
    (uid_felix, 'Felix Weltküche',
     'Auf Weltreise durch Töpfe & Pfannen 🌍 Asiatisch, mexikanisch, arabisch – kein Rezept ist zu komplex.',
     NULL,
     '{"instagram":"@felix_weltküche","tiktok":"@felixcooks"}',
     now())
  ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    social_links = EXCLUDED.social_links,
    updated_at = now();

  -- ══════════════════════════════════════════════════════════
  -- 3. FOLLOW-BEZIEHUNGEN (viele, damit Feeds leben)
  -- ══════════════════════════════════════════════════════════
  INSERT INTO public.user_follows (follower_id, followee_id)
  VALUES
    (uid_lena, uid_marco), (uid_thomas, uid_marco), (uid_sara, uid_marco),
    (uid_felix, uid_marco), (uid_marco, uid_lena), (uid_thomas, uid_lena),
    (uid_felix, uid_lena), (uid_marco, uid_thomas), (uid_sara, uid_thomas),
    (uid_marco, uid_sara), (uid_lena, uid_sara), (uid_felix, uid_sara),
    (uid_marco, uid_felix), (uid_lena, uid_felix), (uid_thomas, uid_felix)
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 4. COMMUNITY REZEPTE (15 Stück)
  -- ══════════════════════════════════════════════════════════
  INSERT INTO public.community_recipes (
    id, user_id, author_name, title, description, category, tags,
    difficulty, cooking_time_minutes, servings,
    recipe_json, is_published, avg_rating, rating_count, view_count, created_at
  ) VALUES
  -- Marco: Italiano
  (r01, uid_marco, 'Marco Küchenchef', 'Echte Pasta Carbonara',
   'Das Original aus Rom – ohne Sahne, nur Ei, Pecorino und Guanciale.',
   'Abendessen', ARRAY['Pasta','Italienisch','Klassiker','Schnell'],
   'Mittel', 25, 2,
   '{"ingredients":[{"name":"Spaghetti","amount":"200g"},{"name":"Guanciale","amount":"100g"},{"name":"Pecorino Romano","amount":"60g"},{"name":"Eier","amount":"2 + 2 Eigelb"},{"name":"Schwarzer Pfeffer","amount":"reichlich"}],"steps":["Nudelwasser salzen, Spaghetti al dente kochen.","Guanciale ohne Öl knusprig braten.","Eier + Eigelb mit Pecorino und Pfeffer verquirlen.","Nudeln zum Guanciale, Ei-Mix unterheben mit Kochwasser cremig rühren.","Sofort mit extra Pecorino servieren."]}'::jsonb,
   true, 4.7, 23, 412, now() - interval '5 days'),

  (r02, uid_marco, 'Marco Küchenchef', 'Risotto ai Funghi',
   'Cremiges Pilzrisotto nach klassischer Art – geduldig gerührt.',
   'Abendessen', ARRAY['Risotto','Italienisch','Vegetarisch','Pilze'],
   'Mittel', 40, 4,
   '{"ingredients":[{"name":"Risottoreis","amount":"320g"},{"name":"Gemischte Pilze","amount":"400g"},{"name":"Parmesan","amount":"80g"},{"name":"Zwiebel","amount":"1"},{"name":"Weißwein","amount":"100ml"},{"name":"Gemüsebrühe","amount":"1L"}],"steps":["Brühe warm halten.","Zwiebel anschwitzen, Reis glasig rösten.","Mit Wein ablöschen, komplett einziehen lassen.","Kellenweise heiße Brühe zugeben, stets rühren.","Pilze separat braten und untermengen.","Mit Parmesan und Butter verfeinern."]}'::jsonb,
   true, 4.5, 18, 287, now() - interval '3 days'),

  (r03, uid_marco, 'Marco Küchenchef', 'Tiramisu – Das Original',
   'Omas Rezept aus Venetien. Echter Mascarpone, frischer Espresso.',
   'Dessert', ARRAY['Dessert','Italienisch','No-Bake','Klassiker'],
   'Einfach', 30, 6,
   '{"ingredients":[{"name":"Mascarpone","amount":"500g"},{"name":"Eier","amount":"4"},{"name":"Zucker","amount":"100g"},{"name":"Espresso","amount":"300ml"},{"name":"Amaretto","amount":"4 EL"},{"name":"Löffelbiskuits","amount":"200g"}],"steps":["Eigelb mit Zucker cremig schlagen.","Mascarpone unterheben, Eiweiß steif schlagen und unterheben.","Biskuits kurz in Espresso-Amaretto tauchen.","Schichten: Biskuits, Creme, Biskuits, Creme – 4h kühlen.","Mit Kakao bestäuben."]}'::jsonb,
   true, 4.9, 41, 638, now() - interval '8 days'),

  -- Lena: Vegan
  (r04, uid_lena, 'Lena Grünzeug', 'Buddha Bowl mit Tahini',
   'Bunte Bowl mit geröstetem Gemüse, Kichererbsen und cremigem Tahini-Dressing.',
   'Mittagessen', ARRAY['Vegan','Gesund','Bowl','Meal-Prep'],
   'Einfach', 30, 2,
   '{"ingredients":[{"name":"Kichererbsen","amount":"400g (Dose)"},{"name":"Süßkartoffel","amount":"2"},{"name":"Brokkoli","amount":"300g"},{"name":"Quinoa","amount":"150g"},{"name":"Tahini","amount":"3 EL"},{"name":"Zitrone","amount":"1"},{"name":"Knoblauch","amount":"2 Zehen"}],"steps":["Ofen auf 200°C vorheizen.","Kichererbsen und Gemüse mit Öl, Salz und Paprika mischen.","30 Min rösten bis knusprig.","Quinoa nach Packungsanweisung kochen.","Tahini mit Zitrone, Knoblauch und Wasser zur Sauce rühren.","Bowl zusammenstellen."]}'::jsonb,
   true, 4.6, 31, 521, now() - interval '2 days'),

  (r05, uid_lena, 'Lena Grünzeug', 'Vegane Bolognese',
   'Herzhafte Bolognese mit Linsen und Walnüssen – man vermisst das Fleisch nicht.',
   'Abendessen', ARRAY['Vegan','Pasta','Linsen','Herzhaft'],
   'Einfach', 45, 4,
   '{"ingredients":[{"name":"Rote Linsen","amount":"200g"},{"name":"Walnüsse","amount":"100g"},{"name":"Passierte Tomaten","amount":"800g"},{"name":"Karotten","amount":"2"},{"name":"Sellerie","amount":"2 Stangen"},{"name":"Rotwein","amount":"100ml"},{"name":"Spaghetti","amount":"400g"}],"steps":["Walnüsse hacken und rösten.","Karotten, Sellerie fein schneiden und anbraten.","Linsen und Wein zugeben.","Tomaten dazu, 30 Min köcheln.","Walnüsse unterrühren, mit Spaghetti servieren."]}'::jsonb,
   true, 4.4, 27, 398, now() - interval '1 day'),

  (r06, uid_lena, 'Lena Grünzeug', 'Overnight Oats Mango-Kokos',
   'Das perfekte Frühstück – am Abend zubereitet, morgens fertig.',
   'Frühstück', ARRAY['Vegan','Frühstück','Meal-Prep','Schnell'],
   'Einfach', 5, 1,
   '{"ingredients":[{"name":"Haferflocken","amount":"80g"},{"name":"Kokosmilch","amount":"200ml"},{"name":"Mango","amount":"1"},{"name":"Chiasamen","amount":"1 EL"},{"name":"Agavensirup","amount":"1 TL"},{"name":"Limette","amount":"0.5"}],"steps":["Haferflocken mit Kokosmilch und Chiasamen vermengen.","Mit Agavensirup süßen.","Über Nacht (min. 6h) im Kühlschrank quellen lassen.","Morgens mit Mango-Würfeln und Limonensaft toppen."]}'::jsonb,
   true, 4.3, 15, 203, now() - interval '4 hours'),

  -- Thomas: Backen & Herzhaft
  (r07, uid_thomas, 'Thomas Backstube', 'Sauerteigbrot',
   'Knuspriges Sauerteigbrot mit langer Fermentation – perfekte Krume.',
   'Brot', ARRAY['Backen','Sauerteig','Brot','Aufwändig'],
   'Schwer', 60, 8,
   '{"ingredients":[{"name":"Weizenmehl 550","amount":"500g"},{"name":"Wasser","amount":"375ml"},{"name":"Sauerteig-Starter","amount":"100g"},{"name":"Salz","amount":"10g"}],"steps":["Mehl und Wasser vermischen (Autolyse 30 Min).","Starter und Salz einarbeiten.","4x Stretch & Fold alle 30 Min.","8-16h kalt gehen lassen.","Auf 250°C im Topf backen (20 Min mit Deckel, 20 Min ohne)."]}'::jsonb,
   true, 4.8, 34, 567, now() - interval '6 days'),

  (r08, uid_thomas, 'Thomas Backstube', 'Flammkuchen Elsässer Art',
   'Hauchdünner Teig mit Schmand, Zwiebeln und Speck – in 20 Minuten fertig.',
   'Abendessen', ARRAY['Flammkuchen','Schnell','Elsässisch','Herzhaft'],
   'Einfach', 20, 4,
   '{"ingredients":[{"name":"Flammkuchenteig","amount":"1 Rolle"},{"name":"Schmand","amount":"200g"},{"name":"Zwiebeln","amount":"2"},{"name":"Speck","amount":"150g"},{"name":"Muskat","amount":"Prise"}],"steps":["Ofen auf 250°C vorheizen.","Teig ausrollen, mit Schmand bestreichen.","Zwiebeln in Ringe, Speck würfeln und verteilen.","10-12 Min backen bis Rand kross ist.","Sofort servieren."]}'::jsonb,
   true, 4.5, 22, 344, now() - interval '2 days'),

  -- Sara: Fitness
  (r09, uid_sara, 'Sara FitFood', 'Chicken Meal Prep Bowls',
   'Proteinreiche Bowls für die ganze Woche – einmal kochen, fünf Mal genießen.',
   'Mittagessen', ARRAY['Meal-Prep','Protein','Gesund','Hühnchen'],
   'Einfach', 40, 5,
   '{"ingredients":[{"name":"Hühnerbrust","amount":"1kg"},{"name":"Brokkoli","amount":"500g"},{"name":"Süßkartoffel","amount":"600g"},{"name":"Brauner Reis","amount":"400g"},{"name":"Olivenöl","amount":"4 EL"},{"name":"Paprikapulver","amount":"2 TL"}],"steps":["Ofen 200°C vorheizen.","Hühnerbrust würzen und braten.","Gemüse in Würfel, mit Öl und Gewürzen rösten.","Reis kochen.","In 5 Meal-Prep-Boxen aufteilen, 4 Tage im Kühlschrank haltbar."]}'::jsonb,
   true, 4.7, 38, 612, now() - interval '3 days'),

  (r10, uid_sara, 'Sara FitFood', 'Protein Pancakes',
   'Fluffige Pancakes mit extra Protein – perfekt nach dem Training.',
   'Frühstück', ARRAY['Proteinreich','Frühstück','Fitness','Schnell'],
   'Einfach', 15, 2,
   '{"ingredients":[{"name":"Magerquark","amount":"250g"},{"name":"Eier","amount":"2"},{"name":"Proteinpulver Vanille","amount":"30g"},{"name":"Haferflocken","amount":"50g"},{"name":"Backpulver","amount":"1 TL"},{"name":"Banane","amount":"1"}],"steps":["Alle Zutaten zu einem glatten Teig mixen.","Kleine Portionen in beschichtete Pfanne geben.","Auf mittlerer Hitze von beiden Seiten goldbraun backen.","Mit frischen Beeren und Ahornsirup servieren."]}'::jsonb,
   true, 4.4, 19, 289, now() - interval '5 hours'),

  (r11, uid_sara, 'Sara FitFood', 'Quinoa Power Salad',
   'Nährstoffbombe mit Quinoa, Avocado und vielen Vitaminen.',
   'Mittagessen', ARRAY['Vegan','Salat','Quinoa','Gesund'],
   'Einfach', 20, 2,
   '{"ingredients":[{"name":"Quinoa","amount":"150g"},{"name":"Avocado","amount":"2"},{"name":"Kirschtomaten","amount":"200g"},{"name":"Gurke","amount":"1"},{"name":"Feta","amount":"100g"},{"name":"Limettensaft","amount":"2 EL"}],"steps":["Quinoa kochen und abkühlen lassen.","Gemüse würfeln, Avocado in Stücke schneiden.","Alles vermengen, mit Limette und Olivenöl anmachen.","Feta darüber krümeln."]}'::jsonb,
   true, 4.2, 14, 178, now() - interval '7 hours'),

  -- Felix: Weltküche
  (r12, uid_felix, 'Felix Weltküche', 'Pad Thai Original',
   'Authentisches Pad Thai wie aus Bangkok – mit Tamarinden-Paste und Erdnüssen.',
   'Abendessen', ARRAY['Asiatisch','Thai','Nudeln','Schnell'],
   'Mittel', 25, 2,
   '{"ingredients":[{"name":"Reisnudeln","amount":"200g"},{"name":"Garnelen","amount":"250g"},{"name":"Tofu","amount":"100g"},{"name":"Ei","amount":"2"},{"name":"Tamarindenpaste","amount":"3 EL"},{"name":"Fischsauce","amount":"2 EL"},{"name":"Erdnüsse","amount":"50g"},{"name":"Sojasprossen","amount":"100g"}],"steps":["Nudeln einweichen bis weich.","Wok stark erhitzen, Garnelen und Tofu anbraten.","Nudeln zugeben, Ei daneben aufschlagen.","Tamarinde, Fischsauce und etwas Zucker zugeben.","Alles vermengen, mit Sprossen und Erdnüssen servieren."]}'::jsonb,
   true, 4.8, 29, 487, now() - interval '1 day'),

  (r13, uid_felix, 'Felix Weltküche', 'Shakshuka',
   'Orientalische Eier in Tomatensauce – einfach, aromatisch, sättigend.',
   'Frühstück', ARRAY['Orientalisch','Eier','Vegetarisch','Schnell'],
   'Einfach', 20, 2,
   '{"ingredients":[{"name":"Eier","amount":"4"},{"name":"Tomaten (Dose)","amount":"800g"},{"name":"Paprika rot","amount":"2"},{"name":"Zwiebel","amount":"1"},{"name":"Kreuzkümmel","amount":"2 TL"},{"name":"Paprikapulver","amount":"1 TL"},{"name":"Chili","amount":"1"},{"name":"Feta","amount":"100g"}],"steps":["Zwiebeln und Paprika in Olivenöl anschwitzen.","Gewürze zugeben, kurz rösten.","Tomaten zugeben, 10 Min köcheln.","Mulden formen, Eier hineinschlagen.","Abgedeckt 5-8 Min stocken lassen.","Mit Feta und Brot servieren."]}'::jsonb,
   true, 4.6, 25, 395, now() - interval '12 hours'),

  (r14, uid_felix, 'Felix Weltküche', 'Kimchi Fried Rice',
   'Koreanischer Klassiker mit fermentiertem Kimchi – umami pur.',
   'Abendessen', ARRAY['Koreanisch','Reis','Fermentiert','Schnell'],
   'Einfach', 15, 2,
   '{"ingredients":[{"name":"Gekochter Reis (vom Vortag)","amount":"300g"},{"name":"Kimchi","amount":"150g"},{"name":"Ei","amount":"2"},{"name":"Speck oder Tofu","amount":"100g"},{"name":"Sesamöl","amount":"1 EL"},{"name":"Gochujang","amount":"1 TL"},{"name":"Frühlingszwiebeln","amount":"3"}],"steps":["Speck kross braten, beiseite stellen.","Kimchi im Wok anbraten, Gochujang zugeben.","Reis zugeben und alles gut anbraten.","In Reismitte Lücke machen, Ei aufschlagen und rühren.","Sesamöl und Frühlingszwiebeln zum Schluss."]}'::jsonb,
   true, 4.7, 21, 334, now() - interval '2 hours'),

  (r15, uid_felix, 'Felix Weltküche', 'Mango Lassi',
   'Erfrischender indischer Mango-Joghurt-Drink – perfekt zum Curry.',
   'Getränk', ARRAY['Indisch','Getränk','Vegan','Schnell'],
   'Einfach', 5, 2,
   '{"ingredients":[{"name":"Mango","amount":"2 reife"},{"name":"Joghurt","amount":"300ml"},{"name":"Milch","amount":"200ml"},{"name":"Zucker","amount":"2 EL"},{"name":"Kardamom","amount":"Prise"}],"steps":["Alles in einen Mixer geben.","Fein pürieren.","Kalt servieren mit etwas Kardamom obenauf."]}'::jsonb,
   true, 4.3, 12, 156, now() - interval '30 minutes')

  ON CONFLICT (id) DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 5. COMMUNITY WOCHENPLÄNE (5 Stück)
  -- ══════════════════════════════════════════════════════════
  INSERT INTO public.community_meal_plans (
    id, user_id, author_name, title, description, tags,
    plan_json, is_published, view_count, created_at
  ) VALUES
  (mp1, uid_marco, 'Marco Küchenchef', 'Mediterrane Woche 🌊',
   'Eine Woche voller Mittelmeer-Aromen. Leicht, frisch und mit viel Olivenöl.',
   ARRAY['Mediterran','Leicht','Sommer','Italienisch'],
   '[
     {"dayIndex":0,"slot":{"type":"dinner"},"recipe":{"id":"r01","title":"Pasta Carbonara","cookingTimeMinutes":25}},
     {"dayIndex":1,"slot":{"type":"lunch"},"recipe":{"id":"r02","title":"Griechischer Salat"}},
     {"dayIndex":2,"slot":{"type":"dinner"},"recipe":{"id":"r02","title":"Risotto ai Funghi","cookingTimeMinutes":40}},
     {"dayIndex":3,"slot":{"type":"dinner"},"recipe":{"id":"r03","title":"Tiramisu","cookingTimeMinutes":30}},
     {"dayIndex":4,"slot":{"type":"lunch"},"recipe":{"id":"r01","title":"Pasta Carbonara","cookingTimeMinutes":25}},
     {"dayIndex":5,"slot":{"type":"dinner"},"recipe":{"id":"r02","title":"Risotto","cookingTimeMinutes":40}},
     {"dayIndex":6,"slot":{"type":"dinner"},"recipe":{"id":"r03","title":"Tiramisu","cookingTimeMinutes":30}}
   ]'::jsonb,
   true, 521, now() - interval '7 days'),

  (mp2, uid_lena, 'Lena Grünzeug', 'Vegane Power-Woche 🌱',
   '7 Tage komplett pflanzlich – voller Energie und Nährstoffe.',
   ARRAY['Vegan','Pflanzlich','Gesund','Meal-Prep'],
   '[
     {"dayIndex":0,"slot":{"type":"breakfast"},"recipe":{"id":"r06","title":"Overnight Oats Mango-Kokos","cookingTimeMinutes":5}},
     {"dayIndex":0,"slot":{"type":"lunch"},"recipe":{"id":"r04","title":"Buddha Bowl mit Tahini","cookingTimeMinutes":30}},
     {"dayIndex":0,"slot":{"type":"dinner"},"recipe":{"id":"r05","title":"Vegane Bolognese","cookingTimeMinutes":45}},
     {"dayIndex":1,"slot":{"type":"breakfast"},"recipe":{"id":"r06","title":"Overnight Oats","cookingTimeMinutes":5}},
     {"dayIndex":1,"slot":{"type":"lunch"},"recipe":{"id":"r11","title":"Quinoa Power Salad","cookingTimeMinutes":20}},
     {"dayIndex":2,"slot":{"type":"dinner"},"recipe":{"id":"r05","title":"Vegane Bolognese","cookingTimeMinutes":45}},
     {"dayIndex":3,"slot":{"type":"lunch"},"recipe":{"id":"r04","title":"Buddha Bowl","cookingTimeMinutes":30}}
   ]'::jsonb,
   true, 389, now() - interval '4 days'),

  (mp3, uid_sara, 'Sara FitFood', 'Fitness Meal-Prep Plan 💪',
   'Hochprotein-Woche für maximale Performance. Vorbereitung am Sonntag für die ganze Woche.',
   ARRAY['Fitness','Protein','Meal-Prep','Gesund'],
   '[
     {"dayIndex":0,"slot":{"type":"breakfast"},"recipe":{"id":"r10","title":"Protein Pancakes","cookingTimeMinutes":15}},
     {"dayIndex":0,"slot":{"type":"lunch"},"recipe":{"id":"r09","title":"Chicken Meal Prep Bowl","cookingTimeMinutes":40}},
     {"dayIndex":1,"slot":{"type":"breakfast"},"recipe":{"id":"r10","title":"Protein Pancakes","cookingTimeMinutes":15}},
     {"dayIndex":1,"slot":{"type":"lunch"},"recipe":{"id":"r11","title":"Quinoa Power Salad","cookingTimeMinutes":20}},
     {"dayIndex":2,"slot":{"type":"lunch"},"recipe":{"id":"r09","title":"Chicken Meal Prep Bowl","cookingTimeMinutes":40}},
     {"dayIndex":3,"slot":{"type":"lunch"},"recipe":{"id":"r11","title":"Quinoa Power Salad","cookingTimeMinutes":20}},
     {"dayIndex":4,"slot":{"type":"lunch"},"recipe":{"id":"r09","title":"Chicken Meal Prep Bowl","cookingTimeMinutes":40}}
   ]'::jsonb,
   true, 445, now() - interval '2 days'),

  (mp4, uid_felix, 'Felix Weltküche', 'Weltreise auf dem Teller 🌍',
   'Jeden Tag ein anderes Land – Asien, Orient, Korea und mehr.',
   ARRAY['International','Asiatisch','Abwechslung','Weltküche'],
   '[
     {"dayIndex":0,"slot":{"type":"dinner"},"recipe":{"id":"r12","title":"Pad Thai Original","cookingTimeMinutes":25}},
     {"dayIndex":1,"slot":{"type":"breakfast"},"recipe":{"id":"r13","title":"Shakshuka","cookingTimeMinutes":20}},
     {"dayIndex":2,"slot":{"type":"dinner"},"recipe":{"id":"r14","title":"Kimchi Fried Rice","cookingTimeMinutes":15}},
     {"dayIndex":3,"slot":{"type":"dinner"},"recipe":{"id":"r12","title":"Pad Thai","cookingTimeMinutes":25}},
     {"dayIndex":4,"slot":{"type":"breakfast"},"recipe":{"id":"r13","title":"Shakshuka","cookingTimeMinutes":20}},
     {"dayIndex":5,"slot":{"type":"dinner"},"recipe":{"id":"r14","title":"Kimchi Fried Rice","cookingTimeMinutes":15}},
     {"dayIndex":6,"slot":{"type":"dinner"},"recipe":{"id":"r15","title":"Mango Lassi + Pad Thai","cookingTimeMinutes":30}}
   ]'::jsonb,
   true, 312, now() - interval '1 day'),

  (mp5, uid_thomas, 'Thomas Backstube', 'Gemütliche Hausmannskost 🏡',
   'Deftige, herzerwärmende Gerichte für die Woche – so wie bei Oma.',
   ARRAY['Deutsch','Deftig','Klassisch','Hausmannskost'],
   '[
     {"dayIndex":0,"slot":{"type":"dinner"},"recipe":{"id":"r08","title":"Flammkuchen Elsässer Art","cookingTimeMinutes":20}},
     {"dayIndex":1,"slot":{"type":"lunch"},"recipe":{"id":"r01","title":"Pasta","cookingTimeMinutes":25}},
     {"dayIndex":2,"slot":{"type":"dinner"},"recipe":{"id":"r08","title":"Flammkuchen","cookingTimeMinutes":20}},
     {"dayIndex":3,"slot":{"type":"lunch"},"recipe":{"id":"r02","title":"Risotto","cookingTimeMinutes":40}},
     {"dayIndex":4,"slot":{"type":"dinner"},"recipe":{"id":"r07","title":"Sauerteigbrot","cookingTimeMinutes":60}},
     {"dayIndex":5,"slot":{"type":"lunch"},"recipe":{"id":"r01","title":"Pasta Carbonara","cookingTimeMinutes":25}},
     {"dayIndex":6,"slot":{"type":"dinner"},"recipe":{"id":"r03","title":"Tiramisu","cookingTimeMinutes":30}}
   ]'::jsonb,
   true, 198, now() - interval '6 days')

  ON CONFLICT (id) DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 6. LIKES auf Rezepte
  -- ══════════════════════════════════════════════════════════
  INSERT INTO public.recipe_likes (recipe_id, user_id)
  VALUES
    (r01, uid_lena), (r01, uid_sara), (r01, uid_felix),
    (r02, uid_thomas), (r02, uid_sara),
    (r03, uid_lena), (r03, uid_thomas), (r03, uid_felix), (r03, uid_sara),
    (r04, uid_marco), (r04, uid_thomas), (r04, uid_felix),
    (r05, uid_marco), (r05, uid_felix),
    (r07, uid_marco), (r07, uid_lena), (r07, uid_sara), (r07, uid_felix),
    (r09, uid_marco), (r09, uid_lena), (r09, uid_thomas),
    (r12, uid_marco), (r12, uid_lena), (r12, uid_sara),
    (r13, uid_marco), (r13, uid_lena), (r13, uid_felix),
    (r14, uid_marco), (r14, uid_thomas)
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 7. KOMMENTARE
  -- ══════════════════════════════════════════════════════════
  INSERT INTO public.recipe_comments (recipe_id, user_id, author_name, content, created_at)
  VALUES
    (r01, uid_lena, 'Lena Grünzeug', 'Absolut authentisch! Endlich mal ohne Sahne 😍', now() - interval '4 days'),
    (r01, uid_sara, 'Sara FitFood', 'Mein Lieblingsrezept – mache ich jede Woche!', now() - interval '3 days'),
    (r03, uid_thomas, 'Thomas Backstube', 'Besser als jedes Café in der Stadt!', now() - interval '7 days'),
    (r03, uid_felix, 'Felix Weltküche', 'Die Konsistenz ist perfekt. Der Amaretto macht es besonders.', now() - interval '6 days'),
    (r04, uid_marco, 'Marco Küchenchef', 'Hätte nicht gedacht dass das so lecker ist ohne Fleisch!', now() - interval '1 day'),
    (r07, uid_lena, 'Lena Grünzeug', 'Das Ergebnis nach 2 Wochen Übung ist unglaublich!', now() - interval '5 days'),
    (r09, uid_lena, 'Lena Grünzeug', 'Auch als vegane Variante mit Tofu super!', now() - interval '2 days'),
    (r12, uid_lena, 'Lena Grünzeug', 'Die Tamarindenpaste macht den Unterschied 🙌', now() - interval '20 hours'),
    (r12, uid_marco, 'Marco Küchenchef', 'Besseres Pad Thai als im Restaurant. Danke!', now() - interval '18 hours'),
    (r13, uid_thomas, 'Thomas Backstube', 'Morgens, mittags, abends – ich könnte das jeden Tag essen!', now() - interval '10 hours')
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 8. WOCHENPLAN SAVES & LIKES
  -- ══════════════════════════════════════════════════════════
  INSERT INTO public.community_meal_plan_saves (plan_id, user_id)
  VALUES
    (mp1, uid_lena), (mp1, uid_sara), (mp1, uid_felix),
    (mp2, uid_marco), (mp2, uid_thomas),
    (mp3, uid_marco), (mp3, uid_lena), (mp3, uid_felix),
    (mp4, uid_marco), (mp4, uid_lena),
    (mp5, uid_marco)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.meal_plan_likes (plan_id, user_id)
  VALUES
    (mp1, uid_lena), (mp1, uid_sara), (mp1, uid_felix), (mp1, uid_thomas),
    (mp2, uid_marco), (mp2, uid_felix),
    (mp3, uid_marco), (mp3, uid_lena), (mp3, uid_felix),
    (mp4, uid_marco), (mp4, uid_sara),
    (mp5, uid_thomas), (mp5, uid_marco)
  ON CONFLICT DO NOTHING;

  -- ══════════════════════════════════════════════════════════
  -- 9. LIKES-COUNTS aktualisieren
  -- ══════════════════════════════════════════════════════════
  UPDATE public.community_recipes r
  SET rating_count = sub.cnt
  FROM (
    SELECT recipe_id, COUNT(*) as cnt FROM public.recipe_likes GROUP BY recipe_id
  ) sub
  WHERE r.id = sub.recipe_id;

  RAISE NOTICE '✅ Foody Seed v2: 5 User, 15 Rezepte, 5 Wochenpläne, Follow-Netzwerk erstellt.';
  RAISE NOTICE '📧 Login: marco@foody-test.de | Passwort: Test1234!';
  RAISE NOTICE '📧 Login: lena@foody-test.de | Passwort: Test1234!';
  RAISE NOTICE '📧 Login: felix@foody-test.de | Passwort: Test1234!';

END $$;

