-- Migration 09: Geteilter Haushalt-Wochenplan
-- Führe diesen SQL-Befehl im Supabase SQL Editor aus.

-- 1. household_id Spalte zu meal_plans hinzufügen (nullable = persönlicher Plan bleibt erhalten)
ALTER TABLE meal_plans ADD COLUMN IF NOT EXISTS household_id uuid REFERENCES households(id) ON DELETE CASCADE;

-- 2. Index für schnelle Haushalt-Abfragen
CREATE INDEX IF NOT EXISTS idx_meal_plans_household ON meal_plans(household_id, week_start);

-- 3. RLS-Policies: alle bestehenden erst droppen, dann neu anlegen
DROP POLICY IF EXISTS "Eigene Pläne" ON meal_plans;
DROP POLICY IF EXISTS "Haushalt-Wochenplan lesbar" ON meal_plans;
DROP POLICY IF EXISTS "Wochenplan schreiben" ON meal_plans;
DROP POLICY IF EXISTS "Wochenplan aktualisieren" ON meal_plans;
DROP POLICY IF EXISTS "Wochenplan löschen" ON meal_plans;

-- SELECT: eigene Einträge (ohne household_id) ODER Haushaltsmitglied
CREATE POLICY "Haushalt-Wochenplan lesbar" ON meal_plans
  FOR SELECT USING (
    (household_id IS NULL AND auth.uid() = user_id)
    OR
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

-- INSERT: nur eigene Einträge
CREATE POLICY "Wochenplan schreiben" ON meal_plans
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

-- UPDATE: eigener Eintrag ODER Haushaltsmitglied
CREATE POLICY "Wochenplan aktualisieren" ON meal_plans
  FOR UPDATE USING (
    auth.uid() = user_id
    OR household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

-- DELETE: eigener Eintrag ODER Haushaltsmitglied
CREATE POLICY "Wochenplan löschen" ON meal_plans
  FOR DELETE USING (
    auth.uid() = user_id
    OR household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

-- 4. Preferences-Tabelle: speichert ob ein User den Haushalt-Wochenplan nutzt
CREATE TABLE IF NOT EXISTS meal_plan_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL UNIQUE,
  use_household_plan boolean DEFAULT false,
  household_id uuid REFERENCES households(id) ON DELETE SET NULL,
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE meal_plan_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Eigene Präferenzen" ON meal_plan_preferences
  FOR ALL USING (auth.uid() = user_id);

