-- ============================================================
-- Migration 27: Community Teilen – Erweiterter Usecase
-- Abholungs-Anfragen, Hilfs-Anfragen, Mini-Chat
-- ============================================================

-- ── 1. Abholungsanfragen für Angebote ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.community_share_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  share_id      UUID NOT NULL REFERENCES public.community_shares(id) ON DELETE CASCADE,
  community_id  UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  TEXT,
  message       TEXT,
  status        TEXT NOT NULL DEFAULT 'pending'  -- pending | accepted | rejected
                CHECK (status IN ('pending','accepted','rejected')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 2. Suchanfragen (ich brauche X) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.community_help_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id  UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  TEXT,
  item_name     TEXT NOT NULL,
  quantity      TEXT,
  note          TEXT,
  status        TEXT NOT NULL DEFAULT 'open'  -- open | closed
                CHECK (status IN ('open','closed')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 3. Aushelfen-Angebote für Suchanfragen ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.community_help_offers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id    UUID NOT NULL REFERENCES public.community_help_requests(id) ON DELETE CASCADE,
  community_id  UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  TEXT,
  message       TEXT,
  status        TEXT NOT NULL DEFAULT 'pending'  -- pending | accepted
                CHECK (status IN ('pending','accepted')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 4. Mini-Chat (für Shares & Help-Anfragen) ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.community_messages (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  context_type   TEXT NOT NULL CHECK (context_type IN ('share','help')),
  context_id     UUID NOT NULL,   -- share_request id oder help_request id
  community_id   UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  sender_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name    TEXT,
  recipient_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  text           TEXT NOT NULL,
  read_at        TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Indizes ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_share_requests_share      ON public.community_share_requests(share_id);
CREATE INDEX IF NOT EXISTS idx_share_requests_user       ON public.community_share_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_help_requests_community   ON public.community_help_requests(community_id);
CREATE INDEX IF NOT EXISTS idx_help_offers_request       ON public.community_help_offers(request_id);
CREATE INDEX IF NOT EXISTS idx_community_messages_ctx    ON public.community_messages(context_type, context_id);
CREATE INDEX IF NOT EXISTS idx_community_messages_recv   ON public.community_messages(recipient_id);

-- ── RLS aktivieren ───────────────────────────────────────────────────────────
ALTER TABLE public.community_share_requests  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_help_requests   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_help_offers     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_messages        ENABLE ROW LEVEL SECURITY;

-- ── RLS Policies: community_share_requests ───────────────────────────────────
-- Lesen: Mitglieder der Community
CREATE POLICY "share_requests_select" ON public.community_share_requests
  FOR SELECT USING (
    community_id IN (SELECT get_my_active_community_ids(auth.uid()))
  );

-- Einfügen: Mitglied kann Anfrage stellen (nicht für eigene Angebote)
CREATE POLICY "share_requests_insert" ON public.community_share_requests
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND community_id IN (SELECT get_my_active_community_ids(auth.uid()))
  );

-- Update: Nur der Angebots-Ersteller kann annehmen/ablehnen
CREATE POLICY "share_requests_update" ON public.community_share_requests
  FOR UPDATE USING (
    -- Ersteller des Angebots darf den Status ändern
    EXISTS (
      SELECT 1 FROM public.community_shares cs
      WHERE cs.id = share_id AND cs.offered_by = auth.uid()
    )
    -- oder der Anfragesteller zieht seine eigene Anfrage zurück
    OR user_id = auth.uid()
  );

-- Löschen: Anfragesteller oder Angebots-Ersteller
CREATE POLICY "share_requests_delete" ON public.community_share_requests
  FOR DELETE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.community_shares cs
      WHERE cs.id = share_id AND cs.offered_by = auth.uid()
    )
  );

-- ── RLS Policies: community_help_requests ────────────────────────────────────
CREATE POLICY "help_requests_select" ON public.community_help_requests
  FOR SELECT USING (
    community_id IN (SELECT get_my_active_community_ids(auth.uid()))
  );

CREATE POLICY "help_requests_insert" ON public.community_help_requests
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND community_id IN (SELECT get_my_active_community_ids(auth.uid()))
  );

CREATE POLICY "help_requests_update" ON public.community_help_requests
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "help_requests_delete" ON public.community_help_requests
  FOR DELETE USING (auth.uid() = user_id);

-- ── RLS Policies: community_help_offers ──────────────────────────────────────
CREATE POLICY "help_offers_select" ON public.community_help_offers
  FOR SELECT USING (
    community_id IN (SELECT get_my_active_community_ids(auth.uid()))
  );

CREATE POLICY "help_offers_insert" ON public.community_help_offers
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND community_id IN (SELECT get_my_active_community_ids(auth.uid()))
  );

-- Anfrage-Ersteller kann Aushelfen-Angebot akzeptieren
CREATE POLICY "help_offers_update" ON public.community_help_offers
  FOR UPDATE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.community_help_requests hr
      WHERE hr.id = request_id AND hr.user_id = auth.uid()
    )
  );

CREATE POLICY "help_offers_delete" ON public.community_help_offers
  FOR DELETE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.community_help_requests hr
      WHERE hr.id = request_id AND hr.user_id = auth.uid()
    )
  );

-- ── RLS Policies: community_messages ─────────────────────────────────────────
CREATE POLICY "messages_select" ON public.community_messages
  FOR SELECT USING (
    sender_id = auth.uid() OR recipient_id = auth.uid()
  );

CREATE POLICY "messages_insert" ON public.community_messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND community_id IN (SELECT get_my_active_community_ids(auth.uid()))
  );

CREATE POLICY "messages_update_read" ON public.community_messages
  FOR UPDATE USING (recipient_id = auth.uid());

CREATE POLICY "messages_delete" ON public.community_messages
  FOR DELETE USING (sender_id = auth.uid());

-- ── Trigger: Wenn share_request accepted → andere pending ablehnen ───────────
CREATE OR REPLACE FUNCTION public.reject_other_share_requests()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    UPDATE public.community_share_requests
    SET status = 'rejected'
    WHERE share_id = NEW.share_id
      AND id != NEW.id
      AND status = 'pending';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reject_other_requests ON public.community_share_requests;
CREATE TRIGGER trg_reject_other_requests
  AFTER UPDATE ON public.community_share_requests
  FOR EACH ROW EXECUTE FUNCTION public.reject_other_share_requests();

-- ── Trigger: Wenn help_offer accepted → andere pending ablehnen ──────────────
CREATE OR REPLACE FUNCTION public.reject_other_help_offers()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    UPDATE public.community_help_offers
    SET status = 'rejected'
    WHERE request_id = NEW.request_id
      AND id != NEW.id
      AND status = 'pending';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reject_other_offers ON public.community_help_offers;
CREATE TRIGGER trg_reject_other_offers
  AFTER UPDATE ON public.community_help_offers
  FOR EACH ROW EXECUTE FUNCTION public.reject_other_help_offers();

