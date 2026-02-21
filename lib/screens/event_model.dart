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
  final double latitude;
  final double longitude;

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
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.joinedcount = 0,
    this.completedcount = 0,
  });

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
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
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
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Student {
  final String fullName;
  final String identifier;
  final String department;
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
      // totalHours is now calculated in DataService.getAllStudents
    );
  }
}
