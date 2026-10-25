-- Packed: base schema (profiles, packing_lists, map_pins, map-photos storage)
--
-- This is the schema the app's Swift code talks to directly via PostgREST
-- (see SupabaseProfileService.swift, SavedLists.swift, PinStore.swift).
-- Named to run before 20261007000000_sharing_and_ai_limits.sql, which
-- builds on top of these tables. Run via `supabase db push` or by pasting
-- into the SQL Editor. Safe to re-run: everything is "if not exists" / "or replace".

-- ---------------------------------------------------------------------------
-- profiles: account info beyond what Supabase Auth itself stores
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  name       text,
  username   text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles
  for select using (id = auth.uid());

drop policy if exists "insert own profile" on public.profiles;
create policy "insert own profile" on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles
  for update using (id = auth.uid());

-- Case-insensitive unique usernames (share_list looks users up by username).
create unique index if not exists profiles_username_unique_idx
  on public.profiles (lower(username));

-- ---------------------------------------------------------------------------
-- packing_lists
-- ---------------------------------------------------------------------------

create table if not exists public.packing_lists (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  items       jsonb not null default '[]',
  trip_type   text,
  duration    integer,
  member      text,
  travel_date date,
  created_at  timestamptz not null default now()
);

alter table public.packing_lists enable row level security;

drop policy if exists "owner full access" on public.packing_lists;
create policy "owner full access" on public.packing_lists
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- map_pins: pin coordinates + photo paths (photo bytes live in Storage)
-- ---------------------------------------------------------------------------

create table if not exists public.map_pins (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  latitude    double precision not null,
  longitude   double precision not null,
  photo_paths jsonb not null default '[]',
  created_at  timestamptz not null default now()
);

alter table public.map_pins enable row level security;

drop policy if exists "owner full access" on public.map_pins;
create policy "owner full access" on public.map_pins
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Storage: map-photos bucket, private, one folder per user id
-- (PinStore.swift uploads to "<userId>/<pinId>_<uuid>.jpg")
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('map-photos', 'map-photos', false)
on conflict (id) do nothing;

drop policy if exists "map-photos owner access" on storage.objects;
create policy "map-photos owner access" on storage.objects
  for all using (
    bucket_id = 'map-photos' and (storage.foldername(name))[1] = auth.uid()::text
  ) with check (
    bucket_id = 'map-photos' and (storage.foldername(name))[1] = auth.uid()::text
  );
