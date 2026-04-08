-- ============================================================
-- MIGRATION: Fix Household RLS Policies
-- Problem: INSERT auf households/household_members war blockiert
-- weil die "for all" Policy nur Mitglieder zuließ, der User
-- beim Erstellen aber noch kein Mitglied ist.
--
-- Lösung: Separate SELECT + INSERT + DELETE Policies.
--
-- Einfach im Supabase SQL Editor ausführen!
-- ============================================================

-- 1. Hilfsfunktion sicherstellen
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

-- 2. Alte Policies entfernen
drop policy if exists "households_policy" on households;
drop policy if exists "households_select_policy" on households;
drop policy if exists "households_insert_policy" on households;

drop policy if exists "household_members_policy" on household_members;
drop policy if exists "household_members_select_policy" on household_members;
drop policy if exists "household_members_insert_policy" on household_members;
drop policy if exists "household_members_delete_policy" on household_members;

-- 3. Neue Policies: households
-- SELECT: nur Haushalte sehen, denen man angehört
create policy "households_select_policy" on households
  for select using (
    id in (select auth_user_household_ids())
  );

-- INSERT: jeder authentifizierte User kann einen Haushalt erstellen
create policy "households_insert_policy" on households
  for insert with check (
    auth.uid() = created_by
  );

-- 4. Neue Policies: household_members
-- SELECT: nur Mitglieder eigener Haushalte sehen
create policy "household_members_select_policy" on household_members
  for select using (
    household_id in (select auth_user_household_ids())
  );

-- INSERT: User kann sich selbst in einen Haushalt eintragen
create policy "household_members_insert_policy" on household_members
  for insert with check (
    auth.uid() = user_id
  );

-- DELETE: User kann sich selbst aus einem Haushalt entfernen
create policy "household_members_delete_policy" on household_members
  for delete using (
    auth.uid() = user_id
  );

-- ============================================================
-- FERTIG! Haushalt erstellen & beitreten funktioniert jetzt.
-- ============================================================

