import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/data_service.dart';

/// Service for managing both in-app and local (system) notifications.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static int _notificationId = 0;

  /// Initialize the local notifications plugin. Call once at app startup.
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  /// Request notification permission on Android 13+.
  static Future<void> requestPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Handle notification tap (when user taps the system notification).
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
    // The app will open automatically; the notification screen can be navigated to
    // from the main UI via the bell icon.
  }

  /// Show an Android system notification AND add to in-app notification list.
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    // Add to in-app notification list
    DataService.instance.addNotification(title, body);

    // Show system notification only if initialized
    if (!_initialized) {
      debugPrint('[NotificationService] Not initialized, skipping system notification');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'dlle_announcements', // channel id
        'Announcements', // channel name
        channelDescription: 'Notifications for new announcements and events',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        _notificationId++,
        title,
        body,
        details,
        payload: title,
      );
    } catch (e) {
      debugPrint('[NotificationService] Error showing notification: $e');
    }
  }

  /// Add to in-app list only (no system notification).
  static void notify(String title, String message) {
    DataService.instance.addNotification(title, message);
  }

  static void clearAll() {
    DataService.instance.notifications.clear();
  }

  static int get unreadCount => DataService.instance.notifications.length;
}
