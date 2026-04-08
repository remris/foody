-- ═══════════════════════════════════════════════════════════════════════════
-- FOODY – Migration 02: Recipe Cache + Indizes + RPC-Funktionen
--
-- NUR DIESE DATEI ausführen wenn supabase_setup.sql bereits ausgeführt wurde.
-- Alle Befehle sind idempotent (mehrfach ausführbar, kein Fehler).
--
-- Supabase Dashboard → SQL Editor → Diese Datei einfügen → Run
-- ═══════════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════
-- 1. NEUE SPALTEN in bestehenden Tabellen
-- ════════════════════════════════════════════════════════════════

-- saved_recipes: Metadaten-Spalten für schnelle Filter (ohne JSON-Parsing)
alter table saved_recipes add column if not exists cooking_time_minutes int;
alter table saved_recipes add column if not exists difficulty           text;
alter table saved_recipes add column if not exists calories             int;
alter table saved_recipes add column if not exists tags                 text[] default '{}';

-- user_inventory: nutri_score (wird von OpenFoodFacts befüllt)
alter table user_inventory add column if not exists nutri_score         text;
alter table user_inventory add column if not exists storage_zone        text default 'all';


-- ════════════════════════════════════════════════════════════════
-- 2. INDIZES auf user_inventory (Vorrat)
-- ════════════════════════════════════════════════════════════════

-- Haupt-Index (jede Vorrats-Abfrage filtert nach user_id)
create index if not exists idx_inventory_user_id
  on user_inventory(user_id);

-- Kombiniert user_id + Name → schnelle Suche & Cache-Key-Berechnung
create index if not exists idx_inventory_user_name
  on user_inventory(user_id, ingredient_name);

-- Ablaufdatum → Dashboard-Warnungen, bald ablaufend
create index if not exists idx_inventory_expiry
  on user_inventory(expiry_date) where expiry_date is not null;

-- Kategorie → Vorrats-Filter
create index if not exists idx_inventory_category
  on user_inventory(user_id, ingredient_category);

-- GIN auf tags-Array → Mehrfach-Tag-Filter
create index if not exists idx_inventory_tags
  on user_inventory using gin(tags);

-- Volltext-Suche auf ingredient_name
-- findet "Tomaten", "Tomatenmark", "Tomatensoße" mit einem Query
create index if not exists idx_inventory_fts
  on user_inventory using gin(to_tsvector('german', ingredient_name));


-- ════════════════════════════════════════════════════════════════
-- 3. INDIZES auf saved_recipes
-- ════════════════════════════════════════════════════════════════

-- isRecipeSaved-Check (wird oft aufgerufen)
create index if not exists idx_saved_recipes_title
  on saved_recipes(user_id, title);

-- GIN auf recipe_json (JSONB) → Suche in Zutaten & Feldern
-- z.B. WHERE recipe_json @> '{"difficulty": "Einfach"}'
create index if not exists idx_saved_recipes_json
  on saved_recipes using gin(recipe_json);

-- Volltext-Suche auf Titel
create index if not exists idx_saved_recipes_fts
  on saved_recipes using gin(to_tsvector('german', title));

-- Kochzeit-Filter
create index if not exists idx_saved_recipes_time
  on saved_recipes(user_id, cooking_time_minutes);

-- Tag-Filter (schnell, vegetarisch, high-protein…)
create index if not exists idx_saved_recipes_tags
  on saved_recipes using gin(tags);


-- ════════════════════════════════════════════════════════════════
-- 4. NEUE TABELLE: recipe_cache
-- KI-generierte Rezepte für 7 Tage cachen.
-- Gleiche Zutaten → Cache-Hit → kein Groq-Call nötig.
-- ════════════════════════════════════════════════════════════════

create table if not exists recipe_cache (
  id           uuid        primary key default gen_random_uuid(),
  cache_key    text        not null unique,   -- SHA-256 Hash der Zutaten (16 Zeichen)
  recipes_json text        not null,          -- JSON-Array der Rezepte
  hit_count    int         default 1,         -- wie oft dieser Cache-Eintrag genutzt
  expires_at   timestamptz not null,          -- TTL: 7 Tage ab Erstellung
  created_at   timestamptz default now()
);

create index if not exists idx_recipe_cache_key
  on recipe_cache(cache_key);
create index if not exists idx_recipe_cache_expires
  on recipe_cache(expires_at);

alter table recipe_cache enable row level security;

-- Alle eingeloggten User dürfen lesen (Community-Cache, kein User-Filter!)
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'recipe_cache' and policyname = 'Cache lesen'
  ) then
    create policy "Cache lesen" on recipe_cache
      for select using (auth.uid() is not null);
  end if;
end $$;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'recipe_cache' and policyname = 'Cache schreiben'
  ) then
    create policy "Cache schreiben" on recipe_cache
      for insert with check (auth.uid() is not null);
  end if;
end $$;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'recipe_cache' and policyname = 'Cache aktualisieren'
  ) then
    create policy "Cache aktualisieren" on recipe_cache
      for update using (auth.uid() is not null);
  end if;
end $$;


-- ════════════════════════════════════════════════════════════════
-- 5. NEUE TABELLE: ingredient_query_stats
-- Zählt welche Zutatenkombinationen am häufigsten angefragt werden.
-- → Zeigt welche Kombis es sich lohnt proaktiv zu cachen.
-- ════════════════════════════════════════════════════════════════

create table if not exists ingredient_query_stats (
  id              uuid        primary key default gen_random_uuid(),
  cache_key       text        not null unique,
  ingredient_list text[]      not null,
  query_count     int         default 1,
  last_queried_at timestamptz default now(),
  is_precached    bool        default false
);

create index if not exists idx_iqstats_key
  on ingredient_query_stats(cache_key);
create index if not exists idx_iqstats_count
  on ingredient_query_stats(query_count desc);

alter table ingredient_query_stats enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'ingredient_query_stats' and policyname = 'Stats lesen'
  ) then
    create policy "Stats lesen"    on ingredient_query_stats for select using (auth.uid() is not null);
    create policy "Stats schreiben" on ingredient_query_stats for insert with check (auth.uid() is not null);
    create policy "Stats erhöhen"   on ingredient_query_stats for update using (auth.uid() is not null);
  end if;
end $$;


-- ════════════════════════════════════════════════════════════════
-- 6. INDIZES auf community_recipes (bereits in Setup, aber ergänzt)
-- ════════════════════════════════════════════════════════════════

create index if not exists idx_cr_recipe_json
  on community_recipes using gin(recipe_json);
create index if not exists idx_cr_fts
  on community_recipes using gin(to_tsvector('german', title));
create index if not exists idx_cr_tags
  on community_recipes using gin(tags);


-- ════════════════════════════════════════════════════════════════
-- 7. RPC-FUNKTIONEN
-- ════════════════════════════════════════════════════════════════

-- Zählt Zutaten-Anfragen atomisch hoch (kein Race-Condition-Problem)
create or replace function upsert_ingredient_stats(
  p_cache_key   text,
  p_ingredients text[]
) returns void language plpgsql security definer as $$
begin
  insert into ingredient_query_stats(cache_key, ingredient_list, query_count, last_queried_at)
  values (p_cache_key, p_ingredients, 1, now())
  on conflict (cache_key) do update
    set query_count     = ingredient_query_stats.query_count + 1,
        last_queried_at = now();
end;
$$;

-- Erhöht Cache-Hit-Count atomisch
create or replace function increment_cache_hits(p_cache_key text)
returns void language plpgsql security definer as $$
begin
  update recipe_cache set hit_count = hit_count + 1 where cache_key = p_cache_key;
end;
$$;


-- ════════════════════════════════════════════════════════════════
-- 8. VIEWS (nützlich für Monitoring im Supabase Dashboard)
-- ════════════════════════════════════════════════════════════════

-- Zeigt wie viele Groq-API-Calls durch den Cache gespart wurden
drop view if exists recipe_cache_stats;
create view recipe_cache_stats as
select
  count(*)                                                      as total_entries,
  sum(hit_count)                                                as total_hits,
  avg(hit_count)::numeric(10,2)                                 as avg_hits_per_entry,
  count(*) filter (where expires_at > now())                    as active_entries,
  count(*) filter (where expires_at < now())                    as expired_entries,
  sum(hit_count) - count(*)                                     as groq_calls_saved
from recipe_cache;

-- Top-50 Zutaten-Kombinationen nach Anfrage-Häufigkeit
drop view if exists top_ingredient_queries;
create view top_ingredient_queries as
select
  ingredient_list,
  query_count,
  is_precached,
  last_queried_at,
  query_count > 10 and not is_precached as should_precache
from ingredient_query_stats
order by query_count desc
limit 50;


-- ════════════════════════════════════════════════════════════════
-- 9. SUPABASE REALTIME aktivieren
--
-- MANUELL im Dashboard aktivieren:
-- Database → Replication → "0 tables" klicken → Tabellen auswählen:
--   ✅ shopping_list_items  (Live-Sync für geteilte Einkaufslisten)
--   ✅ shopping_lists       (Live-Sync Listenverwaltung)
--
-- ODER via SQL (benötigt Superuser, in manchen Projekten verfügbar):
-- alter publication supabase_realtime add table shopping_list_items;
-- alter publication supabase_realtime add table shopping_lists;
-- ════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════
-- ÜBERPRÜFUNG – nach Ausführung kontrollieren:
-- ════════════════════════════════════════════════════════════════
-- select * from recipe_cache_stats;
-- select * from top_ingredient_queries limit 10;
-- select tablename, indexname from pg_indexes where schemaname = 'public' order by tablename;
-- ════════════════════════════════════════════════════════════════

