# Supabase RLS Fix for Social Networking

Hey! It's the exact same **Row Level Security (RLS)** issue blocking these actions. 
When the "Clear All" or "Accept" button is pressed, the code tries to `DELETE` notifications and `INSERT` rows into the `friends` table. Because you have RLS enabled on these tables but haven't provided rules for deletion or insertion, Supabase is silently blocking the operations.

Please go perfectly back to your **Supabase Dashboard -> SQL Editor** and run this snippet to grant the necessary permissions:

```sql
-- 1. Allow users to update & delete their own notifications (Accept/Delete/Clear All)
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = receiver_id);
CREATE POLICY "Users can delete own notifications" ON public.notifications FOR DELETE USING (auth.uid() = receiver_id);
CREATE POLICY "Users can insert notifications" ON public.notifications FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- 2. Allow users to insert requested friendships into the 'friends' table
CREATE POLICY "Users can insert friends" ON public.friends FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);

-- 3. Allow users to delete/unfriend
CREATE POLICY "Users can delete friends" ON public.friends FOR DELETE USING (auth.uid() = user_id OR auth.uid() = friend_id);
```

After running this, your backend will finally permit those commands!
P.S. I also quickly refined the duplicate-clearing logic in the app's code so that it beautifully groups all of those old "Read" notifications together into a single block instead of stacking them! You will notice a cleaner screen instantly!
