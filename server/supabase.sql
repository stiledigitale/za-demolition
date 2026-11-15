-- ZA DEMOLITION · classifica online su Supabase (progetto stiledigitale_games)
-- Tabelle chiuse (RLS senza policy): il gioco usa SOLO le funzioni za_* qui sotto,
-- che controllano la chiave segreta del giocatore e i valori inviati.

create table if not exists public.za_players (
  id         bigint generated always as identity primary key,
  token      text not null unique,                     -- chiave segreta del dispositivo (mai mostrata ad altri)
  code       text not null unique check (code ~ '^[A-Z0-9]{6}$'),  -- codice di recupero
  name       text not null default '' check (char_length(name) <= 14),
  progress   jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.za_players is 'ZA DEMOLITION: giocatori (nome, codice di recupero, progressi). Accesso solo dalle funzioni za_*';

create table if not exists public.za_scores (
  id         bigint generated always as identity primary key,
  player_id  bigint not null references public.za_players(id) on delete cascade,
  mode       text not null check (mode ~ '^(road|s[0-9]{1,2})$'),   -- road = Roadmap, s0..s15 = partita singola per città
  floors     int  not null check (floors between 1 and 100000),
  time_ms    int  not null check (time_ms between 0 and 36000000),
  city       int  not null default 0 check (city between 0 and 999),
  combo      int  not null default 0 check (combo between 0 and 100000),
  operator   int  not null default 0 check (operator between 0 and 99),
  excavator  int  not null default 0 check (excavator between 0 and 99),
  created_at timestamptz not null default now()
);
comment on table public.za_scores is 'ZA DEMOLITION: punteggi. Accesso solo dalle funzioni za_*';
create index if not exists za_scores_board  on public.za_scores (mode, floors desc, time_ms asc);
create index if not exists za_scores_player on public.za_scores (player_id, mode);
create index if not exists za_scores_date   on public.za_scores (created_at);

alter table public.za_players enable row level security;
alter table public.za_scores  enable row level security;
revoke all on public.za_players, public.za_scores from anon, authenticated;

-- ---------- funzioni di servizio ----------
create or replace function public.za_clean_name(p text) returns text
language sql immutable set search_path = '' as $$
  select left(btrim(regexp_replace(regexp_replace(coalesce(p, ''), '[^[:alnum:] ._''-]', '', 'g'), '\s+', ' ', 'g')), 14)
$$;

create or replace function public.za_player(p_id text) returns public.za_players
language plpgsql stable security definer set search_path = '' as $$
declare r public.za_players;
begin
  if p_id is null or length(p_id) < 32 then raise exception 'giocatore sconosciuto' using errcode = 'P0002'; end if;
  select * into r from public.za_players where token = p_id;
  if not found then raise exception 'giocatore sconosciuto' using errcode = 'P0002'; end if;
  return r;
end $$;

create or replace function public.za_new_code() returns text
language plpgsql volatile set search_path = '' as $$
declare chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; b bytea := extensions.gen_random_bytes(6); c text := ''; i int;
begin
  for i in 0..5 loop c := c || substr(chars, (get_byte(b, i) % 32) + 1, 1); end loop;
  return c;
end $$;

-- ---------- funzioni chiamate dal gioco ----------
create or replace function public.za_new_player(p_name text default '', p_progress jsonb default '{}'::jsonb) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare tok text := encode(extensions.gen_random_bytes(32), 'hex'); c text; n text := public.za_clean_name(p_name); i int;
begin
  if p_progress is null or jsonb_typeof(p_progress) <> 'object' or length(p_progress::text) > 4000 then p_progress := '{}'::jsonb; end if;
  for i in 1..10 loop
    c := public.za_new_code();
    exit when not exists (select 1 from public.za_players where code = c);
  end loop;
  insert into public.za_players (token, code, name, progress) values (tok, c, n, p_progress);
  return jsonb_build_object('id', tok, 'code', c, 'name', n);
end $$;

create or replace function public.za_get_progress(p_id text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare p public.za_players := public.za_player(p_id);
begin
  return jsonb_build_object('name', p.name, 'code', p.code, 'progress', p.progress);
end $$;

create or replace function public.za_set_name(p_id text, p_name text) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare p public.za_players := public.za_player(p_id); n text := public.za_clean_name(p_name);
begin
  if char_length(n) < 2 then raise exception 'nome troppo corto' using errcode = '22023'; end if;
  update public.za_players set name = n, updated_at = now() where id = p.id;
  return jsonb_build_object('ok', true, 'name', n);
end $$;

-- i record (best, bestCombo, maxLevel e i record per città) non possono mai scendere
create or replace function public.za_save_progress(p_id text, p_progress jsonb) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare p public.za_players := public.za_player(p_id); o jsonb := p.progress; m jsonb; k text; rec jsonb := '{}'::jsonb;
  gi constant text := '^[0-9]{1,7}$';
begin
  if p_progress is null or jsonb_typeof(p_progress) <> 'object' or length(p_progress::text) > 4000 then
    raise exception 'progressi non validi' using errcode = '22023'; end if;
  m := o || p_progress;
  m := m || jsonb_build_object(
    'best',      greatest(coalesce((o->>'best')::numeric, 0),      coalesce((p_progress->>'best')::numeric, 0)),
    'bestCombo', greatest(coalesce((o->>'bestCombo')::numeric, 0), coalesce((p_progress->>'bestCombo')::numeric, 0)),
    'maxLevel',  greatest(coalesce((o->>'maxLevel')::numeric, 0),  coalesce((p_progress->>'maxLevel')::numeric, 0)));
  -- record per modalità: massimo tra vecchio e nuovo, chiave per chiave
  for k in select jsonb_object_keys(coalesce(o->'rec', '{}'::jsonb) || coalesce(p_progress->'rec', '{}'::jsonb)) loop
    rec := rec || jsonb_build_object(k, greatest(
      case when (o->'rec'->>k) ~ gi then (o->'rec'->>k)::int else 0 end,
      case when (p_progress->'rec'->>k) ~ gi then (p_progress->'rec'->>k)::int else 0 end));
  end loop;
  m := m || jsonb_build_object('rec', rec);
  update public.za_players set progress = m, updated_at = now() where id = p.id;
  return jsonb_build_object('ok', true, 'progress', m);
exception when invalid_text_representation or numeric_value_out_of_range then
  raise exception 'progressi non validi' using errcode = '22023';
end $$;

create or replace function public.za_restore(p_code text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare c text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g')); p public.za_players;
begin
  select * into p from public.za_players where code = c;
  if not found then raise exception 'codice non trovato' using errcode = 'P0002'; end if;
  return jsonb_build_object('id', p.token, 'code', p.code, 'name', p.name, 'progress', p.progress);
end $$;

create or replace function public.za_submit_score(p_id text, p_mode text, p_floors int, p_time_ms int,
  p_city int default 0, p_combo int default 0, p_operator int default 0, p_excavator int default 0) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare p public.za_players := public.za_player(p_id); md text := coalesce(p_mode, 'road'); better int; pb record;
begin
  if md !~ '^(road|s[0-9]{1,2})$' then md := 'road'; end if;
  if p_floors is null or p_floors < 1 then raise exception 'punteggio nullo' using errcode = '22023'; end if;
  if p_time_ms is null or p_time_ms < 0 or p_time_ms > 36000000 then raise exception 'tempo non valido' using errcode = '22023'; end if;
  if p_floors > greatest(30, p_time_ms / 1000.0 * 14) then raise exception 'punteggio non valido' using errcode = '22023'; end if;  -- max ~14 piani al secondo
  if exists (select 1 from public.za_scores where player_id = p.id and created_at > now() - interval '3 seconds') then
    raise exception 'troppo veloce, riprova' using errcode = '22023'; end if;
  insert into public.za_scores (player_id, mode, floors, time_ms, city, combo, operator, excavator)
  values (p.id, md, p_floors, p_time_ms,
          least(greatest(coalesce(p_city, 0), 0), 999), least(greatest(coalesce(p_combo, 0), 0), 100000),
          least(greatest(coalesce(p_operator, 0), 0), 99), least(greatest(coalesce(p_excavator, 0), 0), 99));
  -- miglior risultato del giocatore in questa classifica
  select floors, time_ms into pb from public.za_scores where player_id = p.id and mode = md order by floors desc, time_ms asc limit 1;
  -- quanti altri giocatori hanno un miglior risultato migliore (a parità di piani vince il tempo più basso)
  select count(*) into better from (
    select distinct on (player_id) player_id, floors, time_ms from public.za_scores
    where mode = md and player_id <> p.id order by player_id, floors desc, time_ms asc) b
  where b.floors > pb.floors or (b.floors = pb.floors and b.time_ms < pb.time_ms);
  return jsonb_build_object('ok', true, 'rank', better + 1, 'personalBest', jsonb_build_object('floors', pb.floors, 'time_ms', pb.time_ms));
end $$;

create or replace function public.za_leaderboard(p_mode text default 'road', p_period text default 'all', p_limit int default 50, p_id text default null) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare md text := coalesce(p_mode, 'road'); per text := case when p_period = 'week' then 'week' else 'all' end;
  lim int := least(greatest(coalesce(p_limit, 50), 1), 100); since timestamptz; rows jsonb;
begin
  if md !~ '^(road|s[0-9]{1,2})$' then md := 'road'; end if;
  since := case when per = 'week' then now() - interval '7 days' else '-infinity'::timestamptz end;
  select coalesce(jsonb_agg(jsonb_build_object(
      'pos', b.pos, 'me', (p_id is not null and b.token = p_id), 'name', b.name, 'operator', b.operator, 'excavator', b.excavator,
      'floors', b.floors, 'time_ms', b.time_ms, 'city', b.city, 'combo', b.combo,
      'date', (extract(epoch from b.created_at) * 1000)::bigint) order by b.pos), '[]'::jsonb)
    into rows
  from (
    select row_number() over (order by s.floors desc, s.time_ms asc) as pos, s.*, pl.name, pl.token
    from (select distinct on (player_id) * from public.za_scores
          where mode = md and created_at >= since order by player_id, floors desc, time_ms asc) s
    join public.za_players pl on pl.id = s.player_id
    order by s.floors desc, s.time_ms asc limit lim) b;
  return jsonb_build_object('period', per, 'mode', md, 'rows', rows);
end $$;

-- permessi: il gioco (ruolo anon) può solo chiamare queste funzioni
revoke execute on function public.za_clean_name(text), public.za_player(text), public.za_new_code() from public, anon, authenticated;
revoke execute on function public.za_new_player(text, jsonb), public.za_get_progress(text), public.za_set_name(text, text),
  public.za_save_progress(text, jsonb), public.za_restore(text), public.za_submit_score(text, text, int, int, int, int, int, int),
  public.za_leaderboard(text, text, int, text) from public;
grant execute on function public.za_new_player(text, jsonb), public.za_get_progress(text), public.za_set_name(text, text),
  public.za_save_progress(text, jsonb), public.za_restore(text), public.za_submit_score(text, text, int, int, int, int, int, int),
  public.za_leaderboard(text, text, int, text) to anon, authenticated;
