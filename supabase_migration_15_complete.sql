-- Migration 15 KOMPLETT: image_url Spalte anlegen + Testbilder befüllen
-- Führe NUR DIESES SCRIPT aus (ersetzt Migration 15 + 15b)

-- ─── 1. Spalten anlegen ───
ALTER TABLE public.community_recipes
  ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE public.saved_recipes
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ─── 2. Community Rezepte mit Testbildern befüllen ───
UPDATE public.community_recipes
SET image_url = CASE
  WHEN title ILIKE '%pasta%' OR title ILIKE '%spaghetti%' OR title ILIKE '%nudel%' OR title ILIKE '%carbonara%'
    THEN 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80'
  WHEN title ILIKE '%pizza%'
    THEN 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80'
  WHEN title ILIKE '%suppe%' OR title ILIKE '%eintopf%'
    THEN 'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&q=80'
  WHEN title ILIKE '%salat%'
    THEN 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80'
  WHEN title ILIKE '%hähnchen%' OR title ILIKE '%huhn%' OR title ILIKE '%chicken%'
    THEN 'https://images.unsplash.com/photo-1598103442097-8b74394b95c5?w=800&q=80'
  WHEN title ILIKE '%burger%'
    THEN 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80'
  WHEN title ILIKE '%steak%' OR title ILIKE '%rind%'
    THEN 'https://images.unsplash.com/photo-1546964124-0cce460f38ef?w=800&q=80'
  WHEN title ILIKE '%fisch%' OR title ILIKE '%lachs%' OR title ILIKE '%thunfisch%'
    THEN 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800&q=80'
  WHEN title ILIKE '%curry%'
    THEN 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800&q=80'
  WHEN title ILIKE '%reis%' OR title ILIKE '%risotto%'
    THEN 'https://images.unsplash.com/photo-1536304993881-ff86e0c9c02e?w=800&q=80'
  WHEN title ILIKE '%kuchen%' OR title ILIKE '%torte%' OR title ILIKE '%tiramisu%' OR title ILIKE '%dessert%'
    THEN 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80'
  WHEN title ILIKE '%pancake%' OR title ILIKE '%waffel%' OR title ILIKE '%rührei%' OR title ILIKE '%frühstück%'
    THEN 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80'
  WHEN title ILIKE '%sandwich%' OR title ILIKE '%toast%' OR title ILIKE '%brot%'
    THEN 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=800&q=80'
  WHEN title ILIKE '%vegan%' OR title ILIKE '%vegetarisch%' OR title ILIKE '%tofu%' OR title ILIKE '%gemüse%'
    THEN 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80'
  WHEN title ILIKE '%sushi%' OR title ILIKE '%ramen%' OR title ILIKE '%wok%' OR title ILIKE '%thai%'
    THEN 'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=800&q=80'
  WHEN title ILIKE '%taco%' OR title ILIKE '%burrito%' OR title ILIKE '%mexikan%'
    THEN 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80'
  ELSE
    CASE (('x' || substr(id::text, 1, 8))::bit(32)::int % 5)
      WHEN 0 THEN 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80'
      WHEN 1 THEN 'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=800&q=80'
      WHEN 2 THEN 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80'
      WHEN 3 THEN 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800&q=80'
      ELSE       'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80'
    END
END;

-- ─── 3. saved_recipes: imageUrl in recipe_json schreiben ───
-- (saved_recipes nutzt recipe_json JSONB, kein separates image_url Feld nötig im Code)
UPDATE public.saved_recipes
SET recipe_json = recipe_json || jsonb_build_object('imageUrl',
  CASE
    WHEN title ILIKE '%pasta%' OR title ILIKE '%spaghetti%' OR title ILIKE '%nudel%'
      THEN 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80'
    WHEN title ILIKE '%pizza%'
      THEN 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80'
    WHEN title ILIKE '%suppe%' OR title ILIKE '%eintopf%'
      THEN 'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&q=80'
    WHEN title ILIKE '%salat%'
      THEN 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80'
    WHEN title ILIKE '%hähnchen%' OR title ILIKE '%chicken%'
      THEN 'https://images.unsplash.com/photo-1598103442097-8b74394b95c5?w=800&q=80'
    WHEN title ILIKE '%burger%'
      THEN 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80'
    WHEN title ILIKE '%curry%'
      THEN 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800&q=80'
    WHEN title ILIKE '%fisch%' OR title ILIKE '%lachs%'
      THEN 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800&q=80'
    WHEN title ILIKE '%kuchen%' OR title ILIKE '%tiramisu%' OR title ILIKE '%dessert%'
      THEN 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80'
    WHEN title ILIKE '%vegan%' OR title ILIKE '%vegetarisch%' OR title ILIKE '%gemüse%'
      THEN 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80'
    ELSE
      CASE (('x' || substr(id::text, 1, 8))::bit(32)::int % 5)
        WHEN 0 THEN 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80'
        WHEN 1 THEN 'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=800&q=80'
        WHEN 2 THEN 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80'
        WHEN 3 THEN 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800&q=80'
        ELSE       'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80'
      END
  END
);

-- ─── 4. Ergebnis prüfen ───
SELECT
  'community_recipes' AS tbl,
  COUNT(*) AS gesamt,
  COUNT(image_url) AS mit_bild
FROM public.community_recipes
UNION ALL
SELECT
  'saved_recipes' AS tbl,
  COUNT(*) AS gesamt,
  COUNT(recipe_json->>'imageUrl') AS mit_bild
FROM public.saved_recipes;

