-- ========================================================
-- HepsiRadyo - Supabase Full Database Schema & Migration
-- ========================================================

-- Enable extensions
create extension if not exists "uuid-ossp";

-- 1. Radios Table
create table if not exists radios (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  stream_url text not null,
  favicon_url text,
  tags text[] default '{}',
  country text default 'Turkey',
  city text,
  bitrate int default 128,
  codec text default 'MP3',
  is_active boolean default true,
  is_metadata_supported boolean default true,
  source text default 'radio-browser',
  radio_browser_uuid text unique,
  sort_order int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Categories Table
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text default 'radio',
  color text default '#0B3D2E',
  sort_order int default 0
);

-- 3. Radio - Category Junction
create table if not exists radio_categories (
  radio_id uuid references radios(id) on delete cascade,
  category_id uuid references categories(id) on delete cascade,
  primary key (radio_id, category_id)
);

-- 4. Devices (Anonymous & Auth mapped)
create table if not exists devices (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid references auth.users(id),
  created_at timestamptz default now()
);

-- 5. Favorites
create table if not exists favorites (
  device_id uuid references devices(id) on delete cascade,
  radio_id uuid references radios(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (device_id, radio_id)
);

-- 6. Radio Click Logs (Raw Analytics)
create table if not exists radio_clicks (
  id bigint generated always as identity primary key,
  radio_id uuid references radios(id) on delete cascade,
  device_id uuid references devices(id),
  clicked_at timestamptz default now()
);

-- 7. Aggregated Radio Stats (Top 50)
create table if not exists radio_stats (
  radio_id uuid references radios(id) on delete cascade,
  period text not null,       -- 'daily' | 'weekly' | 'all_time'
  click_count int default 0,
  rank int default 999,
  period_start date default current_date,
  updated_at timestamptz default now(),
  primary key (radio_id, period, period_start)
);

-- 8. Sponsored Banners (Admin Managed)
create table if not exists banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text not null,
  action_type text default 'radio', -- 'radio' | 'url' | 'category'
  target_value text,
  is_active boolean default true,
  sort_order int default 0,
  created_at timestamptz default now()
);

-- 9. Badges & Gamification
create table if not exists badges (
  id text primary key,
  title text not null,
  description text not null,
  icon text not null,
  required_metric text not null, -- 'listen_minutes', 'favorite_count', 'city_count'
  required_value int not null
);

create table if not exists user_badges (
  device_id uuid references devices(id) on delete cascade,
  badge_id text references badges(id) on delete cascade,
  unlocked_at timestamptz default now(),
  primary key (device_id, badge_id)
);

-- 10. Device Push Notification Tokens
create table if not exists device_push_tokens (
  device_id uuid references devices(id) on delete cascade primary key,
  push_token text not null,
  platform text not null,
  updated_at timestamptz default now()
);

-- ========================================================
-- RLS (Row Level Security) Policies
-- ========================================================

alter table radios enable row level security;
alter table categories enable row level security;
alter table radio_categories enable row level security;
alter table favorites enable row level security;
alter table radio_clicks enable row level security;
alter table radio_stats enable row level security;
alter table banners enable row level security;
alter table badges enable row level security;
alter table user_badges enable row level security;
alter table device_push_tokens enable row level security;

-- Public Read Policies
create policy "Public read radios" on radios for select using (true);
create policy "Public read categories" on categories for select using (true);
create policy "Public read radio_categories" on radio_categories for select using (true);
create policy "Public read radio_stats" on radio_stats for select using (true);
create policy "Public read active banners" on banners for select using (is_active = true);
create policy "Public read badges" on badges for select using (true);

-- Device Specific Policies
create policy "Device read own favorites" on favorites for select using (true);
create policy "Device insert own favorites" on favorites for insert with check (true);
create policy "Device delete own favorites" on favorites for delete using (true);

create policy "Device insert radio_clicks" on radio_clicks for insert with check (true);
create policy "Device read user_badges" on user_badges for select using (true);
create policy "Device insert user_badges" on user_badges for insert with check (true);
create policy "Device push tokens upsert" on device_push_tokens for all using (true);

-- Admin Full Access Policies (Service Role / Auth)
create policy "Admin full access radios" on radios for all using (true);
create policy "Admin full access banners" on banners for all using (true);
create policy "Admin full access categories" on categories for all using (true);

-- ========================================================
-- Helper Functions & Cron Job for Radio Stats Calculation
-- ========================================================

create or replace function refresh_radio_stats()
returns void language plpgsql as $$
begin
  -- 1. Daily Stats
  insert into radio_stats (radio_id, period, period_start, click_count, rank, updated_at)
  select 
    radio_id, 
    'daily' as period, 
    current_date as period_start,
    count(*) as click_count,
    row_number() over (order by count(*) desc) as rank,
    now()
  from radio_clicks
  where clicked_at >= current_date
  group by radio_id
  on conflict (radio_id, period, period_start) 
  do update set 
    click_count = excluded.click_count,
    rank = excluded.rank,
    updated_at = now();

  -- 2. Weekly Stats
  insert into radio_stats (radio_id, period, period_start, click_count, rank, updated_at)
  select 
    radio_id, 
    'weekly' as period, 
    date_trunc('week', current_date)::date as period_start,
    count(*) as click_count,
    row_number() over (order by count(*) desc) as rank,
    now()
  from radio_clicks
  where clicked_at >= date_trunc('week', current_date)
  group by radio_id
  on conflict (radio_id, period, period_start) 
  do update set 
    click_count = excluded.click_count,
    rank = excluded.rank,
    updated_at = now();

  -- 3. All-Time Stats
  insert into radio_stats (radio_id, period, period_start, click_count, rank, updated_at)
  select 
    radio_id, 
    'all_time' as period, 
    '2000-01-01'::date as period_start,
    count(*) as click_count,
    row_number() over (order by count(*) desc) as rank,
    now()
  from radio_clicks
  group by radio_id
  on conflict (radio_id, period, period_start) 
  do update set 
    click_count = excluded.click_count,
    rank = excluded.rank,
    updated_at = now();
end;
$$;

-- Seed Standard Categories
insert into categories (name, icon, color, sort_order) values
  ('Haber & Konuşma', 'newspaper', '#1E3A8A', 1),
  ('Pop Müzik', 'music_note', '#9333EA', 2),
  ('Arabesk & Fantazi', 'favorite', '#DC2626', 3),
  ('Halk Müziği & Türkü', 'landscape', '#D97706', 4),
  ('Nostalji & 90''lar', 'radio', '#059669', 5),
  ('Dini & İlahi', 'mosque', '#0D9488', 6),
  ('Spor', 'sports_soccer', '#2563EB', 7),
  ('Yabancı & Pop', 'public', '#7C3AED', 8),
  ('Caz & Klasik', 'piano', '#4B5563', 9),
  ('Yerel Radyolar', 'location_on', '#0B3D2E', 10)
on conflict (name) do nothing;

-- Seed Standard Badges
insert into badges (id, title, description, icon, required_metric, required_value) values
  ('first_listen', 'İlk Frekans', 'İlk radyo yayınını dinledin!', 'play_arrow', 'radio_count', 1),
  ('explorer_5', 'Radyo Kaşifi', '5 farklı radyo frekansı keşfettin.', 'explore', 'radio_count', 5),
  ('explorer_20', 'Frekans Avcısı', '20 farklı radyo dinledin.', 'auto_awesome', 'radio_count', 20),
  ('night_owl', 'Gece Kuşu', 'Gece 00:00 - 05:00 arasında radyo dinledin.', 'nights_stay', 'night_listen', 1),
  ('music_lover_1h', 'Müzik Sever', 'Toplam 1 saat radyo dinledin.', 'headset', 'listen_minutes', 60),
  ('music_lover_10h', 'Frekans Tutkunu', 'Toplam 10 saat radyo dinledin.', 'workspace_premium', 'listen_minutes', 600)
on conflict (id) do nothing;
