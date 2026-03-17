-- ============================================================
-- DLLE Connect — Complete Supabase Database Schema
-- ============================================================
-- Run this entire file in the Supabase SQL Editor to create
-- all required tables, indexes, triggers, and policies.
--
-- Tables created:
--   1. users
--   2. events
--   3. event_registrations
--   4. announcements
--   5. courses
--
-- Also sets up:
--   - Auth trigger (auto-create user on signup)
--   - Supabase Storage policies for 'dlle-connect' bucket
--   - Realtime publication for announcements & events
-- ============================================================


-- ============================================================
-- 1. USERS TABLE
-- ============================================================
-- Stores student and admin user profiles.
-- 'id' links to Supabase Auth (auth.users.id).
-- 'identifier' is the student ID (e.g., "12345").
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier    TEXT          UNIQUE NOT NULL,
    full_name     TEXT          NOT NULL,
    email         TEXT          UNIQUE,
    department    TEXT,
    role          TEXT          NOT NULL DEFAULT 'student'
                                CHECK (role IN ('student', 'admin')),
    year_of_study INTEGER       DEFAULT 1,
    created_at    TIMESTAMPTZ   DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_identifier ON public.users (identifier);
CREATE INDEX IF NOT EXISTS idx_users_email      ON public.users (email);
CREATE INDEX IF NOT EXISTS idx_users_role       ON public.users (role);


-- ============================================================
-- 2. COURSES TABLE
-- ============================================================
-- Stores available courses/departments and their maximum
-- academic year. Used in the signup screen dropdown and
-- event targeting.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.courses (
    id         UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT    NOT NULL UNIQUE,
    max_year   INTEGER NOT NULL DEFAULT 4,
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ============================================================
-- 3. EVENTS TABLE
-- ============================================================
-- Stores all DLLE events created by admins/coordinators.
--
-- target_course : JSON array string (e.g. '["BCOM","BSc.IT"]')
--                 NULL = visible to all courses.
-- target_year   : NULL = visible to all years within target courses.
-- event_expiry_date : After this date students can no longer join.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.events (
    id                UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    title             TEXT              NOT NULL,
    date_str          TEXT,
    event_date        TIMESTAMPTZ       NOT NULL,
    location          TEXT,
    hours             INTEGER           DEFAULT 0,
    description       TEXT,
    start_time        TEXT,
    end_time          TEXT,
    image_path        TEXT,
    latitude          DOUBLE PRECISION  DEFAULT 0.0,
    longitude         DOUBLE PRECISION  DEFAULT 0.0,
    target_course     TEXT,
    target_year       INTEGER,
    event_expiry_date TIMESTAMPTZ,
    created_at        TIMESTAMPTZ       DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_events_event_date ON public.events (event_date);


-- ============================================================
-- 4. EVENT REGISTRATIONS TABLE
-- ============================================================
-- Tracks which students have joined / completed which events.
-- Composite primary key: (student_id, event_id).
-- 'student_id' references users.identifier (NOT users.id).
-- ============================================================
CREATE TABLE IF NOT EXISTS public.event_registrations (
    student_id   TEXT         NOT NULL,
    event_id     UUID         NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    status       TEXT         NOT NULL DEFAULT 'joined'
                              CHECK (status IN ('joined', 'completed')),
    completed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ  DEFAULT now(),
    PRIMARY KEY (student_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_event_registrations_student ON public.event_registrations (student_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_event   ON public.event_registrations (event_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_status  ON public.event_registrations (status);


-- ============================================================
-- 5. ANNOUNCEMENTS TABLE
-- ============================================================
-- Stores announcements created by admins.
-- image_url: optional image attachment (stored in Supabase Storage).
-- ============================================================
CREATE TABLE IF NOT EXISTS public.announcements (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    title      TEXT        NOT NULL,
    message    TEXT        NOT NULL,
    date_str   TEXT,
    image_url  TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON public.announcements (created_at);


-- ============================================================
-- 6. AUTH TRIGGER — Auto-create user on Supabase Auth signup
-- ============================================================
-- When a new user signs up via Supabase Auth the metadata
-- provided during signup is used to insert a row into
-- public.users automatically.
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (
        id, identifier, full_name, email, department, year_of_study, role
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'identifier', ''),
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'email', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'department', ''),
        COALESCE((NEW.raw_user_meta_data->>'year_of_study')::int, 1),
        'student'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ============================================================
-- RLS is DISABLED by default for simplicity.
-- Uncomment the blocks below if you want to enable it.
-- ============================================================

-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

-- -- Users
-- CREATE POLICY "Users can view all users"
--   ON public.users FOR SELECT USING (true);
-- CREATE POLICY "Users can insert own record"
--   ON public.users FOR INSERT WITH CHECK (true);
-- CREATE POLICY "Users can update own record"
--   ON public.users FOR UPDATE USING (auth.uid() = id);

-- -- Events
-- CREATE POLICY "Anyone can view events"
--   ON public.events FOR SELECT USING (true);
-- CREATE POLICY "Admins can manage events"
--   ON public.events FOR ALL USING (true);

-- -- Event Registrations
-- CREATE POLICY "Anyone can view registrations"
--   ON public.event_registrations FOR SELECT USING (true);
-- CREATE POLICY "Students can manage own registrations"
--   ON public.event_registrations FOR ALL USING (true);

-- -- Announcements
-- CREATE POLICY "Anyone can view announcements"
--   ON public.announcements FOR SELECT USING (true);
-- CREATE POLICY "Admins can manage announcements"
--   ON public.announcements FOR ALL USING (true);

-- -- Courses
-- CREATE POLICY "Anyone can view courses"
--   ON public.courses FOR SELECT USING (true);
-- CREATE POLICY "Admins can manage courses"
--   ON public.courses FOR ALL USING (true);


-- ============================================================
-- 8. SUPABASE STORAGE POLICIES — 'dlle-connect' bucket
-- ============================================================
-- The app stores announcement and event images in a public
-- Supabase Storage bucket called 'dlle-connect'.
--
-- IMPORTANT: You must first create the bucket manually in the
-- Supabase Dashboard → Storage → New Bucket:
--   Name: dlle-connect
--   Public: ON
--
-- Then run the policies below.
-- ============================================================

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated uploads"  ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates"  ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes"  ON storage.objects;
DROP POLICY IF EXISTS "Allow public read"            ON storage.objects;
DROP POLICY IF EXISTS "Allow anon uploads"           ON storage.objects;
DROP POLICY IF EXISTS "Allow anon updates"           ON storage.objects;
DROP POLICY IF EXISTS "Allow anon deletes"           ON storage.objects;
DROP POLICY IF EXISTS "Allow all uploads"            ON storage.objects;
DROP POLICY IF EXISTS "Allow all updates"            ON storage.objects;
DROP POLICY IF EXISTS "Allow all deletes"            ON storage.objects;

-- Allow anyone (anon + authenticated) to upload files
CREATE POLICY "Allow all uploads"
  ON storage.objects FOR INSERT
  TO anon, authenticated
  WITH CHECK (bucket_id = 'dlle-connect');

-- Allow anyone to read/view files
CREATE POLICY "Allow public read"
  ON storage.objects FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'dlle-connect');

-- Allow anyone to update/overwrite files
CREATE POLICY "Allow all updates"
  ON storage.objects FOR UPDATE
  TO anon, authenticated
  USING (bucket_id = 'dlle-connect');

-- Allow anyone to delete files
CREATE POLICY "Allow all deletes"
  ON storage.objects FOR DELETE
  TO anon, authenticated
  USING (bucket_id = 'dlle-connect');


-- ============================================================
-- 9. REALTIME — Enable for announcements & events
-- ============================================================
-- The app subscribes to realtime INSERT events on these tables
-- to push live notifications to students.
-- ============================================================

-- Add tables to the supabase_realtime publication so that
-- Realtime broadcasts work. This is idempotent.
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;


-- ============================================================
-- ✅ Schema setup complete!
-- Next steps:
--   1. Create the 'dlle-connect' storage bucket (see SETUP.md)
--   2. Optionally run seed.sql to insert sample data
--   3. Create an admin account (see SETUP.md)
-- ============================================================
