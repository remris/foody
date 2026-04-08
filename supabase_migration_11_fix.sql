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
    select 1
    from household_members
    where household_id = hid
      and user_id = auth.uid()
      and role = 'admin'
  );
$$;

drop policy if exists "household_members_policy" on household_members;
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

drop policy if exists "households_policy" on households;
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

