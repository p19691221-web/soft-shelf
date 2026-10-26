-- 開放聊天室（open-voice）· 只負責「誰在房間裡」和交換連線資料，聲音不經過資料庫
-- Supabase → SQL Editor 貼上整份按 Run，一次就好。和其他資料表互不影響。
create table if not exists ov_peers (
  peer_id uuid primary key default gen_random_uuid(),
  peer_key uuid not null default gen_random_uuid(),
  room text not null check (room ~ '^[a-z0-9-]{4,40}$'),
  nick text not null check (char_length(nick) between 1 and 16),
  mic boolean not null default true,
  joined_at timestamptz not null default now(),
  seen_at timestamptz not null default now());
create index if not exists ov_peers_room on ov_peers (room);
create table if not exists ov_signals (
  id bigint generated always as identity primary key,
  to_peer uuid not null, from_peer uuid not null,
  kind text not null check (kind in ('offer','answer')),
  body text not null check (char_length(body) <= 30000),
  created_at timestamptz not null default now());
create index if not exists ov_signals_to on ov_signals (to_peer, id);
alter table ov_peers enable row level security;
alter table ov_signals enable row level security;
revoke all on ov_peers, ov_signals from public, anon, authenticated;

create or replace function ov_room(p_room text) returns json
language sql stable security definer set search_path = public as $$
  select coalesce(json_agg(nick order by joined_at), '[]'::json) from ov_peers
  where room = lower(p_room) and seen_at > now() - interval '30 seconds';
$$;

create or replace function ov_join(p_room text, p_nick text) returns json
language plpgsql security definer set search_path = public as $$
declare r ov_peers; rm text := lower(btrim(p_room));
begin
  delete from ov_peers where seen_at < now() - interval '30 seconds';
  delete from ov_signals where created_at < now() - interval '2 minutes';
  if (select count(*) from ov_peers) >= 300 then raise exception '現在人太多了，請稍後再試'; end if;
  if (select count(*) from ov_peers where room = rm) >= 10 then raise exception '這個房間滿了（最多 10 人）'; end if;
  insert into ov_peers (room, nick) values (rm, btrim(p_nick)) returning * into r;
  return json_build_object('peer', r.peer_id, 'key', r.peer_key);
end $$;

create or replace function ov_poll(p_peer uuid, p_key uuid, p_after bigint default 0, p_mic boolean default null) returns json
language plpgsql security definer set search_path = public as $$
declare rm text;
begin
  update ov_peers set seen_at = now(), mic = coalesce(p_mic, mic)
  where peer_id = p_peer and peer_key = p_key returning room into rm;
  if not found then return json_build_object('gone', true); end if;
  delete from ov_signals where to_peer = p_peer and id <= coalesce(p_after, 0);
  return json_build_object(
    'peers', (select coalesce(json_agg(json_build_object('peer', peer_id, 'nick', nick, 'mic', mic)
       order by joined_at), '[]'::json) from ov_peers
      where room = rm and peer_id <> p_peer and seen_at > now() - interval '30 seconds'),
    'signals', (select coalesce(json_agg(json_build_object('id', id, 'from', from_peer, 'kind', kind,
       'body', body) order by id), '[]'::json) from ov_signals where to_peer = p_peer and id > coalesce(p_after, 0)));
end $$;

create or replace function ov_send(p_peer uuid, p_key uuid, p_to uuid, p_kind text, p_body text) returns json
language plpgsql security definer set search_path = public as $$
declare rm text;
begin
  select room into rm from ov_peers where peer_id = p_peer and peer_key = p_key;
  if rm is null then raise exception '你已經不在房間裡'; end if;
  if not exists (select 1 from ov_peers where peer_id = p_to and room = rm) then return json_build_object('ok', false); end if;
  if (select count(*) from ov_signals where from_peer = p_peer and created_at > now() - interval '10 seconds') >= 40 then
    raise exception '連線太頻繁，請稍等'; end if;
  insert into ov_signals (to_peer, from_peer, kind, body) values (p_to, p_peer, p_kind, p_body);
  return json_build_object('ok', true);
end $$;

create or replace function ov_leave(p_peer uuid, p_key uuid) returns json
language plpgsql security definer set search_path = public as $$
begin
  delete from ov_peers where peer_id = p_peer and peer_key = p_key;
  delete from ov_signals where to_peer = p_peer or from_peer = p_peer;
  return json_build_object('ok', true);
end $$;

revoke all on function ov_room(text), ov_join(text,text), ov_poll(uuid,uuid,bigint,boolean),
  ov_send(uuid,uuid,uuid,text,text), ov_leave(uuid,uuid) from public;
grant execute on function ov_room(text), ov_join(text,text), ov_poll(uuid,uuid,bigint,boolean),
  ov_send(uuid,uuid,uuid,text,text), ov_leave(uuid,uuid) to anon, authenticated;
