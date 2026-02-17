import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event_model.dart';
import 'notification_model.dart';
import 'user_model.dart';
import 'announcement_model.dart';

class DataService {
  // ---------------- SINGLETON ----------------
  DataService._privateConstructor();
  static final DataService instance = DataService._privateConstructor();
  // ---------------- THEME NOTIFIER (NEW) ----------------
  // This notifies main.dart when the theme changes
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    // Save to preferences logic can go here
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

  Future<void> login(String name, String id) async {
    studentName = name;
    studentId = id;
    isLoggedIn = true;
   await saveLoginSession(id);
  }

  Future<void> logout() async {
    isLoggedIn = false;
    studentName = "";
    studentId = "";
    await clearLoginSession();
  }

  // ---------------- PASSWORD ----------------
  String adminPassword = "admin123"; // default password

  bool changeAdminPassword(String oldPass, String newPass) {
    if (oldPass != adminPassword) {
      return false;
    }
    adminPassword = newPass;
    return true;
  }

  //----------------Admin profile-----------------------
  String adminName = "";

  void updateAdminProfile(String name, String gmail) {
    adminName = name;
  }

  // ---------------- EVENTS ----------------
  final List<EventItem> _events = [
    EventItem(
      title: "Tree Plantation Drive",
      date: "25 July 2026",
      hours: 5,
      eventdate: DateTime (2026,7,25),
      description: "Planting trees to improve environment.",
      Location: "Mumbai, Maharashtra, India",
      starttime: "10:00 AM",
      endtime: "2:00 PM",
      imagepath: "",
      latitude: 19.0760,
      longitude: 72.8777,
    ),
    EventItem(
      title: "Beach Cleanup",
      date: "15 February 2026",
      eventdate: DateTime (2026,2,15),
      hours: 4,
      description: "Cleaning and maintaining the beach.",
      Location: "Versova",
      starttime: "9:00 AM",
      endtime: "11:00 AM",
      imagepath: "",
      latitude: 19.0980,
      longitude: 72.8300,
    ),
    EventItem(
      title: "Blood Donation Camp",
      date: "15 June 2026",
      eventdate: DateTime (2026,6,15),
      hours: 10,
      description: "Donate blood and save lives.",
      Location: "GSCC",
      starttime: "10:00 AM",
      endtime: "2:00 PM",
      imagepath: "",
      latitude: 19.0500,
      longitude: 72.9000,
    ),
  ];
  bool canJoinEvent(EventItem event) {
    final today = DateTime.now();
    return today.isBefore(event.eventdate);
  }

  List<EventItem> get events => _events;

  void addEvent(EventItem event) {
    _events.insert(0, event);
    addNotification("New Event Added", event.title);
  }

  void updateEvent(EventItem oldEvent, EventItem updatedEvent) {
    final index = _events.indexOf(oldEvent);
    if (index != -1) _events[index] = updatedEvent;
  }

  void deleteEvent(EventItem event) {
    _events.remove(event);
  }

  // ---------------- EVENT ACTIONS ----------------
  void joinEvent(EventItem event, String studentId) {
    final student = students.firstWhere((s) => s.id == studentId);

    if (!student.joinedEvents.contains(event.title)) {
      student.joinedEvents.add(event.title);
      event.joined = true;
      event.joinedcount++;
      saveStudents();

      addNotification("Event Joined", event.title);
    }
  }

  void completeEvent(EventItem event, String studentId) {
    final student = students.firstWhere((s) => s.id == studentId);

    if (!student.completedEvents.contains(event.title)) {
      student.completedEvents.add(event.title);
      student.totalHours += event.hours;
      saveStudents();

      event.completed = true;
      event.completedcount++;

      addNotification("Event Completed", event.title);
    }
  }

  void uploadProofForEvent(EventItem event, String studentId) {
    completeEvent(event, studentId);
  }

  // ---------------- DASHBOARD ----------------
  int get totalHours {
    final student =
    students.firstWhere((s) => s.id == studentId, orElse: () => students[0]);
    return student.totalHours;
  }

  int get completedEventsCount =>
      _events.where((e) => e.completed).length;

  List<EventItem> get joinedEvents =>
      _events.where((e) => e.joined && !e.completed).toList();

  List<EventItem> get completedEvents =>
      _events.where((e) => e.completed).toList();

  // ---------------- NOTIFICATIONS ----------------
  List<AppNotification> notifications = [];

  void addNotification(String title, String message) {
    notifications.insert(
      0,
      AppNotification(
        title: title,
        message: message,
        time: DateTime.now(),
      ),
    );
  }

  // ---------------- ANNOUNCEMENTS ----------------
  final List<Announcement> _announcements = [];

  List<Announcement> get announcements => _announcements;

  void addAnnouncement(String title, String message, String date) {
    _announcements.insert(
      0,
      Announcement(title: title, message: message, date: date),
    );
    saveAnnouncements();

    addNotification("Announcement", title);
  }
  Future<void> saveAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _announcements.map((a) => {
      'title': a.title,
      'message': a.message,
      'date': a.date,
    }).toList();

    prefs.setString('announcements', jsonEncode(data));
  }

  Future<void> loadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('announcements');

    if (data == null) return;

    final decoded = jsonDecode(data) as List;

    _announcements.clear();
    _announcements.addAll(
      decoded.map((e) => Announcement(
        title: e['title'],
        message: e['message'],
        date: e['date'],
      )),
    );
  }


  // ---------------- STUDENTS ----------------
  List<Student> students = [
    Student(name: "Aarav Patel", id: "20210001", department: "BCOM"),
    Student(name: "Diya Sharma", id: "20220002", department: "BMS"),
    Student(name: "Rohan Gupta", id: "20230003", department: "BBA"),
    Student(name: "Priya Singh", id: "20210004", department: "B.Sc IT"),
    Student(name: "Vikram Verma", id: "20220005", department: "BCOM"),
  ];

  List<Student> getAllStudents() => students;

  List<Student> getStudentsJoinedEvent(EventItem event) {
    return students
        .where((s) => s.joinedEvents.contains(event.title))
        .toList();
  }

  List<Student> getStudentsCompletedEvent(EventItem event) {
    return students
        .where((s) => s.completedEvents.contains(event.title))
        .toList();
  }
  Future<void> saveStudents() async {
    final prefs = await SharedPreferences.getInstance();

    final data = students.map((s) => {
      'name': s.name,
      'id': s.id,
      'department': s.department,
      'totalHours': s.totalHours,
      'joinedEvents': s.joinedEvents,
      'completedEvents': s.completedEvents,
    }).toList();

    prefs.setString('students', jsonEncode(data));
  }
  Future<void> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('students');

    if (data == null) return;

    final decoded = jsonDecode(data) as List;

    students = decoded.map((e) => Student(
      name: e['name'],
      id: e['id'],
      department: e['department'],
      totalHours: e['totalHours'],
      joinedEvents: List<String>.from(e['joinedEvents']),
      completedEvents: List<String>.from(e['completedEvents']),
    )).toList();
  }
  // -------- PROFILE DATA --------
  String stuName = ""; // Default
  String stuId = "";
  String studentCourse = "";
  void updateProfile({
    required String name,
    required String id,
    required String course,
  }) {
    stuName = name;
    stuId = id;
    studentCourse = course;
  }
  bool notificationEnabled = true;
  //bool darkModeEnabled = true;

}
