-- ============================================================
-- FOODY – Community Wochenpläne Seed
-- 3 vollständige Wochenpläne mit je 7 Tagen & Mahlzeiten
-- Nutzt die user_ids aus auth.users (erste 3 User)
-- HINWEIS: Erst supabase_seed_community_recipes.sql ausführen!
-- ============================================================

DO $$
DECLARE
  v_user1 uuid;
  v_user2 uuid;
  v_user3 uuid;
BEGIN
  SELECT id INTO v_user1 FROM auth.users ORDER BY created_at LIMIT 1;
  SELECT id INTO v_user2 FROM auth.users ORDER BY created_at OFFSET 1 LIMIT 1;
  SELECT id INTO v_user3 FROM auth.users ORDER BY created_at OFFSET 2 LIMIT 1;

  IF v_user2 IS NULL THEN v_user2 := v_user1; END IF;
  IF v_user3 IS NULL THEN v_user3 := v_user1; END IF;

  -- ─────────────────────────────────────────────────────────
  -- Wochenplan 1: "Mediterrane Genusswoche"
  -- ─────────────────────────────────────────────────────────
  INSERT INTO public.community_meal_plans (
    user_id, author_name, title, description, tags, plan_json, is_published, view_count
  ) VALUES (
    v_user1, 'Marco Küchenchef',
    'Mediterrane Genusswoche 🌊',
    'Eine Woche voller Mittelmeer-Aromen. Leicht, frisch und einfach zuzubereiten. Perfekt für den Sommer.',
    ARRAY['Mediterran','Leicht','Sommer','Gesund','Einfach'],
    '[
      {
        "day": "Montag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Klassischer Griechischer Salat", "recipeId": "seed-griechsalat-01"},
          {"mealType": "Abendessen", "recipeTitle": "Knoblauch-Garnelen Linguine", "recipeId": "seed-garnelenlingune-01"}
        ]
      },
      {
        "day": "Dienstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Shakshuka – Eier in Tomatensauce", "recipeId": "seed-shakshuka-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Klassischer Griechischer Salat", "recipeId": "seed-griechsalat-01"},
          {"mealType": "Abendessen", "recipeTitle": "One-Pan Lachs mit Ofengemüse", "recipeId": "seed-lachs-01"}
        ]
      },
      {
        "day": "Mittwoch",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Herzhafte Linsensuppe", "recipeId": "seed-linsensuppe-01"},
          {"mealType": "Abendessen", "recipeTitle": "Spaghetti Carbonara – Das Original", "recipeId": "seed-carbonara-01"}
        ]
      },
      {
        "day": "Donnerstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Shakshuka – Eier in Tomatensauce", "recipeId": "seed-shakshuka-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Klassischer Griechischer Salat", "recipeId": "seed-griechsalat-01"},
          {"mealType": "Abendessen", "recipeTitle": "Knoblauch-Garnelen Linguine", "recipeId": "seed-garnelenlingune-01"}
        ]
      },
      {
        "day": "Freitag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Herzhafte Linsensuppe", "recipeId": "seed-linsensuppe-01"},
          {"mealType": "Abendessen", "recipeTitle": "One-Pan Lachs mit Ofengemüse", "recipeId": "seed-lachs-01"}
        ]
      },
      {
        "day": "Samstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Shakshuka – Eier in Tomatensauce", "recipeId": "seed-shakshuka-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Klassischer Griechischer Salat", "recipeId": "seed-griechsalat-01"},
          {"mealType": "Abendessen", "recipeTitle": "Spaghetti Carbonara – Das Original", "recipeId": "seed-carbonara-01"},
          {"mealType": "Dessert", "recipeTitle": "Tiramisu – Das Original", "recipeId": "seed-tiramisu-01"}
        ]
      },
      {
        "day": "Sonntag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Knoblauch-Garnelen Linguine", "recipeId": "seed-garnelenlingune-01"},
          {"mealType": "Abendessen", "recipeTitle": "One-Pan Lachs mit Ofengemüse", "recipeId": "seed-lachs-01"},
          {"mealType": "Dessert", "recipeTitle": "Schokoladen-Lava-Cake", "recipeId": "seed-lavacake-01"}
        ]
      }
    ]'::jsonb,
    true, 342
  ) ON CONFLICT DO NOTHING;

  -- ─────────────────────────────────────────────────────────
  -- Wochenplan 2: "High-Protein Fitness-Woche"
  -- ─────────────────────────────────────────────────────────
  INSERT INTO public.community_meal_plans (
    user_id, author_name, title, description, tags, plan_json, is_published, view_count
  ) VALUES (
    v_user2, 'Sara FitFood',
    'High-Protein Fitness-Woche 💪',
    'Proteinreich und kalorienoptimiert für aktive Menschen. Alle Mahlzeiten unter 45 Min. zubereitet.',
    ARRAY['High-Protein','Fitness','Gesund','Meal-Prep','Schnell'],
    '[
      {
        "day": "Montag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Bananenpfannkuchen (3 Zutaten)", "recipeId": "seed-bananenpancake-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Hähnchen-Teriyaki Bowl", "recipeId": "seed-teriyaki-01"},
          {"mealType": "Abendessen", "recipeTitle": "One-Pan Lachs mit Ofengemüse", "recipeId": "seed-lachs-01"}
        ]
      },
      {
        "day": "Dienstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Hähnchen-Teriyaki Bowl", "recipeId": "seed-teriyaki-01"},
          {"mealType": "Abendessen", "recipeTitle": "Butter Chicken (Murgh Makhani)", "recipeId": "seed-butterchicken-01"}
        ]
      },
      {
        "day": "Mittwoch",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Bananenpfannkuchen (3 Zutaten)", "recipeId": "seed-bananenpancake-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Klassischer Griechischer Salat", "recipeId": "seed-griechsalat-01"},
          {"mealType": "Abendessen", "recipeTitle": "Knoblauch-Garnelen Linguine", "recipeId": "seed-garnelenlingune-01"}
        ]
      },
      {
        "day": "Donnerstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Shakshuka – Eier in Tomatensauce", "recipeId": "seed-shakshuka-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Hähnchen-Teriyaki Bowl", "recipeId": "seed-teriyaki-01"},
          {"mealType": "Abendessen", "recipeTitle": "One-Pan Lachs mit Ofengemüse", "recipeId": "seed-lachs-01"}
        ]
      },
      {
        "day": "Freitag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Herzhafte Linsensuppe", "recipeId": "seed-linsensuppe-01"},
          {"mealType": "Abendessen", "recipeTitle": "Butter Chicken (Murgh Makhani)", "recipeId": "seed-butterchicken-01"}
        ]
      },
      {
        "day": "Samstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Bananenpfannkuchen (3 Zutaten)", "recipeId": "seed-bananenpancake-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Hähnchen-Teriyaki Bowl", "recipeId": "seed-teriyaki-01"},
          {"mealType": "Abendessen", "recipeTitle": "BBQ Pulled Pork Burger", "recipeId": "seed-pulledpork-01"}
        ]
      },
      {
        "day": "Sonntag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Shakshuka – Eier in Tomatensauce", "recipeId": "seed-shakshuka-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Klassischer Griechischer Salat", "recipeId": "seed-griechsalat-01"},
          {"mealType": "Abendessen", "recipeTitle": "One-Pan Lachs mit Ofengemüse", "recipeId": "seed-lachs-01"},
          {"mealType": "Dessert", "recipeTitle": "Schokoladen-Lava-Cake", "recipeId": "seed-lavacake-01"}
        ]
      }
    ]'::jsonb,
    true, 218
  ) ON CONFLICT DO NOTHING;

  -- ─────────────────────────────────────────────────────────
  -- Wochenplan 3: "Vegane Wohlfühlwoche"
  -- ─────────────────────────────────────────────────────────
  INSERT INTO public.community_meal_plans (
    user_id, author_name, title, description, tags, plan_json, is_published, view_count
  ) VALUES (
    v_user3, 'Lena Grünzeug',
    'Vegane Wohlfühlwoche 🌱',
    'Eine vollständig vegane Woche voller Geschmack. Beweise dass Pflanzenkost alles andere als langweilig ist!',
    ARRAY['Vegan','Pflanzlich','Nachhaltig','Gesund','Herbst'],
    '[
      {
        "day": "Montag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Bananenpfannkuchen (3 Zutaten)", "recipeId": "seed-bananenpancake-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Herzhafte Linsensuppe", "recipeId": "seed-linsensuppe-01"},
          {"mealType": "Abendessen", "recipeTitle": "Vegane Tacos mit Schwarzen Bohnen", "recipeId": "seed-vegantacos-01"}
        ]
      },
      {
        "day": "Dienstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Cremige Kürbissuppe (Vegan)", "recipeId": "seed-kuerbissuppe-01"},
          {"mealType": "Abendessen", "recipeTitle": "Vegane Tacos mit Schwarzen Bohnen", "recipeId": "seed-vegantacos-01"}
        ]
      },
      {
        "day": "Mittwoch",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Bananenpfannkuchen (3 Zutaten)", "recipeId": "seed-bananenpancake-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Klassischer Griechischer Salat", "recipeId": "seed-griechsalat-01"},
          {"mealType": "Abendessen", "recipeTitle": "Herzhafte Linsensuppe", "recipeId": "seed-linsensuppe-01"}
        ]
      },
      {
        "day": "Donnerstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Cremige Kürbissuppe (Vegan)", "recipeId": "seed-kuerbissuppe-01"},
          {"mealType": "Abendessen", "recipeTitle": "Vegane Tacos mit Schwarzen Bohnen", "recipeId": "seed-vegantacos-01"}
        ]
      },
      {
        "day": "Freitag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Bananenpfannkuchen (3 Zutaten)", "recipeId": "seed-bananenpancake-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Herzhafte Linsensuppe", "recipeId": "seed-linsensuppe-01"},
          {"mealType": "Abendessen", "recipeTitle": "Hähnchen-Teriyaki Bowl", "recipeId": "seed-teriyaki-01"}
        ]
      },
      {
        "day": "Samstag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Shakshuka – Eier in Tomatensauce", "recipeId": "seed-shakshuka-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Klassischer Griechischer Salat", "recipeId": "seed-griechsalat-01"},
          {"mealType": "Abendessen", "recipeTitle": "Vegane Tacos mit Schwarzen Bohnen", "recipeId": "seed-vegantacos-01"}
        ]
      },
      {
        "day": "Sonntag",
        "slots": [
          {"mealType": "Frühstück", "recipeTitle": "Avocado Toast mit Spiegelei", "recipeId": "seed-avotoast-01"},
          {"mealType": "Mittagessen", "recipeTitle": "Cremige Kürbissuppe (Vegan)", "recipeId": "seed-kuerbissuppe-01"},
          {"mealType": "Abendessen", "recipeTitle": "Herzhafte Linsensuppe", "recipeId": "seed-linsensuppe-01"},
          {"mealType": "Dessert", "recipeTitle": "Bananenpfannkuchen (3 Zutaten)", "recipeId": "seed-bananenpancake-01"}
        ]
      }
    ]'::jsonb,
    true, 156
  ) ON CONFLICT DO NOTHING;

  RAISE NOTICE '✅ 3 Community-Wochenpläne erfolgreich eingefügt!';
END $$;

-- ─── Ergebnis prüfen ───
SELECT
  title,
  author_name,
  array_length(tags, 1) AS tag_count,
  jsonb_array_length(plan_json) AS tage,
  view_count,
  is_published
FROM public.community_meal_plans
ORDER BY created_at DESC
LIMIT 10;

