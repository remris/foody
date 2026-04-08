-- Migration: Bewertungssystem für Community-Rezepte
-- Führe dieses Script in deiner Supabase SQL-Konsole aus

-- 1. avg_rating und rating_count zu community_recipes hinzufügen
ALTER TABLE community_recipes
  ADD COLUMN IF NOT EXISTS avg_rating DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS rating_count INTEGER NOT NULL DEFAULT 0;

-- 2. recipe_ratings Tabelle erstellen
CREATE TABLE IF NOT EXISTS recipe_ratings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id    UUID NOT NULL REFERENCES community_recipes(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stars        INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (recipe_id, user_id)
);

-- 3. Index für schnelle Abfragen
CREATE INDEX IF NOT EXISTS idx_recipe_ratings_recipe_id ON recipe_ratings(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ratings_user_id ON recipe_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_community_recipes_avg_rating ON community_recipes(avg_rating DESC NULLS LAST);

-- 4. RLS aktivieren
ALTER TABLE recipe_ratings ENABLE ROW LEVEL SECURITY;

-- Jeder kann Bewertungen lesen
CREATE POLICY "recipe_ratings_select" ON recipe_ratings
  FOR SELECT USING (true);

-- Nur eingeloggte User können bewerten
CREATE POLICY "recipe_ratings_insert" ON recipe_ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User können ihre eigene Bewertung updaten
CREATE POLICY "recipe_ratings_update" ON recipe_ratings
  FOR UPDATE USING (auth.uid() = user_id);

-- User können ihre eigene Bewertung löschen
CREATE POLICY "recipe_ratings_delete" ON recipe_ratings
  FOR DELETE USING (auth.uid() = user_id);

-- 5. Funktion zum automatischen Aktualisieren von avg_rating + rating_count
CREATE OR REPLACE FUNCTION update_recipe_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE community_recipes
  SET
    avg_rating = (
      SELECT AVG(stars)::DOUBLE PRECISION
      FROM recipe_ratings
      WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id)
    ),
    rating_count = (
      SELECT COUNT(*)::INTEGER
      FROM recipe_ratings
      WHERE recipe_id = COALESCE(NEW.recipe_id, OLD.recipe_id)
    )
  WHERE id = COALESCE(NEW.recipe_id, OLD.recipe_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Trigger setzen
DROP TRIGGER IF EXISTS trigger_update_recipe_rating_stats ON recipe_ratings;
CREATE TRIGGER trigger_update_recipe_rating_stats
  AFTER INSERT OR UPDATE OR DELETE ON recipe_ratings
  FOR EACH ROW EXECUTE FUNCTION update_recipe_rating_stats();

-- 7. Bestehende avg_rating + rating_count initialisieren (falls schon Ratings da wären)
UPDATE community_recipes r
SET
  avg_rating = sub.avg,
  rating_count = sub.cnt
FROM (
  SELECT recipe_id, AVG(stars)::DOUBLE PRECISION AS avg, COUNT(*)::INTEGER AS cnt
  FROM recipe_ratings
  GROUP BY recipe_id
) sub
WHERE r.id = sub.recipe_id;

