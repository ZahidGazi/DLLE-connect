import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'dashboard_screen.dart';
import 'events_screen.dart';
import 'announcement_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventItem event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  int currentIndex = 2; // Events selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: const Text("Event Details"), // ✅ WHITE via theme
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE PLACEHOLDER
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2933),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.image, size: 60, color: Colors.white38),
            ),

            const SizedBox(height: 20),

            Text(
              widget.event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(widget.event.date,
                    style: const TextStyle(color: Colors.white)),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text("${widget.event.hours} Hours",
                    style: const TextStyle(color: Colors.white)),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Description",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.event.description,
              style: const TextStyle(color: Colors.white),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.event.joined
                    ? null
                    : () {
                  DataService.instance.joinedEvents;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("You joined ${widget.event.title}"),
                      ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  widget.event.joined ? Colors.grey : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.event.joined
                      ? "Already Joined"
                      : "Join Event",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),



    );
  }

  // ✅ FIXED NAV ITEM (WHITE TEXT & ICON)
  Widget navItem(
      IconData icon, String label, int index, VoidCallback onTap) {
    bool selected = currentIndex == index;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selected ? Colors.blueAccent : Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.blueAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
