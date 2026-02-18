import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings macOSSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      macOS: macOSSettings,
    );

    try {
      final bool? initialized = await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      debugPrint('Notification Service Initialized: $initialized');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  static Future<void> showNotification(String title, String body) async {
    debugPrint('Attempting to show notification: $title - $body');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pomodoro_timer_channel_v4',
          'Pomodoro Timer Alerts',
          channelDescription: 'Important alerts for completion',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('smooth_notification'),
          playSound: true,
          ongoing: false,
          autoCancel: false,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
        );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      macOS: darwinDetails,
    );

    try {
      final int id = DateTime.now().millisecondsSinceEpoch % 100000;
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
      debugPrint('Notification sent successfully with ID: $id');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static Future<void> scheduleNotification(
    String title,
    String body,
    int seconds,
  ) async {
    if (seconds <= 0) return;

    debugPrint('Scheduling notification in $seconds seconds: $title');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pomodoro_timer_scheduled_v1',
          'Scheduled Timer Alerts',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      macOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: 0,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.now(
          tz.local,
        ).add(Duration(seconds: seconds)),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        notificationDetails: details,
      );
      debugPrint('Notification scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled');
  }

  static Future<void> sendTestNotification() async {
    debugPrint('Sending test notification...');
    await showNotification(
      'Test Notification 🔔',
      'If you see this, your notifications are working perfectly!',
    );
  }

  static Future<bool> requestPermissions() async {
    debugPrint('Requesting notification permissions...');

    bool granted = false;

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final bool? result = await androidImplementation
          .requestNotificationsPermission();
      granted = result ?? false;
      debugPrint('Android notification permission granted: $granted');
    }

    final macOSImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    if (macOSImplementation != null) {
      final bool? result = await macOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
      granted = result ?? false;
      debugPrint('macOS notification permission granted: $granted');
    }

    return granted;
  }
}
