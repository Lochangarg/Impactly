# Supabase RLS Fix for Awards

Hey! It looks like Row Level Security (RLS) is blocking the Event Creator from doing these two things:
1. Modifying the `user_events` table (to change `award_pending` to `approved`)
2. Adding points to another user's `profiles` score.

Because RLS silently blocks these actions, the application thinks it succeeded, but the database refuses to save it. 

Please go to your **Supabase Dashboard -> SQL Editor** and paste & run the following code:

```sql
-- 1. Give Event Creators permission to update 'user_events' for their own events.
CREATE POLICY "Creators can update user_events"
ON public.user_events
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.events
    WHERE events.id = user_events.event_id AND events.created_by = auth.uid()
  )
);

-- 2. Allow point distributions to update profiles. 
-- (Drops the strict 'only update own profile' policy and allows community awards)
DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;

CREATE POLICY "Users can update profiles for points." 
ON public.profiles 
FOR UPDATE 
USING (true);
```

After running this, your "Approve" and "Decline" buttons will immediately start affecting the database properly. Let me know when you've run it!
