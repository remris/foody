-- ============================================================
-- Migration 27 – Voraussetzung: Funktion get_my_active_community_ids
-- Führe dieses Skript VOR supabase_migration_27_share_requests.sql aus
-- (oder falls Migration 26 nicht vollständig ausgeführt wurde)
-- ============================================================

-- ── Hilfsfunktion: gibt alle Community-IDs zurück, in denen der User aktiv ist
-- SECURITY DEFINER → umgeht RLS, verhindert infinite recursion in Policies
CREATE OR REPLACE FUNCTION public.get_my_active_community_ids(uid UUID)
RETURNS TABLE(community_id UUID)
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT community_id
  FROM public.community_members
  WHERE user_id = uid AND status = 'active';
$$;

-- Stelle sicher, dass authenticated-User die Funktion aufrufen dürfen
GRANT EXECUTE ON FUNCTION public.get_my_active_community_ids(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_active_community_ids(UUID) TO anon;

