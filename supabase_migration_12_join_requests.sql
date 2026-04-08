-- ============================================================
-- Migration 12: Join-Requests + RLS-Fix (infinite recursion)
-- ============================================================

-- ── 1. Hilfsfunktionen (security definer = kein RLS) ─────────────────────

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

create or replace function is_household_admin(hid uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from household_members
    where household_id = hid
      and user_id = auth.uid()
      and role = 'admin'
  );
$$;

-- Haushalt per Invite-Code finden (security definer umgeht RLS)
-- Wird gebraucht damit ein Nicht-Mitglied den Haushalt per Code sehen kann
create or replace function get_household_by_invite_code(code text)
returns table (
  id uuid,
  name text,
  created_by uuid,
  invite_code text,
  created_at timestamptz
)
language sql
security definer
stable
as $$
  select id, name, created_by, invite_code, created_at
  from households
  where households.invite_code = upper(trim(code));
$$;

-- ── 2. household_join_requests Tabelle ───────────────────────────────────

create table if not exists household_join_requests (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households on delete cascade not null,
  user_id uuid references auth.users not null,
  display_name text,
  status text default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz default now(),
  unique(household_id, user_id)
);

alter table household_join_requests enable row level security;

drop policy if exists "join_requests_select" on household_join_requests;
drop policy if exists "join_requests_insert" on household_join_requests;
drop policy if exists "join_requests_update" on household_join_requests;
drop policy if exists "join_requests_delete" on household_join_requests;

-- SELECT: eigene Anfragen ODER Admin des Haushalts
create policy "join_requests_select" on household_join_requests
  for select using (
    user_id = auth.uid()
    or is_household_admin(household_id)
  );

-- INSERT: jeder angemeldete User kann eine Anfrage stellen
create policy "join_requests_insert" on household_join_requests
  for insert with check (
    auth.uid() = user_id
  );

-- UPDATE: Admin des Haushalts (annehmen/ablehnen) ODER User aktualisiert eigene Anfrage
create policy "join_requests_update" on household_join_requests
  for update using (
    user_id = auth.uid()
    or is_household_admin(household_id)
  ) with check (
    user_id = auth.uid()
    or is_household_admin(household_id)
  );

-- DELETE: eigene Anfrage zurückziehen ODER Admin
create policy "join_requests_delete" on household_join_requests
  for delete using (
    user_id = auth.uid()
    or is_household_admin(household_id)
  );

-- ── 3. household_members RLS neu (infinite recursion fix) ────────────────

drop policy if exists "household_members_policy"        on household_members;
drop policy if exists "household_members_select_policy" on household_members;
drop policy if exists "household_members_insert_policy" on household_members;
drop policy if exists "household_members_update_policy" on household_members;
drop policy if exists "household_members_delete_policy" on household_members;

create policy "household_members_select_policy" on household_members
  for select using (
    user_id = auth.uid()
    or household_id in (select auth_user_household_ids())
  );

create policy "household_members_insert_policy" on household_members
  for insert with check (
    auth.uid() = user_id
    or is_household_admin(household_id)
  );

create policy "household_members_update_policy" on household_members
  for update using (
    auth.uid() = user_id
    or is_household_admin(household_id)
  );

create policy "household_members_delete_policy" on household_members
  for delete using (
    auth.uid() = user_id
    or is_household_admin(household_id)
  );

-- ── 4. households RLS neu ────────────────────────────────────────────────

drop policy if exists "households_policy"        on households;
drop policy if exists "households_select_policy" on households;
drop policy if exists "households_insert_policy" on households;
drop policy if exists "households_update_policy" on households;
drop policy if exists "households_delete_policy" on households;

create policy "households_select_policy" on households
  for select using (
    id in (select auth_user_household_ids())
    or created_by = auth.uid()
  );

create policy "households_insert_policy" on households
  for insert with check (
    auth.uid() = created_by
  );

create policy "households_update_policy" on households
  for update using (
    created_by = auth.uid()
    or is_household_admin(id)
  );

create policy "households_delete_policy" on households
  for delete using (
    created_by = auth.uid()
    or is_household_admin(id)
  );

-- ── 5. accept_join_request Funktion (security definer) ──────────────────
-- Admin ruft diese Funktion auf → läuft mit elevated rights
-- → kein RLS-Problem beim Eintragen des neuen Members

create or replace function accept_join_request(request_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  req record;
begin
  -- Anfrage laden
  select * into req
  from household_join_requests
  where id = request_id and status = 'pending';

  if not found then
    raise exception 'Anfrage nicht gefunden oder bereits bearbeitet';
  end if;

  -- Prüfen ob der Aufrufer Admin des Haushalts ist
  if not is_household_admin(req.household_id) then
    raise exception 'Keine Admin-Berechtigung';
  end if;

  -- Status auf accepted setzen
  update household_join_requests
  set status = 'accepted'
  where id = request_id;

  -- Mitglied eintragen
  insert into household_members (household_id, user_id, display_name, role)
  values (req.household_id, req.user_id, req.display_name, 'member')
  on conflict (household_id, user_id) do update
    set display_name = excluded.display_name;
end;
$$;

-- ── 6. Realtime für join_requests aktivieren ─────────────────────────────
-- Tabelle ist bereits in supabase_realtime Publikation enthalten
-- alter publication supabase_realtime add table household_join_requests;

