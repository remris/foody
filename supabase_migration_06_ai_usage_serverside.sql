-- Migration 06: ai_usage Tabelle für serverseitiges Rate-Limiting
-- (wird von der Groq-Proxy Edge Function verwendet)
-- Ausführen in Supabase SQL Editor

-- Tabelle für KI-Nutzung (serverseitig verwaltet)
CREATE TABLE IF NOT EXISTS public.ai_usage (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  week_start   DATE        NOT NULL DEFAULT CURRENT_DATE,
  used_this_week INTEGER   NOT NULL DEFAULT 0,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON public.ai_usage(user_id);

-- RLS
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User kann eigene Nutzung lesen"
  ON public.ai_usage FOR SELECT
  USING (auth.uid() = user_id);

-- Service-Role darf alles (wird von Edge Function verwendet)
CREATE POLICY "Service kann Nutzung verwalten"
  ON public.ai_usage FOR ALL
  USING (true)
  WITH CHECK (true);

