import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'event_details.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  Widget build(BuildContext context) {
    final events = DataService.instance.events;

    // ✅ Get Theme Colors
    final cardColor = Theme.of(context).cardTheme.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
       appBar: AppBar(title: const Text("Events")),

      body: events.isEmpty
          ? Center(
        child: Text(
          "No events available",
          style: TextStyle(color: subTextColor),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(event: event),
                ),
              ).then((_) => setState(() {})); // Refresh on back
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                // ✅ DYNAMIC COLOR: Changes based on mode
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                // Add shadow ONLY in light mode for depth
                boxShadow: isDarkMode ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: isDarkMode
                    ? Border.all(color: Colors.white10)
                    : Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- CONTENT SECTION --------
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            color: textColor, // Dynamic Text Color
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // VIEW DETAILS BUTTON
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailsScreen(event: event),
                                  ),
                                );
                              },
                              child: const Text(
                                "View Details",
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                      ],
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