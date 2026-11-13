-- Code Hills 1001 — initial backend schema (Supabase / Postgres).
--
-- Apply with the Supabase CLI:   supabase db push
-- or paste into Dashboard → SQL Editor → Run.
--
-- Security model (read before changing anything):
-- * Row Level Security is enabled on every table and the app only ever holds
--   the anon/publishable key. Never put a service-role key in the Flutter app.
-- * profiles.is_admin is protected twice: column-level grants (an ordinary
--   user can update only their username) and a trigger that refuses any
--   is_admin change unless it comes from the owner (`postgres` / service
--   role). Hiding the admin screen in Flutter is not a security boundary.
-- * Administrator promotion is an owner action in the SQL editor, never
--   something an app client can do.
-- * comments / partner_requests carry user_id, defaulted from auth.uid(), so
--   ownership is proved by the authenticated session rather than by a
--   client-supplied name.
--
-- The Flutter client maps rows with its existing fromJson methods, so the
-- JSON field names still match the original SQLite column names.
--
-- This schema has not been applied to a production project yet. If you ran an
-- earlier revision of this file, drop and recreate these tables (there is no
-- data to keep) so the new columns and policies exist.

-- ---------------------------------------------------------------------------
-- profiles — one row per auth user (created automatically on sign-up).
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  username   text not null unique,
  is_admin   boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to anon, authenticated;

-- Column-level update grant: clients may rename themselves and nothing else.
-- is_admin is deliberately not grantable, so a forged update fails in Postgres
-- before RLS is even consulted.
grant update (username) on public.profiles to authenticated;

drop policy if exists "profiles are readable by everyone" on public.profiles;
create policy "profiles are readable by everyone"
  on public.profiles for select
  using (true);

drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- The old "admins update any profile" policy is removed on purpose: role
-- changes go through the owner's SQL session, not through the app.
drop policy if exists "admins update any profile" on public.profiles;

-- Belt and braces: even the owner's own session must use an explicit
-- promotion statement, and no client role can flip the flag.
create or replace function public.guard_profile_admin_flag()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.is_admin is distinct from old.is_admin
     and current_user not in ('postgres', 'service_role', 'supabase_admin')
  then
    raise exception
      'profiles.is_admin can only be changed by the project owner';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_profile_admin_flag on public.profiles;
create trigger guard_profile_admin_flag
  before update on public.profiles
  for each row execute function public.guard_profile_admin_flag();

-- Auto-create a profile when a new auth user registers.
-- username is unique, so two accounts called "john@a.com" / "john@b.com" must
-- not make the second sign-up fail: fall back to a short id suffix.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_name text;
  candidate text;
begin
  base_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'username', ''),
    split_part(coalesce(new.email, 'user'), '@', 1)
  );
  candidate := base_name;
  if exists (select 1 from public.profiles p where p.username = candidate) then
    candidate := base_name || '_' || left(new.id::text, 6);
  end if;

  insert into public.profiles (id, username)
  values (new.id, candidate)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- comments — shared per-plan discussion (was local SharedPreferences).
-- ---------------------------------------------------------------------------
create table if not exists public.comments (
  id           bigint generated always as identity primary key,
  plan_id      integer not null,
  user_id      uuid not null default auth.uid()
                 references auth.users (id) on delete cascade,
  username     text not null,
  comment_text text not null,
  created_at   timestamptz not null default now()
);

create index if not exists comments_plan_id_idx on public.comments (plan_id);
create index if not exists comments_user_id_idx on public.comments (user_id);

alter table public.comments enable row level security;

revoke all on public.comments from anon, authenticated;
grant select on public.comments to anon, authenticated;
grant insert, delete on public.comments to authenticated;

drop policy if exists "comments readable by everyone" on public.comments;
create policy "comments readable by everyone"
  on public.comments for select
  using (true);

-- Signed-in users insert comments as themselves: user_id comes from the
-- session (default auth.uid()) and the display name must be their own profile.
drop policy if exists "signed-in users insert own comments" on public.comments;
create policy "signed-in users insert own comments"
  on public.comments for insert
  with check (
    auth.uid() is not null
    and user_id = auth.uid()
    and username = (
      select p.username from public.profiles p where p.id = auth.uid()
    )
  );

-- Author or admin may delete.
drop policy if exists "author or admin deletes comment" on public.comments;
create policy "author or admin deletes comment"
  on public.comments for delete
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.profiles p where p.id = auth.uid() and p.is_admin
    )
  );

-- ---------------------------------------------------------------------------
-- inquiries — Contact Us submissions (was local SharedPreferences).
-- ---------------------------------------------------------------------------
create table if not exists public.inquiries (
  id         bigint generated always as identity primary key,
  name       text not null,
  email      text,
  inquiry    text not null,
  created_at timestamptz not null default now()
);

alter table public.inquiries enable row level security;

revoke all on public.inquiries from anon, authenticated;
grant insert on public.inquiries to anon, authenticated;
grant select on public.inquiries to authenticated;

-- Anyone (incl. signed-out) may submit an inquiry.
drop policy if exists "anyone inserts inquiries" on public.inquiries;
create policy "anyone inserts inquiries"
  on public.inquiries for insert
  with check (true);

-- Only admins may read the inbox. Note: because ordinary users have no select
-- policy, the client must insert without `returning` (see AppData._sendInquiry)
-- or the request comes back as a permissions error.
drop policy if exists "admins read inquiries" on public.inquiries;
create policy "admins read inquiries"
  on public.inquiries for select
  using (
    exists (
      select 1 from public.profiles p where p.id = auth.uid() and p.is_admin
    )
  );

-- ---------------------------------------------------------------------------
-- partner_requests — REQUEST PARTNERSHIP on a plan (new shared table).
-- ---------------------------------------------------------------------------
create table if not exists public.partner_requests (
  id         bigint generated always as identity primary key,
  plan_id    integer not null,
  plan_name  text not null,
  user_id    uuid not null default auth.uid()
               references auth.users (id) on delete cascade,
  username   text not null,
  message    text,
  created_at timestamptz not null default now()
);

create index if not exists partner_requests_user_id_idx
  on public.partner_requests (user_id);

alter table public.partner_requests enable row level security;

revoke all on public.partner_requests from anon, authenticated;
grant select, insert on public.partner_requests to authenticated;

-- Signed-in users send requests as themselves (owner proved by the session).
drop policy if exists "signed-in users insert own partner requests"
  on public.partner_requests;
create policy "signed-in users insert own partner requests"
  on public.partner_requests for insert
  with check (auth.uid() is not null and user_id = auth.uid());

-- Users see their own requests; admins see all.
drop policy if exists "own or admin reads partner requests"
  on public.partner_requests;
create policy "own or admin reads partner requests"
  on public.partner_requests for select
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.profiles p where p.id = auth.uid() and p.is_admin
    )
  );

-- ---------------------------------------------------------------------------
-- Seed the first admin: sign up in the app, then promote yourself from the
-- SQL editor (which runs as the owner and passes the guard trigger):
--
--   update public.profiles set is_admin = true
--   where username = 'your-username';
--
-- Verify the policies with at least two accounts (an ordinary user and an
-- admin): a user must not read the inquiry inbox, impersonate another
-- username, change their own is_admin flag, or delete someone else's rows.
-- ---------------------------------------------------------------------------
