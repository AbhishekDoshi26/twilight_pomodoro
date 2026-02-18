import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService extends TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  static Future<void> init() async {
    if (!Platform.isMacOS) return;

    await trayManager.setIcon(
      'assets/app_icon.png', // Ensure this is a transparent template icon for best results
    );

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
    // Left click on macOS usually toggles the window
    _toggleWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    // trayManager handles showing the context menu automatically on macOS usually,
    // but we can force it or handle specific right-click logic here if needed.
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
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _toggleWindow() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      // If visible but not focused, focus it. If focused, hide it (optional behavior)
      await windowManager.focus();
    } else {
      await _showWindow();
    }
  }
}
