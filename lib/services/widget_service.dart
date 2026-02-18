import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.abhishek.pomodoro/widget',
  );

  static Future<void> init() async {
    // Custom native bridge initialized in AppDelegate.swift
  }

  static Future<void> updateWidget({
    required int secondsRemaining,
    required int totalSeconds,
    required String mode,
    required bool isRunning,
  }) async {
    if (!Platform.isMacOS) return;

    try {
      await _channel.invokeMethod('updateWidget', {
        'secondsRemaining': secondsRemaining,
        'totalSeconds': totalSeconds,
        'mode': mode,
        'isRunning': isRunning,
      });
    } catch (e) {
      debugPrint('Error updating native widget: $e');
    }
  }
}
