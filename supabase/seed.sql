-- ============================================================
-- DLLE Connect — Sample Seed Data
-- ============================================================
-- Run this AFTER schema.sql to populate the database with
-- sample data for testing and demonstration purposes.
--
-- NOTE: This does NOT create Supabase Auth accounts.
--       You must create the admin account separately
--       (see SETUP.md for instructions).
-- ============================================================


-- ============================================================
-- 1. COURSES
-- ============================================================
INSERT INTO public.courses (name, max_year) VALUES
    ('B.Sc. Computer Science', 3),
    ('B.Sc. Information Technology', 3),
    ('B.Com', 3),
    ('B.A.', 3),
    ('B.Sc. Physics', 3),
    ('B.Sc. Chemistry', 3),
    ('B.Sc. Mathematics', 3),
    ('B.Sc. Biotechnology', 3),
    ('B.E. / B.Tech', 4),
    ('M.Sc.', 2),
    ('M.Com', 2),
    ('M.A.', 2)
ON CONFLICT (name) DO NOTHING;


-- ============================================================
-- 2. SAMPLE EVENTS
-- ============================================================
-- These are example events for demonstration.
-- Dates are set relative to 2025; adjust as needed.
-- ============================================================
INSERT INTO public.events (title, date_str, event_date, location, hours, description, start_time, end_time, latitude, longitude, target_course, target_year, event_expiry_date) VALUES
(
    'Community Clean-Up Drive',
    '15/3/2025',
    '2025-03-15T09:00:00+05:30',
    'RSET Campus, Mumbai, Maharashtra, India',
    5,
    'Join us for a community clean-up drive around the campus and nearby areas. Gloves and bags will be provided. Wear comfortable clothing and shoes.',
    '09:00 AM',
    '02:00 PM',
    19.0760,
    72.8777,
    NULL,
    NULL,
    '2025-03-14T23:59:00+05:30'
),
(
    'Digital Marketing Workshop',
    '27/2/2025',
    '2025-02-27T10:00:00+05:30',
    'RSET Campus, Mumbai, Maharashtra, India',
    60,
    'A comprehensive workshop on digital marketing fundamentals including SEO, social media marketing, content strategy, and analytics. Open to all departments.',
    '10:00 AM',
    '04:00 PM',
    19.0760,
    72.8777,
    NULL,
    NULL,
    '2025-02-26T23:59:00+05:30'
),
(
    'Blood Donation Camp',
    '10/4/2025',
    '2025-04-10T08:00:00+05:30',
    'College Auditorium, Mumbai, Maharashtra, India',
    3,
    'Annual blood donation camp organized in collaboration with the Red Cross Society. All healthy students above 18 years are encouraged to participate.',
    '08:00 AM',
    '11:00 AM',
    19.0760,
    72.8777,
    NULL,
    NULL,
    '2025-04-09T23:59:00+05:30'
),
(
    'Tree Plantation Drive',
    '5/6/2025',
    '2025-06-05T07:00:00+05:30',
    'Sanjay Gandhi National Park, Mumbai, India',
    4,
    'World Environment Day special — plant trees and contribute to a greener future. Transportation will be arranged from campus.',
    '07:00 AM',
    '11:00 AM',
    19.2147,
    72.9109,
    NULL,
    NULL,
    '2025-06-04T23:59:00+05:30'
),
(
    'Financial Literacy Seminar',
    '20/5/2025',
    '2025-05-20T11:00:00+05:30',
    '1777, Kurla, Mumbai, Maharashtra, 400070, India',
    15,
    'Learn the basics of personal finance, budgeting, investments, and tax planning. Targeted at Commerce students but open to all.',
    '11:00 AM',
    '02:00 PM',
    19.0728,
    72.8826,
    '["B.Com"]',
    NULL,
    '2025-05-19T23:59:00+05:30'
),
(
    'Coding Bootcamp',
    '1/7/2025',
    '2025-07-01T09:00:00+05:30',
    'Computer Lab, RSET Campus, Mumbai, India',
    10,
    'Intensive one-day coding bootcamp covering Python, web development basics, and problem-solving. Targeted at CS and IT students.',
    '09:00 AM',
    '05:00 PM',
    19.0760,
    72.8777,
    '["B.Sc. Computer Science","B.Sc. Information Technology"]',
    2,
    '2025-06-30T23:59:00+05:30'
);


-- ============================================================
-- 3. SAMPLE ANNOUNCEMENTS
-- ============================================================
INSERT INTO public.announcements (title, message, date_str, image_url) VALUES
(
    'Welcome to DLLE Connect!',
    'We are excited to launch the new DLLE Connect app. Stay tuned for upcoming events and announcements. Make sure to enable notifications so you never miss an update!',
    '1/1/2025',
    NULL
),
(
    'Semester 2 Events Schedule Released',
    'The schedule for Semester 2 DLLE extension activities has been finalized. Check the Events tab for all upcoming events. Registration opens one week before each event.',
    '15/1/2025',
    NULL
),
(
    'Certificate Downloads Now Available',
    'You can now download PDF certificates for all completed events directly from the app. Go to the event details page and tap the download button.',
    '1/2/2025',
    NULL
);


-- ============================================================
-- ✅ Seed data inserted!
--
-- Next: Create an admin account via Supabase Auth
-- (see SETUP.md, Section 5)
-- ============================================================
