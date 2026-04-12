-- ============================================================
-- Migration 26b: RLS Fix – community_members infinite recursion
-- ============================================================
-- Problem: community_members_select Policy fragt community_members
--          selbst ab → "infinite recursion detected in policy"
-- Lösung:  security-definer Hilfsfunktion die RLS umgeht,
--          identisch zum Muster aus household_rls_fix.
-- ============================================================

-- ── 1. Hilfsfunktion: gibt aktive community_ids des Users zurück ─────────────
--    SECURITY DEFINER → läuft als postgres, umgeht RLS → kein Loop
CREATE OR REPLACE FUNCTION public.get_my_active_community_ids(uid UUID)
RETURNS TABLE(community_id UUID)
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT community_id
  FROM public.community_members
  WHERE user_id = uid AND status = 'active';
$$;

-- ── 2. Alte rekursive Policies droppen ───────────────────────────────────────
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

-- ── 3. community_members – neue Policies (kein Self-Join) ────────────────────

-- SELECT: eigene Zeile ODER Mitglied einer gemeinsamen aktiven Community
CREATE POLICY "community_members_select" ON public.community_members
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT cm.community_id
      FROM public.get_my_active_community_ids(auth.uid()) cm
    )
  );

-- INSERT: nur eigene Zeile
CREATE POLICY "community_members_insert" ON public.community_members
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- UPDATE: eigene Zeile ODER Admin der Community (via communities-Tabelle, kein Self-Join)
CREATE POLICY "community_members_update" ON public.community_members
  FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

-- DELETE: eigene Zeile ODER Admin der Community
CREATE POLICY "community_members_delete" ON public.community_members
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

-- ── 4. community_posts – neue Policies ───────────────────────────────────────

CREATE POLICY "community_posts_select" ON public.community_posts
  FOR SELECT TO authenticated
  USING (
    community_id IN (
      SELECT cm.community_id FROM public.get_my_active_community_ids(auth.uid()) cm
    )
  );

CREATE POLICY "community_posts_insert" ON public.community_posts
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND community_id IN (
      SELECT cm.community_id FROM public.get_my_active_community_ids(auth.uid()) cm
    )
  );

CREATE POLICY "community_posts_delete" ON public.community_posts
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

-- ── 5. community_shares – neue Policies ──────────────────────────────────────

CREATE POLICY "community_shares_select" ON public.community_shares
  FOR SELECT TO authenticated
  USING (
    community_id IN (
      SELECT cm.community_id FROM public.get_my_active_community_ids(auth.uid()) cm
    )
  );

CREATE POLICY "community_shares_insert" ON public.community_shares
  FOR INSERT TO authenticated
  WITH CHECK (
    offered_by = auth.uid()
    AND community_id IN (
      SELECT cm.community_id FROM public.get_my_active_community_ids(auth.uid()) cm
    )
  );

CREATE POLICY "community_shares_update" ON public.community_shares
  FOR UPDATE TO authenticated
  USING (
    community_id IN (
      SELECT cm.community_id FROM public.get_my_active_community_ids(auth.uid()) cm
    )
  );

CREATE POLICY "community_shares_delete" ON public.community_shares
  FOR DELETE TO authenticated
  USING (
    offered_by = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

