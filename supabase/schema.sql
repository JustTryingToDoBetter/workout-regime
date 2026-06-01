-- Supabase schema for the private couple tracker.
-- Paste this into the SQL editor, then run it once.

create extension if not exists pgcrypto;

create table if not exists public.users (
  id text primary key check (id in ('his', 'her')),
  name text not null,
  role text not null unique check (role in ('his', 'her')),
  created_at timestamptz not null default now()
);

create table if not exists public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.users(id) on delete cascade,
  workout_name text not null,
  phase text,
  week_number integer not null default 1,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  notes text not null default ''
);

create table if not exists public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_name text not null,
  set_number integer not null,
  target_reps text,
  actual_reps text,
  weight text,
  rpe text,
  note text,
  completed boolean not null default false
);

create table if not exists public.measurements (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.users(id) on delete cascade,
  body_weight numeric,
  waist numeric,
  hips numeric,
  notes text,
  measured_at timestamptz not null default now()
);

create table if not exists public.progress_photos (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.users(id) on delete cascade,
  image_url text not null,
  caption text,
  uploaded_at timestamptz not null default now()
);

create table if not exists public.encouragement_messages (
  id uuid primary key default gen_random_uuid(),
  from_user_id text not null references public.users(id) on delete cascade,
  target_role text not null check (target_role in ('his', 'her', 'shared')),
  message text not null,
  created_at timestamptz not null default now()
);

create index if not exists workout_sessions_user_id_started_at_idx on public.workout_sessions (user_id, started_at desc);
create index if not exists workout_sessions_completed_at_idx on public.workout_sessions (completed_at desc);
create index if not exists workout_sets_session_id_idx on public.workout_sets (session_id);
create index if not exists measurements_user_id_measured_at_idx on public.measurements (user_id, measured_at desc);
create index if not exists progress_photos_user_id_uploaded_at_idx on public.progress_photos (user_id, uploaded_at desc);
create index if not exists encouragement_messages_created_at_idx on public.encouragement_messages (created_at desc);

insert into public.users (id, name, role)
values
  ('his', 'You', 'his'),
  ('her', 'Your girlfriend', 'her')
on conflict (id) do update
set name = excluded.name,
    role = excluded.role;

-- Optional helper view for quick dashboard queries in Supabase.
create or replace view public.shared_dashboard as
select
  u.id as user_id,
  u.name,
  u.role,
  coalesce(count(ws.id) filter (
    where ws.completed_at >= date_trunc('week', now())
  ), 0) as workouts_completed_this_week
from public.users u
left join public.workout_sessions ws on ws.user_id = u.id
group by u.id, u.name, u.role;
