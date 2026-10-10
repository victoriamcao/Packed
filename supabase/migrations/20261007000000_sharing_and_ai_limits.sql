-- Packed: list sharing + AI usage limits
--
-- Run once in the Supabase SQL editor (or `supabase db push`).
-- Assumes the existing tables from the original setup:
--   packing_lists(id uuid, user_id uuid, title, items jsonb, ...)
--   profiles(id uuid, name text, username text)
-- Safe to re-run: everything is "if not exists" / "or replace".

-- ---------------------------------------------------------------------------
-- 1. Sharing
-- ---------------------------------------------------------------------------

create table if not exists public.list_shares (
  list_id    uuid not null references public.packing_lists(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (list_id, user_id)
);

alter table public.list_shares enable row level security;

-- Helpers run as the table owner so policies on packing_lists and
-- list_shares can check each other without infinite RLS recursion.
create or replace function public.is_list_owner(p_list_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from packing_lists where id = p_list_id and user_id = auth.uid());
$$;

create or replace function public.is_list_member(p_list_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from list_shares where list_id = p_list_id and user_id = auth.uid());
$$;

-- You can see your own share rows, and the owner can see all shares of their list.
drop policy if exists "read own or owned shares" on public.list_shares;
create policy "read own or owned shares" on public.list_shares
  for select using (user_id = auth.uid() or public.is_list_owner(list_id));

-- Shared users can read the lists shared with them. (Owners keep whatever
-- policies they already have; Postgres ORs policies together.)
drop policy if exists "members can read shared lists" on public.packing_lists;
create policy "members can read shared lists" on public.packing_lists
  for select using (public.is_list_member(id));

-- Owner shares a list with someone, by their Packed username.
create or replace function public.share_list(p_list_id uuid, p_username text)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid;
begin
  if not public.is_list_owner(p_list_id) then
    raise exception 'Only the list''s owner can share it.';
  end if;

  select id into v_user from profiles
  where lower(username) = lower(trim(both '@' from trim(p_username)))
  limit 1;

  if v_user is null then
    raise exception 'No Packed user with that username.';
  end if;
  if v_user = auth.uid() then
    raise exception 'That''s you!';
  end if;

  insert into list_shares (list_id, user_id) values (p_list_id, v_user)
  on conflict do nothing;
end;
$$;

-- Owner stops sharing with someone.
create or replace function public.unshare_list(p_list_id uuid, p_username text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_list_owner(p_list_id) then
    raise exception 'Only the list''s owner can change sharing.';
  end if;

  delete from list_shares s
  using profiles p
  where s.list_id = p_list_id
    and s.user_id = p.id
    and lower(p.username) = lower(p_username);
end;
$$;

-- A shared user removes a shared list from their own Saved Lists.
create or replace function public.leave_shared_list(p_list_id uuid)
returns void
language sql security definer set search_path = public
as $$
  delete from list_shares where list_id = p_list_id and user_id = auth.uid();
$$;

-- Who a list is shared with (owner and members can see this).
create or replace function public.list_share_members(p_list_id uuid)
returns table (username text, name text)
language plpgsql stable security definer set search_path = public
as $$
begin
  if not (public.is_list_owner(p_list_id) or public.is_list_member(p_list_id)) then
    raise exception 'You don''t have access to this list.';
  end if;

  return query
    select p.username, p.name
    from list_shares s join profiles p on p.id = s.user_id
    where s.list_id = p_list_id
    order by s.created_at;
end;
$$;

-- Shared users can change a list's items (check off, add, remove, reorder)
-- but nothing else about it, so this goes through a function instead of
-- giving them UPDATE on the whole row.
create or replace function public.update_shared_list_items(p_list_id uuid, p_items jsonb)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not (public.is_list_owner(p_list_id) or public.is_list_member(p_list_id)) then
    raise exception 'You don''t have access to this list.';
  end if;
  if jsonb_typeof(p_items) <> 'array' then
    raise exception 'Items must be a list.';
  end if;

  update packing_lists set items = p_items where id = p_list_id;
end;
$$;

revoke all on function public.share_list(uuid, text) from public, anon;
revoke all on function public.unshare_list(uuid, text) from public, anon;
revoke all on function public.leave_shared_list(uuid) from public, anon;
revoke all on function public.list_share_members(uuid) from public, anon;
revoke all on function public.update_shared_list_items(uuid, jsonb) from public, anon;
grant execute on function public.share_list(uuid, text) to authenticated;
grant execute on function public.unshare_list(uuid, text) to authenticated;
grant execute on function public.leave_shared_list(uuid) to authenticated;
grant execute on function public.list_share_members(uuid) to authenticated;
grant execute on function public.update_shared_list_items(uuid, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. AI usage limits (written only by the generate-packing-list function)
-- ---------------------------------------------------------------------------

create table if not exists public.ai_generations (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists ai_generations_user_time on public.ai_generations (user_id, created_at);

-- RLS on with no policies = only the service role (the Edge Function) can touch it.
alter table public.ai_generations enable row level security;

-- ---------------------------------------------------------------------------
-- 3. Usernames must be unique (case-insensitive) for sharing to make sense.
--    If this fails, you already have duplicate usernames - fix those first.
-- ---------------------------------------------------------------------------

create unique index if not exists profiles_username_lower_unique
  on public.profiles (lower(username));
