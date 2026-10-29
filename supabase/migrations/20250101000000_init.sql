-- Code Hills 1001 — initial backend schema (Supabase / Postgres).
--
-- Apply with the Supabase CLI:   supabase db push
-- or paste into Dashboard → SQL Editor → Run.
--
-- Design notes:
-- * Row Level Security on every table (locked by default).
-- * profiles.is_admin drives the in-app Admin Portal.
-- * comments/inquiries/partner_requests reuse the JSON field names the
--   Flutter app already uses (comment_text, plan_id…) so the client maps
--   rows with its existing fromJson methods.

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

-- Anyone (incl. signed-out visitors) may read display names.
create policy "profiles are readable by everyone"
  on public.profiles for select
  using (true);

-- Users may update their own row, but never touch is_admin
-- (column-level grant below takes care of that).
create policy "users update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Only admins may change any profile (e.g. promote a user).
create policy "admins update any profile"
  on public.profiles for update
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.is_admin
  ));

-- Auto-create a profile when a new auth user registers.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'username',
      split_part(new.email, '@', 1)
    )
  )
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
  username     text not null,
  comment_text text not null,
  created_at   timestamptz not null default now()
);

create index if not exists comments_plan_id_idx on public.comments (plan_id);

alter table public.comments enable row level security;

create policy "comments readable by everyone"
  on public.comments for select
  using (true);

-- Signed-in users insert comments as themselves (username must match profile).
create policy "signed-in users insert own comments"
  on public.comments for insert
  with check (
    auth.uid() is not null
    and username = (select p.username from public.profiles p where p.id = auth.uid())
  );

-- Author or admin may delete.
create policy "author or admin deletes comment"
  on public.comments for delete
  using (
    username = (select p.username from public.profiles p where p.id = auth.uid())
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
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

-- Anyone (incl. signed-out) may submit an inquiry.
create policy "anyone inserts inquiries"
  on public.inquiries for insert
  with check (true);

-- Only admins may read the inbox.
create policy "admins read inquiries"
  on public.inquiries for select
  using (exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.is_admin
  ));

-- ---------------------------------------------------------------------------
-- partner_requests — REQUEST PARTNERSHIP on a plan (new shared table).
-- ---------------------------------------------------------------------------
create table if not exists public.partner_requests (
  id         bigint generated always as identity primary key,
  plan_id    integer not null,
  plan_name  text not null,
  username   text not null,
  message    text,
  created_at timestamptz not null default now()
);

alter table public.partner_requests enable row level security;

-- Signed-in users send requests as themselves.
create policy "signed-in users insert own partner requests"
  on public.partner_requests for insert
  with check (
    auth.uid() is not null
    and username = (select p.username from public.profiles p where p.id = auth.uid())
  );

-- Users see their own requests; admins see all.
create policy "own or admin reads partner requests"
  on public.partner_requests for select
  using (
    username = (select p.username from public.profiles p where p.id = auth.uid())
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  );

-- ---------------------------------------------------------------------------
-- Seed the first admin: sign up in the app with your email, then promote:
--   update public.profiles set is_admin = true where username = 'you';
-- ---------------------------------------------------------------------------
