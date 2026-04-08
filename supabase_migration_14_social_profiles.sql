-- Migration 14: Social Profiles & Follow-System
-- Ausführen in: Supabase Dashboard → SQL Editor

-- ─── user_profiles Tabelle ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  TEXT,
  bio           TEXT CHECK (char_length(bio) <= 200),
  avatar_url    TEXT,
  social_links  JSONB DEFAULT '{}'::jsonb,
  -- social_links Schema: { "instagram": "@handle", "tiktok": "@handle", "youtube": "url", "website": "url" }
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- ─── user_follows Tabelle ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_follows (
  follower_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  followee_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (follower_id, followee_id),
  CHECK (follower_id <> followee_id)
);

-- ─── Indizes ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_followee ON public.user_follows(followee_id);

-- ─── Trigger: Profil bei Registrierung automatisch anlegen ───────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_profile();

-- ─── Für bestehende User Profile anlegen ─────────────────────────────────────
INSERT INTO public.user_profiles (id, display_name)
SELECT id, split_part(email, '@', 1)
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ─── RLS aktivieren ───────────────────────────────────────────────────────────
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;

-- user_profiles: Jeder kann lesen, nur eigenes Profil bearbeiten
CREATE POLICY "profiles_public_read" ON public.user_profiles
  FOR SELECT USING (true);

CREATE POLICY "profiles_own_update" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "profiles_own_insert" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- user_follows: Jeder kann lesen, nur eigene Follows anlegen/löschen
CREATE POLICY "follows_public_read" ON public.user_follows
  FOR SELECT USING (true);

CREATE POLICY "follows_own_insert" ON public.user_follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "follows_own_delete" ON public.user_follows
  FOR DELETE USING (auth.uid() = follower_id);

-- ─── Storage Bucket für Avatare ───────────────────────────────────────────────
-- Manuell im Dashboard anlegen: Storage → New Bucket → "avatars" → Public
-- Oder via SQL:
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatars_own_upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_own_update" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_own_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

