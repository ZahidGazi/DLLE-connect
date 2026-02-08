import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'event_model.dart';
import 'notification_model.dart';
import 'user_model.dart';
import 'announcement_model.dart';

class DataService {
  // ---------------- SINGLETON ----------------
  DataService._privateConstructor();
  static final DataService instance = DataService._privateConstructor();

  // ---------------- LOGIN / SESSION ----------------
  bool isLoggedIn = false;
  String studentName = "";
  String studentId = "";

  void login(String name, String id) {
    studentName = name;
    studentId = id;
    isLoggedIn = true;
  }

  void logout() {
    isLoggedIn = false;
    studentName = "";
    studentId = "";
  }

  // ---------------- EVENTS ----------------
  final List<EventItem> _events = [
    EventItem(
      title: "Tree Plantation Drive",
      date: "25 July 2024",
      hours: 5,
      description: "Planting trees to improve environment.",
      Location: "GSCC",
    ),
    EventItem(
      title: "Beach Cleanup",
      date: "10 August 2024",
      hours: 4,
      description: "Cleaning and maintaining the beach.",
      Location: "Versova",
    ),
    EventItem(
      title: "Blood Donation Camp",
      date: "15 June 2024",
      hours: 10,
      description: "Donate blood and save lives.",
      Location: "GSCC",
    ),
  ];

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

      addNotification("Event Joined", event.title);
    }
  }

  void completeEvent(EventItem event, String studentId) {
    final student = students.firstWhere((s) => s.id == studentId);

    if (!student.completedEvents.contains(event.title)) {
      student.completedEvents.add(event.title);
      student.totalHours += event.hours;

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
    addNotification("Announcement", title);
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
}
