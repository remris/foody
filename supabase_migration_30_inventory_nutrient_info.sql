-- Migration 30: nutrient_info JSONB-Spalte für user_inventory
-- Speichert Nährwerte pro 100g die beim Barcode-Scan von OpenFoodFacts ausgelesen werden.

ALTER TABLE user_inventory
  ADD COLUMN IF NOT EXISTS nutrient_info JSONB DEFAULT NULL;

COMMENT ON COLUMN user_inventory.nutrient_info IS
  'Nährwerte pro 100g: {kcal_100g, protein_100g, fat_100g, carbs_100g, fiber_100g, salt_100g}. '
  'Wird beim Barcode-Scan aus OpenFoodFacts befüllt.';

