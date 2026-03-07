import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_details.dart';
import '../utils/responsive_helper.dart';

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
    // Filtering by course/year is already done inside DataService.fetchEvents()
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
              : _buildEventList(events, cardColor, textColor, subTextColor, isDarkMode),
            ),
    );
  }

  Widget _buildEventList(
    List events,
    Color? cardColor,
    Color textColor,
    Color subTextColor,
    bool isDarkMode,
  ) {
    final cols = ResponsiveHelper.listGridColumns(context);
    final padding = ResponsiveHelper.padding(context);

    if (cols == 1) {
      // Mobile: simple ListView
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: events.length,
        itemBuilder: (context, index) =>
            _eventCard(events[index], cardColor, textColor, subTextColor, isDarkMode),
      );
    }

    // Tablet / Desktop: GridView
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) =>
          _eventCard(events[index], cardColor, textColor, subTextColor, isDarkMode),
    );
  }

  Widget _eventCard(
    dynamic event,
    Color? cardColor,
    Color textColor,
    Color subTextColor,
    bool isDarkMode,
  ) {
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
        margin: const EdgeInsets.only(bottom: 12),
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
                        fontSize: ResponsiveHelper.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: ResponsiveHelper.fontSize(context, 11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // -------- DATE --------
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: subTextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.date,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: ResponsiveHelper.fontSize(context, 12),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // -------- LOCATION --------
              Row(
                children: [
                  Icon(Icons.location_on, size: 13, color: subTextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: ResponsiveHelper.fontSize(context, 12),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // -------- HOURS + VIEW DETAILS --------
              Row(
                children: [
                  Icon(Icons.timer, size: 13, color: subTextColor),
                  const SizedBox(width: 6),
                  Text(
                    "${event.hours} Hours",
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: ResponsiveHelper.fontSize(context, 12),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "View Details →",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: ResponsiveHelper.fontSize(context, 12),
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
  }
}
