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

  static Future<Map<String, dynamic>?> getWidgetState() async {
    if (!Platform.isMacOS) return null;

    try {
      final result = await _channel.invokeMethod('getWidgetState');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      debugPrint('Error getting native widget state: $e');
    }
    return null;
  }
}
