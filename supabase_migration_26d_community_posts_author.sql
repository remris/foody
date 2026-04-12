-- ============================================================
-- Migration 26d: author_name Spalte zu community_posts hinzufügen
-- ============================================================
-- Die Flutter-App liest/schreibt author_name beim Erstellen von Posts.
-- Diese Spalte wurde in der initialen Migration vergessen.
-- ============================================================

ALTER TABLE public.community_posts
  ADD COLUMN IF NOT EXISTS author_name TEXT;

-- Bestehende Zeilen mit leerem author_name lassen (NULL ist ok,
-- Flutter zeigt dann 'Unbekannt' als Fallback).

