import 'package:flutter/material.dart';
import 'data_service.dart';
import 'notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Load notifications from announcements, then clear the badge.
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    await DataService.instance.loadNotificationsFromAnnouncements();
    // Clear the badge count when the user opens the notification screen
    await DataService.instance.clearNotificationCount();
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  IconData _getNotificationIcon(String title) {
    if (title.contains("Announcement")) return Icons.campaign;
    if (title.contains("Event Joined")) return Icons.event_available;
    if (title.contains("Event Completed")) return Icons.check_circle;
    if (title.contains("New Event")) return Icons.event;
    return Icons.notifications;
  }

  Color _getNotificationColor(String title) {
    if (title.contains("Announcement")) return Colors.blueAccent;
    if (title.contains("Event Joined")) return Colors.orangeAccent;
    if (title.contains("Event Completed")) return Colors.greenAccent;
    if (title.contains("New Event")) return Colors.purpleAccent;
    return Colors.blueGrey;
  }

  Future<void> _dismissSingle(AppNotification n) async {
    if (n.announcementId != null) {
      await DataService.instance.dismissNotification(n.announcementId!);
    } else {
      DataService.instance.notifications.remove(n);
    }
    if (mounted) setState(() {});
  }

  Future<void> _clearAll() async {
    await DataService.instance.clearAllNotifications();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<AppNotification> notifications =
        DataService.instance.notifications;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text(
                "Clear All",
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 72,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No notifications yet",
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You'll be notified when new announcements\nor events are posted.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final iconColor = _getNotificationColor(n.title);

                    return Dismissible(
                      key: Key(n.announcementId ?? '${n.title}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                      ),
                      onDismissed: (_) => _dismissSingle(n),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1F2933)
                              : const Color(0xFFEEF2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon circle
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getNotificationIcon(n.title),
                                color: iconColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.message,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTime(n.time),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Individual delete button
                            GestureDetector(
                              onTap: () => _dismissSingle(n),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
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
