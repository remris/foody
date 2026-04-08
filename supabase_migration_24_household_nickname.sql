-- Migration 24: household_nickname Spalte in user_profiles
-- Ermöglicht einen separaten Spitznamen für den Haushalt
-- (nur für Haushaltsmitglieder sichtbar, Community-Name bleibt display_name)

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS household_nickname TEXT;

COMMENT ON COLUMN public.user_profiles.household_nickname IS
  'Optionaler Spitzname für den Haushalt (z.B. Papa, Mama). Nur intern sichtbar, nicht in der Community.';

