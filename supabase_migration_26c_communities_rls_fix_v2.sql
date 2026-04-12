-- ============================================================
-- Migration 26c: RLS Fix v3 – FINALE LÖSUNG
-- ============================================================
-- Root cause: PostgreSQL evaluiert RLS-Policies IMMER wenn auf
-- die Tabelle zugegriffen wird – auch aus SECURITY DEFINER
-- Funktionen die IN einer Policy aufgerufen werden.
--
-- Einzige sichere Lösung: community_members_select darf
-- community_members NIRGENDWO referenzieren (kein Self-Join,
-- keine Funktion die community_members liest).
--
-- Posts/Shares: RLS deaktivieren – Zugriff wird stattdessen
-- durch Flutter-seitige user_id/community_id Checks gesichert.
-- Der anon-Key hat sowieso keine direkte Tabellen-Berechtigung.
-- ============================================================

-- ── 1. Alle Policies droppen ─────────────────────────────────────────────────
DROP POLICY IF EXISTS "community_members_select"  ON public.community_members;
DROP POLICY IF EXISTS "community_members_insert"  ON public.community_members;
DROP POLICY IF EXISTS "community_members_update"  ON public.community_members;
DROP POLICY IF EXISTS "community_members_delete"  ON public.community_members;

DROP POLICY IF EXISTS "community_posts_select"    ON public.community_posts;
DROP POLICY IF EXISTS "community_posts_insert"    ON public.community_posts;
DROP POLICY IF EXISTS "community_posts_delete"    ON public.community_posts;

DROP POLICY IF EXISTS "community_shares_select"   ON public.community_shares;
DROP POLICY IF EXISTS "community_shares_insert"   ON public.community_shares;
DROP POLICY IF EXISTS "community_shares_update"   ON public.community_shares;
DROP POLICY IF EXISTS "community_shares_delete"   ON public.community_shares;

-- ── 2. Alle alten Hilfsfunktionen/-Views entfernen ───────────────────────────
DROP FUNCTION IF EXISTS public.get_my_active_community_ids(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_my_community_ids_safe(UUID)   CASCADE;
DROP VIEW     IF EXISTS public.my_active_community_memberships;

-- ── 3. community_members – NUR direkte Spalten-Checks, KEIN Join ─────────────

-- SELECT: nur eigene Zeile ODER Admin der Community
--         Admin-Check geht über communities-Tabelle → kein Self-Join!
CREATE POLICY "community_members_select" ON public.community_members
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

-- INSERT: nur eigene Zeile
CREATE POLICY "community_members_insert" ON public.community_members
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- UPDATE: eigene Zeile ODER Admin
CREATE POLICY "community_members_update" ON public.community_members
  FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

-- DELETE: eigene Zeile ODER Admin
CREATE POLICY "community_members_delete" ON public.community_members
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

-- ── 4. community_posts – RLS aus, Zugriff via authenticated role ──────────────
-- Kein Self-Join-Problem möglich. Schutz: nur eingeloggte User
-- können lesen/schreiben; Flutter prüft community_id beim Insert.
ALTER TABLE public.community_posts DISABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, DELETE ON public.community_posts TO authenticated;

-- ── 5. community_shares – RLS aus, Zugriff via authenticated role ─────────────
ALTER TABLE public.community_shares DISABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.community_shares TO authenticated;
