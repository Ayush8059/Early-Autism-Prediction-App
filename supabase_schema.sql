create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  phone_number text not null default '',
  feedback text not null default '',
  avatar_url text not null default '',
  notification_enabled boolean not null default false,
  reminder_hour int not null default 9 check (reminder_hour between 0 and 23),
  reminder_minute int not null default 0 check (reminder_minute between 0 and 59),
  reminder_days int[] not null default array[1,2,3,4,5,6,7],
  language text not null default 'English',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Parent')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  date_of_birth date,
  gender text,
  created_at timestamptz not null default now()
);

alter table public.profiles
  alter column notification_enabled set default false;

alter table public.profiles
  add column if not exists phone_number text not null default '';

alter table public.profiles
  add column if not exists feedback text not null default '';

alter table public.profiles
  add column if not exists avatar_url text not null default '';

alter table public.profiles
  add column if not exists language text not null default 'English';

alter table public.profiles
  alter column language set default 'English';

update public.profiles
set language = 'English'
where language = 'en';

alter table public.profiles
  add column if not exists reminder_hour int not null default 9 check (reminder_hour between 0 and 23);

alter table public.profiles
  add column if not exists reminder_minute int not null default 0 check (reminder_minute between 0 and 59);

alter table public.profiles
  add column if not exists reminder_days int[] not null default array[1,2,3,4,5,6,7];

create table if not exists public.questionnaire_assessments (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  score int not null check (score between 0 and 12),
  risk_level text not null check (risk_level in ('Low', 'Medium', 'High')),
  answers jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.photo_assessments (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  image_path text not null,
  status text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed')),
  confidence_score numeric(5,2),
  autistic_percent numeric(5,2),
  non_autistic_percent numeric(5,2),
  risk_level text check (risk_level in ('Low', 'Medium', 'High')),
  message text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.photo_assessments
  add column if not exists autistic_percent numeric(5,2);

alter table public.photo_assessments
  add column if not exists non_autistic_percent numeric(5,2);

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  category text not null,
  recommended_risk_level text check (recommended_risk_level in ('Low', 'Medium', 'High')),
  created_at timestamptz not null default now()
);

create table if not exists public.activity_completions (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  activity_id uuid not null references public.activities(id) on delete cascade,
  completed_at timestamptz not null default now()
);

create index if not exists children_parent_id_idx on public.children(parent_id);
create index if not exists questionnaire_parent_child_idx on public.questionnaire_assessments(parent_id, child_id, created_at desc);
create index if not exists photo_parent_child_idx on public.photo_assessments(parent_id, child_id, created_at desc);
create index if not exists completions_parent_child_idx on public.activity_completions(parent_id, child_id, completed_at desc);
create unique index if not exists activities_title_key on public.activities(title);

insert into public.activities (title, description, category, recommended_risk_level)
values
  ('Color Sorting', 'Sort blocks by color and shape to build focus.', 'Focus', 'Low'),
  ('Follow the Sound', 'Listen, locate, and point toward sounds.', 'Attention', 'Medium'),
  ('Emotion Cards', 'Match faces with happy, sad, calm, or angry.', 'Social', 'Medium'),
  ('Texture Touch', 'Explore soft, rough, smooth, and fuzzy textures.', 'Sensory', 'High')
on conflict (title) do update
set description = excluded.description,
    category = excluded.category,
    recommended_risk_level = excluded.recommended_risk_level;

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  message text not null,
  created_at timestamptz not null default now()
);

create index if not exists chat_messages_parent_created_idx on public.chat_messages(parent_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.children enable row level security;
alter table public.questionnaire_assessments enable row level security;
alter table public.photo_assessments enable row level security;
alter table public.activities enable row level security;
alter table public.activity_completions enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Parents can manage own children" on public.children;
drop policy if exists "Parents can manage own questionnaire assessments" on public.questionnaire_assessments;
drop policy if exists "Parents can manage own photo assessments" on public.photo_assessments;
drop policy if exists "Authenticated users can read activities" on public.activities;
drop policy if exists "Parents can manage own activity completions" on public.activity_completions;
drop policy if exists "Parents can manage own chat messages" on public.chat_messages;

create policy "Users can read own profile" on public.profiles
  for select using (id = auth.uid());

create policy "Users can insert own profile" on public.profiles
  for insert with check (id = auth.uid());

create policy "Users can update own profile" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

create policy "Parents can manage own children" on public.children
  for all using (parent_id = auth.uid()) with check (parent_id = auth.uid());

create policy "Parents can manage own questionnaire assessments" on public.questionnaire_assessments
  for all using (parent_id = auth.uid()) with check (parent_id = auth.uid());

create policy "Parents can manage own photo assessments" on public.photo_assessments
  for all using (parent_id = auth.uid()) with check (parent_id = auth.uid());

create policy "Authenticated users can read activities" on public.activities
  for select using (auth.role() = 'authenticated');

create policy "Parents can manage own activity completions" on public.activity_completions
  for all using (parent_id = auth.uid()) with check (parent_id = auth.uid());

create policy "Parents can manage own chat messages" on public.chat_messages
  for all using (parent_id = auth.uid()) with check (parent_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('child-photos', 'child-photos', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('parent-avatars', 'parent-avatars', false)
on conflict (id) do nothing;

drop policy if exists "Users can upload own child photos" on storage.objects;
drop policy if exists "Users can read own child photos" on storage.objects;
drop policy if exists "Users can update own child photos" on storage.objects;
drop policy if exists "Users can delete own child photos" on storage.objects;
drop policy if exists "Users can upload own parent avatar" on storage.objects;
drop policy if exists "Users can read own parent avatar" on storage.objects;
drop policy if exists "Users can update own parent avatar" on storage.objects;
drop policy if exists "Users can delete own parent avatar" on storage.objects;

create policy "Users can upload own child photos" on storage.objects
  for insert with check (
    bucket_id = 'child-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can read own child photos" on storage.objects
  for select using (
    bucket_id = 'child-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update own child photos" on storage.objects
  for update using (
    bucket_id = 'child-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  ) with check (
    bucket_id = 'child-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete own child photos" on storage.objects
  for delete using (
    bucket_id = 'child-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can upload own parent avatar" on storage.objects
  for insert with check (
    bucket_id = 'parent-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can read own parent avatar" on storage.objects
  for select using (
    bucket_id = 'parent-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update own parent avatar" on storage.objects
  for update using (
    bucket_id = 'parent-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  ) with check (
    bucket_id = 'parent-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete own parent avatar" on storage.objects
  for delete using (
    bucket_id = 'parent-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create or replace function public.get_daily_streak()
returns int
language sql
stable
security invoker
set search_path = public
as $$
  with activity_days as (
    select completed_at::date as day
    from public.activity_completions
    where parent_id = auth.uid()
  ),
  distinct_days as (
    select distinct day
    from activity_days
    where day <= current_date
  ),
  numbered_days as (
    select
      day,
      row_number() over (order by day desc) as row_number
    from distinct_days
  ),
  streak_group as (
    select day
    from numbered_days
    where day = current_date - (row_number - 1)::int
  )
  select count(*)::int from streak_group;
$$;

insert into public.activities (title, description, category, recommended_risk_level)
values
  ('Color Sorting', 'Sort blocks by color to improve focus.', 'focus', 'Low'),
  ('Follow the Sound', 'Listen and point to the direction of sounds.', 'sensory', 'Medium'),
  ('Emotion Cards', 'Identify happy, sad, or angry faces.', 'communication', 'Medium'),
  ('Texture Touch', 'Feel different materials in a sensory bin.', 'sensory', 'High')
on conflict (title) do nothing;
