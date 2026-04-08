-- ============================================================
-- Migration 22: Social Posts
-- Ausfuehren im Supabase SQL-Editor
-- ============================================================
-- ── Tabellen ──────────────────────────────────────────────
create table if not exists social_posts (
  id                  uuid        primary key default gen_random_uuid(),
  user_id             uuid        not null references auth.users(id) on delete cascade,
  author_name         text        not null default 'Foody-User',
  avatar_url          text,
  text                text        not null,
  attached_recipe_id  uuid        references community_recipes(id)      on delete set null,
  attached_plan_id    uuid        references community_meal_plans(id)   on delete set null,
  like_count          int         not null default 0,
  comment_count       int         not null default 0,
  created_at          timestamptz not null default now()
);
create table if not exists social_post_likes (
  post_id  uuid not null references social_posts(id) on delete cascade,
  user_id  uuid not null references auth.users(id)   on delete cascade,
  primary key (post_id, user_id)
);
create table if not exists social_post_comments (
  id          uuid        primary key default gen_random_uuid(),
  post_id     uuid        not null references social_posts(id) on delete cascade,
  user_id     uuid        not null references auth.users(id)   on delete cascade,
  author_name text        not null default 'Foody-User',
  text        text        not null,
  created_at  timestamptz not null default now()
);
-- ── Indexes ──────────────────────────────────────────────
create index if not exists social_posts_user_id_idx         on social_posts(user_id);
create index if not exists social_posts_created_at_idx      on social_posts(created_at desc);
create index if not exists social_post_comments_post_id_idx on social_post_comments(post_id);
-- ── Row Level Security ───────────────────────────────────
alter table social_posts         enable row level security;
alter table social_post_likes    enable row level security;
alter table social_post_comments enable row level security;
-- social_posts
create policy "social_posts_select" on social_posts for select using (auth.uid() is not null);
create policy "social_posts_insert" on social_posts for insert with check (auth.uid() = user_id);
create policy "social_posts_update" on social_posts for update using (true);
create policy "social_posts_delete" on social_posts for delete using (auth.uid() = user_id);
-- social_post_likes
create policy "post_likes_select" on social_post_likes for select using (auth.uid() is not null);
create policy "post_likes_insert" on social_post_likes for insert with check (auth.uid() = user_id);
create policy "post_likes_delete" on social_post_likes for delete using (auth.uid() = user_id);
-- social_post_comments
create policy "post_comments_select" on social_post_comments for select using (auth.uid() is not null);
create policy "post_comments_insert" on social_post_comments for insert with check (auth.uid() = user_id);
create policy "post_comments_delete" on social_post_comments for delete using (auth.uid() = user_id);
-- ── Trigger: comment_count bei INSERT/DELETE automatisch pflegen ──
create or replace function _trg_post_comment_inc()
returns trigger language plpgsql security definer as $$
begin
  update social_posts set comment_count = comment_count + 1 where id = NEW.post_id;
  return NEW;
end;
$$;
create or replace trigger trg_post_comment_count_inc
  after insert on social_post_comments
  for each row execute function _trg_post_comment_inc();
create or replace function _trg_post_comment_dec()
returns trigger language plpgsql security definer as $$
begin
  update social_posts set comment_count = greatest(comment_count - 1, 0) where id = OLD.post_id;
  return OLD;
end;
$$;
create or replace trigger trg_post_comment_count_dec
  after delete on social_post_comments
  for each row execute function _trg_post_comment_dec();
-- ── RPC: comment_count manuell inkrementieren (Flutter-Fallback) ──
create or replace function increment_post_comment_count(p_post_id uuid)
returns void language plpgsql security definer as $$
begin
  update social_posts set comment_count = comment_count + 1 where id = p_post_id;
end;
$$;
