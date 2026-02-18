import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/tray_service.dart';
import '../services/widget_service.dart';
import '../widgets/pomodoro_background.dart';
import '../widgets/timer_controls.dart';
import '../widgets/mode_selector.dart';
import '../widgets/timer_display.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/eye_break_dialog.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  int _workTime = 25 * 60, _shortBreakTime = 5 * 60, _longBreakTime = 15 * 60;
  final int _eyeCareWorkTime = 20 * 60, _eyeCareBreakTime = 20;
  late int _secondsRemaining;
  Timer? _timer;
  bool _isRunning = false;
  String _mode = 'Work';
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _workTime;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    NotificationService.requestPermissions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) {
      return;
    }
    if (_secondsRemaining == 0) {
      setState(() => _secondsRemaining = _getDurationForMode(_mode));
    }
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        _progressController.value = 0.0;
        _progressController.animateTo(
          1.0,
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
        );

        // Update macOS Menu Bar
        final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
        final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
        TrayService.updateTrayText('$minutes:$seconds');

        // Update macOS Desktop Widget
        WidgetService.updateWidget(
          secondsRemaining: _secondsRemaining,
          totalSeconds: _getDurationForMode(_mode),
          mode: _mode,
          isRunning: _isRunning,
        );
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        // Explicitly update widget when timer reaches zero
        WidgetService.updateWidget(
          secondsRemaining: 0,
          totalSeconds: _getDurationForMode(_mode),
          mode: _mode,
          isRunning: false,
        );
        _handleTimerCompletion();
      }
    });
    _progressController.value = 0.0;
    _progressController.animateTo(
      1.0,
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
    );
  }

  void _handleTimerCompletion() {
    debugPrint('Timer completed in mode: $_mode');
    String title = 'Time is up!', body = 'Great job staying focused.';
    if (_mode == 'Work') {
      body = 'Work session complete. Time to take a break!';
    } else if (_mode == 'Short' || _mode == 'Long') {
      body = 'Break over. Ready to work?';
    } else if (_mode == 'Eye Care') {
      title = 'Eye Care Break Needed';
      body = 'Look 20 feet away for 20 seconds now.';
      NotificationService.showNotification(title, body);
      return _showEyeBreakPrompt();
    } else if (_mode == 'Eye Break') {
      title = 'Eye Break Over';
      body = 'Success! You can resume your work now.';
      NotificationService.showNotification(title, body);
      return _showResumeWorkPrompt();
    }
    NotificationService.showNotification(title, body);
  }

  void _showResumeWorkPrompt() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Resume Work',
      pageBuilder: (_, _, _) => Container(),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, _, _) => Transform.scale(
        scale: anim1.value,
        child: Opacity(
          opacity: anim1.value,
          child: AlertDialog(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.greenAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Refresh Complete!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your eyes are rested. Ready to continue focusing?',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _switchMode('Eye Care');
                          _startTimer();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Resume Work',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEyeBreakPrompt() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Eye Break',
      pageBuilder: (_, _, _) => Container(),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, _, _) => Transform.scale(
        scale: anim1.value,
        child: Opacity(
          opacity: anim1.value,
          child: EyeBreakDialog(
            onStartBreak: () {
              _switchMode('Eye Break');
              _startTimer();
            },
          ),
        ),
      ),
    );
  }

  void _pauseTimer() {
    _timer?.cancel();
    _progressController.stop();
    setState(() => _isRunning = false);
    TrayService.updateTrayText('');
    WidgetService.updateWidget(
      secondsRemaining: _secondsRemaining,
      totalSeconds: _getDurationForMode(_mode),
      mode: _mode,
      isRunning: false,
    );
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _secondsRemaining = _getDurationForMode(_mode);
      _progressController.value = 0.0;
    });
    TrayService.updateTrayText('');
    WidgetService.updateWidget(
      secondsRemaining: _secondsRemaining,
      totalSeconds: _getDurationForMode(_mode),
      mode: _mode,
      isRunning: false,
    );
  }

  int _getDurationForMode(String mode) {
    if (mode == 'Work') {
      return _workTime;
    }
    if (mode == 'Short') {
      return _shortBreakTime;
    }
    if (mode == 'Long') {
      return _longBreakTime;
    }
    return mode == 'Eye Care' ? _eyeCareWorkTime : _eyeCareBreakTime;
  }

  void _switchMode(String mode) {
    _pauseTimer();
    setState(() {
      _mode = mode;
      _secondsRemaining = _getDurationForMode(mode);
      _progressController.value = 0.0;
    });
  }

  void _showSettings() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      pageBuilder: (_, _, _) => Container(),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, _, _) => Transform.scale(
        scale: anim1.value,
        child: Opacity(
          opacity: anim1.value,
          child: SettingsDialog(
            workTime: _workTime,
            shortBreakTime: _shortBreakTime,
            longBreakTime: _longBreakTime,
            mode: _mode,
            onWorkTimeChanged: (v) => setState(() {
              _workTime = v;
              if (_mode == 'Work') _secondsRemaining = v;
            }),
            onShortBreakTimeChanged: (v) => setState(() {
              _shortBreakTime = v;
              if (_mode == 'Short') _secondsRemaining = v;
            }),
            onLongBreakTimeChanged: (v) => setState(() {
              _longBreakTime = v;
              if (_mode == 'Long') _secondsRemaining = v;
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalDur = _getDurationForMode(_mode);
    return Scaffold(
      body: Stack(
        children: [
          const PomodoroBackground(),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 380,
                  height: 560,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      ModeSelector(
                        currentMode: _mode,
                        onModeChanged: _switchMode,
                      ),
                      const SizedBox(height: 50),
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) => TimerDisplay(
                          progress:
                              ((_secondsRemaining -
                                          (1.0 -
                                              (_isRunning
                                                  ? (1.0 -
                                                        _progressController
                                                            .value)
                                                  : 1.0))) /
                                      totalDur)
                                  .clamp(0.0, 1.0),
                          secondsRemaining: _secondsRemaining,
                          mode: _mode,
                          isEyeBreak: _mode == 'Eye Break',
                          formattedTime:
                              '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                        ),
                      ),
                      const SizedBox(height: 60),
                      TimerControls(
                        isRunning: _isRunning,
                        onReset: _resetTimer,
                        onToggle: _isRunning ? _pauseTimer : _startTimer,
                        onSettings: _showSettings,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
