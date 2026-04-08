-- Migration 17: Haushalt-Feature-Einstellungen (Admin-gesteuert)
-- Fügt shared_inventory, shared_shopping_list und shared_meal_plan
-- als Admin-Einstellungen zum households-Tabelle hinzu.
-- Wenn Admin aktiviert → gilt für ALLE Mitglieder.

ALTER TABLE public.households
  ADD COLUMN IF NOT EXISTS shared_inventory    boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS shared_shopping_list boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS shared_meal_plan    boolean NOT NULL DEFAULT false;

-- Kommentare
COMMENT ON COLUMN public.households.shared_inventory     IS 'Admin-Einstellung: Gemeinsamer Vorrat für alle Mitglieder';
COMMENT ON COLUMN public.households.shared_shopping_list IS 'Admin-Einstellung: Gemeinsame Einkaufsliste für alle Mitglieder';
COMMENT ON COLUMN public.households.shared_meal_plan     IS 'Admin-Einstellung: Gemeinsamer Wochenplan für alle Mitglieder';

-- RLS: Nur Admin darf diese Felder updaten
-- (bestehende RLS-Policy für households update wird erweitert)
-- Falls noch keine Update-Policy existiert:
DO $$
BEGIN
  -- Policy: Nur Haushaltsmitglieder dürfen lesen
  -- (normalerweise schon vorhanden)

  -- Policy: Nur Admin darf Haushalt-Settings ändern
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'households'
      AND policyname = 'admin_can_update_household_settings'
  ) THEN
    CREATE POLICY admin_can_update_household_settings
      ON public.households
      FOR UPDATE
      USING (
        EXISTS (
          SELECT 1 FROM public.household_members hm
          WHERE hm.household_id = households.id
            AND hm.user_id = auth.uid()
            AND hm.role = 'admin'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.household_members hm
          WHERE hm.household_id = households.id
            AND hm.user_id = auth.uid()
            AND hm.role = 'admin'
        )
      );
  END IF;
END $$;

