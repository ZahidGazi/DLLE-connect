import 'package:flutter/material.dart';
import 'data_service.dart';     // correct path
import 'event_details.dart';        // correct file import

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  Widget build(BuildContext context) {
    final events = DataService.instance.events;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: const Text("Events"),
        backgroundColor: const Color(0xFF0D1117),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final e = events[index];

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
                // Title
                Text(
                  e.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Details
                Text("Date: ${e.date}",
                    style: const TextStyle(color: Colors.white70)),
                Text("Hours: ${e.hours}",
                    style: const TextStyle(color: Colors.white70)),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // JOIN BUTTON
                    ElevatedButton(
                      onPressed: e.joined
                          ? null
                          : () {
                        setState(() {
                          e.joined = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        e.joined ? Colors.grey : Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        e.joined ? "Joined" : "Join",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    // VIEW DETAILS BUTTON
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailsScreen(event: e),
                          ),
                        );
                      },
                      child: const Text(
                        "View Details",
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 14,
                        ),
                      ),
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
