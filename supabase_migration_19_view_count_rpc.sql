-- Migration: Increment View Count RPC Funktion
-- Führe dieses Script im Supabase SQL Editor aus.

-- Funktion: view_count für community_recipes und community_meal_plans erhöhen
CREATE OR REPLACE FUNCTION increment_view_count(p_table text, p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_table = 'community_recipes' THEN
    UPDATE community_recipes
    SET view_count = view_count + 1
    WHERE id = p_id;
  ELSIF p_table = 'community_meal_plans' THEN
    UPDATE community_meal_plans
    SET view_count = view_count + 1
    WHERE id = p_id;
  END IF;
END;
$$;

-- Zugriffsrechte für authentifizierte User
GRANT EXECUTE ON FUNCTION increment_view_count(text, uuid) TO authenticated;

-- Sicherstellen dass view_count Spalten existieren (falls noch nicht vorhanden)
ALTER TABLE community_recipes
  ADD COLUMN IF NOT EXISTS view_count int DEFAULT 0;

ALTER TABLE community_meal_plans
  ADD COLUMN IF NOT EXISTS view_count int DEFAULT 0;

