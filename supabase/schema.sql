-- Run this once in the Supabase dashboard: SQL Editor -> New query -> Run.
-- Safe to run again: it also upgrades a table created by an earlier version.

-- Philippine time (UTC+8, no daylight saving). This makes now(), current_date
-- and every timestamp shown in the dashboard match the app. Applies to new
-- connections (run `show timezone;` in a new SQL tab to confirm).
alter database postgres set timezone to 'Asia/Manila';

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
  due_date        date not null default ((now() at time zone 'Asia/Manila')::date),
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
alter table public.tasks add column if not exists due_date date not null default ((now() at time zone 'Asia/Manila')::date);
alter table public.tasks alter column due_date set default ((now() at time zone 'Asia/Manila')::date);
alter table public.tasks add column if not exists category text not null default 'Personal';
alter table public.tasks alter column category set default 'Personal';
alter table public.tasks add column if not exists is_urgent boolean not null default false;

create index if not exists tasks_user_due_idx
  on public.tasks (user_id, due_date);

-- A due date can never be set to a day before today (Philippine time).
-- Updates that leave the date unchanged (status, progress...) are allowed, so
-- old tasks stay editable.
create or replace function public.tasks_check_due_date()
returns trigger
language plpgsql
as $$
begin
  if (tg_op = 'INSERT' or new.due_date is distinct from old.due_date)
     and new.due_date < (now() at time zone 'Asia/Manila')::date then
    raise exception 'The due date cannot be in the past (Philippine time).';
  end if;
  return new;
end;
$$;

drop trigger if exists tasks_check_due_date on public.tasks;
create trigger tasks_check_due_date
  before insert or update on public.tasks
  for each row execute function public.tasks_check_due_date();

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
