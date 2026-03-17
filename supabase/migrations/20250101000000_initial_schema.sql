-- ============================================================
-- Migration: Initial Schema
-- Created: 2025-01-01
-- Description: Creates all tables for DLLE Connect app
-- ============================================================

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE,
    department TEXT,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin')),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_identifier ON public.users (identifier);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users (email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users (role);

-- 2. EVENTS TABLE
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    date_str TEXT,
    event_date TIMESTAMPTZ NOT NULL,
    location TEXT,
    hours INTEGER DEFAULT 0,
    description TEXT,
    start_time TEXT,
    end_time TEXT,
    image_path TEXT,
    latitude DOUBLE PRECISION DEFAULT 0.0,
    longitude DOUBLE PRECISION DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_events_event_date ON public.events (event_date);

-- 3. EVENT REGISTRATIONS TABLE
CREATE TABLE IF NOT EXISTS public.event_registrations (
    student_id TEXT NOT NULL,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'joined' CHECK (status IN ('joined', 'completed')),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (student_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_event_registrations_student ON public.event_registrations (student_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_event ON public.event_registrations (event_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_status ON public.event_registrations (status);

-- 4. ANNOUNCEMENTS TABLE
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    date_str TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON public.announcements (created_at);

-- 5. TRIGGER: Auto-create user record on Supabase Auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, identifier, full_name, email, department, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'identifier', ''),
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'email', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'department', ''),
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
