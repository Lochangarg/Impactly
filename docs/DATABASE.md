# 🗄️ Database Documentation — Impactly

This document provides a detailed overview of the **Impactly** database architecture, schema, and security policies.

## 🚀 Overview

- **Database Engine**: [PostgreSQL](https://www.postgresql.org/)
- **Hosting Platform**: [Supabase](https://supabase.com/)
- **Infrastructure**: Managed cloud database with Auth, Storage, and Real-time capabilities.

---

## 🏗️ Schema Definitions

The database consists of the following tables, all residing in the `public` schema.

### 1. `profiles`
Stores extended user information, linked to Supabase Auth users.
- **`id`** (UUID, PK): References `auth.users(id)`.
- **`full_name`** (Text): The user's display name.
- **`username`** (Text, Unique): Unique handle for the user.
- **`phone`** (Text): Contact number.
- **`city`** (Text): User's location.
- **`profile_picture`** (Text): URL to the image stored in Supabase Storage.
- **`interests`** (Text[]): Array of interests selected during onboarding.
- **`points`** (Integer): Total Impact Points earned.
- **`level`** (Integer): Current user level based on points.
- **`created_at`** (Timestamp): Registration date.

### 2. `events`
Volunteer opportunities created by organizers.
- **`id`** (UUID, PK): Auto-generated unique ID.
- **`created_by`** (UUID, FK): References `profiles(id)`.
- **`title`** (Text): Name of the event.
- **`description`** (Text): Full event details.
- **`category`** (Text): e.g., 'Education', 'Environment'.
- **`location`** (Text): Physical or virtual location.
- **`date`** (Timestamp): When the event takes place.
- **`points`** (Integer): Points awarded for joining.

### 3. `user_events`
Join table representing the many-to-many relationship between users and events.
- **`user_id`** (UUID, FK): References `profiles(id)`.
- **`event_id`** (UUID, FK): References `events(id)`.
- **`joined_at`** (Timestamp): When the user joined.

### 4. `posts`
Community feed entries shared by users.
- **`id`** (UUID, PK): Auto-generated.
- **`content`** (Text): Text body of the post.
- **`image_url`** (Text): Optional photo attached to the post.
- **`created_by`** (UUID, FK): References `profiles(id)`.
- **`event_id`** (UUID, FK): Optional link to a specific event.
- **`likes`** (UUID[]): Array of profile IDs who liked the post.

### 5. `comments`
Interactions on community posts.
- **`post_id`** (UUID, FK): References `posts(id)`.
- **`user_id`** (UUID, FK): References `profiles(id)`.
- **`text`** (Text): Comment content.

### 6. `notifications`
System and social alerts for users.
- **`receiver_id`** (UUID, FK): Recipient.
- **`sender_id`** (UUID, FK): Originator (optional).
- **`type`** (Text): e.g., 'friend_request', 'event_reminder'.
- **`status`** (Text): 'pending', 'read', 'accepted', 'declined'.

### 7. `friends`
Social graph representing confirmed friendships.
- **`user_id`** (UUID, FK): User A.
- **`friend_id`** (UUID, FK): User B.

### 8. `messages`
Direct private messaging between users.
- **`sender_id`** (UUID, FK): Message sender.
- **`receiver_id`** (UUID, FK): Message recipient.
- **`content`** (Text): Encrypted/Plaintext message body.

---

## 🔒 Security & Policies (RLS)

All tables have **Row Level Security (RLS)** enabled to ensure data privacy.

| Table | Policy Name | Access Level |
| :--- | :--- | :--- |
| `profiles` | Public profiles are viewable by everyone | Read-only for all |
| `profiles` | Users can update own profile | Write for owner |
| `events` | Events are viewable by everyone | Read-only for all |
| `posts` | Posts are viewable by everyone | Read-only for all |
| `messages` | Users can view their own messages | Only participants |

---

## 📁 Storage Buckets

File assets are stored in the following Supabase Storage buckets:
1. `profile_pictures`: User avatars and covers.
2. `post_images`: Photos shared in the community feed.

---

## ⚙️ Triggers & Functions

- **`on_auth_user_created`**: A database trigger that automatically creates a record in the `profiles` table whenever a new user signs up through Supabase Auth.

---

## 🛠️ Connection Info

To connect the application to the database, ensure your `.env` file contains:
```env
SUPABASE_URL=https://your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```
