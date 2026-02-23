import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_details.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isLoading = false;

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await DataService.instance.fetchEvents();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = DataService.instance.events;

    final cardColor = Theme.of(context).cardTheme.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Events")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).primaryColor,
              backgroundColor: cardColor,
              child: events.isEmpty
                  ? ListView(
                      // Wrap in ListView so RefreshIndicator works even when empty
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: 64, color: subTextColor.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "No events available",
                                  style: TextStyle(color: subTextColor, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Pull down to refresh",
                                  style: TextStyle(color: subTextColor.withOpacity(0.6), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];

                        // Determine status
                        String statusText = "Open";
                        Color statusColor = Colors.blueAccent;
                        IconData statusIcon = Icons.event_available;

                        if (event.completed) {
                          statusText = "Completed";
                          statusColor = Colors.greenAccent;
                          statusIcon = Icons.check_circle;
                        } else if (event.joined) {
                          statusText = "Joined";
                          statusColor = Colors.orangeAccent;
                          statusIcon = Icons.how_to_reg;
                        } else if (!DataService.instance.canJoinEvent(event)) {
                          statusText = "Expired";
                          statusColor = Colors.redAccent;
                          statusIcon = Icons.event_busy;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailsScreen(event: event),
                              ),
                            ).then((_) => setState(() {}));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isDarkMode
                                  ? []
                                  : [
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // -------- TITLE + STATUS ROW --------
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          event.title,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor.withOpacity(0.4)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(statusIcon, size: 14, color: statusColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // -------- DATE --------
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: subTextColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        event.date,
                                        style: TextStyle(color: subTextColor, fontSize: 13),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // -------- LOCATION --------
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: subTextColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          event.location,
                                          style: TextStyle(color: subTextColor, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // -------- HOURS --------
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 14, color: subTextColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${event.hours} Hours",
                                        style: TextStyle(color: subTextColor, fontSize: 13),
                                      ),
                                      const Spacer(),
                                      // VIEW DETAILS
                                      Text(
                                        "View Details →",
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
