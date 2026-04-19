import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
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

  static Future<void> scheduleDailyNotifications(String? userId) async {
    try {
      // If no userId provided, user is not logged in - skip notifications
      if (userId == null) {
        developer.log('User not logged in, skipping notification scheduling');
        return;
      }

      // Check which meals have NOT been logged today
      final missingMeals = await _getMissingMeals(userId);
      developer.log('Missing meals for user $userId: $missingMeals');

      if (missingMeals.isEmpty) {
        // All meals logged
        developer.log('User $userId has already logged all meals today, skipping notifications');
        return;
      }

      // Send notifications only for missing meals
      if (missingMeals.contains('breakfast')) {
        await _scheduleDaily(0, 21, 31, 'Breakfast Reminder', '🥣 Good morning! Don\'t forget your breakfast.');
      }

      if (missingMeals.contains('lunch')) {
        await _scheduleDaily(1, 21, 32, 'Lunch Reminder', '🍽️ Lunch time! Have you logged your meal yet?');
      }

      if (missingMeals.contains('dinner')) {
        await _scheduleDaily(2, 21, 33, 'Dinner Reminder', '🍖 Dinner time! Don\'t forget to log your meal.');
      }

      developer.log('Notifications scheduled for missing meals: $missingMeals');
    } catch (e) {
      developer.log('Error scheduling notifications: $e');
    }
  }

  static Future<List<String>> _getMissingMeals(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startOfDayIso = startOfDay.toIso8601String();
      final endOfDayIso = startOfDay.add(const Duration(days: 1)).toIso8601String();

      // Fetch all meals logged by user today
      final response = await Supabase.instance.client
          .from('MealLog')
          .select('meal_type')
          .eq('user_id', userId)
          .gte('meal_date', startOfDayIso)
          .lt('meal_date', endOfDayIso);

      // Extract meal types that were logged
      final loggedMealTypes = (response as List)
          .map((meal) => (meal['meal_type'] as String).toLowerCase())
          .toList();

      developer.log('Meals logged today for user $userId: $loggedMealTypes');

      // Define meals to track
      final mealsToTrack = ['breakfast', 'lunch', 'dinner'];

      // Find missing meals
      final missing = mealsToTrack
          .where((meal) => !loggedMealTypes.contains(meal))
          .toList();

      developer.log('Missing meals for user $userId: $missing');
      return missing;
    } catch (e) {
      developer.log('Error checking missing meals: $e');
      // Default to all meals if there's an error (pessimistic approach - send all notifications)
      return ['breakfast', 'lunch', 'dinner'];
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
