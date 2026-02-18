import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'services/notification_service.dart';
import 'services/tray_service.dart';
import 'services/widget_service.dart';
import 'screens/pomodoro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must add this for window_manager
  await windowManager.ensureInitialized();

  await NotificationService.init();
  await TrayService.init();
  await WidgetService.init();
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tahoe Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PomodoroScreen(),
    );
  }
}
