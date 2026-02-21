import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'events_screen.dart';
import 'event_details.dart';
import 'announcement_screen.dart';
import 'upload_screen.dart';
import 'setting_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0; // Default to Dashboard (Index 0)

  // ✅ PAGE ORDER:
  // 0: DashboardHomeContent
  // 1: StudentAnnouncementScreen
  // 2: EventsScreen
  // 3: UploadScreen
  // 4: StudentSettingsScreen
  final List<Widget> _pages = [
    const DashboardHomeContent(),
    const StudentAnnouncementScreen(),
    const EventsScreen(),
    const UploadScreen(),
    const StudentSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).bottomNavigationBarTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // This switches the main content
      body: _pages[_currentIndex],

      // This is the ONLY Navigation Bar in the app
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: navTheme.backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home, "Dashboard", 0),
            navItem(Icons.campaign, "Announcement", 1),
            navItem(Icons.calendar_today, "Events", 2),
            navItem(Icons.upload, "Upload", 3),
            navItem(Icons.settings, "Settings", 4),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    final color = selected ? Colors.blueAccent : Colors.black;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.blueAccent : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... (Keep the DashboardHomeContent class below as it was in previous code)
class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}
// ... (Paste the rest of DashboardHomeContent logic here)
class _DashboardHomeContentState extends State<DashboardHomeContent> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await DataService.instance.fetchEvents();
    await DataService.instance.fetchAnnouncements();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // -------- DATA PROCESSING FOR GRAPH --------
  Map<String, int> getMonthlyJoinedData() {
    final joinedEvents = DataService.instance.joinedEvents;
    Map<String, int> monthlyCounts = {};

    for (var event in joinedEvents) {
      try {
        List<String> parts = event.date.split(' ');
        if (parts.length >= 2) {
          String month = parts[1].substring(0, 3);
          monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint("Error parsing date: ${event.date}");
      }
    }
    return monthlyCounts;
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  // -------- NAVIGATION HELPER --------
  void _navigateToEventList(String title, List<EventItem> events) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventListScreen(title: title, events: events),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Dashboard"),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = DataService.instance;
    final joinedEvents = data.joinedEvents;
    final completedEvents = data.completedEvents;
    final totalHours = completedEvents.fold<int>(0, (sum, e) => sum + e.hours);

    final monthlyData = getMonthlyJoinedData();
    final List<String> monthOrder = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // AppBar is here so it only shows on the "Dashboard" tab
      appBar: AppBar(
        title: const Text("Dashboard"),
        automaticallyImplyLeading: false,
      ),

      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).cardTheme.color,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // -------- PROFILE CARD --------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            data.studentName.isEmpty ? "Student Name" : data.studentName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text("ID: ${data.studentId.isEmpty ? "Unknown" : data.studentId}",
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text("Course: ${data.studentCourse.isEmpty ? "Unknown" : data.studentCourse}",
                            style: Theme.of(context).textTheme.bodyMedium),
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
                          totalHours.toString(),
                          "Total Hours",
                          Icons.access_time,
                          Colors.blueAccent
                      )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: statCard(
                          completedEvents.length.toString(),
                          "Events Completed",
                          Icons.check_circle,
                          Colors.greenAccent
                      )),
                ],
              ),

              const SizedBox(height: 20),

              // -------- MONTHLY GRAPH --------
              Text(
                "Monthly Joined Events",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: 180,
                  child: monthlyData.isEmpty
                      ? const Center(
                    child: Text(
                      "No events joined yet",
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: monthOrder.map((month) {
                      if (!monthlyData.containsKey(month)) return const SizedBox.shrink();

                      int count = monthlyData[month] ?? 0;
                      int maxCount = monthlyData.values.reduce((a, b) => a > b ? a : b);
                      double barHeight = (count / (maxCount == 0 ? 1 : maxCount)) * 120;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            count.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 20,
                            height: barHeight < 10 ? 10 : barHeight,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            month,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // -------- JOINED EVENTS SECTION --------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Joined Events",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => _navigateToEventList("Joined Events", joinedEvents),
                    child: const Text("View All", style: TextStyle(color: Colors.indigo)),
                  ),
                ],
              ),

              if (joinedEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No joined events"),
                  ),
                ),

              for (var e in joinedEvents.take(3))
                eventTile(e),

              const SizedBox(height: 10),

              // -------- COMPLETED EVENTS SECTION --------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Activity Completed",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => _navigateToEventList("Completed Events", completedEvents),
                    child: const Text("View All", style: TextStyle(color: Colors.indigo)),
                  ),
                ],
              ),

              if (completedEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No completed events"),
                  ),
                ),

              for (var e in completedEvents.take(3))
                completedTile(e),
            ],
          ),
        ),
      ),
    );
  }

  Widget statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget eventTile(EventItem event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(event.date,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
          ],
        ),
      ),
    );
  }

  Widget completedTile(EventItem event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(event.date,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            Text("+${event.hours} Hours",
                style: const TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
//      VIEW ALL SCREEN (INTERNAL)
// ==========================================
class EventListScreen extends StatelessWidget {
  final String title;
  final List<EventItem> events;

  const EventListScreen({
    super.key,
    required this.title,
    required this.events
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: events.isEmpty
          ? const Center(child: Text("No events found", style: TextStyle(color: Colors.white54)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(event.date, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  if (event.completed)
                    Text("+${event.hours} Hrs", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))
                  else
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
