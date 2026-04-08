-- ─────────────────────────────────────────────────────────────────────────────
-- Foody – Haushalt-Aktivitätslog Migration
-- Führe dieses SQL in deinem Supabase SQL-Editor aus.
-- ─────────────────────────────────────────────────────────────────────────────

-- Aktivitätslog für Haushaltsmitglieder
create table if not exists household_activity_log (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households(id) on delete cascade not null,
  user_id uuid references auth.users not null,
  display_name text default 'Unbekannt',
  action text not null check (action in ('added', 'updated', 'deleted', 'checked', 'unchecked')),
  item_type text not null check (item_type in ('inventory', 'shopping')),
  item_name text not null,
  created_at timestamptz default now()
);

alter table household_activity_log enable row level security;

-- Nur Haushaltsmitglieder können das Log ihres Haushalts lesen
create policy "Aktivitätslog lesen" on household_activity_log
  for select using (
    auth.uid() in (
      select user_id from household_members where household_id = household_activity_log.household_id
    )
  );

-- Nur Haushaltsmitglieder können ins Log schreiben
create policy "Aktivitätslog schreiben" on household_activity_log
  for insert with check (
    auth.uid() = user_id and
    auth.uid() in (
      select user_id from household_members where household_id = household_activity_log.household_id
    )
  );

-- Index für schnelle Abfragen
create index if not exists idx_activity_household on household_activity_log(household_id, created_at desc);
create index if not exists idx_activity_user on household_activity_log(user_id);

