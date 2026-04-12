-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 28: household_messages – Tabelle sicherstellen + Realtime
-- Sicher idempotent: kann mehrfach ausgeführt werden
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Tabelle erstellen (falls noch nicht vorhanden)
create table if not exists public.household_messages (
  id           uuid        primary key default gen_random_uuid(),
  household_id uuid        references public.households(id) on delete cascade not null,
  user_id      uuid        references auth.users(id) not null,
  sender_name  text        not null default 'Mitglied',
  content      text        not null,
  emoji        text,
  is_system    bool        not null default false,
  created_at   timestamptz not null default now()
);

-- 2. Indizes
create index if not exists idx_hm_household_created
  on public.household_messages(household_id, created_at desc);

create index if not exists idx_hm_user
  on public.household_messages(user_id);

-- 3. RLS aktivieren
alter table public.household_messages enable row level security;

-- 4. Policies (erst löschen, dann neu anlegen – idempotent)
drop policy if exists "Chat lesen"     on public.household_messages;
drop policy if exists "Chat schreiben" on public.household_messages;
drop policy if exists "Chat löschen"   on public.household_messages;

-- Lesen: nur Haushaltsmitglieder des jeweiligen Haushalts
create policy "Chat lesen" on public.household_messages
  for select using (
    household_id in (
      select household_id
      from public.household_members
      where user_id = auth.uid()
    )
  );

-- Schreiben: Mitglied muss im Haushalt sein, user_id muss mit auth.uid() übereinstimmen
create policy "Chat schreiben" on public.household_messages
  for insert with check (
    auth.uid() = user_id
    and household_id in (
      select household_id
      from public.household_members
      where user_id = auth.uid()
    )
  );

-- Löschen: nur eigene Nachrichten
create policy "Chat löschen" on public.household_messages
  for delete using (auth.uid() = user_id);

-- 5. Realtime aktivieren
alter publication supabase_realtime add table public.household_messages;

-- 6. Prüfabfrage
select
  'household_messages existiert ✅' as status,
  count(*) as anzahl_nachrichten
from public.household_messages;

