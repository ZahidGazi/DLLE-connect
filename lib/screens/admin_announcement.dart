import 'package:flutter/material.dart';
import 'data_service.dart';

class AnnouncementScreens extends StatefulWidget {
  const AnnouncementScreens({super.key});

  @override
  State<AnnouncementScreens> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreens> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  // Dummy past announcements
  final List<Map<String, String>> pastAnnouncements = [
    {
      "title": "fgf",
      "date": "2024-07-25",
      "image": "https://via.placeholder.com/400x200"
    },
    {
      "title": "New Course Offering: Data Science",
      "date": "2024-07-20",
      "image": "https://via.placeholder.com/400x200"
    },
  ];

  // ---------------- DATE PICKER ----------------
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcements = DataService.instance.announcements;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            // ---------------- NEW ANNOUNCEMENT ----------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2933),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "New Announcement",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: inputDecoration("Title"),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: inputDecoration("Message"),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const Icon(Icons.calendar_today,
                              color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isEmpty ||
                              messageController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          DataService.instance.addAnnouncement(
                            titleController.text,
                            messageController.text,
                            "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                          );

                          titleController.clear();
                          messageController.clear();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Announcement posted")),
                          );

                          setState(() {});
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Post Announcement",
                        style: TextStyle(fontSize: 16,color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ---------------- PAST ANNOUNCEMENTS ----------------

            const Text(
              "Past Announcements",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final item = announcements[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2933),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.date,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.message,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- INPUT DECORATION ----------------
  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF0D1117),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
