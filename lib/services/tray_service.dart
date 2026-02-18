import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService extends TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  static Future<void> init() async {
    if (!Platform.isMacOS) return;

    try {
      await trayManager.setIcon('assets/app_icon.png');
    } catch (e) {
      debugPrint('Error setting tray icon: $e');
    }

    final Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Show App'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
    trayManager.addListener(_instance);
  }

  static Future<void> updateTrayText(String text) async {
    if (!Platform.isMacOS) return;
    await trayManager.setTitle(text);
  }

  @override
  void onTrayIconMouseDown() {
    // Avoid double-firing; use MouseUp for click behavior
  }

  @override
  void onTrayIconMouseUp() {
    _toggleWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      _showWindow();
    } else if (menuItem.key == 'exit_app') {
      exit(0);
    }
  }

  Future<void> _showWindow() async {
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
    await windowManager.restore();
    await windowManager.focus();
  }

  bool _isToggling = false;

  Future<void> _toggleWindow() async {
    if (_isToggling) return;
    _isToggling = true;

    try {
      bool isMinimized = await windowManager.isMinimized();
      bool isVisible = await windowManager.isVisible();

      if (isMinimized || !isVisible) {
        await _showWindow();
      } else {
        bool isFocused = await windowManager.isFocused();
        if (isFocused) {
          await windowManager.hide();
        } else {
          await windowManager.focus();
        }
      }
    } catch (e) {
      debugPrint('Error toggling window: $e');
    } finally {
      _isToggling = false;
    }
  }
}
