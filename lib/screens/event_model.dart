class EventItem {
  String title;
  String date;
  String Location;
  int hours;
  String description;

  bool joined;
  bool completed;
  int joinedcount;
  int completedcount;

  DateTime? completedAt;
  double? latitude;
  double? longitude;

  EventItem({
    required this.title,
    required this.date,
    required this.Location,
    required this.hours,
    required this.description,
    this.joined = false,
    this.completed = false,
    this.completedAt,
    this.latitude,
    this.longitude,
    this.joinedcount = 0,
    this.completedcount = 0,
  });
}
class Student {
  final String name;
  final String id;
  final String department;
  int totalHours;
  List<String>joinedEvents;
  List<String>completedEvents;


  Student({
    required this.name,
    required this.id,
    required this.department,
    this.totalHours = 0,
    List<String>? joinedEvents,
    List<String> ?completedEvents,
  })
      : joinedEvents = joinedEvents ?? [],
        completedEvents = completedEvents ?? [];

}

