-- Migration 08: Wochenplan Saves + Ratings
-- Ausführen in: Supabase Dashboard → SQL Editor

-- ── Tabelle: community_meal_plan_saves ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS community_meal_plan_saves (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id     UUID NOT NULL REFERENCES community_meal_plans(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, plan_id)
);

ALTER TABLE community_meal_plan_saves ENABLE ROW LEVEL SECURITY;

-- Jeder kann seine eigenen Saves sehen
CREATE POLICY "saves_select_own" ON community_meal_plan_saves
  FOR SELECT USING (auth.uid() = user_id);

-- Eigene Saves erstellen
CREATE POLICY "saves_insert_own" ON community_meal_plan_saves
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Eigene Saves löschen
CREATE POLICY "saves_delete_own" ON community_meal_plan_saves
  FOR DELETE USING (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_meal_plan_saves_user ON community_meal_plan_saves(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plan_saves_plan ON community_meal_plan_saves(plan_id);


-- ── Tabelle: community_meal_plan_ratings ────────────────────────────────────
CREATE TABLE IF NOT EXISTS community_meal_plan_ratings (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id     UUID NOT NULL REFERENCES community_meal_plans(id) ON DELETE CASCADE,
  stars       SMALLINT NOT NULL CHECK (stars BETWEEN 1 AND 5),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, plan_id)
);

ALTER TABLE community_meal_plan_ratings ENABLE ROW LEVEL SECURITY;

-- Alle können Bewertungen lesen (für Durchschnitt)
CREATE POLICY "ratings_select_all" ON community_meal_plan_ratings
  FOR SELECT USING (true);

-- Eigene Bewertung erstellen/aktualisieren
CREATE POLICY "ratings_insert_own" ON community_meal_plan_ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ratings_update_own" ON community_meal_plan_ratings
  FOR UPDATE USING (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_meal_plan_ratings_plan ON community_meal_plan_ratings(plan_id);
CREATE INDEX IF NOT EXISTS idx_meal_plan_ratings_user ON community_meal_plan_ratings(user_id);

