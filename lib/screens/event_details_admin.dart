import 'package:flutter/material.dart';
import 'data_service.dart';
import 'edit_event.dart';
import 'event_model.dart';
import 'joined_stu_screen.dart';

class AdminEventDetailsScreen extends StatefulWidget {
  final EventItem event;

  const AdminEventDetailsScreen({super.key, required this.event});

  @override
  State<AdminEventDetailsScreen> createState() => _AdminEventDetailsScreenState();
}

class _AdminEventDetailsScreenState extends State<AdminEventDetailsScreen> {
  List<Student> _joinedStudents = [];
  List<Student> _completedStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (widget.event.id == null) return;
    
    final joined = await DataService.instance.getStudentsJoinedEvent(widget.event.id!);
    final completed = await DataService.instance.getStudentsCompletedEvent(widget.event.id!);
    
    if (mounted) {
      setState(() {
        _joinedStudents = joined;
        _completedStudents = completed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Event Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "📍 ${widget.event.location}",
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              "📅 ${widget.event.date}",
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              "⏱ ${widget.event.hours} Hours",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              "Description",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.event.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                analyticsButton(
                  context: context,
                  icon: Icons.group,
                  label: "Joined",
                  value: _joinedStudents.length.toString(),
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventStudentsScreen(
                          title: "Students Joined",
                          students: _joinedStudents,
                        ),
                      ),
                    );
                  },
                ),
                analyticsButton(
                  context: context,
                  icon: Icons.check_circle,
                  label: "Completed",
                  value: _completedStudents.length.toString(),
                  color: Colors.greenAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventStudentsScreen(
                          title: "Students Completed",
                          students: _completedStudents,
                        ),
                      ),
                    );
                  },
                ),
                analyticsCard(
                  icon: Icons.timer,
                  label: "Total Hours",
                  value: (_completedStudents.length * widget.event.hours).toString(),
                  color: Colors.blueAccent,
                ),
              ],
            ),
            if (widget.event.completed)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  "This event is completed and cannot be modified.",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit Event"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.event.completed ? Colors.grey : Colors.orange,
                ),
                onPressed: widget.event.completed
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditEventScreen(event: widget.event),
                    ),
                  ).then((_) {
                    _loadStudents(); // Reload in case data changed
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text("Delete Event"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.event.completed ? Colors.grey : Colors.redAccent,
                ),
                onPressed: widget.event.completed
                    ? null
                    : () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF1F2933),
                      title: const Text("Delete Event", style: TextStyle(color: Colors.white)),
                      content: const Text("Are you sure you want to delete this event?", style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        TextButton(
                          onPressed: () {
                            if (widget.event.id != null) {
                              DataService.instance.deleteEvent(widget.event.id!);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget analyticsButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget analyticsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
