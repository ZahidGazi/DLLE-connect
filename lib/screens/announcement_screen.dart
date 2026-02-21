import 'package:flutter/material.dart';
import 'data_service.dart';
import 'announcement_model.dart';

class StudentAnnouncementScreen extends StatefulWidget {
  const StudentAnnouncementScreen({super.key});

  @override
  State<StudentAnnouncementScreen> createState() =>
      _StudentAnnouncementScreenState();
}

class _StudentAnnouncementScreenState
    extends State<StudentAnnouncementScreen> {
  @override
  void initState() {
    super.initState();
    _checkLatestNotification();
  }

  void _checkLatestNotification() {
    if (DataService.instance.notifications.isNotEmpty) {
      final latest = DataService.instance.notifications.first;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${latest.title}: ${latest.message}",
              ),
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcements = DataService.instance.announcements;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        elevation: 0,
        centerTitle: true,
      ),
      body: announcements.isEmpty
          ? const Center(
              child: Text(
                "No announcements available",
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final item = announcements[index];

                return GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C2237) : const Color(
                          0xFFD6DDE6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.black : Colors.black12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -------- TITLE --------
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // -------- DATE --------
                        Text(
                          item.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // -------- MESSAGE (PREVIEW) --------
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
