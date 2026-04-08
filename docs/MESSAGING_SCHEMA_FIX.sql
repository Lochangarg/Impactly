-- 8. Messages Table (Direct Messaging)
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  receiver_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for messages
alter table public.messages enable row level security;

-- Policies for Messages
-- Users can see messages where they are either the sender or the receiver
create policy "Users can view their own messages." on public.messages
  for select using (auth.uid() = sender_id or auth.uid() = receiver_id);

-- Users can insert messages where they are the sender
create policy "Users can send messages." on public.messages
  for insert with check (auth.uid() = sender_id);

-- Enable Realtime for Messages
alter publication supabase_realtime add table public.messages;
