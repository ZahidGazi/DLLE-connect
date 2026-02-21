import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Student student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Future<void> _deleteStudent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2933),
        title: const Text("Remove Student", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to remove ${widget.student.fullName} from the system? This will also delete their event registrations.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
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
          Navigator.pop(context, true); // Return true to indicate deletion
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
    // We use the full events list from DataService to show details
    final allEvents = DataService.instance.events;
    
    final joinedEvents = allEvents
        .where((e) => widget.student.joinedEvents.contains(e.title) && !widget.student.completedEvents.contains(e.title))
        .toList();

    final completedEvents = allEvents
        .where((e) => widget.student.completedEvents.contains(e.title))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: const Text("Student Details"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------------- PROFILE CARD ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2933),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: ${widget.student.identifier}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          widget.student.department,
                          style: const TextStyle(color: Colors.white70),
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
                color: const Color(0xFF1F2933),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total DLLE Hours",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.blueAccent),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.student.totalHours}",
                        style: const TextStyle(
                          color: Colors.white,
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
            sectionTitle("Joined Events (Ongoing)"),
            joinedEvents.isEmpty
                ? emptyText("No ongoing joined events")
                : Column(
              children: joinedEvents
                  .map((e) => eventTile(
                icon: Icons.schedule,
                iconColor: Colors.orangeAccent,
                title: e.title,
                subtitle: e.date,
                status: "Ongoing",
              ))
                  .toList(),
            ),

            const SizedBox(height: 24),

            // ---------------- COMPLETED EVENTS ----------------
            sectionTitle("Completed Events"),
            completedEvents.isEmpty
                ? emptyText("No completed events")
                : Column(
              children: completedEvents
                  .map((e) => eventTile(
                icon: Icons.check_circle,
                iconColor: Colors.greenAccent,
                title: e.title,
                subtitle: "${e.date}  •  ${e.hours} hrs",
                status: "Completed",
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget eventTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }
}
