
-- ═══════════════════════════════════════════════════════════════════════════
-- FOODY – Migration 03: Haushalt-Chat
-- Ausführen in: Supabase Dashboard → SQL Editor
-- Voraussetzung: supabase_setup.sql bereits ausgeführt
-- ═══════════════════════════════════════════════════════════════════════════

-- Haushalt-Chat-Nachrichten
create table if not exists household_messages (
  id           uuid        primary key default gen_random_uuid(),
  household_id uuid        references households on delete cascade not null,
  user_id      uuid        references auth.users not null,
  sender_name  text        not null default 'Mitglied',
  content      text        not null,
  emoji        text,                        -- optionales Emoji-Prefix
  is_system    bool        default false,   -- System-Nachrichten
  created_at   timestamptz default now()
);

-- Indizes
create index if not exists idx_hm_household
  on household_messages(household_id, created_at desc);
create index if not exists idx_hm_user
  on household_messages(user_id);

-- RLS
alter table household_messages enable row level security;

-- Lesen: nur Haushaltsmitglieder
create policy "Chat lesen" on household_messages
  for select using (
    household_id in (select auth_user_household_ids())
  );

-- Schreiben: nur Haushaltsmitglieder
create policy "Chat schreiben" on household_messages
  for insert with check (
    auth.uid() = user_id
    and household_id in (select auth_user_household_ids())
  );

-- Löschen: nur eigene Nachrichten
create policy "Chat löschen" on household_messages
  for delete using (auth.uid() = user_id);

-- Realtime für Haushalt-Chat aktivieren
-- Im Dashboard: Database → Replication → household_messages aktivieren
-- ODER:
-- alter publication supabase_realtime add table household_messages;

-- Alte Nachrichten automatisch löschen (älter als 30 Tage)
-- Via pg_cron (falls verfügbar):
-- select cron.schedule('cleanup-chat', '0 4 * * *',
--   $$delete from household_messages where created_at < now() - interval '30 days'$$);

