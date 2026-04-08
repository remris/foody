-- ═══════════════════════════════════════════════════════════════════════════
-- Foody – Migration: Recipe Cache + Realtime + Zutaten-Indizes
-- Ausführen in: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. Recipe Cache Tabelle ───────────────────────────────────────────────
create table if not exists recipe_cache (
  id           uuid primary key default gen_random_uuid(),
  cache_key    text not null unique,
  recipes_json text not null,
  hit_count    int default 1,
  expires_at   timestamptz not null,
  created_at   timestamptz default now()
);
create index if not exists idx_recipe_cache_key     on recipe_cache(cache_key);
create index if not exists idx_recipe_cache_expires on recipe_cache(expires_at);

alter table recipe_cache enable row level security;
create policy "Cache lesen"        on recipe_cache for select using (auth.uid() is not null);
create policy "Cache schreiben"    on recipe_cache for insert with check (auth.uid() is not null);
create policy "Cache aktualisieren" on recipe_cache for update using (auth.uid() is not null);


-- ── 2. Zutaten-Indizes (user_inventory) ──────────────────────────────────
-- Problem ohne Index: jede Vorrats-Abfrage macht Full Table Scan.
-- Bei 10.000 Usern × je 30 Zutaten = 300.000 Zeilen → langsam ohne Index.

-- Haupt-Index: user_id (wird bei fast allen Queries gefiltert)
create index if not exists idx_inventory_user_id
  on user_inventory(user_id);

-- Kombiniert: user_id + ingredient_name (für Cache-Key-Berechnung & Suche)
create index if not exists idx_inventory_user_name
  on user_inventory(user_id, ingredient_name);

-- Barcode-Lookup (beim Scannen)
create index if not exists idx_inventory_barcode
  on user_inventory(barcode) where barcode is not null;

-- Ablaufdatum-Index (für Dashboard-Warnungen: "bald ablaufend")
create index if not exists idx_inventory_expiry
  on user_inventory(expiry_date) where expiry_date is not null;

-- Kategorie-Index (für Vorrats-Filter nach Kategorie/Zone)
create index if not exists idx_inventory_category
  on user_inventory(user_id, ingredient_category);

-- GIN-Index auf tags-Array (für Tag-Mehrfachfilter: WHERE tags && ARRAY['bio','vegan'])
create index if not exists idx_inventory_tags
  on user_inventory using gin(tags);

-- Volltext-Suche auf ingredient_name (für Suchfeld im Vorrat-Tab)
-- Erlaubt: WHERE to_tsvector('german', ingredient_name) @@ plainto_tsquery('german', 'tom')
-- → findet "Tomaten", "Tomatenmark", "Tomatensoße" mit einem Query
create index if not exists idx_inventory_fts
  on user_inventory using gin(to_tsvector('german', ingredient_name));


-- ── 3. Gespeicherte Rezepte – Indizes & Volltext ─────────────────────────
-- saved_recipes speichert recipe_json als JSONB → GIN-Index macht es durchsuchbar.

-- Index für user_id (Standard-Abfrage)
create index if not exists idx_saved_recipes_user
  on saved_recipes(user_id);

-- Index auf title (isRecipeSaved-Check, Duplikat-Vermeidung)
create index if not exists idx_saved_recipes_title
  on saved_recipes(user_id, title);

-- GIN-Index auf recipe_json (JSONB) – erlaubt schnelle Queries wie:
-- WHERE recipe_json @> '{"difficulty": "Einfach"}'
-- WHERE recipe_json->'ingredients' @> '[{"name": "Tomaten"}]'
create index if not exists idx_saved_recipes_json
  on saved_recipes using gin(recipe_json);

-- Volltext-Suche auf Rezept-Titel
create index if not exists idx_saved_recipes_fts
  on saved_recipes using gin(to_tsvector('german', title));

-- Spalte für Kochzeit ergänzen (für schnelle Filter ohne JSON-Parsing)
alter table saved_recipes
  add column if not exists cooking_time_minutes int,
  add column if not exists difficulty text,
  add column if not exists calories int,
  add column if not exists tags text[] default '{}';

-- Index auf denormalisierte Felder
create index if not exists idx_saved_recipes_time
  on saved_recipes(user_id, cooking_time_minutes);
create index if not exists idx_saved_recipes_tags
  on saved_recipes using gin(tags);


-- ── 4. Ingredient Popularity Tracking ────────────────────────────────────
-- Zählt welche Zutatenkombinationen am häufigsten für KI-Rezepte angefragt werden.
-- Nutzen: Beliebte Kombinationen proaktiv cachen (Cronjob nachts).
-- Bsp: "Hähnchen + Reis + Gemüse" wird 500×/Tag angefragt → 1× generieren, 499× cachen.

create table if not exists ingredient_query_stats (
  id              uuid primary key default gen_random_uuid(),
  cache_key       text not null unique,  -- gleicher Key wie recipe_cache
  ingredient_list text[] not null,       -- normalisierte Zutaten
  query_count     int default 1,         -- wie oft diese Kombination angefragt
  last_queried_at timestamptz default now(),
  is_precached    bool default false     -- wurde proaktiv gecacht?
);

create index if not exists idx_iqstats_key   on ingredient_query_stats(cache_key);
create index if not exists idx_iqstats_count on ingredient_query_stats(query_count desc);

alter table ingredient_query_stats enable row level security;
create policy "Stats lesen"    on ingredient_query_stats for select using (auth.uid() is not null);
create policy "Stats schreiben" on ingredient_query_stats for insert with check (auth.uid() is not null);
create policy "Stats erhöhen"   on ingredient_query_stats for update using (auth.uid() is not null);


-- ── 5. Performance: Shopping List Indizes ────────────────────────────────
create index if not exists idx_sli_list_id  on shopping_list_items(list_id);
create index if not exists idx_sli_checked  on shopping_list_items(list_id, is_checked);
create index if not exists idx_sl_household on shopping_lists(household_id) where household_id is not null;


-- ── 6. Community Recipes – Indizes ───────────────────────────────────────
-- GIN auf recipe_json für Zutat-Suche in Community-Rezepten
create index if not exists idx_cr_recipe_json
  on community_recipes using gin(recipe_json);
create index if not exists idx_cr_fts
  on community_recipes using gin(to_tsvector('german', title));
create index if not exists idx_cr_tags
  on community_recipes using gin(tags);
create index if not exists idx_cr_category
  on community_recipes(category, created_at desc);


-- ── 7. Cache-Statistik-View ───────────────────────────────────────────────
create or replace view recipe_cache_stats as
select
  count(*) as total_entries,
  sum(hit_count) as total_hits,
  avg(hit_count)::numeric(10,2) as avg_hits_per_entry,
  count(*) filter (where expires_at > now()) as active_entries,
  count(*) filter (where expires_at < now()) as expired_entries,
  round(count(*) filter (where expires_at > now())::numeric / nullif(count(*), 0) * 100, 2) as cache_health_pct
from recipe_cache;

-- Top-10 beliebteste Zutaten-Kombinationen
create or replace view top_ingredient_queries as
select
  ingredient_list,
  query_count,
  is_precached,
  last_queried_at,
  -- Wenn query_count > 10 und nicht gecacht → proaktiv cachen lohnt sich
  query_count > 10 and not is_precached as should_precache
from ingredient_query_stats
order by query_count desc
limit 50;

-- Abfragen:
-- select * from recipe_cache_stats;
-- select * from top_ingredient_queries where should_precache;


-- ── 8. Supabase Realtime aktivieren ──────────────────────────────────────
-- Im Dashboard: Database → Replication → Tabellen aktivieren:
--   ✅ shopping_list_items
--   ✅ shopping_lists
-- Optional: user_inventory (für Haushalt-Vorrat-Sync)
/*
alter publication supabase_realtime add table shopping_list_items;
alter publication supabase_realtime add table shopping_lists;
alter publication supabase_realtime add table user_inventory;
*/


-- ── 9. Automatische Cache-Bereinigung ─────────────────────────────────────
-- Via Supabase Dashboard → Edge Functions oder pg_cron (falls verfügbar):
-- select cron.schedule('cleanup-recipe-cache', '0 3 * * *',
--   $$delete from recipe_cache where expires_at < now()$$);


-- ── 10. RPC-Funktion: upsert_ingredient_stats ────────────────────────────
-- Wird aus der App aufgerufen wenn User Rezepte generiert.
-- Erhöht query_count atomisch (kein Race-Condition-Problem).
create or replace function upsert_ingredient_stats(
  p_cache_key    text,
  p_ingredients  text[]
) returns void
language plpgsql security definer as $$
begin
  insert into ingredient_query_stats(cache_key, ingredient_list, query_count, last_queried_at)
  values (p_cache_key, p_ingredients, 1, now())
  on conflict (cache_key) do update
    set query_count     = ingredient_query_stats.query_count + 1,
        last_queried_at = now();
end;
$$;

-- ── 11. RPC-Funktion: increment_cache_hits ───────────────────────────────
-- Erhöht hit_count atomisch wenn Cache-Eintrag genutzt wird.
create or replace function increment_cache_hits(p_cache_key text)
returns void
language plpgsql security definer as $$
begin
  update recipe_cache
  set hit_count = hit_count + 1
  where cache_key = p_cache_key;
end;
$$;
