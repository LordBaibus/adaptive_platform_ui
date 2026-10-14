-- Run this once in the Supabase dashboard: SQL Editor -> New query -> Run.
-- Safe to run again: it also upgrades a table created by an earlier version.

create table if not exists public.tasks (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid()
                  references auth.users (id) on delete cascade,
  title           text not null check (char_length(btrim(title)) > 0),
  description     text not null default '',
  status          text not null default 'todo'
                  check (status in ('todo', 'in_process', 'completed')),
  progress        int  not null default 0 check (progress between 0 and 100),
  estimated_hours int  not null default 8 check (estimated_hours > 0),
  due_date        date not null default current_date,
  category        text not null default 'Personal',
  is_urgent       boolean not null default false,
  created_at      timestamptz not null default now()
);

alter table public.tasks add column if not exists status text not null default 'todo'
  check (status in ('todo', 'in_process', 'completed'));
alter table public.tasks add column if not exists progress int not null default 0
  check (progress between 0 and 100);
alter table public.tasks add column if not exists estimated_hours int not null default 8
  check (estimated_hours > 0);
alter table public.tasks add column if not exists due_date date not null default current_date;
alter table public.tasks add column if not exists category text not null default 'Personal';
alter table public.tasks alter column category set default 'Personal';
alter table public.tasks add column if not exists is_urgent boolean not null default false;

create index if not exists tasks_user_due_idx
  on public.tasks (user_id, due_date);

-- Row Level Security: every user can only see and change their own rows.
alter table public.tasks enable row level security;

drop policy if exists "tasks_select_own" on public.tasks;
create policy "tasks_select_own" on public.tasks
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "tasks_insert_own" on public.tasks;
create policy "tasks_insert_own" on public.tasks
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "tasks_update_own" on public.tasks;
create policy "tasks_update_own" on public.tasks
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "tasks_delete_own" on public.tasks;
create policy "tasks_delete_own" on public.tasks
  for delete to authenticated
  using ((select auth.uid()) = user_id);
