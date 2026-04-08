-- ============================================================
-- Migration 11: household_members RLS – infinite recursion fix
--
-- Problem: DELETE/UPDATE Policies auf household_members prüfen
-- ob der User Admin ist, indem sie household_members selbst
-- abfragen → rekursive Policy → PostgreSQL Error 42P17
--
-- Lösung:
--   1. Hilfsfunktion is_household_admin() als SECURITY DEFINER
--      → läuft mit elevated rights, umgeht RLS beim Prüfen
--   2. Alle Policies die household_members selbst abfragen
--      werden auf diese Funktion umgestellt
-- ============================================================

-- ── 1. Hilfsfunktionen ───────────────────────────────────────────────────

-- Gibt alle household_ids zurück, in denen der aktuelle User Mitglied ist
create or replace function auth_user_household_ids()
returns setof uuid
language sql
security definer   -- umgeht RLS
stable
as $$
  select household_id
  from household_members
  where user_id = auth.uid();
$$;

-- Prüft ob der aktuelle User Admin eines bestimmten Haushalts ist
create or replace function is_household_admin(hid uuid)
returns boolean
language sql
security definer   -- umgeht RLS → keine Rekursion
stable
as $$
  select exists (
    select 1
    from household_members
    where household_id = hid
      and user_id = auth.uid()
      and role = 'admin'
  );
$$;

-- ── 2. Policies für household_members neu setzen ─────────────────────────

drop policy if exists "household_members_policy"        on household_members;
drop policy if exists "household_members_select_policy" on household_members;
drop policy if exists "household_members_insert_policy" on household_members;
drop policy if exists "household_members_update_policy" on household_members;
drop policy if exists "household_members_delete_policy" on household_members;

-- SELECT: eigener Eintrag ODER Mitglied desselben Haushalts
create policy "household_members_select_policy" on household_members
  for select using (
    user_id = auth.uid()
    or household_id in (select auth_user_household_ids())
  );

-- INSERT: User trägt sich selbst ein
create policy "household_members_insert_policy" on household_members
  for insert with check (
    auth.uid() = user_id
  );

-- UPDATE: eigene Mitgliedschaft ODER Admin des Haushalts (über Funktion, kein Self-Join)
create policy "household_members_update_policy" on household_members
  for update using (
    auth.uid() = user_id
    or is_household_admin(household_id)
  );

-- DELETE: eigene Mitgliedschaft ODER Admin des Haushalts (über Funktion, kein Self-Join)
create policy "household_members_delete_policy" on household_members
  for delete using (
    auth.uid() = user_id
    or is_household_admin(household_id)
  );

-- ── 3. Policies für households neu setzen ───────────────────────────────

drop policy if exists "households_policy"        on households;
drop policy if exists "households_select_policy" on households;
drop policy if exists "households_insert_policy" on households;
drop policy if exists "households_update_policy" on households;
drop policy if exists "households_delete_policy" on households;

-- SELECT: Mitglied ODER Ersteller
create policy "households_select_policy" on households
  for select using (
    id in (select auth_user_household_ids())
    or created_by = auth.uid()
  );

-- INSERT: jeder angemeldete User kann einen Haushalt erstellen
create policy "households_insert_policy" on households
  for insert with check (
    auth.uid() = created_by
  );

-- UPDATE: Ersteller ODER Admin (über Funktion)
create policy "households_update_policy" on households
  for update using (
    created_by = auth.uid()
    or is_household_admin(id)
  );

-- DELETE: Ersteller ODER Admin (über Funktion)
create policy "households_delete_policy" on households
  for delete using (
    created_by = auth.uid()
    or is_household_admin(id)
  );

-- ============================================================
-- FERTIG – führe dieses SQL im Supabase SQL-Editor aus.
-- ============================================================

