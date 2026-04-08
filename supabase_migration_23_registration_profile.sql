-- Migration 23: referral_source Spalte zu user_profiles hinzufügen
-- Die Tabelle user_profiles wurde in Migration 14 erstellt.
-- Datum: April 2026

-- referral_source Spalte hinzufügen (falls nicht vorhanden)
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS referral_source TEXT DEFAULT '';

-- display_name ist bereits in Migration 14 vorhanden – sicherstellen
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Trigger aktualisieren: display_name aus Supabase-Auth-Metadaten lesen
-- (wird bei Registrierung mit signUpWithProfile gesetzt)
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, display_name, referral_source)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      split_part(NEW.email, '@', 1)
    ),
    COALESCE(NEW.raw_user_meta_data->>'referral_source', '')
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name = COALESCE(
      EXCLUDED.display_name,
      public.user_profiles.display_name
    ),
    referral_source = COALESCE(
      EXCLUDED.referral_source,
      public.user_profiles.referral_source,
      ''
    );
  RETURN NEW;
END;
$$;

-- Trigger neu anlegen
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_profile();

-- Index für referral_source (für Analytics)
CREATE INDEX IF NOT EXISTS idx_user_profiles_referral_source
  ON public.user_profiles (referral_source)
  WHERE referral_source IS NOT NULL AND referral_source != '';

COMMENT ON COLUMN public.user_profiles.referral_source IS
  'Woher der User die App kennt (aus Registrierung)';

