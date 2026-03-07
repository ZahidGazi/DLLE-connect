# DLLE Connect

A comprehensive cross-platform application designed to streamline and digitize the operations of the **Department of Lifelong Learning and Extension (DLLE)**.

## Overview

DLLE Connect bridges the communication and management gap between DLLE administrators/coordinators and participating students. It serves as a centralized hub for organizing extension work projects, tracking volunteer hours, managing event participation, broadcasting announcements, and generating certificates.

## Features

### For Students
- **Browse & Join Events** — View all available DLLE events filtered by your course and year
- **Track Volunteer Hours** — Automatic hour tracking upon event completion with a dashboard summary
- **Announcements** — Receive real-time announcements from coordinators
- **Push Notifications** — System notifications for new events and announcements (Android)
- **Download Certificates** — Auto-generated PDF certificates for completed events
- **Photo Upload** — Upload event photos with EXIF metadata and GPS location
- **Dark Mode** — Toggle between light and dark themes

### For Admins / Coordinators
- **Create & Manage Events** — Full CRUD with course/year targeting, location picker, and image upload
- **Manage Students** — View, edit, and bulk-delete student records
- **Post Announcements** — Create announcements with optional image attachments
- **Event Analytics** — View join/completion statistics per event
- **Manage Courses** — Add, edit, and delete available courses/departments

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) — cross-platform (Android, iOS, Web, Desktop) |
| Backend | Supabase (PostgreSQL + Auth + REST API + Realtime + Storage) |
| PDF Generation | `pdf` + `printing` packages |
| State Management | Singleton DataService with `ValueNotifier` |
| Local Storage | `shared_preferences` |
| Location | `geolocator` + `flutter_map` + `geocoding` |
| Camera / Media | `image_picker` + `native_exif` |
| Notifications | `flutter_local_notifications` + Supabase Realtime |

## Project Structure

```
lib/
├── main.dart                       # App entry point, Supabase init, theme setup
├── supabase_config.dart            # Supabase URL & anon key
│
├── screens/
│   ├── splash_screen.dart          # Splash / auto-login screen
│   ├── login_screen.dart           # Student & Admin login
│   ├── signup_screen.dart          # Student registration
│   ├── email_confirmation_screen.dart  # Email verification prompt
│   │
│   ├── dashboard_screen.dart       # Student dashboard (stats, events)
│   ├── Coordinator_dashboard.dart  # Admin/Coordinator dashboard
│   │
│   ├── events_screen.dart          # Browse all events (student)
│   ├── event_details.dart          # Event detail view (student)
│   ├── event_details_admin.dart    # Event detail view (admin)
│   ├── manage_events.dart          # Admin: create events
│   ├── edit_event.dart             # Admin: edit event form
│   ├── event_analytics.dart        # Admin: event statistics
│   ├── joined_stu_screen.dart      # Admin: students joined an event
│   │
│   ├── announcement_screen.dart    # Student: view announcements
│   ├── admin_announcement.dart     # Admin: manage announcements
│   ├── notification_screen.dart    # In-app notification list
│   │
│   ├── manage_stu_screen.dart      # Admin: manage students
│   ├── student_details.dart        # Admin: student detail view
│   ├── manage_courses_screen.dart  # Admin: manage courses
│   │
│   ├── certificates_screen.dart    # Student: certificates list
│   ├── upload_screen.dart          # Photo upload with EXIF/location
│   ├── location_picker_sheet.dart  # Map-based location picker
│   │
│   ├── setting_screen.dart         # Student settings
│   ├── admin_setting_screen.dart   # Admin settings
│   ├── admin_edit_profile.dart     # Admin profile editing
│   ├── admin_password.dart         # Admin password change
│   │
│   ├── data_service.dart           # Central data/state management (singleton)
│   ├── event_model.dart            # EventItem & Student models
│   ├── user_model.dart             # AppUser model
│   ├── notification_model.dart     # AppNotification model
│   └── announcement_model.dart     # Announcement model
│
├── services/
│   ├── supabase_service.dart       # Auth service (login / signup / signout)
│   ├── Certificate_service.dart    # PDF certificate generation
│   └── notification_service.dart   # Local notification helper
│
└── utils/
    ├── app_theme.dart              # Light & dark theme definitions
    └── responsive_helper.dart      # Responsive layout utilities
```

## Database Schema

The app uses **5 Supabase tables**:

| Table | Description |
|-------|-------------|
| `users` | Student and admin profiles (linked to Supabase Auth) |
| `courses` | Available courses/departments with max academic year |
| `events` | DLLE events with targeting, location, and expiry |
| `event_registrations` | Tracks student join/completion status per event |
| `announcements` | Admin announcements with optional image |

### `users`
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID (PK) | Linked to `auth.users.id` |
| `identifier` | TEXT (UNIQUE) | Student ID |
| `full_name` | TEXT | |
| `email` | TEXT (UNIQUE) | |
| `department` | TEXT | Course name |
| `role` | TEXT | `'student'` or `'admin'` |
| `year_of_study` | INTEGER | Academic year (default: 1) |

### `courses`
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID (PK) | |
| `name` | TEXT (UNIQUE) | Course name |
| `max_year` | INTEGER | Max academic year |

### `events`
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID (PK) | |
| `title` | TEXT | |
| `date_str` | TEXT | Display date |
| `event_date` | TIMESTAMPTZ | For sorting |
| `location` | TEXT | |
| `hours` | INTEGER | Volunteer hours |
| `description` | TEXT | |
| `start_time` / `end_time` | TEXT | |
| `image_path` | TEXT | Optional image URL |
| `latitude` / `longitude` | DOUBLE PRECISION | GPS coordinates |
| `target_course` | TEXT | JSON array or NULL (all) |
| `target_year` | INTEGER | NULL = all years |
| `event_expiry_date` | TIMESTAMPTZ | Registration deadline |

### `event_registrations`
| Column | Type | Notes |
|--------|------|-------|
| `student_id` | TEXT (PK) | → `users.identifier` |
| `event_id` | UUID (PK) | → `events.id` |
| `status` | TEXT | `'joined'` or `'completed'` |
| `completed_at` | TIMESTAMPTZ | |

### `announcements`
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID (PK) | |
| `title` | TEXT | |
| `message` | TEXT | |
| `image_url` | TEXT | Optional |
| `created_at` | TIMESTAMPTZ | |

> Full SQL schema with indexes, triggers, and policies: [`supabase/schema.sql`](supabase/schema.sql)

## Getting Started

### Prerequisites

- **Flutter SDK** ^3.8.1
- A **Supabase** account and project
- **Android Studio** or **VS Code** with Flutter extension

### Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd DLLE-connect

# 2. Install Flutter dependencies
flutter pub get

# 3. Set up Supabase (see SETUP.md for detailed instructions)
#    - Create a Supabase project
#    - Run supabase/schema.sql in the SQL Editor
#    - Run supabase/seed.sql (optional — sample data)
#    - Create a storage bucket named 'dlle-connect'
#    - Create an admin account

# 4. Update Supabase credentials
#    Edit lib/supabase_config.dart with your project URL and anon key

# 5. Run the app
flutter run
```

> 📖 **For a complete step-by-step setup guide, see [SETUP.md](SETUP.md)**

## Roles

| Role | Access |
|------|--------|
| **Student** | Browse events, join/complete events, view announcements, upload photos, download certificates, track volunteer hours |
| **Admin / Coordinator** | Create/manage events, manage students, post announcements, manage courses, view event analytics |

## Realtime Features

The app uses Supabase Realtime to deliver instant updates:

- **New Announcement** → System notification + in-app notification for all students
- **New Event** → System notification for eligible students (filtered by course/year)

## Storage

Images are stored in a Supabase Storage bucket named `dlle-connect`:

| Folder | Content |
|--------|---------|
| `announcements/` | Announcement images |
| `events/` | Event images |

## Version

1.0.0

## License

This project is private and not published to pub.dev.
