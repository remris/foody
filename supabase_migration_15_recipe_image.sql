-- Migration 15: image_url Spalte für Rezepte
-- Führe dieses SQL in der Supabase SQL-Konsole aus

-- 1. Füge image_url Spalte zu saved_recipes hinzu (falls Tabelle existiert)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'saved_recipes') THEN
    IF NOT EXISTS (SELECT FROM information_schema.columns
                   WHERE table_name = 'saved_recipes' AND column_name = 'image_url') THEN
      ALTER TABLE public.saved_recipes ADD COLUMN image_url TEXT;
      RAISE NOTICE 'Added image_url to saved_recipes';
    END IF;
  END IF;
END $$;

-- 2. Füge image_url Spalte zu community_recipes hinzu
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'community_recipes') THEN
    IF NOT EXISTS (SELECT FROM information_schema.columns
                   WHERE table_name = 'community_recipes' AND column_name = 'image_url') THEN
      ALTER TABLE public.community_recipes ADD COLUMN image_url TEXT;
      RAISE NOTICE 'Added image_url to community_recipes';
    END IF;
  END IF;
END $$;

-- 3. Optional: Index auf image_url für bessere Performance bei Abfragen
CREATE INDEX IF NOT EXISTS idx_saved_recipes_has_image
  ON public.saved_recipes ((image_url IS NOT NULL))
  WHERE image_url IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_community_recipes_has_image
  ON public.community_recipes ((image_url IS NOT NULL))
  WHERE image_url IS NOT NULL;

-- 4. Kommentar hinzufügen
COMMENT ON COLUMN public.saved_recipes.image_url IS 'URL zum Rezeptbild (optional)';
COMMENT ON COLUMN public.community_recipes.image_url IS 'URL zum Rezeptbild (optional)';

