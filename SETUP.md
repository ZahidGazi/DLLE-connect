# DLLE Connect — Setup Guide

This guide walks you through setting up the DLLE Connect application from scratch, including the Supabase backend and the Flutter app.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Create a Supabase Project](#2-create-a-supabase-project)
3. [Run the Database Schema](#3-run-the-database-schema)
4. [Run the Seed Data (Optional)](#4-run-the-seed-data-optional)
5. [Create the Storage Bucket](#5-create-the-storage-bucket)
6. [Enable Realtime](#6-enable-realtime)
7. [Create an Admin Account](#7-create-an-admin-account)
8. [Configure the Flutter App](#8-configure-the-flutter-app)
9. [Run the App](#9-run-the-app)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites

Before you begin, make sure you have the following installed:

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | ^3.8.1 | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| Dart SDK | (bundled with Flutter) | — |
| Android Studio or VS Code | Latest | [developer.android.com/studio](https://developer.android.com/studio) |
| Git | Latest | [git-scm.com](https://git-scm.com/) |

You also need:
- A **Supabase account** — [supabase.com](https://supabase.com/) (free tier works)
- A physical Android device or emulator for testing

Verify Flutter is set up correctly:

```bash
flutter doctor
```

---

## 2. Create a Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click **New Project**
3. Fill in:
   - **Project name**: `dlle-connect` (or any name you prefer)
   - **Database password**: Choose a strong password (save it somewhere safe)
   - **Region**: Choose the closest region to your users
4. Click **Create new project** and wait for it to be provisioned (~2 minutes)

Once ready, note down these values from **Settings → API**:

| Value | Where to find it |
|-------|-----------------|
| **Project URL** | `Settings → API → Project URL` |
| **Anon public key** | `Settings → API → Project API keys → anon / public` |

You will need these in [Step 8](#8-configure-the-flutter-app).

---

## 3. Run the Database Schema

1. In your Supabase Dashboard, go to **SQL Editor**
2. Click **New query**
3. Open the file [`supabase/schema.sql`](supabase/schema.sql) from this repository
4. Copy the **entire contents** and paste into the SQL Editor
5. Click **Run**

You should see a success message. This creates all 5 tables, indexes, the auth trigger, storage policies, and realtime configuration.

### What gets created:

| Table | Description |
|-------|-------------|
| `users` | Student and admin profiles |
| `courses` | Available courses/departments |
| `events` | DLLE events |
| `event_registrations` | Student ↔ Event join/completion tracking |
| `announcements` | Admin announcements |

---

## 4. Run the Seed Data (Optional)

To populate the database with sample courses, events, and announcements for testing:

1. In the **SQL Editor**, click **New query**
2. Open the file [`supabase/seed.sql`](supabase/seed.sql)
3. Copy the **entire contents** and paste into the SQL Editor
4. Click **Run**

This inserts:
- **12 sample courses** (B.Sc. CS, B.Com, M.Sc., etc.)
- **6 sample events** (with various targeting configurations)
- **3 sample announcements**

> **Note**: The seed data does NOT create user accounts. You must create the admin account separately (see Step 7).

---

## 5. Create the Storage Bucket

The app stores announcement and event images in Supabase Storage.

1. In your Supabase Dashboard, go to **Storage**
2. Click **New bucket**
3. Configure:
   - **Name**: `dlle-connect`
   - **Public bucket**: **ON** (toggle enabled)
4. Click **Create bucket**

> The storage access policies were already created by `schema.sql` in Step 3. No additional policy setup is needed.

### Verify Storage Policies

Go to **Storage → Policies** and confirm you see these policies for the `dlle-connect` bucket:

- `Allow all uploads` (INSERT)
- `Allow public read` (SELECT)
- `Allow all updates` (UPDATE)
- `Allow all deletes` (DELETE)

---

## 6. Enable Realtime

The app uses Supabase Realtime to push live notifications when new announcements or events are created.

`schema.sql` already adds the `announcements` and `events` tables to the `supabase_realtime` publication. To verify:

1. Go to **Database → Replication** in your Supabase Dashboard
2. Under **supabase_realtime**, confirm that `announcements` and `events` are listed
3. If they are not listed, enable them by toggling them on

---

## 7. Create an Admin Account

The admin account must be created manually via the Supabase Dashboard.

### Step 7a: Create the Auth User

1. Go to **Authentication → Users**
2. Click **Add user → Create new user**
3. Fill in:
   - **Email**: `admin@dlle.com` (or any email you prefer)
   - **Password**: Choose a strong password
   - **Auto Confirm User**: **ON** (toggle enabled)
4. Click **Create user**
5. Copy the **User UID** from the newly created row

### Step 7b: Insert the Admin Record

1. Go to **SQL Editor** → **New query**
2. Run the following SQL (replace the values):

```sql
INSERT INTO public.users (id, identifier, full_name, email, department, role)
VALUES (
    'PASTE_THE_USER_UID_HERE',   -- The UUID from Step 7a
    'admin',                      -- Admin identifier (used for login)
    'DLLE Admin',                 -- Display name
    'admin@dlle.com',             -- Same email as Step 7a
    'Administration',             -- Department
    'admin'                       -- Role must be 'admin'
);
```

### Step 7c: Test Admin Login

In the app, on the login screen:
1. Select **Admin** role
2. Enter the email and password from Step 7a
3. You should be taken to the Coordinator Dashboard

---

## 8. Configure the Flutter App

1. Open the file `lib/supabase_config.dart`
2. Replace the values with your Supabase project credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
}
```

> **Where to find these values**: Supabase Dashboard → **Settings → API**

---

## 9. Run the App

```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Build a release APK (Android)
flutter build apk --release

# Build for iOS (macOS only)
flutter build ios --release
```

### First Launch

On first launch, the app will:
1. Show a splash screen
2. Attempt to connect to Supabase (may take a few seconds if the project was paused)
3. Navigate to the login screen

---

## 10. Troubleshooting

### "525 SSL Handshake Error" on first request

**Cause**: Supabase free-tier projects pause after inactivity. The first request triggers a cold start.

**Solution**: The app has built-in retry logic that handles this automatically. A warm-up ping is also sent at startup. If the issue persists, wait 10–15 seconds and try again.

---

### "Email not confirmed" error during login

**Cause**: Supabase email confirmation is enabled and the user hasn't verified their email.

**Solution**:
- Check the email inbox (including spam) for the confirmation link
- Use the "Resend Confirmation Email" button on the confirmation screen
- To disable email confirmation: Supabase Dashboard → **Authentication → Settings → Email Auth → Toggle off "Enable email confirmations"**

---

### Students can't see certain events

**Cause**: The event has `target_course` or `target_year` set, and the student's course/year doesn't match.

**Solution**: Verify the student's `department` and `year_of_study` in the `users` table match the event's targeting. Events with `target_course = NULL` are visible to everyone.

---

### Storage upload returns 403 Forbidden

**Cause**: Storage policies are missing or the bucket doesn't exist.

**Solution**:
1. Verify the bucket `dlle-connect` exists in **Storage**
2. Verify it is set to **Public**
3. Re-run the storage policy section from `schema.sql` in the SQL Editor

---

### "User already registered" during signup

**Cause**: The email or student ID is already in use.

**Solution**: Use a different email/student ID, or delete the existing record from **Authentication → Users** and the `users` table.

---

### App shows empty events / announcements

**Cause**: No data in the database, or the Supabase project is still waking up.

**Solution**:
1. Pull down to refresh in the app
2. Run `seed.sql` to insert sample data
3. Check the Supabase Dashboard → **Table Editor** to verify data exists

---

### Realtime notifications not working

**Cause**: Tables are not added to the realtime publication.

**Solution**:
1. Go to **Database → Replication**
2. Ensure `announcements` and `events` are enabled under `supabase_realtime`
3. Or run in SQL Editor:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
```

---

## Summary Checklist

- [ ] Supabase project created
- [ ] `schema.sql` executed in SQL Editor
- [ ] `seed.sql` executed (optional)
- [ ] Storage bucket `dlle-connect` created (Public: ON)
- [ ] Realtime enabled for `announcements` and `events`
- [ ] Admin auth user created and confirmed
- [ ] Admin record inserted into `users` table with `role = 'admin'`
- [ ] `lib/supabase_config.dart` updated with your project URL and anon key
- [ ] `flutter pub get` completed
- [ ] App runs successfully with `flutter run`
