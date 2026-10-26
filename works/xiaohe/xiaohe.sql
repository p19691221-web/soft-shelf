-- 小禾陪你聊 · 用量上限（防止被濫用、費用失控）
-- Supabase → SQL Editor 貼上整份按 Run，一次就好。
create table if not exists xh_usage (
  bucket text primary key,
  n int not null default 0,
  updated_at timestamptz not null default now());
alter table xh_usage enable row level security;
revoke all on xh_usage from public, anon, authenticated;

-- 每次小禾要回話前先呼叫：同一個來源每小時最多 p_hour 次、全部人每天最多 p_day 次
create or replace function xh_take(p_who text, p_hour int default 60, p_day int default 3000) returns boolean
language plpgsql security definer set search_path = public as $$
declare d text := 'day:' || to_char(now() at time zone 'Asia/Taipei', 'YYYY-MM-DD');
        h text := 'ip:' || left(coalesce(p_who, '?'), 80) || ':' || to_char(now(), 'YYYY-MM-DD-HH24');
        nd int; nh int;
begin
  delete from xh_usage where updated_at < now() - interval '2 days';
  insert into xh_usage (bucket, n) values (d, 1) on conflict (bucket) do update set n = xh_usage.n + 1, updated_at = now() returning n into nd;
  insert into xh_usage (bucket, n) values (h, 1) on conflict (bucket) do update set n = xh_usage.n + 1, updated_at = now() returning n into nh;
  return nd <= p_day and nh <= p_hour;
end $$;

revoke all on function xh_take(text,int,int) from public, anon, authenticated;
grant execute on function xh_take(text,int,int) to service_role;
