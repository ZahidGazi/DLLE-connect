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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(title: Text(title)),

      body: students.isEmpty
          ? const Center(
        child: Text(
          "No students found",
          style: TextStyle(color: Colors.white54),
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
              color: const Color(0xFF1F2933),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "ID: ${s.identifier}",
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
