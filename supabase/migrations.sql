-- ============================================================
-- DLLE Connect - Database Migrations
-- Run these in your Supabase SQL Editor (in order)
-- ============================================================

-- 1. Create the courses table
--    Stores available courses and their max academic year.
CREATE TABLE IF NOT EXISTS courses (
  id        uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name      text NOT NULL UNIQUE,
  max_year  int  NOT NULL DEFAULT 4,
  created_at timestamptz DEFAULT now()
);

-- 2. Add image_url column to announcements
--    Allows announcements to include an optional photo.
ALTER TABLE announcements
  ADD COLUMN IF NOT EXISTS image_url text;

-- 3. Add year_of_study column to users
--    Stores the student's current year (1, 2, 3, ...).
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS year_of_study int DEFAULT 1;

-- 4. Add targeting columns to events
--    target_course: NULL = visible to all courses
--    target_year:   NULL = visible to all years within target_course
ALTER TABLE events
  ADD COLUMN IF NOT EXISTS target_course text;

ALTER TABLE events
  ADD COLUMN IF NOT EXISTS target_year int;

-- 5. Add location coordinates to events
--    latitude / longitude: stored as double precision (float8)
--    Used for event attendance verification and map display.
--    Default 0.0 for existing rows.
ALTER TABLE events
  ADD COLUMN IF NOT EXISTS latitude  double precision NOT NULL DEFAULT 0.0;

ALTER TABLE events
  ADD COLUMN IF NOT EXISTS longitude double precision NOT NULL DEFAULT 0.0;

-- ============================================================
-- Optional: Seed some default courses
-- ============================================================
-- INSERT INTO courses (name, max_year) VALUES
--   ('B.Sc. Computer Science', 3),
--   ('B.Sc. Information Technology', 3),
--   ('B.Com', 3),
--   ('B.A.', 3),
--   ('B.Sc. Physics', 3),
--   ('B.Sc. Chemistry', 3),
--   ('B.Sc. Mathematics', 3),
--   ('B.Sc. Biotechnology', 3),
--   ('B.E. / B.Tech', 4),
--   ('M.Sc.', 2),
--   ('M.Com', 2),
--   ('M.A.', 2)
-- ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- RLS Policies (if Row Level Security is enabled)
-- ============================================================

-- Allow all authenticated users to read courses
-- CREATE POLICY "Allow read courses" ON courses
--   FOR SELECT USING (auth.role() = 'authenticated');

-- Allow service role to insert/update/delete courses
-- (Admin operations go through the service role or anon key with RLS disabled)

-- ============================================================
-- Supabase Storage Policies for 'dlle-connect' bucket
-- Run these to fix the 403 Unauthorized upload error
--
-- NOTE: The admin in this app uses a local password check and does NOT
-- sign in via Supabase Auth, so they operate as the 'anon' role.
-- All storage policies must allow 'anon' for admin operations.
-- ============================================================

-- Drop existing policies first (safe to run even if they don't exist)
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow anon deletes" ON storage.objects;

-- 1. Allow anyone (anon + authenticated) to upload files
CREATE POLICY "Allow all uploads"
  ON storage.objects
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (bucket_id = 'dlle-connect');

-- 2. Allow anyone to read/view files (needed to display images in the app)
CREATE POLICY "Allow public read"
  ON storage.objects
  FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'dlle-connect');

-- 3. Allow anyone to update/overwrite files
CREATE POLICY "Allow all updates"
  ON storage.objects
  FOR UPDATE
  TO anon, authenticated
  USING (bucket_id = 'dlle-connect');

-- 4. Allow anyone to delete files
CREATE POLICY "Allow all deletes"
  ON storage.objects
  FOR DELETE
  TO anon, authenticated
  USING (bucket_id = 'dlle-connect');
