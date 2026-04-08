# 🚀 Supabase Migration Plan — Impactly

This document outlines the steps required to transition the **Impactly** backend from **Parse Server** (Back4App) to **Supabase**.

## 1. 🏗️ Database Setup (Supabase SQL)

Run the following SQL in your Supabase SQL Editor to create the necessary tables and relationships.

```sql
-- 1. Profiles Table (Extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  username text unique,
  phone text,
  city text,
  profile_picture text, -- URL to Supabase Storage
  interests text[],
  points integer default 0,
  level integer default 1,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Events Table
create table public.events (
  id uuid default gen_random_uuid() primary key,
  created_by uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  description text,
  category text,
  location text,
  date timestamp with time zone,
  points integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. User Events (Many-to-Many Join)
create table public.user_events (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  event_id uuid references public.events(id) on delete cascade not null,
  joined_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, event_id)
);

-- 4. Posts Table
create table public.posts (
  id uuid default gen_random_uuid() primary key,
  content text not null,
  image_url text, -- URL to Supabase Storage
  created_by uuid references public.profiles(id) on delete cascade not null,
  event_id uuid references public.events(id) on delete set null,
  likes uuid[] default '{}', -- Array of user IDs who liked
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Comments Table
create table public.comments (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  text text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Notifications Table
create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  receiver_id uuid references public.profiles(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) on delete set null,
  event_id uuid references public.events(id) on delete set null,
  type text not null, -- 'friend_request', 'event_reminder', etc.
  message text,
  status text default 'pending', -- 'pending', 'read', 'accepted', 'declined'
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. Friends Table (Relations)
create table public.friends (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  friend_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, friend_id)
);

-- 8. Messages Table (Direct Messaging)
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  receiver_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Set up Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.user_events enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.notifications enable row level security;
alter table public.friends enable row level security;
alter table public.messages enable row level security;

-- Policies (Public read for events/posts/profiles)
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
create policy "Users can insert their own profile." on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);

create policy "Events are viewable by everyone." on public.events for select using (true);
create policy "Users can create events." on public.events for insert with check (auth.uid() = created_by);

create policy "Posts are viewable by everyone." on public.posts for select using (true);
create policy "Users can create posts." on public.posts for insert with check (auth.uid() = created_by);

-- 4. Messaging Policies
create policy "Users can view their own messages." on public.messages for select using (auth.uid() = sender_id or auth.uid() = receiver_id);
create policy "Users can send messages." on public.messages for insert with check (auth.uid() = sender_id);

-- Enable Realtime
alter publication supabase_realtime add table public.messages;

-- Function to handle new user signup
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, username)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'username');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

## 2. 📁 Storage Buckets

In your Supabase Dashboard → **Storage**, create two public buckets:
1.  `profile_pictures`
2.  `post_images`

## 3. 🛠️ Code Changes

> [!NOTE]
> I have already started the migration with **Phase 1** (Environment & Initialization) and **Phase 2** (SupabaseService creation).

### Phase 1: Environment & Initialization (DONE ✅)
- [x] Updated `pubspec.yaml` (Added `supabase_flutter`, removed `parse_server_sdk_flutter`).
- [x] Updated `.env` with Supabase placeholders.
- [x] Refactored `lib/core/config/env.dart` for Supabase keys.
- [x] Rewrote `main.dart` entry point for Supabase initialization.

### Phase 2: Core Service Layer (DONE ✅)
- [x] Created `SupabaseService` in `lib/core/services/supabase_service.dart`.
- [ ] Implement `EventModel`, `PostModel`, and `UserModel` with `fromMap` factories to decouple UI from Supabase Maps.

### Phase 3: Auth Refactoring
- [ ] Update `LoginScreen` and `SignupScreen` to use `SupabaseService.signIn` and `signUp`.
- [ ] Update `Logout` logic in `SettingsScreen`.

### Phase 4: Feature Refactoring
- [ ] **Home & Events**: Update `EventProvider` to fetch from Supabase.
- [ ] **Feed**: Update `FeedScreen` and `PostDetailScreen`.
- [ ] **Profile**: Handle profile updates and image uploads to Supabase Storage.
- [ ] **Social**: Update Friend relations and Search querying.

---

### Questions for User:
1. Do you have a Supabase project ready, or should I help you set one up?
2. Shall I proceed with refactoring the **Authentication** layer first, or the **Home/Events** feed?
