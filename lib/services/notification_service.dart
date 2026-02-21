import '../screens/data_service.dart';

/// Service for managing in-app notifications.
/// This acts as a wrapper around DataService's notification methods
/// for cleaner separation of concerns.
class NotificationService {
  static void notify(String title, String message) {
    DataService.instance.addNotification(title, message);
  }

  static void clearAll() {
    DataService.instance.notifications.clear();
  }

  static int get unreadCount => DataService.instance.notifications.length;
}
