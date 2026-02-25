import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'event_model.dart';
import 'notification_model.dart';
import 'announcement_model.dart';
import '../services/notification_service.dart';

class DataService {
  // ---------------- SINGLETON ----------------
  DataService._privateConstructor() {
    _loadAdminCredentials();
  }
  static final DataService instance = DataService._privateConstructor();

  final _supabase = Supabase.instance.client;

  // ---------------- THEME NOTIFIER ----------------
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference(isDark);
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  // ---------------- ADMIN ----------------
  String adminName = "Admin";
  String _adminPassword = "password";

  Future<void> _loadAdminCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    adminName = prefs.getString('adminName') ?? "Admin";
    _adminPassword = prefs.getString('adminPassword') ?? "password";
  }

  bool checkAdminPassword(String password) {
    return password == _adminPassword;
  }

  Future<bool> changeAdminPassword(String oldPassword, String newPassword) async {
    try {
      // Use the currently authenticated user's email — always correct
      // regardless of what identifier is stored in studentId.
      final email = _supabase.auth.currentUser?.email;
      if (email == null || email.isEmpty) {
        debugPrint("Admin password change error: no authenticated user email");
        return false;
      }
      // Verify old password against Supabase auth
      await _supabase.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );
      // Old password correct — update to new password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } on AuthException catch (e) {
      debugPrint("Admin password change error: ${e.message}");
      return false;
    } catch (e) {
      debugPrint("Admin password change error: $e");
      return false;
    }
  }

  Future<void> setAdminName(String name) async {
    adminName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adminName', name);
  }

  // ---------------- LOGIN / SESSION ----------------
  Future<void> saveLoginSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUser', userId);
  }

  Future<String?> getSavedLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loggedInUser');
  }

  Future<void> clearLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser');
  }

  bool isLoggedIn = false;
  String studentName = "";
  String studentId = "";
  String studentCourse = "";
  int studentYearOfStudy = 1;
  int totalHours = 0;
  bool notificationEnabled = true;

  Future<void> login(String identifier) async {
    try {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('identifier', identifier)
          .single();
      studentName = userData['full_name'] ?? '';
      studentId = userData['identifier'] ?? '';
      studentCourse = userData['department'] ?? '';
      studentYearOfStudy = userData['year_of_study'] ?? 1;
      isLoggedIn = true;
      await saveLoginSession(identifier);
      await fetchEvents();
      await getTotalHours(studentId);
    } catch (e) {
      debugPrint("Login error: $e");
    }
  }

  Future<String> changeStudentPasswordWithVerification({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      String email;
      try {
        final userData = await _supabase
            .from('users')
            .select('email')
            .eq('identifier', studentId)
            .maybeSingle();
        if (userData != null && userData['email'] != null) {
          email = userData['email'];
        } else {
          email = "$studentId@dlle.com";
        }
      } catch (e) {
        email = "$studentId@dlle.com";
      }

      await _supabase.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return "success";
    } on AuthException catch (e) {
      if (e.message.contains("Invalid login credentials")) {
        return "Incorrect old password";
      }
      return e.message;
    } catch (e) {
      debugPrint("Error changing password: $e");
      return "An error occurred. Please try again.";
    }
  }

  void updateProfile({
    required String name,
    required String id,
    required String course,
  }) {
    studentName = name;
    studentId = id;
    studentCourse = course;
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Supabase signOut error (ignored): $e");
    }
    isLoggedIn = false;
    studentName = "";
    studentId = "";
    studentCourse = "";
    studentYearOfStudy = 1;
    totalHours = 0;
    _events = [];
    notifications = [];
    notificationCountNotifier.value = 0;
    await clearLoginSession();
  }

  // ---------------- EVENTS ----------------
  List<EventItem> _events = [];
  List<EventItem> get events => _events;

  List<Student> _cachedStudents = [];
  List<Student> get students => _cachedStudents;

  Future<void> fetchEvents() async {
    try {
      final response =
          await _supabase.from('events').select().order('event_date');
      _events = (response as List).map((e) => EventItem.fromMap(e)).toList();

      if (studentId.isNotEmpty) {
        final regs = await _supabase
            .from('event_registrations')
            .select()
            .eq('student_id', studentId);

        final regList = regs as List;
        for (var event in _events) {
          event.joined = false;
          event.completed = false;

          final regIndex = regList.indexWhere(
            (r) => r['event_id'] == event.id,
          );
          if (regIndex != -1) {
            final reg = regList[regIndex];
            event.joined = true;
            if (reg['status'] == 'completed') {
              event.completed = true;
              event.completedAt =
                  DateTime.tryParse(reg['completed_at'] ?? '');
            }
          }
        }

        // Filter events: show "All" events + events matching student's course/year
        _events = _events.where((event) {
          // No targeting → visible to everyone
          if (event.targetCourses == null || event.targetCourses!.isEmpty) {
            return true;
          }
          // Student's course is in the targeted courses list
          if (event.targetCourses!.contains(studentCourse)) {
            // No year targeting → visible to all years in those courses
            if (event.targetYear == null) return true;
            // Year matches
            return event.targetYear == studentYearOfStudy;
          }
          return false;
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching events: $e");
    }
  }

  bool canJoinEvent(EventItem event) {
    final today = DateTime.now();
    return today.isBefore(event.eventdate);
  }

  Future<void> addEvent(EventItem event) async {
    await _supabase.from('events').insert(event.toMap());
    await fetchEvents();
    addNotification("New Event Added", event.title);
  }

  Future<void> updateEvent(EventItem updatedEvent) async {
    if (updatedEvent.id == null) return;
    await _supabase
        .from('events')
        .update(updatedEvent.toMap())
        .eq('id', updatedEvent.id!);
    await fetchEvents();
  }

  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('events').delete().eq('id', eventId);
    await _supabase
        .from('event_registrations')
        .delete()
        .eq('event_id', eventId);
    await fetchEvents();
  }

  // ---------------- EVENT ACTIONS ----------------
  Future<void> joinEvent(EventItem event, String studentId) async {
    final eventId = event.id;
    if (eventId == null) return;

    await _supabase.from('event_registrations').upsert({
      'student_id': studentId,
      'event_id': eventId,
      'status': 'joined',
    });

    await fetchEvents();
    addNotification("Event Joined", event.title);
  }

  Future<void> completeEvent(EventItem event, String studentId) async {
    final eventId = event.id;
    if (eventId == null) return;

    await _supabase.from('event_registrations').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).match({'student_id': studentId, 'event_id': eventId});

    await getTotalHours(studentId);
    await fetchEvents();
    addNotification("Event Completed", event.title);
  }

  // ---------------- DASHBOARD ----------------
  Future<int> getTotalHours(String studentId) async {
    try {
      final regs = await _supabase
          .from('event_registrations')
          .select('event_id, status, events(hours)')
          .eq('student_id', studentId)
          .eq('status', 'completed');

      int calculatedHours = 0;
      for (var reg in (regs as List)) {
        calculatedHours += (reg['events']['hours'] as int? ?? 0);
      }
      totalHours = calculatedHours;
      return totalHours;
    } catch (e) {
      return totalHours;
    }
  }

  List<EventItem> get joinedEvents =>
      _events.where((e) => e.joined && !e.completed).toList();

  List<EventItem> get completedEvents =>
      _events.where((e) => e.completed).toList();

  /// Events the student has not joined yet and that are still upcoming.
  List<EventItem> get suggestedEvents => _events
      .where((e) =>
          !e.joined &&
          !e.completed &&
          e.eventdate.isAfter(DateTime.now()))
      .toList();

  // ---------------- NOTIFICATIONS ----------------
  List<AppNotification> notifications = [];

  /// Tracks unread notification count — used for the bell badge in the UI.
  final ValueNotifier<int> notificationCountNotifier = ValueNotifier(0);

  /// Set of announcement IDs that the user has permanently dismissed.
  Set<String> _dismissedAnnouncementIds = {};

  /// Timestamp of when the user last opened the notification screen.
  /// Used to determine which announcements are "unread" (for badge count).
  DateTime _lastSeenAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Load persisted dismissed IDs and lastSeenAt from SharedPreferences.
  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList('dismissedAnnouncementIds') ?? [];
    _dismissedAnnouncementIds = dismissed.toSet();
    final lastSeenMs = prefs.getInt('lastSeenAt') ?? 0;
    _lastSeenAt = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);
  }

  Future<void> _saveDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'dismissedAnnouncementIds', _dismissedAnnouncementIds.toList());
  }

  Future<void> _saveLastSeenAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'lastSeenAt', _lastSeenAt.millisecondsSinceEpoch);
  }

  void addNotification(String title, String message) {
    notifications.insert(
      0,
      AppNotification(
        title: title,
        message: message,
        time: DateTime.now(),
      ),
    );
    notificationCountNotifier.value = notifications.length;
  }

  /// Called when user opens the notification screen — clears the badge
  /// and saves the current time as lastSeenAt so future loads don't re-badge.
  Future<void> clearNotificationCount() async {
    _lastSeenAt = DateTime.now();
    await _saveLastSeenAt();
    notificationCountNotifier.value = 0;
  }

  /// Permanently dismiss a single notification by its announcement ID.
  Future<void> dismissNotification(String announcementId) async {
    _dismissedAnnouncementIds.add(announcementId);
    await _saveDismissedIds();
    notifications.removeWhere((n) => n.announcementId == announcementId);
    // Recount unread
    final unread = notifications
        .where((n) =>
            n.announcementId != null &&
            n.time.isAfter(_lastSeenAt))
        .length;
    notificationCountNotifier.value = unread;
  }

  /// Permanently dismiss ALL current notifications.
  Future<void> clearAllNotifications() async {
    for (final n in notifications) {
      if (n.announcementId != null) {
        _dismissedAnnouncementIds.add(n.announcementId!);
      }
    }
    await _saveDismissedIds();
    _lastSeenAt = DateTime.now();
    await _saveLastSeenAt();
    notifications.clear();
    notificationCountNotifier.value = 0;
  }

  /// Load notifications from the announcements table in Supabase.
  /// Skips permanently dismissed announcements.
  /// Badge count = announcements newer than lastSeenAt (and not dismissed).
  Future<void> loadNotificationsFromAnnouncements() async {
    try {
      await _loadNotificationPrefs();

      if (_announcements.isEmpty) {
        await fetchAnnouncements();
      }

      notifications.clear();

      int unreadCount = 0;
      for (final announcement in _announcements) {
        final id = announcement.id ?? '';
        // Skip permanently dismissed
        if (_dismissedAnnouncementIds.contains(id)) continue;

        notifications.add(
          AppNotification(
            title: "📢 New Announcement",
            message: announcement.title,
            time: announcement.createdAt,
            announcementId: id,
          ),
        );

        // Count as unread if newer than lastSeenAt
        if (announcement.createdAt.isAfter(_lastSeenAt)) {
          unreadCount++;
        }
      }

      notificationCountNotifier.value = unreadCount;
      debugPrint(
          "[DataService] Loaded ${notifications.length} notifications, $unreadCount unread");
    } catch (e) {
      debugPrint("Error loading notifications from announcements: $e");
    }
  }

  // ---------------- REALTIME SUBSCRIPTIONS ----------------
  RealtimeChannel? _announcementsChannel;

  void initRealtimeSubscriptions() {
    _announcementsChannel = _supabase
        .channel('public:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            final newRow = payload.newRecord;
            final id = newRow['id']?.toString() ?? '';

            // Skip if already dismissed
            if (_dismissedAnnouncementIds.contains(id)) return;

            final announcement = Announcement(
              id: id,
              title: newRow['title'] ?? '',
              message: newRow['message'] ?? '',
              createdAt: DateTime.tryParse(
                      newRow['created_at']?.toString() ?? '') ??
                  DateTime.now(),
              imageUrl: newRow['image_url'],
            );

            final alreadyExists =
                _announcements.any((a) => a.id == announcement.id);
            if (!alreadyExists) {
              _announcements.insert(0, announcement);
            }

            // Show system notification + add to in-app list
            NotificationService.showNotification(
              title: "📢 New Announcement",
              body: announcement.title,
            );

            // Add to in-app notification list with announcementId
            notifications.insert(
              0,
              AppNotification(
                title: "📢 New Announcement",
                message: announcement.title,
                time: announcement.createdAt,
                announcementId: id,
              ),
            );
            // Increment badge
            notificationCountNotifier.value =
                notificationCountNotifier.value + 1;
          },
        )
        .subscribe();
  }

  void disposeRealtimeSubscriptions() {
    if (_announcementsChannel != null) {
      _supabase.removeChannel(_announcementsChannel!);
      _announcementsChannel = null;
    }
  }

  // ---------------- ANNOUNCEMENTS ----------------
  List<Announcement> _announcements = [];
  List<Announcement> get announcements => _announcements;

  Future<void> fetchAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);
      _announcements = (response as List).map((e) {
        return Announcement(
          id: e['id'].toString(),
          title: e['title'] ?? '',
          message: e['message'] ?? '',
          createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ??
              DateTime.now(),
          imageUrl: e['image_url'],
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
    }
  }

  /// Upload an announcement image to Supabase Storage.
  /// Returns the public URL of the uploaded image.
  Future<String?> uploadAnnouncementImage(File imageFile) async {
    try {
      final fileName =
          'announcements/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage
          .from('dlle-connect')
          .upload(fileName, imageFile,
              fileOptions:
                  const FileOptions(contentType: 'image/jpeg', upsert: true));
      final publicUrl =
          _supabase.storage.from('dlle-connect').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading announcement image: $e");
      return null;
    }
  }

  /// Upload an event image to Supabase Storage (events/ folder).
  /// Returns the public URL of the uploaded image, or null on failure.
  Future<String?> uploadEventImage(File imageFile) async {
    try {
      final fileName =
          'events/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage
          .from('dlle-connect')
          .upload(fileName, imageFile,
              fileOptions:
                  const FileOptions(contentType: 'image/jpeg', upsert: true));
      final publicUrl =
          _supabase.storage.from('dlle-connect').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading event image: $e");
      return null;
    }
  }

  Future<void> addAnnouncement(String title, String message,
      {String? imageUrl}) async {
    await _supabase.from('announcements').insert({
      'title': title,
      'message': message,
      if (imageUrl != null) 'image_url': imageUrl,
    });
    // Realtime subscription handles updating the list and notifying users.
  }

  Future<void> updateAnnouncement(String id, String title, String message,
      {String? imageUrl}) async {
    await _supabase.from('announcements').update({
      'title': title,
      'message': message,
      'image_url': imageUrl, // null clears the image
    }).eq('id', id);
    await fetchAnnouncements();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _supabase.from('announcements').delete().eq('id', id);
    // Also dismiss from notifications so it doesn't reappear
    _dismissedAnnouncementIds.add(id);
    await _saveDismissedIds();
    notifications.removeWhere((n) => n.announcementId == id);
    notificationCountNotifier.value = notifications
        .where((n) =>
            n.announcementId != null && n.time.isAfter(_lastSeenAt))
        .length;
    await fetchAnnouncements();
  }

  // ---------------- COURSES ----------------
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> get courses => _courses;

  Future<void> fetchCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .order('name', ascending: true);
      _courses = List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("Error fetching courses: $e");
    }
  }

  Future<void> addCourse(String name, int maxYear) async {
    try {
      await _supabase.from('courses').insert({
        'name': name,
        'max_year': maxYear,
      });
      await fetchCourses();
    } catch (e) {
      debugPrint("Error adding course: $e");
      rethrow;
    }
  }

  Future<void> updateCourse(String id, String name, int maxYear) async {
    try {
      await _supabase.from('courses').update({
        'name': name,
        'max_year': maxYear,
      }).eq('id', id);
      await fetchCourses();
    } catch (e) {
      debugPrint("Error updating course: $e");
      rethrow;
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      await _supabase.from('courses').delete().eq('id', id);
      await fetchCourses();
    } catch (e) {
      debugPrint("Error deleting course: $e");
      rethrow;
    }
  }

  // ---------------- USERS / STUDENTS ----------------
  Future<void> createStudent({
    required String identifier,
    required String name,
    required String department,
    int yearOfStudy = 1,
  }) async {
    try {
      await _supabase.from('users').insert({
        'identifier': identifier,
        'full_name': name,
        'department': department,
        'year_of_study': yearOfStudy,
        'role': 'student',
      });
      await getAllStudents();
    } catch (e) {
      debugPrint("Error creating student in database: $e");
      rethrow;
    }
  }

  Future<void> updateStudent(
    String originalIdentifier, {
    required String name,
    required String department,
  }) async {
    try {
      await _supabase.from('users').update({
        'full_name': name,
        'department': department,
      }).eq('identifier', originalIdentifier);
      await getAllStudents();
    } catch (e) {
      debugPrint("Error updating student: $e");
      rethrow;
    }
  }

  Future<void> deleteStudent(String studentIdentifier) async {
    try {
      await _supabase
          .from('event_registrations')
          .delete()
          .eq('student_id', studentIdentifier);
      await _supabase
          .from('users')
          .delete()
          .eq('identifier', studentIdentifier);
      await getAllStudents();
    } catch (e) {
      debugPrint("Error deleting student: $e");
      rethrow;
    }
  }

  Future<List<Student>> getAllStudents() async {
    try {
      final response =
          await _supabase.from('users').select().eq('role', 'student');
      final List usersList = response as List;

      List regs = [];
      try {
        final regsResponse = await _supabase
            .from('event_registrations')
            .select('*, events(title, hours)');
        regs = regsResponse as List;
      } catch (regError) {
        debugPrint("Error fetching registrations: $regError");
      }

      _cachedStudents = usersList.map((u) {
        final student = Student.fromMap(u);

        final studentRegs =
            regs.where((r) => r['student_id'] == student.identifier).toList();

        student.joinedEvents = studentRegs
            .map((r) =>
                (r['events'] as Map<String, dynamic>?)?['title'] as String? ??
                'Unknown')
            .toList();

        int calculatedHours = 0;
        student.completedEvents = [];
        for (var r in studentRegs) {
          if (r['status'] == 'completed') {
            final eventData = r['events'] as Map<String, dynamic>?;
            student.completedEvents.add(eventData?['title'] ?? 'Unknown');
            calculatedHours += (eventData?['hours'] as int? ?? 0);
          }
        }
        student.totalHours = calculatedHours;

        return student;
      }).toList();

      return _cachedStudents;
    } catch (e) {
      debugPrint("Error in getAllStudents: $e");
      return [];
    }
  }

  Future<List<Student>> getStudentsJoinedEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('event_registrations')
          .select('student_id, users(*)')
          .eq('event_id', eventId)
          .eq('status', 'joined');

      return (response as List).map((item) {
        if (item['users'] == null) return null;
        return Student.fromMap(item['users'] as Map<String, dynamic>);
      }).whereType<Student>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Student>> getStudentsCompletedEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('event_registrations')
          .select('student_id, users(*)')
          .eq('event_id', eventId)
          .eq('status', 'completed');

      return (response as List).map((item) {
        if (item['users'] == null) return null;
        return Student.fromMap(item['users'] as Map<String, dynamic>);
      }).whereType<Student>().toList();
    } catch (e) {
      return [];
    }
  }
}
