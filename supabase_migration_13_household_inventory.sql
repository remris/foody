-- Migration 13: Household Inventory (geteilter Vorrat)
-- Fügt household_id zu user_inventory hinzu, damit Items geteilt werden können.

-- 1. Spalte hinzufügen
ALTER TABLE user_inventory
  ADD COLUMN IF NOT EXISTS household_id uuid REFERENCES households(id) ON DELETE SET NULL;

-- 2. Index
CREATE INDEX IF NOT EXISTS idx_user_inventory_household ON user_inventory(household_id)
  WHERE household_id IS NOT NULL;

-- 3. RLS-Policies ersetzen
DROP POLICY IF EXISTS "user_inventory_select" ON user_inventory;
DROP POLICY IF EXISTS "user_inventory_insert" ON user_inventory;
DROP POLICY IF EXISTS "user_inventory_update" ON user_inventory;
DROP POLICY IF EXISTS "user_inventory_delete" ON user_inventory;
DROP POLICY IF EXISTS "user_inventory_policy" ON user_inventory;

-- Select: Eigene Items + Haushalt-Items
CREATE POLICY "user_inventory_select" ON user_inventory FOR SELECT USING (
  auth.uid() = user_id
  OR (
    household_id IS NOT NULL
    AND household_id IN (
      SELECT hm.household_id FROM household_members hm WHERE hm.user_id = auth.uid()
    )
  )
);

-- Insert: Nur eigene Items oder Items für den eigenen Haushalt
CREATE POLICY "user_inventory_insert" ON user_inventory FOR INSERT WITH CHECK (
  auth.uid() = user_id
  AND (
    household_id IS NULL
    OR household_id IN (
      SELECT hm.household_id FROM household_members hm WHERE hm.user_id = auth.uid()
    )
  )
);

-- Update: Eigene Items oder Haushalt-Items
CREATE POLICY "user_inventory_update" ON user_inventory FOR UPDATE USING (
  auth.uid() = user_id
  OR (
    household_id IS NOT NULL
    AND household_id IN (
      SELECT hm.household_id FROM household_members hm WHERE hm.user_id = auth.uid()
    )
  )
);

-- Delete: Eigene Items oder Haushalt-Items
CREATE POLICY "user_inventory_delete" ON user_inventory FOR DELETE USING (
  auth.uid() = user_id
  OR (
    household_id IS NOT NULL
    AND household_id IN (
      SELECT hm.household_id FROM household_members hm WHERE hm.user_id = auth.uid()
    )
  )
);

-- 4. RPC: Alle persönlichen Items in den Haushalt migrieren
CREATE OR REPLACE FUNCTION migrate_items_to_household(p_household_id uuid)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  migrated integer;
BEGIN
  -- Prüfe ob User Mitglied des Haushalts ist
  IF NOT EXISTS (
    SELECT 1 FROM household_members WHERE user_id = auth.uid() AND household_id = p_household_id
  ) THEN
    RAISE EXCEPTION 'Nicht Mitglied dieses Haushalts';
  END IF;

  UPDATE user_inventory
  SET household_id = p_household_id
  WHERE user_id = auth.uid()
    AND household_id IS NULL;

  GET DIAGNOSTICS migrated = ROW_COUNT;
  RETURN migrated;
END;
$$;

-- 5. RPC: Haushalt-Items zurück zu persönlich migrieren (beim Verlassen)
CREATE OR REPLACE FUNCTION migrate_items_from_household(p_household_id uuid)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  migrated integer;
BEGIN
  UPDATE user_inventory
  SET household_id = NULL
  WHERE user_id = auth.uid()
    AND household_id = p_household_id;

  GET DIAGNOSTICS migrated = ROW_COUNT;
  RETURN migrated;
END;
$$;

