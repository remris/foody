-- Migration 21: subscriptions Tabelle für RevenueCat erweitern
-- Die Tabelle existiert bereits mit: id, user_id, plan, valid_until, source, created_at, updated_at
-- Diese Migration ergänzt fehlende RevenueCat-Felder
-- Ausführen im Supabase SQL Editor

-- ============================================================
-- 1. Fehlende Spalten ergänzen (safe – nur wenn nicht vorhanden)
-- ============================================================

-- is_active als normale bool-Spalte (wird per Trigger/Webhook aktuell gehalten)
-- HINWEIS: generated always as (now()) ist nicht erlaubt (not immutable)
alter table public.subscriptions
  add column if not exists is_active boolean default false;

-- is_active initial befüllen basierend auf valid_until
update public.subscriptions
  set is_active = (valid_until is not null and valid_until > now())
  where is_active is null or is_active = false;

-- RevenueCat spezifische Felder
alter table public.subscriptions
  add column if not exists revenuecat_product_id text,
  add column if not exists revenuecat_store text,
  add column if not exists environment text,
  add column if not exists cancelled_at timestamptz,
  add column if not exists cancel_reason text,
  add column if not exists started_at timestamptz;

-- expires_at als Alias für valid_until (für Webhook-Kompatibilität)
-- Wir verwenden weiterhin valid_until, der Webhook wird angepasst

-- ============================================================
-- 2. plan-Werte erweitern (pro_yearly hinzufügen)
-- ============================================================
alter table public.subscriptions
  drop constraint if exists subscriptions_plan_check;

alter table public.subscriptions
  add constraint subscriptions_plan_check
  check (plan in ('free', 'pro', 'pro_yearly', 'pro_plus'));

-- ============================================================
-- 3. RLS Policies aktualisieren
-- ============================================================

-- Service Role Policy für Webhook (umgeht RLS)
do $$ begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'subscriptions'
    and policyname = 'Service Role Vollzugriff'
  ) then
    create policy "Service Role Vollzugriff" on public.subscriptions
      for all using (true);
  end if;
end $$;

-- ============================================================
-- 4. Standard-Einträge für bestehende User (die noch keinen haben)
-- ============================================================
insert into public.subscriptions (user_id, plan, valid_until, source)
select id, 'free', null, 'manual'
from auth.users
where id not in (select user_id from public.subscriptions)
on conflict (user_id) do nothing;

-- ============================================================
-- 5. Trigger: Automatisch Eintrag für neue User erstellen
-- ============================================================
create or replace function public.create_default_subscription()
returns trigger language plpgsql security definer as $$
begin
  insert into public.subscriptions (user_id, plan, source, is_active)
  values (new.id, 'free', 'manual', false)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_subscription on auth.users;
create trigger on_auth_user_created_subscription
  after insert on auth.users
  for each row execute function public.create_default_subscription();

-- ============================================================
-- 5b. Trigger: is_active automatisch setzen wenn valid_until sich ändert
-- ============================================================
create or replace function public.sync_subscription_is_active()
returns trigger language plpgsql as $$
begin
  new.is_active := (new.valid_until is not null and new.valid_until > now());
  return new;
end;
$$;

drop trigger if exists sync_is_active_on_subscription on public.subscriptions;
create trigger sync_is_active_on_subscription
  before insert or update of valid_until, plan on public.subscriptions
  for each row execute function public.sync_subscription_is_active();

-- ============================================================
-- 6. Hilfsfunktion: is_pro_user() für andere RLS-Policies
-- ============================================================
create or replace function public.is_pro_user(uid uuid default auth.uid())
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from public.subscriptions
    where user_id = uid
      and plan in ('pro', 'pro_yearly', 'pro_plus')
      and valid_until is not null
      and valid_until > now()
  );
$$;

-- ============================================================
-- 7. Performance-Index
-- ============================================================
create index if not exists idx_subscriptions_user_valid
  on public.subscriptions(user_id, valid_until);

create index if not exists idx_subscriptions_user_active
  on public.subscriptions(user_id, is_active)
  where is_active = true;

-- ============================================================
-- FERTIG!
-- Nächste Schritte:
--   1. RevenueCat Webhook deployen:
--      supabase functions deploy revenuecat-webhook
--   2. Secrets setzen:
--      supabase secrets set REVENUECAT_WEBHOOK_SECRET=<dein-secret>
--   3. In RevenueCat Dashboard:
--      Webhooks → URL: https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook
--      Authorization: Bearer <dein-secret>
-- ============================================================
