-- ============================================================
-- Migration 26: Meine Communities
-- ============================================================
-- Tabellen: communities, community_members, community_posts, community_shares
-- Pro-Gate: Erstellen erfordert Pro; Beitreten ist für alle möglich
-- Max. 50 Mitglieder pro Community
-- Admin muss jeden Beitritt manuell bestätigen
-- community_shares: nach "Abgeholt"-Markierung sofort gelöscht (Trigger)
-- ============================================================

-- ── 1. communities ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.communities (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  description   TEXT,
  plz           TEXT,                         -- Postleitzahl (optional)
  city          TEXT,                         -- Stadt (optional, für Anzeige)
  invite_code   TEXT UNIQUE NOT NULL,
  admin_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  max_members   INT NOT NULL DEFAULT 50,
  is_public     BOOLEAN NOT NULL DEFAULT true, -- bei PLZ-Suche sichtbar
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 2. community_members ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.community_members (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id   UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name   TEXT,
  status         TEXT NOT NULL DEFAULT 'pending'  -- 'pending' | 'active' | 'rejected'
                   CHECK (status IN ('pending', 'active', 'rejected')),
  joined_at      TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(community_id, user_id)
);

-- ── 3. community_posts ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.community_posts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id    UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content         TEXT NOT NULL CHECK (char_length(content) <= 1000),
  recipe_id       TEXT,                        -- optional: eigenes Rezept anhängen
  meal_plan_id    UUID,                        -- optional: eigener Wochenplan anhängen
  recipe_title    TEXT,                        -- gecachter Titel für schnelle Anzeige
  meal_plan_title TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 4. community_shares (Reste / Vorrat verschenken) ────────────────────────
CREATE TABLE IF NOT EXISTS public.community_shares (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id     UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  offered_by       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  offered_by_name  TEXT,
  item_name        TEXT NOT NULL,
  quantity         TEXT,                       -- z.B. "500 g", "1 Stück"
  note             TEXT,
  status           TEXT NOT NULL DEFAULT 'available'
                     CHECK (status IN ('available', 'claimed')),
  claimed_by       UUID REFERENCES auth.users(id),
  claimed_by_name  TEXT,
  claimed_at       TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 5. Trigger: community_shares nach claim sofort löschen ──────────────────
CREATE OR REPLACE FUNCTION public.delete_claimed_share()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'claimed' THEN
    DELETE FROM public.community_shares WHERE id = NEW.id;
    RETURN NULL; -- verhindert Update, da Zeile bereits gelöscht
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_delete_claimed_share ON public.community_shares;
CREATE TRIGGER trg_delete_claimed_share
  BEFORE UPDATE OF status ON public.community_shares
  FOR EACH ROW EXECUTE FUNCTION public.delete_claimed_share();

-- ── 6. Trigger: max_members Check beim Beitritt ──────────────────────────────
CREATE OR REPLACE FUNCTION public.check_community_max_members()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  current_count INT;
  max_count     INT;
BEGIN
  -- Nur bei neuen aktiven Mitgliedern prüfen
  IF NEW.status = 'active' THEN
    SELECT COUNT(*) INTO current_count
      FROM public.community_members
      WHERE community_id = NEW.community_id AND status = 'active';
    SELECT max_members INTO max_count
      FROM public.communities WHERE id = NEW.community_id;
    IF current_count >= max_count THEN
      RAISE EXCEPTION 'Community ist voll (max. % Mitglieder)', max_count;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_community_max_members ON public.community_members;
CREATE TRIGGER trg_check_community_max_members
  BEFORE INSERT OR UPDATE OF status ON public.community_members
  FOR EACH ROW EXECUTE FUNCTION public.check_community_max_members();

-- ── 7. Helper: Community per invite_code finden (security-definer) ───────────
CREATE OR REPLACE FUNCTION public.get_community_by_invite_code(code TEXT)
RETURNS SETOF public.communities
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT * FROM public.communities WHERE invite_code = upper(trim(code));
$$;

-- ── 8. updated_at auto-update ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_communities_updated_at ON public.communities;
CREATE TRIGGER trg_communities_updated_at
  BEFORE UPDATE ON public.communities
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_community_posts_updated_at ON public.community_posts;
CREATE TRIGGER trg_community_posts_updated_at
  BEFORE UPDATE ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── 9. Indexes ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_community_members_community ON public.community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_user     ON public.community_members(user_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_community  ON public.community_posts(community_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_shares_community ON public.community_shares(community_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_communities_plz            ON public.communities(plz);

-- ── 10. RLS aktivieren ────────────────────────────────────────────────────────
ALTER TABLE public.communities        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_shares   ENABLE ROW LEVEL SECURITY;

-- ── 11. Hilfsfunktion gegen infinite recursion ───────────────────────────────
-- SECURITY DEFINER → umgeht RLS, kein Self-Join in den Policies nötig
CREATE OR REPLACE FUNCTION public.get_my_active_community_ids(uid UUID)
RETURNS TABLE(community_id UUID)
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT community_id
  FROM public.community_members
  WHERE user_id = uid AND status = 'active';
$$;

-- communities: alle Auth-User dürfen lesen (PLZ-Suche), nur Admin darf schreiben
CREATE POLICY "communities_select" ON public.communities
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "communities_insert" ON public.communities
  FOR INSERT TO authenticated WITH CHECK (admin_id = auth.uid());

CREATE POLICY "communities_update" ON public.communities
  FOR UPDATE TO authenticated USING (admin_id = auth.uid());

CREATE POLICY "communities_delete" ON public.communities
  FOR DELETE TO authenticated USING (admin_id = auth.uid());

-- community_members: kein Self-Join → Hilfsfunktion nutzen
CREATE POLICY "community_members_select" ON public.community_members
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT cm.community_id FROM public.get_my_active_community_ids(auth.uid()) cm
    )
  );

CREATE POLICY "community_members_insert" ON public.community_members
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "community_members_update" ON public.community_members
  FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

CREATE POLICY "community_members_delete" ON public.community_members
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    OR community_id IN (
      SELECT id FROM public.communities WHERE admin_id = auth.uid()
    )
  );

-- community_posts: Hilfsfunktion statt Self-Join
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

-- community_shares: Hilfsfunktion statt Self-Join
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

