-- ============================================================
-- FOODY – Supabase Setup
-- Alle Tabellen auf einmal anlegen.
-- Einfach im Supabase SQL Editor einfügen und ausführen.
-- ============================================================

-- 1. user_inventory (Inventar)
create table if not exists user_inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  ingredient_id text not null,
  ingredient_name text not null,
  ingredient_category text,
  ingredient_image_url text,
  quantity float,
  unit text,
  expiry_date timestamptz,
  min_threshold float default 0,
  barcode text,
  tags text[],
  created_at timestamptz default now()
);
-- Fehlende Spalten nachträglich hinzufügen (falls Tabelle bereits existiert)
alter table user_inventory add column if not exists min_threshold float default 0;
alter table user_inventory add column if not exists barcode text;
alter table user_inventory add column if not exists tags text[];
alter table user_inventory enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'user_inventory' and policyname = 'user_inventory_policy'
  ) then
    create policy "user_inventory_policy" on user_inventory
      for all using (auth.uid() = user_id);
  end if;
end $$;
create index if not exists idx_inventory_user on user_inventory(user_id);
-- Barcode-Index nur wenn Spalte existiert
do $$ begin
  if exists (
    select 1 from information_schema.columns
    where table_name = 'user_inventory' and column_name = 'barcode'
  ) then
    execute 'create index if not exists idx_inventory_barcode on user_inventory(barcode)';
  end if;
end $$;

-- 2. shopping_lists (Einkaufslisten)
create table if not exists shopping_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  name text not null,
  icon text default 'shopping_cart',
  created_at timestamptz default now()
);
alter table shopping_lists enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename = 'shopping_lists' and policyname = 'shopping_lists_policy') then
    create policy "shopping_lists_policy" on shopping_lists for all using (auth.uid() = user_id);
  end if;
end $$;

-- 3. shopping_list_items (Einkaufslisteneinträge)
create table if not exists shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid references shopping_lists on delete cascade not null,
  user_id uuid references auth.users not null,
  name text not null,
  quantity text,
  is_checked boolean default false,
  created_at timestamptz default now()
);
alter table shopping_list_items enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename = 'shopping_list_items' and policyname = 'shopping_list_items_policy') then
    create policy "shopping_list_items_policy" on shopping_list_items for all using (auth.uid() = user_id);
  end if;
end $$;

-- 4. saved_recipes (Gespeicherte Rezepte)
create table if not exists saved_recipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  title text not null,
  recipe_json jsonb not null,
  source text default 'ai',
  created_at timestamptz default now()
);
alter table saved_recipes enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename = 'saved_recipes' and policyname = 'saved_recipes_policy') then
    create policy "saved_recipes_policy" on saved_recipes for all using (auth.uid() = user_id);
  end if;
end $$;

-- 5. scanned_products (Scan-History & Favoriten)
create table if not exists scanned_products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  barcode text not null,
  product_name text not null,
  product_data jsonb,
  scan_count int default 1,
  is_favorite boolean default false,
  last_scanned_at timestamptz default now(),
  created_at timestamptz default now()
);
alter table scanned_products enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename = 'scanned_products' and policyname = 'scanned_products_policy') then
    create policy "scanned_products_policy" on scanned_products for all using (auth.uid() = user_id);
  end if;
end $$;
create index if not exists idx_scanned_barcode on scanned_products(user_id, barcode);

-- 6. households (Geteilter Haushalt)
create table if not exists households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid references auth.users not null,
  invite_code text unique,
  created_at timestamptz default now()
);
alter table households enable row level security;

-- 7. household_members (Haushaltsmitglieder)
create table if not exists household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households on delete cascade not null,
  user_id uuid references auth.users not null,
  role text default 'member' check (role in ('admin', 'member')),
  display_name text,
  joined_at timestamptz default now(),
  unique(household_id, user_id)
);
alter table household_members enable row level security;

-- ============================================================
-- RLS-Hilfsfunktion (security definer = kein RLS beim Aufruf)
-- Verhindert infinite recursion in household_members Policy
-- ============================================================
create or replace function auth_user_household_ids()
returns setof uuid
language sql
security definer
stable
as $$
  select household_id
  from household_members
  where user_id = auth.uid();
$$;

-- RLS für households (nutzt Hilfsfunktion)
-- SELECT/UPDATE/DELETE: nur eigene Haushalte
drop policy if exists "households_policy" on households;
drop policy if exists "households_select_policy" on households;
drop policy if exists "households_insert_policy" on households;
create policy "households_select_policy" on households
  for select using (
    id in (select auth_user_household_ids())
  );
create policy "households_insert_policy" on households
  for insert with check (
    auth.uid() = created_by
  );

-- RLS für household_members (nutzt Hilfsfunktion – KEIN rekursiver Self-Join)
drop policy if exists "household_members_policy" on household_members;
drop policy if exists "household_members_select_policy" on household_members;
drop policy if exists "household_members_insert_policy" on household_members;
create policy "household_members_select_policy" on household_members
  for select using (
    household_id in (select auth_user_household_ids())
  );
create policy "household_members_insert_policy" on household_members
  for insert with check (
    auth.uid() = user_id
  );

-- ============================================================
-- FERTIG! Alle 7 Tabellen sind angelegt.
-- ============================================================

-- ============================================================
-- MIGRATION – Nachträgliche Änderungen (idempotent, sicher
-- auf bestehenden Datenbanken auszuführen)
-- ============================================================

-- scanned_products: alle Felder prüfen
alter table scanned_products add column if not exists product_data jsonb;
alter table scanned_products add column if not exists scan_count int default 1;
alter table scanned_products add column if not exists is_favorite boolean default false;
alter table scanned_products add column if not exists last_scanned_at timestamptz default now();

-- shopping_list_items: sort_order für Drag & Drop
alter table shopping_list_items add column if not exists sort_order int default 0;

-- shopping_lists: icon + household_id Felder
alter table shopping_lists add column if not exists icon text default 'shopping_cart';
alter table shopping_lists add column if not exists household_id uuid references households(id) on delete set null;

-- saved_recipes: source Feld
alter table saved_recipes add column if not exists source text default 'ai';

-- Hilfsfunktion sicherstellen (security definer, kein RLS beim Aufruf)
create or replace function auth_user_household_ids()
returns setof uuid
language sql
security definer
stable
as $$
  select household_id from household_members where user_id = auth.uid();
$$;

-- RLS Policy für shopping_lists: eigene + Haushalt-Listen
drop policy if exists "shopping_lists_policy" on shopping_lists;
create policy "shopping_lists_policy" on shopping_lists
  for all using (
    auth.uid() = user_id
    or (
      household_id is not null
      and household_id in (select auth_user_household_ids())
    )
  );

-- RLS Policy für shopping_list_items: eigene + Haushalt-Listen-Items
drop policy if exists "shopping_list_items_policy" on shopping_list_items;
create policy "shopping_list_items_policy" on shopping_list_items
  for all using (
    auth.uid() = user_id
    or list_id in (
      select id from shopping_lists
      where household_id in (select auth_user_household_ids())
    )
  );

-- Household Policies (safe, kein rekursiver Self-Join)
-- SELECT: nur eigene Haushalte sehen
drop policy if exists "household_members_policy" on household_members;
drop policy if exists "household_members_select_policy" on household_members;
drop policy if exists "household_members_insert_policy" on household_members;
drop policy if exists "household_members_delete_policy" on household_members;
create policy "household_members_select_policy" on household_members
  for select using (
    household_id in (select auth_user_household_ids())
  );
-- INSERT: User kann sich selbst in einen Haushalt eintragen
create policy "household_members_insert_policy" on household_members
  for insert with check (
    auth.uid() = user_id
  );
-- DELETE: User kann sich selbst entfernen
create policy "household_members_delete_policy" on household_members
  for delete using (
    auth.uid() = user_id
  );

drop policy if exists "households_policy" on households;
drop policy if exists "households_select_policy" on households;
drop policy if exists "households_insert_policy" on households;
-- SELECT: nur Haushalte sehen, denen man angehört
create policy "households_select_policy" on households
  for select using (
    id in (select auth_user_household_ids())
  );
-- INSERT: jeder kann einen Haushalt erstellen (created_by = auth.uid())
create policy "households_insert_policy" on households
  for insert with check (
    auth.uid() = created_by
  );

-- Indizes für Performance
create index if not exists idx_shopping_lists_household
  on shopping_lists(household_id)
  where household_id is not null;

create index if not exists idx_scanned_favorite
  on scanned_products(user_id, is_favorite)
  where is_favorite = true;

create index if not exists idx_scanned_last
  on scanned_products(user_id, last_scanned_at desc);

create index if not exists idx_shopping_items_list
  on shopping_list_items(list_id, sort_order);

create index if not exists idx_saved_recipes_user
  on saved_recipes(user_id, created_at desc);

-- ============================================================
-- HINWEIS: Folgende Daten werden LOKAL (SharedPreferences)
-- gespeichert und brauchen KEINE Supabase-Tabelle:
--   - Einkaufslisten-Templates  (shopping_templates_provider)
--   - Artikel-Preisschätzungen  (item_prices_provider)
--   - Zuletzt gekochte Rezepte  (cooked_recipes_provider)
--   - Rezept-Notizen            (recipe_notes_provider)
--   - Rezept-Bewertungen        (recipe_rating_provider)
--   - Rezept-Kategorien         (recipe_category_provider)
--   - Lieblingsrezepte          (recipe_favorites_provider)
--   - Stammartikel              (staple_items_provider)
--   - Letzte KI-Prompts         (recent_prompts_provider)
-- ============================================================

-- ============================================================
-- MONETARISIERUNG & NEUE FEATURES (Phase 1)
-- ============================================================

-- 8. subscriptions (Abo-Status pro User)
create table if not exists subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null unique,
  plan text not null default 'free' check (plan in ('free', 'pro', 'pro_plus')),
  valid_until timestamptz,
  source text default 'manual' check (source in ('manual', 'revenuecat', 'stripe', 'promo')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table subscriptions enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'subscriptions' and policyname = 'subscriptions_policy'
  ) then
    create policy "subscriptions_policy" on subscriptions
      for all using (auth.uid() = user_id);
  end if;
end $$;
create index if not exists idx_subscriptions_user on subscriptions(user_id);

-- 9. nutrition_log (Tages-Kalorien & Makro-Tracking – Pro-Feature)
create table if not exists nutrition_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  logged_at date not null default current_date,
  recipe_title text,
  calories int not null default 0,
  protein float default 0,
  carbs float default 0,
  fat float default 0,
  fiber float default 0,
  servings float default 1,
  created_at timestamptz default now()
);
alter table nutrition_log enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'nutrition_log' and policyname = 'nutrition_log_policy'
  ) then
    create policy "nutrition_log_policy" on nutrition_log
      for all using (auth.uid() = user_id);
  end if;
end $$;
create index if not exists idx_nutrition_log_user_date
  on nutrition_log(user_id, logged_at desc);

-- 10. meal_plans (Mahlzeiten-Wochenplaner – Pro-Feature)
create table if not exists meal_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  week_start date not null,
  day_index int not null check (day_index between 0 and 6),
  slot text not null check (slot in ('breakfast', 'lunch', 'dinner', 'snack')),
  recipe_json jsonb not null,
  created_at timestamptz default now(),
  unique(user_id, week_start, day_index, slot)
);
alter table meal_plans enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'meal_plans' and policyname = 'meal_plans_policy'
  ) then
    create policy "meal_plans_policy" on meal_plans
      for all using (auth.uid() = user_id);
  end if;
end $$;
create index if not exists idx_meal_plans_user_week
  on meal_plans(user_id, week_start);

-- ============================================================
-- FERTIG! Alle 10 Tabellen sind angelegt.
-- ============================================================

-- ============================================================
-- MIGRATION: Community-Rezepte (Phase 28)
-- Neue Tabellen für Community-Feature hinzufügen.
-- ============================================================

-- 11. community_recipes
create table if not exists community_recipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  author_name text default 'Foody-User',
  title text not null,
  description text default '',
  recipe_json jsonb not null,
  image_url text,
  tags text[] default '{}',
  category text,
  difficulty text default 'Mittel',
  cooking_time_minutes int default 30,
  servings int default 2,
  is_published bool default true,
  source text default 'community',
  view_count int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table community_recipes enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'community_recipes' and policyname = 'community_recipes_select'
  ) then
    create policy "community_recipes_select" on community_recipes
      for select using (auth.uid() is not null and is_published = true);
  end if;
end $$;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'community_recipes' and policyname = 'community_recipes_all'
  ) then
    create policy "community_recipes_all" on community_recipes
      for all using (auth.uid() = user_id);
  end if;
end $$;
create index if not exists idx_cr_created on community_recipes(created_at desc);
create index if not exists idx_cr_user on community_recipes(user_id);
create index if not exists idx_cr_category on community_recipes(category);

-- Funktion zum Erhöhen des View-Counters (sicher via RPC)
create or replace function increment_view_count(recipe_id uuid)
returns void language sql security definer as $$
  update community_recipes
  set view_count = view_count + 1
  where id = recipe_id;
$$;

-- 12. recipe_likes
create table if not exists recipe_likes (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid references community_recipes on delete cascade not null,
  user_id uuid references auth.users not null,
  created_at timestamptz default now(),
  unique(recipe_id, user_id)
);
alter table recipe_likes enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'recipe_likes' and policyname = 'recipe_likes_select'
  ) then
    create policy "recipe_likes_select" on recipe_likes
      for select using (auth.uid() is not null);
  end if;
end $$;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'recipe_likes' and policyname = 'recipe_likes_all'
  ) then
    create policy "recipe_likes_all" on recipe_likes
      for all using (auth.uid() = user_id);
  end if;
end $$;
create index if not exists idx_likes_recipe on recipe_likes(recipe_id);
create index if not exists idx_likes_user on recipe_likes(user_id);

-- 13. recipe_comments
create table if not exists recipe_comments (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid references community_recipes on delete cascade not null,
  user_id uuid references auth.users not null,
  author_name text default 'Foody-User',
  content text not null,
  created_at timestamptz default now()
);
alter table recipe_comments enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'recipe_comments' and policyname = 'recipe_comments_select'
  ) then
    create policy "recipe_comments_select" on recipe_comments
      for select using (auth.uid() is not null);
  end if;
end $$;
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename = 'recipe_comments' and policyname = 'recipe_comments_all'
  ) then
    create policy "recipe_comments_all" on recipe_comments
      for all using (auth.uid() = user_id);
  end if;
end $$;
create index if not exists idx_comments_recipe on recipe_comments(recipe_id);

-- ============================================================
-- FERTIG! Community-Migration abgeschlossen.
-- Gesamt: 13 Tabellen + 1 RPC-Funktion
-- ============================================================
