class EventItem {
  String title;
  String date;
  final DateTime eventdate;
  String Location;
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
    required this.title,
    required this.date,
    required this.eventdate,
    required this.Location,
    required this.hours,
    required this.description,
    required this.starttime,
    required this.endtime,
    this.imagepath,
    this.joined = false,
    this.completed = false,
    this.completedAt,
    this.latitude=0.0,
    this.longitude=0.0,
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

