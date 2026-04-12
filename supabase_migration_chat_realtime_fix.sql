-- ═══════════════════════════════════════════════════════════════════════════
-- Fix: Haushalt-Chat Realtime aktivieren + RLS prüfen
-- Ausführen in: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Realtime für household_messages aktivieren
--    (falls noch nicht über das Dashboard aktiviert)
alter publication supabase_realtime add table household_messages;

-- 2. Sicherstellen dass die RLS-Policies korrekt sind
--    (drop & recreate um alte fehlerhafte Policies zu entfernen)

drop policy if exists "Chat lesen" on household_messages;
drop policy if exists "Chat schreiben" on household_messages;
drop policy if exists "Chat löschen" on household_messages;

-- Lesen: nur Haushaltsmitglieder
create policy "Chat lesen" on household_messages
  for select using (
    household_id in (select auth_user_household_ids())
  );

-- Schreiben: nur Haushaltsmitglieder dürfen eigene Nachrichten einfügen
create policy "Chat schreiben" on household_messages
  for insert with check (
    auth.uid() = user_id
    and household_id in (select auth_user_household_ids())
  );

-- Löschen: nur eigene Nachrichten
create policy "Chat löschen" on household_messages
  for delete using (auth.uid() = user_id);

-- 3. Test: Prüfe ob die Tabelle existiert und Einträge hat
select count(*) as anzahl_nachrichten from household_messages;

-- 4. Prüfe ob auth_user_household_ids() funktioniert (als eingeloggter User)
-- select * from auth_user_household_ids();

