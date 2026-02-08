import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'events_screen.dart';
import 'announcement_screen.dart';
import 'upload_screen.dart';
import 'setting_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final data = DataService.instance;

    final joinedEvents = data.joinedEvents;
    final completedEvents = data.completedEvents;

    final totalHours =
    completedEvents.fold<int>(0, (sum, e) => sum + e.hours);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        centerTitle: true,
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // -------- PROFILE CARD --------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2933),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ethan Carter",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("ID: 123456789",
                          style: TextStyle(color: Colors.white70)),
                      Text("B.Sc Computer Science",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // -------- STATS --------
            Row(
              children: [
                Expanded(
                    child: statCard(
                        totalHours.toString(), "Total Hours")),
                const SizedBox(width: 12),
                Expanded(
                    child: statCard(
                        completedEvents.length.toString(),
                        "Events Completed")),
              ],
            ),

            const SizedBox(height: 20),

            // -------- BAR GRAPH PLACEHOLDER --------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2933),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    "📊 Bar Chart Placeholder",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // -------- JOINED EVENTS --------
            const Text(
              "Joined Events",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (joinedEvents.isEmpty)
              const Text("No joined events",
                  style: TextStyle(color: Colors.white54)),

            for (var e in joinedEvents)
              eventTile(e.title, e.date),

            const SizedBox(height: 20),

            // -------- COMPLETED EVENTS --------
            const Text(
              "Activity Completed",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (completedEvents.isEmpty)
              const Text("No completed events",
                  style: TextStyle(color: Colors.white54)),

            for (var e in completedEvents)
              completedTile(e.title, e.date, "+${e.hours} Hours"),
          ],
        ),
      ),

      // ---------------- BOTTOM NAV ----------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: const Color(0xFF0D1117),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home, "Dashboard", 0, () {}),
            navItem(Icons.campaign, "Announce", 1, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentAnnouncementScreen()),
              );
            }),
            navItem(Icons.calendar_today, "Events", 2, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventsScreen()),
              );
            }),
            navItem(Icons.upload, "Upload", 3, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadScreen()),
              ).then((_) => setState(() {}));
            }),
            navItem(Icons.settings, "Settings", 4, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentSettingsScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget navItem(
      IconData icon, String label, int index, VoidCallback onTap) {
    final selected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => currentIndex = index);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: selected ? Colors.blueAccent : Colors.white),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color:
                  selected ? Colors.blueAccent : Colors.white,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget eventTile(String title, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14)),
              const SizedBox(height: 4),
              Text(date,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ],
          ),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  Widget completedTile(String title, String date, String hours) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14)),
              const SizedBox(height: 4),
              Text(date,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ],
          ),
          Text(hours,
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
