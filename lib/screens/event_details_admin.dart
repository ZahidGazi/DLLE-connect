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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final cardColor = Theme.of(context).cardTheme.color ?? const Color(0xFF1F2933);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // -------- INFO SECTION --------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.location_on, widget.event.location, textColor, subTextColor),
                  const SizedBox(height: 10),
                  _infoRow(Icons.calendar_today, widget.event.date, textColor, subTextColor),
                  const SizedBox(height: 10),
                  _infoRow(Icons.access_time, "${widget.event.starttime} - ${widget.event.endtime}", textColor, subTextColor),
                  const SizedBox(height: 10),
                  _infoRow(Icons.timer, "${widget.event.hours} Hours", textColor, subTextColor),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              "Description",
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.event.description,
              style: TextStyle(color: subTextColor, height: 1.5),
            ),
            const SizedBox(height: 20),

            // -------- ANALYTICS ROW --------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _analyticsButton(
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
                _analyticsButton(
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
                _analyticsCard(
                  icon: Icons.timer,
                  label: "Total Hours",
                  value: (_completedStudents.length * widget.event.hours).toString(),
                  color: Colors.blueAccent,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ],
            ),

            if (widget.event.completed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  "This event is completed and cannot be modified.",
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // -------- EDIT BUTTON --------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text("Edit Event", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.event.completed ? Colors.grey : Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          _loadStudents();
                        });
                      },
              ),
            ),
            const SizedBox(height: 12),

            // -------- DELETE BUTTON --------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("Delete Event", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.event.completed ? Colors.grey : Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: widget.event.completed
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: cardColor,
                            title: Text("Delete Event", style: TextStyle(color: textColor)),
                            content: Text(
                              "Are you sure you want to delete this event?",
                              style: TextStyle(color: subTextColor),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
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

  Widget _infoRow(IconData icon, String text, Color textColor, Color subTextColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _analyticsButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
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
          Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _analyticsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color subTextColor,
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
        Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
      ],
    );
  }
}
