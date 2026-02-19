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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _workTime = 25 * 60, _shortBreakTime = 5 * 60, _longBreakTime = 15 * 60;
  int _customWorkTime = 20 * 60, _customBreakTime = 5 * 60;
  final int _eyeCareWorkTime = 20 * 60, _eyeCareBreakTime = 20;
  late int _secondsRemaining;
  Timer? _timer;
  bool _isRunning = false;
  bool _notificationsEnabled = true;
  String _mode = 'Work';
  bool _isCustomBreak = false; // Moved here for clarity
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
    WidgetsBinding.instance.addObserver(this);
    _loadWidgetState();
    debugPrint('PomodoroScreen initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWidgetState();
    } else if (state == AppLifecycleState.paused) {
      _syncWidget();
    }
  }

  Future<void> _loadWidgetState() async {
    final state = await WidgetService.getWidgetState();
    if (state != null && mounted) {
      if (state['secondsRemaining'] != null) {
        setState(() {
          _secondsRemaining = state['secondsRemaining'] as int;
          if (state['mode'] != null) {
            _mode = state['mode'] as String;
          }
        });
      }

      bool isRunningState = state['isRunning'] == true;
      int secondsState = state['secondsRemaining'] as int? ?? 0;

      // Update seconds only if discrepancy is large (> 2s) to avoid jitter
      if (secondsState > 0 && (_secondsRemaining - secondsState).abs() > 2) {
        setState(() {
          _secondsRemaining = secondsState;
        });
      }

      if (isRunningState && secondsState <= 0) {
        // It finished while we were away!
        setState(() {
          _isRunning = false;
          _secondsRemaining = 0;
        });
        _timer?.cancel();
        _syncWidget(); // Update native side to stop reporting isRunning=true
        _handleTimerCompletion();
        return;
      }

      if (isRunningState && !_isRunning) {
        _startTimer();
      } else if (!isRunningState && _isRunning) {
        _pauseTimer();
      }

      // Update tray text
      _updateTray();
    }
  }

  void _updateTray() {
    if (_isRunning) {
      final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
      final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
      TrayService.updateTrayText('$minutes:$seconds');
    } else {
      TrayService.updateTrayText('PAUSED');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Safety first: prevent multiple timers
    if (_isRunning) {
      setState(() => _isRunning = false); // Reset state before restarting
    }

    if (_secondsRemaining <= 0) {
      setState(() => _secondsRemaining = _getDurationForMode(_mode));
    }
    setState(() => _isRunning = true);
    // Update Widget immediately on start
    _syncWidget();

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

        // Periodically sync widget every 15 seconds to ensure it stays alive
        if (_secondsRemaining % 15 == 0) {
          _syncWidget();
        }
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        // Explicitly update widget when timer reaches zero
        _syncWidget();
        _handleTimerCompletion();
      }
    });

    // Handle immediate first second animation
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
      if (_notificationsEnabled) {
        NotificationService.showNotification(title, body);
      }
      return _showEyeBreakPrompt();
    } else if (_mode == 'Eye Break') {
      title = 'Eye Break Over';
      body = 'Success! You can resume your work now.';
      if (_notificationsEnabled) {
        NotificationService.showNotification(title, body);
      }
      return _showResumeWorkPrompt();
    } else if (_mode == 'Custom') {
      if (!_isCustomBreak) {
        title = 'Work Session Over';
        body = 'Time for a $_customBreakTime seconds break!';
        _showCustomBreakPrompt();
      } else {
        title = 'Break Over';
        body = 'Ready to resume work?';
        _showCustomResumePrompt();
      }
    }

    if (_notificationsEnabled) {
      NotificationService.showNotification(title, body);
    }
  }

  void _showCustomBreakPrompt() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Custom Break',
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
                        Icons.coffee_outlined,
                        color: Colors.orangeAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Work Complete!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time for a ${(_customBreakTime ~/ 60)} minute break.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _isCustomBreak = true);
                          _switchMode('Custom');
                          _startTimer();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
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
                          'Start Break',
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

  void _showCustomResumePrompt() {
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
                        Icons.work_outline,
                        color: Colors.greenAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Break Over!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ready to jump back into work?',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _isCustomBreak = false);
                          _switchMode('Custom');
                          _startTimer();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
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
    _syncWidget();
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _secondsRemaining = _getDurationForMode(_mode);
      _progressController.value = 0.0;
    });
    TrayService.updateTrayText('');
    _syncWidget();
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
    if (mode == 'Custom') {
      return _isCustomBreak ? _customBreakTime : _customWorkTime;
    }
    return mode == 'Eye Care' ? _eyeCareWorkTime : _eyeCareBreakTime;
  }

  void _switchMode(String mode) {
    _pauseTimer();
    setState(() {
      _mode = mode;
      if (mode != 'Custom') {
        _isCustomBreak = false;
      }
      _secondsRemaining = _getDurationForMode(mode);
      _progressController.value = 0.0;
    });
    _syncWidget();
  }

  void _syncWidget() {
    WidgetService.updateWidget(
      secondsRemaining: _secondsRemaining,
      totalSeconds: _getDurationForMode(_mode),
      mode: _mode,
      isRunning: _isRunning,
    );
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
            customWorkTime: _customWorkTime,
            customBreakTime: _customBreakTime,
            mode: _mode,
            notificationsEnabled: _notificationsEnabled, // Pass current state
            onWorkTimeChanged: (v) => setState(() {
              _workTime = v;
              if (_mode == 'Work') {
                _secondsRemaining = v;
                _syncWidget();
              }
            }),
            onShortBreakTimeChanged: (v) => setState(() {
              _shortBreakTime = v;
              if (_mode == 'Short') {
                _secondsRemaining = v;
                _syncWidget();
              }
            }),
            onLongBreakTimeChanged: (v) => setState(() {
              _longBreakTime = v;
              if (_mode == 'Long') {
                _secondsRemaining = v;
                _syncWidget();
              }
            }),
            onCustomWorkTimeChanged: (v) => setState(() {
              _customWorkTime = v;
              if (_mode == 'Custom' && !_isCustomBreak) {
                _secondsRemaining = v;
                _syncWidget();
              }
            }),
            onCustomBreakTimeChanged: (v) => setState(() {
              _customBreakTime = v;
              if (_mode == 'Custom' && _isCustomBreak) {
                _secondsRemaining = v;
                _syncWidget();
              }
            }),
            onNotificationsChanged: (v) => setState(() {
              _notificationsEnabled = v;
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
                          mode: _mode == 'Custom'
                              ? (_isCustomBreak
                                    ? 'Custom Break'
                                    : 'Custom Work')
                              : _mode,
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
