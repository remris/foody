-- Migration 05: Community Meal Plans
-- Ausführen in Supabase SQL Editor

-- ── Tabelle: community_meal_plans ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.community_meal_plans (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  author_name     TEXT        NOT NULL DEFAULT 'Foody-User',
  title           TEXT        NOT NULL,
  description     TEXT        NOT NULL DEFAULT '',
  plan_json       JSONB       NOT NULL DEFAULT '[]',
  tags            TEXT[]      NOT NULL DEFAULT '{}',
  is_published    BOOLEAN     NOT NULL DEFAULT true,
  view_count      INTEGER     NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Tabelle: meal_plan_likes ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.meal_plan_likes (
  id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id   UUID        NOT NULL REFERENCES public.community_meal_plans(id) ON DELETE CASCADE,
  user_id   UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(plan_id, user_id)
);

-- ── Indizes ───────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_community_meal_plans_user_id
  ON public.community_meal_plans(user_id);

CREATE INDEX IF NOT EXISTS idx_community_meal_plans_tags
  ON public.community_meal_plans USING gin(tags);

CREATE INDEX IF NOT EXISTS idx_community_meal_plans_created_at
  ON public.community_meal_plans(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_meal_plan_likes_plan_id
  ON public.meal_plan_likes(plan_id);

CREATE INDEX IF NOT EXISTS idx_meal_plan_likes_user_id
  ON public.meal_plan_likes(user_id);

-- ── Row Level Security ────────────────────────────────────────────────────
ALTER TABLE public.community_meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_plan_likes ENABLE ROW LEVEL SECURITY;

-- community_meal_plans Policies
CREATE POLICY "Veröffentlichte Pläne sind öffentlich lesbar"
  ON public.community_meal_plans FOR SELECT
  USING (is_published = true);

CREATE POLICY "User kann eigene Pläne lesen"
  ON public.community_meal_plans FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "User kann Pläne erstellen"
  ON public.community_meal_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "User kann eigene Pläne bearbeiten"
  ON public.community_meal_plans FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "User kann eigene Pläne löschen"
  ON public.community_meal_plans FOR DELETE
  USING (auth.uid() = user_id);

-- meal_plan_likes Policies
CREATE POLICY "Likes sind öffentlich lesbar"
  ON public.meal_plan_likes FOR SELECT
  USING (true);

CREATE POLICY "User kann eigene Likes erstellen"
  ON public.meal_plan_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "User kann eigene Likes löschen"
  ON public.meal_plan_likes FOR DELETE
  USING (auth.uid() = user_id);

