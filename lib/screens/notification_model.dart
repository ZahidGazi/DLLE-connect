class AppNotification {
  final String title;
  final String message;
  final DateTime time;
  /// The announcement ID this notification was generated from.
  /// Used to persist dismissals across app restarts.
  final String? announcementId;

  AppNotification({
    required this.title,
    required this.message,
    required this.time,
    this.announcementId,
  });
}
