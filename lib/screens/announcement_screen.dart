import 'package:flutter/material.dart';
import 'data_service.dart';

class StudentAnnouncementScreen extends StatefulWidget {
  const StudentAnnouncementScreen({super.key});

  @override
  State<StudentAnnouncementScreen> createState() =>
      _StudentAnnouncementScreenState();
}

class _StudentAnnouncementScreenState
    extends State<StudentAnnouncementScreen> {
  @override
void initstate (){
    super.initState();
    if (DataService.instance.notifications.isNotEmpty) {
      final latest = DataService.instance.notifications.first;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${latest.title}: ${latest.message}",
            ),
            backgroundColor: Colors.blueGrey,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcements = DataService.instance.announcements;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: const Text("Announcements"),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        centerTitle: true,
      ),

      body: announcements.isEmpty
          ? const Center(
        child: Text(
          "No announcements available",
          style: TextStyle(color: Colors.white54),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final item = announcements[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2933),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // -------- TITLE --------
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // -------- DATE --------
                Text(
                  item.date,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 10),

                // -------- MESSAGE --------
                Text(
                  item.message,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
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
