import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:developer' as developer;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();

      // Set timezone to Malaysia (Asia/Kuala_Lumpur)
      final malaysiaTimeZone = tz.getLocation('Asia/Kuala_Lumpur');
      tz.setLocalLocation(malaysiaTimeZone);

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Request permission (Android 13+)
      final android_plugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (android_plugin != null) {
        await android_plugin.requestNotificationsPermission();
      }
    } catch (e) {
      developer.log('Error initializing notifications: $e');
    }
  }

  static void _handleNotificationTap(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}');
  }

  static Future<void> scheduleDailyNotifications() async {
    try {
      await _scheduleDaily(0, 20, 53, 'Morning Reminder', 'Good morning! Time to check in.');
      await _scheduleDaily(1, 13, 0, 'Afternoon Reminder', 'Afternoon check-in time!');
      await _scheduleDaily(2, 18, 0, 'Evening Reminder', 'Evening reminder — don\'t forget!');
    } catch (e) {
      developer.log('Error scheduling notifications: $e');
    }
  }

  static Future<void> _scheduleDaily(
      int id, int hour, int minute, String title, String body,
      ) async {
    try {
      final scheduledTime = _nextInstanceOfTime(hour, minute);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_channel', 'Daily Reminders',
            channelDescription: 'Daily nutrition reminders',
            importance: Importance.high,
            priority: Priority.high,
            ongoing: false,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      developer.log('Error scheduling notification $id: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    // Get Malaysia timezone
    final location = tz.getLocation('Asia/Kuala_Lumpur');
    final now = tz.TZDateTime.now(location);

    // Create scheduled time for today
    var scheduled = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);

    // If this time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // Test method - shows notification immediately
  static Future<void> showTestNotification() async {
    try {
      await _notifications.show(
        999,
        'Test Notification',
        'This notification should appear immediately!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      developer.log('Error showing test notification: $e');
    }
  }

  // Debug method - lists all pending notifications
  static Future<void> debugPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      for (var notif in pending) {
        developer.log('Pending: ID=${notif.id}, Title=${notif.title}');
      }
    } catch (e) {
      developer.log('Error getting pending notifications: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      developer.log('All notifications cancelled');
    } catch (e) {
      developer.log('Error cancelling notifications: $e');
    }
  }
}
