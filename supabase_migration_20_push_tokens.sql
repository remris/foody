-- Migration 20: Push Notification Tokens & Settings
-- Ausführen im Supabase SQL Editor

-- ============================================================
-- 1. push_tokens – FCM/APNs Token pro User/Device
-- ============================================================
create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  token text not null,
  platform text check (platform in ('android', 'ios', 'web')),
  device_name text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, token)
);

alter table public.push_tokens enable row level security;

create policy "Eigene Push-Tokens lesen" on public.push_tokens
  for select using (auth.uid() = user_id);

create policy "Eigene Push-Tokens verwalten" on public.push_tokens
  for insert with check (auth.uid() = user_id);

create policy "Eigene Push-Tokens aktualisieren" on public.push_tokens
  for update using (auth.uid() = user_id);

create policy "Eigene Push-Tokens löschen" on public.push_tokens
  for delete using (auth.uid() = user_id);

-- Index für schnelle User-Lookups
create index if not exists idx_push_tokens_user on public.push_tokens(user_id);

-- ============================================================
-- 2. notification_settings – User-Präferenzen für Benachrichtigungen
-- ============================================================
create table if not exists public.notification_settings (
  user_id uuid primary key references auth.users,
  -- Kern-Benachrichtigungen (kostenlos)
  mhd_warnings bool default true,
  mhd_warning_days_before int default 2 check (mhd_warning_days_before between 1 and 7),
  household_changes bool default true,
  chat_messages bool default true,
  meal_reminders bool default false,
  meal_reminder_time time default '17:00:00',
  -- Community-Benachrichtigungen
  new_follower bool default true,
  recipe_likes bool default false,
  recipe_comments bool default false,
  -- Pro-Features
  weekly_summary bool default false,
  ai_limit_warning bool default true,
  -- Metadaten
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.notification_settings enable row level security;

create policy "Eigene Notification-Settings" on public.notification_settings
  for all using (auth.uid() = user_id);

-- Automatische Standard-Settings beim neuen User erstellen
create or replace function public.create_default_notification_settings()
returns trigger language plpgsql security definer as $$
begin
  insert into public.notification_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- Trigger: Beim Erstellen eines neuen Auth-Users automatisch Settings anlegen
drop trigger if exists on_auth_user_created_notification_settings on auth.users;
create trigger on_auth_user_created_notification_settings
  after insert on auth.users
  for each row execute function public.create_default_notification_settings();

-- ============================================================
-- 3. notification_log – Gesendete Benachrichtigungen tracken (optional, für Debugging)
-- ============================================================
create table if not exists public.notification_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  notification_type text not null, -- 'mhd_warning', 'household_change', 'new_follower', etc.
  title text,
  body text,
  data jsonb,
  sent_at timestamptz default now(),
  fcm_message_id text
);

alter table public.notification_log enable row level security;

-- Nur admins können den Log lesen (oder via Service Role)
create policy "Notification-Log nur eigene" on public.notification_log
  for select using (auth.uid() = user_id);

-- Automatisch alte Logs nach 30 Tagen löschen (Cleanup)
-- (In Supabase pg_cron konfigurieren)
-- select cron.schedule('delete-old-notification-logs', '0 3 * * *',
--   $$delete from public.notification_log where sent_at < now() - interval '30 days'$$);

-- ============================================================
-- 4. Bestehende notification_settings für aktuelle User anlegen
-- ============================================================
insert into public.notification_settings (user_id)
select id from auth.users
on conflict (user_id) do nothing;

-- ============================================================
-- Fertig! Nächste Schritte:
-- 1. Firebase-Projekt anlegen: console.firebase.google.com
-- 2. google-services.json → android/app/
-- 3. GoogleService-Info.plist → ios/Runner/
-- 4. firebase_core + firebase_messaging in pubspec.yaml ergänzen
-- 5. Supabase Edge Function 'send-push' deployen
-- ============================================================

