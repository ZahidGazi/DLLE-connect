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
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  /// Load saved theme preference from SharedPreferences.
  /// Called once at app startup before runApp().
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true; // Default to dark
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle theme and persist the choice.
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
  
  bool changeAdminPassword(String oldPassword, String newPassword) {
    if (oldPassword == _adminPassword) {
      _adminPassword = newPassword;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('adminPassword', newPassword);
      });
      return true;
    }
    return false;
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
  String studentId = ""; // This stores the 'identifier' from the users table
  String studentCourse = "";
  int totalHours = 0;
  bool notificationEnabled = true;

  Future<void> login(String identifier) async {
    try {
      final userData = await _supabase.from('users').select().eq('identifier', identifier).single();
      studentName = userData['full_name'] ?? '';
      studentId = userData['identifier'] ?? '';
      studentCourse = userData['department'] ?? '';
      isLoggedIn = true;
      await saveLoginSession(identifier);
      await fetchEvents(); // Load events for the logged in student
      await getTotalHours(studentId); // Calculate and set totalHours
    } catch (e) {
      debugPrint("Login error: $e");
    }
  }

  Future<String> changeStudentPasswordWithVerification({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Look up the real email from the users table using the student identifier
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
          // Fallback for older accounts that might still use synthetic emails
          email = "$studentId@dlle.com";
        }
      } catch (e) {
        // Fallback for older accounts
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
    isLoggedIn = false;
    studentName = "";
    studentId = "";
    studentCourse = "";
    totalHours = 0;
    await clearLoginSession();
  }

  // ---------------- EVENTS ----------------
  List<EventItem> _events = [];
  List<EventItem> get events => _events;

  List<Student> _cachedStudents = [];
  List<Student> get students => _cachedStudents;

  Future<void> fetchEvents() async {
    try {
      final response = await _supabase.from('events').select().order('event_date');
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
              event.completedAt = DateTime.tryParse(reg['completed_at'] ?? '');
            }
          }
        }
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
    await _supabase.from('event_registrations').delete().eq('event_id', eventId);
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

  // ---------------- NOTIFICATIONS ----------------
  List<AppNotification> notifications = [];

  /// Tracks unread notification count — used for the bell badge in the UI.
  final ValueNotifier<int> notificationCountNotifier = ValueNotifier(0);

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

  void clearNotificationCount() {
    notificationCountNotifier.value = 0;
  }

  /// Load notifications from the announcements table in Supabase.
  /// This ensures that when a student opens the app (even after restart),
  /// the notification screen shows all past announcements as notifications.
  Future<void> loadNotificationsFromAnnouncements() async {
    try {
      // Fetch announcements if not already loaded
      if (_announcements.isEmpty) {
        await fetchAnnouncements();
      }

      // Clear existing in-memory notifications to avoid duplicates
      notifications.clear();

      // Convert each announcement into an AppNotification
      for (final announcement in _announcements) {
        notifications.add(
          AppNotification(
            title: "📢 New Announcement",
            message: announcement.title,
            time: DateTime.tryParse(announcement.date) ?? DateTime.now(),
          ),
        );
      }

      // Update the badge count
      notificationCountNotifier.value = notifications.length;
      debugPrint("[DataService] Loaded ${notifications.length} notifications from announcements");
    } catch (e) {
      debugPrint("Error loading notifications from announcements: $e");
    }
  }

  // ---------------- REALTIME SUBSCRIPTIONS ----------------
  RealtimeChannel? _announcementsChannel;

  /// Call once at app startup (after Supabase.initialize).
  /// Listens for new announcements inserted by admin and notifies all users.
  void initRealtimeSubscriptions() {
    _announcementsChannel = _supabase
        .channel('public:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            final newRow = payload.newRecord;
            final announcement = Announcement(
              id: newRow['id']?.toString(),
              title: newRow['title'] ?? '',
              message: newRow['message'] ?? '',
              date: newRow['date_str'] ?? '',
            );

            // Avoid duplicate if already in list
            final alreadyExists = _announcements.any((a) => a.id == announcement.id);
            if (!alreadyExists) {
              _announcements.insert(0, announcement);
            }

            // Show system notification + add to in-app list
            NotificationService.showNotification(
              title: "📢 New Announcement",
              body: announcement.title,
            );
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
      final response = await _supabase.from('announcements').select().order('created_at', ascending: false);
      _announcements = (response as List).map((e) => Announcement(
        id: e['id'].toString(),
        title: e['title'],
        message: e['message'],
        date: e['date_str'],
      )).toList();
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
    }
  }

  Future<void> addAnnouncement(String title, String message, String date) async {
    await _supabase.from('announcements').insert({
      'title': title,
      'message': message,
      'date_str': date,
    });
    // Note: fetchAnnouncements() is NOT called here because the Realtime
    // subscription will handle updating the list and notifying all users
    // (including the admin who posted it) automatically.
  }

  Future<void> updateAnnouncement(String id, String title, String message, String date) async {
    await _supabase.from('announcements').update({
      'title': title,
      'message': message,
      'date_str': date,
    }).eq('id', id);
    await fetchAnnouncements();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _supabase.from('announcements').delete().eq('id', id);
    await fetchAnnouncements();
  }

  // ---------------- USERS / STUDENTS ----------------
  Future<void> createStudent({
    required String identifier,
    required String name,
    required String department,
  }) async {
    try {
      await _supabase.from('users').insert({
        'identifier': identifier,
        'full_name': name,
        'department': department,
        'role': 'student',
      });
      await getAllStudents();
    } catch (e) {
      debugPrint("Error creating student in database: $e");
      rethrow;
    }
  }

  Future<void> updateStudent(String originalIdentifier, {
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
      // 1. Delete registrations first
      await _supabase.from('event_registrations').delete().eq('student_id', studentIdentifier);
      
      // 2. Delete the user record
      await _supabase.from('users').delete().eq('identifier', studentIdentifier);
      
      await getAllStudents();
    } catch (e) {
      debugPrint("Error deleting student: $e");
      rethrow;
    }
  }

  Future<List<Student>> getAllStudents() async {
    try {
      // 1. Fetch all users with 'student' role
      final response = await _supabase.from('users').select().eq('role', 'student');
      final List usersList = response as List;
      
      // 2. Fetch all registrations with event details
      List regs = [];
      try {
        final regsResponse = await _supabase.from('event_registrations').select('*, events(title, hours)');
        regs = regsResponse as List;
      } catch (regError) {
        debugPrint("Error fetching registrations: $regError");
        // Continue with empty registrations list if it fails
      }

      // 3. Map users to Student objects
      _cachedStudents = usersList.map((u) {
        final student = Student.fromMap(u);
        
        // Match registrations for this specific student using 'identifier'
        final studentRegs = regs.where((r) => r['student_id'] == student.identifier).toList();
        
        student.joinedEvents = studentRegs
            .map((r) => (r['events'] as Map<String, dynamic>?)?['title'] as String? ?? 'Unknown')
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
