import 'package:flutter/material.dart';
import 'data_service.dart';
import 'edit_event.dart';
import 'event_model.dart';
import 'joined_stu_screen.dart';

class AdminEventDetailsScreen extends StatelessWidget {
  final EventItem event;

  const AdminEventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final joinedStudents =
    DataService.instance.getStudentsJoinedEvent(event);
    final completedStudents =
    DataService.instance.getStudentsCompletedEvent(event);

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

            // -------- EVENT TITLE --------
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "📍 ${event.Location}",
              style: const TextStyle(color: Colors.white70),
            ),

            Text(
              "📅 ${event.date}",
              style: const TextStyle(color: Colors.white70),
            ),

            Text(
              "⏱ ${event.hours} Hours",
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
              event.description,
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 20),

            // -------- ANALYTICS --------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                analyticsButton(
                  context: context,
                  icon: Icons.group,
                  label: "Joined",
                  value: event.joinedcount.toString(),
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventStudentsScreen(
                          title: "Students Joined",
                          students: joinedStudents,
                        ),
                      ),
                    );
                  },
                ),

                analyticsButton(
                  context: context,
                  icon: Icons.check_circle,
                  label: "Completed",
                  value: event.completedcount.toString(),
                  color: Colors.greenAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventStudentsScreen(
                          title: "Students Completed",
                          students: completedStudents,
                        ),
                      ),
                    );
                  },
                ),

                analyticsCard(
                  icon: Icons.timer,
                  label: "Total Hours",
                  value:
                  (event.completedcount * event.hours).toString(),
                  color: Colors.blueAccent,
                ),
              ],
            ),

            if (event.completed)
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

            // -------- EDIT BUTTON --------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit Event"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  event.completed ? Colors.grey : Colors.orange,
                ),
                onPressed: event.completed
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditEventScreen(event: event),
                    ),
                  ).then((_) => Navigator.pop(context));
                },
              ),
            ),

            const SizedBox(height: 12),

            // -------- DELETE BUTTON --------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text("Delete Event"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  event.completed ? Colors.grey : Colors.redAccent,
                ),
                onPressed: event.completed
                    ? null
                    : () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor:
                      const Color(0xFF1F2933),
                      title: const Text(
                        "Delete Event",
                        style:
                        TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Are you sure you want to delete this event?",
                        style: TextStyle(
                            color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            DataService.instance
                                .deleteEvent(event);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(
                                color: Colors.redAccent),
                          ),
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

  // -------- ANALYTICS BUTTON --------
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
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // -------- ANALYTICS CARD --------
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
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
