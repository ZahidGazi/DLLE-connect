import 'package:flutter/material.dart';
import 'event_model.dart';

class EventStudentsScreen extends StatelessWidget {
  final String title;
  final List<Student> students;

  const EventStudentsScreen({
    super.key,
    required this.title,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final cardColor = Theme.of(context).cardTheme.color ?? const Color(0xFF1F2933);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: students.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: subTextColor.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    "No students found",
                    style: TextStyle(color: subTextColor),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final s = students[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Text(
                          s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : "?",
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.fullName,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ID: ${s.identifier}",
                              style: TextStyle(color: subTextColor),
                            ),
                            if (s.department.isNotEmpty)
                              Text(
                                s.department,
                                style: TextStyle(color: subTextColor, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
