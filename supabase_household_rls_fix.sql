-- ============================================================
-- HOUSEHOLD RLS FIX
-- Fehler: "new row violated rls policy for table households"
--
-- Problem: Beim Erstellen eines Haushalts gibt es einen Race-Condition:
-- 1. INSERT into households (created_by = auth.uid()) → OK via insert policy
-- 2. INSERT into household_members (user_id = auth.uid()) → OK via insert policy
-- 3. Aber SELECT auf households schlägt fehl, weil der User noch kein Mitglied ist
--    wenn die INSERT-Policy geprüft wird (Supabase prüft auch RETURNING nach WITH CHECK)
--
-- Lösung: UPDATE und DELETE Policies hinzufügen (fehlten bisher)
-- und sicherstellen, dass auth_user_household_ids() korrekt funktioniert.
-- ============================================================

-- Sicherstellen dass die Hilfsfunktion existiert und korrekt ist
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

-- Alle bestehenden Policies für households löschen
drop policy if exists "households_policy" on households;
drop policy if exists "households_select_policy" on households;
drop policy if exists "households_insert_policy" on households;
drop policy if exists "households_update_policy" on households;
drop policy if exists "households_delete_policy" on households;

-- SELECT: nur Haushalte sehen, denen man angehört
create policy "households_select_policy" on households
  for select using (
    id in (select auth_user_household_ids())
    or created_by = auth.uid()  -- Ersteller kann Haushalt direkt nach Erstellung sehen
  );

-- INSERT: jeder angemeldete User kann einen Haushalt erstellen
create policy "households_insert_policy" on households
  for insert with check (
    auth.uid() = created_by
  );

-- UPDATE: nur Admins (via household_members) oder Ersteller
create policy "households_update_policy" on households
  for update using (
    created_by = auth.uid()
    or id in (
      select household_id from household_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

-- DELETE: nur Ersteller
create policy "households_delete_policy" on households
  for delete using (
    created_by = auth.uid()
  );

-- Alle bestehenden Policies für household_members löschen
drop policy if exists "household_members_policy" on household_members;
drop policy if exists "household_members_select_policy" on household_members;
drop policy if exists "household_members_insert_policy" on household_members;
drop policy if exists "household_members_delete_policy" on household_members;
drop policy if exists "household_members_update_policy" on household_members;

-- SELECT: Mitglieder sehen wenn man im gleichen Haushalt ist ODER es eigener Eintrag
create policy "household_members_select_policy" on household_members
  for select using (
    user_id = auth.uid()
    or household_id in (select auth_user_household_ids())
  );

-- INSERT: User kann sich selbst in einen Haushalt eintragen
create policy "household_members_insert_policy" on household_members
  for insert with check (
    auth.uid() = user_id
  );

-- UPDATE: eigene Mitgliedschaft aktualisieren oder Admin kann alle bearbeiten
create policy "household_members_update_policy" on household_members
  for update using (
    auth.uid() = user_id
    or household_id in (
      select household_id from household_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

-- DELETE: User kann sich selbst entfernen oder Admin kann Mitglieder entfernen
create policy "household_members_delete_policy" on household_members
  for delete using (
    auth.uid() = user_id
    or household_id in (
      select household_id from household_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

-- ============================================================
-- FERTIG! Household RLS-Fix abgeschlossen.
-- Führe dieses SQL im Supabase SQL-Editor aus.
-- ============================================================

