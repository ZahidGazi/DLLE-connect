# Supabase Database — DLLE Connect

This directory contains all SQL files needed to set up the DLLE Connect database on Supabase.

## Files

| File | Purpose |
|------|---------|
| `schema.sql` | **Complete database schema** — tables, indexes, triggers, storage policies, realtime setup |
| `seed.sql` | **Sample data** — courses, demo events, demo announcements |
| `migrations.sql` | Legacy incremental migrations (for reference only) |
| `migrations/` | Timestamped migration files (for Supabase CLI usage) |

## Quick Setup (SQL Editor)

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to **SQL Editor**
3. Copy and paste the contents of **`schema.sql`** → Click **Run**
4. *(Optional)* Copy and paste the contents of **`seed.sql`** → Click **Run**

> For the full step-by-step guide including storage bucket setup and admin account creation, see **[SETUP.md](../SETUP.md)** in the project root.

## Database Tables

| Table | Description |
|-------|-------------|
| `users` | Student and admin profiles (linked to Supabase Auth) |
| `courses` | Available courses/departments with max academic year |
| `events` | DLLE events created by coordinators |
| `event_registrations` | Tracks student join/completion status for events |
| `announcements` | Admin announcements with optional image |

## Schema Overview

### `users`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Links to `auth.users.id` |
| `identifier` | TEXT (UNIQUE) | Student ID (e.g., "12345") |
| `full_name` | TEXT | Student/admin full name |
| `email` | TEXT (UNIQUE) | Email address |
| `department` | TEXT | Course/department name |
| `role` | TEXT | `'student'` or `'admin'` |
| `year_of_study` | INTEGER | Current academic year (default: 1) |
| `created_at` | TIMESTAMPTZ | Auto-set on creation |

### `courses`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Auto-generated |
| `name` | TEXT (UNIQUE) | Course name (e.g., "B.Sc. Computer Science") |
| `max_year` | INTEGER | Maximum academic year for this course |
| `created_at` | TIMESTAMPTZ | Auto-set on creation |

### `events`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Auto-generated |
| `title` | TEXT | Event title |
| `date_str` | TEXT | Display date string |
| `event_date` | TIMESTAMPTZ | Actual event date (used for sorting) |
| `location` | TEXT | Event location |
| `hours` | INTEGER | DLLE volunteer hours awarded |
| `description` | TEXT | Event description |
| `start_time` | TEXT | Start time string |
| `end_time` | TEXT | End time string |
| `image_path` | TEXT | Optional event image URL |
| `latitude` | DOUBLE PRECISION | GPS latitude (default: 0.0) |
| `longitude` | DOUBLE PRECISION | GPS longitude (default: 0.0) |
| `target_course` | TEXT | JSON array of targeted courses, or NULL for all |
| `target_year` | INTEGER | Targeted year, or NULL for all years |
| `event_expiry_date` | TIMESTAMPTZ | Registration closes after this date |
| `created_at` | TIMESTAMPTZ | Auto-set on creation |

### `event_registrations`
| Column | Type | Description |
|--------|------|-------------|
| `student_id` | TEXT (PK) | References `users.identifier` |
| `event_id` | UUID (PK) | References `events.id` (CASCADE delete) |
| `status` | TEXT | `'joined'` or `'completed'` |
| `completed_at` | TIMESTAMPTZ | When the student completed the event |
| `created_at` | TIMESTAMPTZ | Auto-set on creation |

### `announcements`
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Auto-generated |
| `title` | TEXT | Announcement title |
| `message` | TEXT | Announcement body |
| `date_str` | TEXT | Display date string |
| `image_url` | TEXT | Optional image URL (Supabase Storage) |
| `created_at` | TIMESTAMPTZ | Auto-set on creation |

## Auth Trigger

A database trigger (`on_auth_user_created`) automatically creates a row in `public.users` whenever a new user signs up through Supabase Auth. It reads the metadata passed during signup:

- `identifier` → Student ID
- `full_name` → Full name
- `email` → Email address
- `department` → Course/department
- `year_of_study` → Academic year

## Realtime

The schema enables Supabase Realtime on the `announcements` and `events` tables. The app subscribes to `INSERT` events to push live notifications to students when:

- A new announcement is posted
- A new event is created (filtered by course/year eligibility)

## Storage

The app uses a Supabase Storage bucket named **`dlle-connect`** with two folders:

| Folder | Purpose |
|--------|---------|
| `announcements/` | Announcement images |
| `events/` | Event images |

Storage policies in `schema.sql` allow both `anon` and `authenticated` roles to upload, read, update, and delete files in this bucket.

## Row Level Security (RLS)

RLS is **disabled by default** for simplicity. If you want to enable it, uncomment the RLS policy blocks in `schema.sql` and adjust them to your security requirements.

## Supabase CLI (Optional)

If you prefer using the Supabase CLI for migrations:

```bash
# Install (npm)
npm install -g supabase

# Initialize
supabase init

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Push migrations
supabase db push

# Pull current remote schema
supabase db pull
