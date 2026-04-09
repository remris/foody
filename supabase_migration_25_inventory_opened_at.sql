-- Migration 25: opened_at Spalte für user_inventory
-- Fügt die "Geöffnet"-Funktionalität hinzu

ALTER TABLE user_inventory
  ADD COLUMN IF NOT EXISTS opened_at TIMESTAMPTZ DEFAULT NULL;

-- Index für schnelle Abfragen auf geöffnete Items
CREATE INDEX IF NOT EXISTS idx_user_inventory_opened
  ON user_inventory (user_id, opened_at)
  WHERE opened_at IS NOT NULL;

-- Kommentar
COMMENT ON COLUMN user_inventory.opened_at IS
  'Timestamp wann der Artikel geöffnet wurde. NULL = ungeöffnet.';

