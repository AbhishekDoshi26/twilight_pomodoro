import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
          requestCriticalPermission: true,
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

    // Android Configuration
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'pomodoro_timer_channel_v4', // New channel for persistence
      'Pomodoro Timer Alerts',
      channelDescription: 'Important alerts for completion',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('smooth_notification'),
      playSound: true,
      ongoing:
          false, // Turn off ongoing so it doesn't vanish with the app lifecycle
      autoCancel: false, // Keep it on the screen until dismissed
      enableVibration: true,
      visibility:
          NotificationVisibility.public, // Show full content on lock screen
      category:
          AndroidNotificationCategory.alarm, // Treats it as an important alarm
    );

    // macOS Configuration
    // Note: For custom sounds on macOS, the file must be added to the Xcode project resources.
    // If it's not found, it will fallback to the default sound.
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'smooth_notification.mp3',
      presentAlert: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      macOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: DateTime.now().millisecond, // Unique ID to avoid overlapping
        title: title,
        body: body,
        notificationDetails: details,
      );
      debugPrint('Notification sent successfully');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static Future<void> requestPermissions() async {
    debugPrint('Requesting notification permissions...');

    // Request Android 13+ permissions
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      debugPrint('Android notification permission granted: $granted');
    }

    // Request macOS permissions
    final macOSImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macOSImplementation != null) {
      final granted = await macOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
      debugPrint('macOS notification permission granted: $granted');
    }
  }
}
