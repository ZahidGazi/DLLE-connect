import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import '../utils/responsive_helper.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Student student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Future<void> _deleteStudent() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text("Remove Student",
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text(
          "Are you sure you want to remove ${widget.student.fullName} from the system? "
          "This will also delete their event registrations.",
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DataService.instance.deleteStudent(widget.student.identifier);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student removed successfully")),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;
    final subTextColor = theme.textTheme.bodyMedium?.color;

    final allEvents = DataService.instance.events;

    final joinedEvents = allEvents
        .where((e) =>
            widget.student.joinedEvents.contains(e.title) &&
            !widget.student.completedEvents.contains(e.title))
        .toList();

    final completedEvents = allEvents
        .where((e) => widget.student.completedEvents.contains(e.title))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Student Details"),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ResponsiveHelper.maxFormWidth(context)),
        child: SingleChildScrollView(
        padding: ResponsiveHelper.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- PROFILE CARD ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.fullName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: ${widget.student.identifier}",
                          style: TextStyle(color: subTextColor),
                        ),
                        Text(
                          widget.student.department,
                          style: TextStyle(color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- TOTAL HOURS ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total DLLE Hours",
                    style: TextStyle(color: subTextColor, fontSize: 16),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.blueAccent),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.student.totalHours}",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- JOINED EVENTS ----------------
            _sectionTitle("Joined Events (Ongoing)", textColor),
            joinedEvents.isEmpty
                ? _emptyText("No ongoing joined events", subTextColor)
                : Column(
                    children: joinedEvents
                        .map((e) => _eventTile(
                              icon: Icons.schedule,
                              iconColor: Colors.orangeAccent,
                              title: e.title,
                              subtitle: e.date,
                              status: "Ongoing",
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ))
                        .toList(),
                  ),

            const SizedBox(height: 24),

            // ---------------- COMPLETED EVENTS ----------------
            _sectionTitle("Completed Events", textColor),
            completedEvents.isEmpty
                ? _emptyText("No completed events", subTextColor)
                : Column(
                    children: completedEvents
                        .map((e) => _eventTile(
                              icon: Icons.check_circle,
                              iconColor: Colors.greenAccent,
                              title: e.title,
                              subtitle: "${e.date}  •  ${e.hours} hrs",
                              status: "Completed",
                              cardColor: cardColor,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ))
                        .toList(),
                  ),

            const SizedBox(height: 40),

            // ---------------- REMOVE BUTTON ----------------
            Center(
              child: ElevatedButton.icon(
                onPressed: _deleteStudent,
                icon: const Icon(Icons.delete),
                label: const Text("Remove Student from DLLE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _eventTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String status,
    required Color? cardColor,
    required Color? textColor,
    required Color? subTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: subTextColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == "Completed"
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == "Completed"
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String text, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
