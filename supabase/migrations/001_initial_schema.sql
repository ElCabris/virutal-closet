-- ─── Extensions ───────────────────────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ─── Profiles ─────────────────────────────────────────────────────────────────
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  avatar_url  text,
  style_tags  text[],
  created_at  timestamptz default now() not null,
  updated_at  timestamptz default now() not null
);

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ─── Garments ─────────────────────────────────────────────────────────────────
create table if not exists garments (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  category    text not null,
  brand       text,
  color       text,
  season      text,
  occasion    text,
  price       numeric(10,2),
  image_url   text,
  notes       text,
  wear_count  int not null default 0,
  last_worn   timestamptz,
  created_at  timestamptz default now() not null,
  updated_at  timestamptz default now() not null
);

create index if not exists garments_user_id_idx on garments(user_id);
create index if not exists garments_category_idx on garments(user_id, category);

-- ─── Outfits ──────────────────────────────────────────────────────────────────
create table if not exists outfits (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  garment_ids uuid[] not null default '{}',
  occasion    text,
  season      text,
  image_url   text,
  notes       text,
  wear_count  int not null default 0,
  last_worn   timestamptz,
  created_at  timestamptz default now() not null,
  updated_at  timestamptz default now() not null
);

create index if not exists outfits_user_id_idx on outfits(user_id);

-- ─── Calendar Entries ─────────────────────────────────────────────────────────
create table if not exists calendar_entries (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  outfit_id   uuid not null references outfits(id) on delete cascade,
  date        date not null,
  notes       text,
  created_at  timestamptz default now() not null,
  unique(user_id, date)
);

create index if not exists calendar_entries_user_date_idx
  on calendar_entries(user_id, date);

-- ─── Storage Buckets ──────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values
  ('garments', 'garments', true),
  ('outfits',  'outfits',  true),
  ('avatars',  'avatars',  true)
on conflict (id) do nothing;

-- ─── Row-Level Security ───────────────────────────────────────────────────────
alter table profiles         enable row level security;
alter table garments         enable row level security;
alter table outfits          enable row level security;
alter table calendar_entries enable row level security;

-- Profiles
create policy "Users can view own profile"
  on profiles for select using (auth.uid() = id);
create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);

-- Garments
create policy "Users can manage own garments"
  on garments for all using (auth.uid() = user_id);

-- Outfits
create policy "Users can manage own outfits"
  on outfits for all using (auth.uid() = user_id);

-- Calendar entries
create policy "Users can manage own calendar"
  on calendar_entries for all using (auth.uid() = user_id);

-- Storage policies
create policy "Users can upload garment images"
  on storage.objects for insert
  with check (bucket_id = 'garments' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Garment images are public"
  on storage.objects for select
  using (bucket_id = 'garments');

create policy "Users can delete own garment images"
  on storage.objects for delete
  using (bucket_id = 'garments' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Avatar images are public"
  on storage.objects for select using (bucket_id = 'avatars');

create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
