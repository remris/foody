-- Migration 16: Recipe Images Storage Bucket
-- Ausführen im Supabase SQL Editor

-- ── Storage Bucket anlegen ────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'recipe-images',
  'recipe-images',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg','image/jpg','image/png','image/webp','image/heic']
) ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg','image/jpg','image/png','image/webp','image/heic'];

-- ── RLS Policies ──────────────────────────────────────────────────────────

-- Alle können öffentliche Bilder lesen
CREATE POLICY "recipe_images_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'recipe-images');

-- Eingeloggte User können eigene Bilder hochladen
CREATE POLICY "recipe_images_auth_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'recipe-images'
    AND (storage.foldername(name))[1] = 'recipe_images'
  );

-- User können nur eigene Bilder überschreiben/löschen
CREATE POLICY "recipe_images_auth_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'recipe-images'
    AND auth.uid()::text = (storage.foldername(name))[2]
  );

CREATE POLICY "recipe_images_auth_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'recipe-images'
    AND auth.uid()::text = (storage.foldername(name))[2]
  );

SELECT 'recipe-images Bucket und Policies angelegt ✅' AS status;

