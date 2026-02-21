# DLLE Connect

A comprehensive cross-platform application designed to streamline and digitize the operations of the **Department of Lifelong Learning and Extension (DLLE)**.

## Overview

DLLE Connect bridges the communication and management gap between DLLE administrators and participating students. It serves as a centralized hub for:

- **Organizing extension work projects** — Create and manage DLLE events
- **Tracking volunteer hours** — Automatic hour tracking upon event completion
- **Managing event participation** — From registration to certification
- **Announcements** — Broadcast important updates to all students
- **Certificate generation** — Auto-generate PDF certificates for completed events

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Backend | Supabase (PostgreSQL + Auth + REST API) |
| PDF Generation | `pdf` + `printing` packages |
| State Management | Singleton DataService with ValueNotifier |
| Local Storage | SharedPreferences |
| Location | Geolocator |
| Camera/Media | Image Picker, Native EXIF |

## Project Structure

```
lib/
├── main.dart                  # App entry point & theme configuration
├── supabase_config.dart       # Supabase URL & anon key
├── screens/
│   ├── login_screen.dart      # Student/Admin login
│   ├── signup_screen.dart     # Student registration
│   ├── dashboard_screen.dart  # Student dashboard with stats & events
│   ├── Coordinator_dashboard.dart  # Admin dashboard
│   ├── events_screen.dart     # Browse all events
│   ├── event_details.dart     # Event detail view (student)
│   ├── event_details_admin.dart # Event detail view (admin)
│   ├── manage_events.dart     # Admin: create/edit events
│   ├── edit_event.dart        # Admin: edit event form
│   ├── event_analytics.dart   # Admin: event statistics
│   ├── manage_stu_screen.dart # Admin: manage students
│   ├── student_details.dart   # Admin: student detail view
│   ├── joined_stu_screen.dart # Admin: students joined an event
│   ├── announcement_screen.dart    # Student: view announcements
│   ├── admin_announcement.dart     # Admin: manage announcements
│   ├── notification_screen.dart    # In-app notifications
│   ├── upload_screen.dart          # Photo upload with EXIF/location
│   ├── setting_screen.dart         # Student settings
│   ├── admin_setting_screen.dart   # Admin settings
│   ├── admin_edit_profile.dart     # Admin profile editing
│   ├── admin_password.dart         # Admin password change
│   ├── data_service.dart      # Central data/state management (singleton)
│   ├── event_model.dart       # EventItem & Student models
│   ├── user_model.dart        # User model
│   ├── notification_model.dart # AppNotification model
│   └── announcement_model.dart # Announcement model
├── services/
│   ├── supabase_service.dart       # Auth service (login/signup/signout)
│   ├── Certificate_service.dart    # PDF certificate generation
│   └── notification_service.dart   # Notification helper service
└── utils/
```

## Supabase Database Schema

The app requires the following tables in your Supabase project:

### `users`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key, linked to `auth.users.id` |
| identifier | Text | Student ID (unique) |
| full_name | Text | |
| email | Text | |
| department | Text | |
| role | Text | `'student'` or `'admin'` |

### `events`
| Column | Type |
|--------|------|
| id | UUID (PK) |
| title | Text |
| date_str | Text |
| event_date | Timestamp |
| location | Text |
| hours | Integer |
| description | Text |
| start_time | Text |
| end_time | Text |
| image_path | Text (nullable) |
| latitude | Float |
| longitude | Float |

### `event_registrations`
| Column | Type | Notes |
|--------|------|-------|
| student_id | Text | References `users.identifier` |
| event_id | UUID | References `events.id` (FK required) |
| status | Text | `'joined'` or `'completed'` |
| completed_at | Timestamp | Nullable |

### `announcements`
| Column | Type |
|--------|------|
| id | UUID (PK) |
| title | Text |
| message | Text |
| date_str | Text |
| created_at | Timestamp |

## Getting Started

### Prerequisites
- Flutter SDK ^3.8.1
- A Supabase project with the tables above created

### Setup
1. Clone the repository
2. Update `lib/supabase_config.dart` with your Supabase URL and anon key
3. Run `flutter pub get`
4. Run `flutter run`

## Roles

- **Student**: Can browse events, join/complete events, view announcements, upload photos, download certificates, and track volunteer hours.
- **Admin/Coordinator**: Can create/manage events, manage students, post announcements, and view event analytics.

## Version
1.0.0
