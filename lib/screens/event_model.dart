import 'dart:convert';

class EventItem {
  String? id;
  String title;
  String date;
  final DateTime eventdate;
  String location;
  int hours;
  String description;
  final String starttime;
  final String endtime;
  String? imagepath;

  bool joined;
  bool completed;
  int joinedcount;
  int completedcount;

  DateTime? completedAt;
  DateTime? eventExpiryDate;
  final double latitude;
  final double longitude;

  /// Targeting: null or empty list means visible to all courses.
  /// Supports multiple courses (e.g. ["BCOM", "BSc.IT"]).
  List<String>? targetCourses;

  /// Targeting: null means visible to all years within the target courses.
  int? targetYear;

  EventItem({
    this.id,
    required this.title,
    required this.date,
    required this.eventdate,
    required this.location,
    required this.hours,
    required this.description,
    required this.starttime,
    required this.endtime,
    this.imagepath,
    this.joined = false,
    this.completed = false,
    this.completedAt,
    this.eventExpiryDate,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.joinedcount = 0,
    this.completedcount = 0,
    this.targetCourses,
    this.targetYear,
  });

  /// Parses the `target_course` DB column into a `List<String>`.
  /// Handles three cases:
  ///   1. null / empty → null (visible to everyone)
  ///   2. JSON array string → ["BCOM","BSc.IT"]  (new multi-select format)
  ///   3. Plain string → ["BCOM"]  (backward compat with old single-course data)
  static List<String>? _parseTargetCourses(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    // Try JSON array first
    try {
      final decoded = jsonDecode(str);
      if (decoded is List) {
        final list = decoded.whereType<String>().toList();
        return list.isEmpty ? null : list;
      }
    } catch (_) {}
    // Fallback: treat as a single plain-string course (old data)
    return [str];
  }

  factory EventItem.fromMap(Map<String, dynamic> map) {
    return EventItem(
      id: map['id'],
      title: map['title'],
      date: map['date_str'] ?? '',
      eventdate: DateTime.parse(map['event_date']),
      location: map['location'] ?? '',
      hours: map['hours'] ?? 0,
      description: map['description'] ?? '',
      starttime: map['start_time'] ?? '',
      endtime: map['end_time'] ?? '',
      imagepath: map['image_path'],
      eventExpiryDate: map['event_expiry_date'] != null
          ? DateTime.tryParse(map['event_expiry_date'].toString())
          : null,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      targetCourses: _parseTargetCourses(map['target_course']),
      targetYear: map['target_year'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date_str': date,
      'event_date': eventdate.toIso8601String(),
      'location': location,
      'hours': hours,
      'description': description,
      'start_time': starttime,
      'end_time': endtime,
      'image_path': imagepath,
      'event_expiry_date': eventExpiryDate?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      // Store as JSON array string, or null when targeting everyone
      'target_course': (targetCourses == null || targetCourses!.isEmpty)
          ? null
          : jsonEncode(targetCourses),
      'target_year': targetYear,
    };
  }
}

class Student {
  final String fullName;
  final String identifier;
  final String department;
  final int yearOfStudy;
  int totalHours; // This will be calculated on the fly
  List<String> joinedEvents;
  List<String> completedEvents;

  // Add getters for backward compatibility with older code using .name and .id
  String get name => fullName;
  String get id => identifier;

  Student({
    required this.fullName,
    required this.identifier,
    required this.department,
    this.yearOfStudy = 1,
    this.totalHours = 0,
    List<String>? joinedEvents,
    List<String>? completedEvents,
  })  : joinedEvents = joinedEvents ?? [],
        completedEvents = completedEvents ?? [];

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      fullName: map['full_name'] ?? 'No Name',
      identifier: map['identifier'] ?? 'No ID',
      department: map['department'] ?? 'No Department',
      yearOfStudy: map['year_of_study'] ?? 1,
      // totalHours is now calculated in DataService.getAllStudents
    );
  }
}
