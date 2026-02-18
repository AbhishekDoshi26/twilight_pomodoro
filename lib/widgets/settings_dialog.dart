import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import 'settings_slider.dart';

class SettingsDialog extends StatefulWidget {
  final int workTime;
  final int shortBreakTime;
  final int longBreakTime;
  final String mode;
  final bool notificationsEnabled;
  final Function(int) onWorkTimeChanged;
  final Function(int) onShortBreakTimeChanged;
  final Function(int) onLongBreakTimeChanged;
  final Function(bool) onNotificationsChanged;

  const SettingsDialog({
    super.key,
    required this.workTime,
    required this.shortBreakTime,
    required this.longBreakTime,
    required this.mode,
    required this.notificationsEnabled,
    required this.onWorkTimeChanged,
    required this.onShortBreakTimeChanged,
    required this.onLongBreakTimeChanged,
    required this.onNotificationsChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _localWorkTime;
  late int _localShortBreakTime;
  late int _localLongBreakTime;
  late bool _localNotificationsEnabled;

  @override
  void initState() {
    super.initState();
    _localWorkTime = widget.workTime;
    _localShortBreakTime = widget.shortBreakTime;
    _localLongBreakTime = widget.longBreakTime;
    _localNotificationsEnabled = widget.notificationsEnabled;
    _verifyPermissions();
  }

  Future<void> _verifyPermissions() async {
    if (_localNotificationsEnabled) {
      final granted = await NotificationService.requestPermissions();
      if (!granted && mounted) {
        setState(() {
          _localNotificationsEnabled = false;
        });
        widget.onNotificationsChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SettingsSlider(
                    label: 'Work duration',
                    value: (_localWorkTime ~/ 60).toDouble(),
                    min: 5,
                    max: 60,
                    onChanged: (val) {
                      setState(() {
                        _localWorkTime = val.toInt() * 60;
                      });
                      widget.onWorkTimeChanged(_localWorkTime);
                    },
                  ),
                  SettingsSlider(
                    label: 'Short break',
                    value: (_localShortBreakTime ~/ 60).toDouble(),
                    min: 1,
                    max: 15,
                    onChanged: (val) {
                      setState(() {
                        _localShortBreakTime = val.toInt() * 60;
                      });
                      widget.onShortBreakTimeChanged(_localShortBreakTime);
                    },
                  ),
                  SettingsSlider(
                    label: 'Long break',
                    value: (_localLongBreakTime ~/ 60).toDouble(),
                    min: 5,
                    max: 45,
                    onChanged: (val) {
                      setState(() {
                        _localLongBreakTime = val.toInt() * 60;
                      });
                      widget.onLongBreakTimeChanged(_localLongBreakTime);
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      value: _localNotificationsEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final granted =
                              await NotificationService.requestPermissions();
                          if (!granted && context.mounted) {
                            // If denied, don't enable the switch
                            setState(() {
                              _localNotificationsEnabled = false;
                            });
                            widget.onNotificationsChanged(false);

                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E2E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Notifications Disabled',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Please enable notifications for Twilight Pomodoro in System Settings > Notifications.',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _openNotificationSettings();
                                    },
                                    child: Text(
                                      'Open Settings',
                                      style: GoogleFonts.outfit(
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                        }

                        if (context.mounted) {
                          setState(() {
                            _localNotificationsEnabled = val;
                          });
                          widget.onNotificationsChanged(val);
                        }
                      },
                      title: Text(
                        'Enable Notifications',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      activeThumbColor: Colors.orangeAccent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Done',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openNotificationSettings() {
    if (Platform.isMacOS) {
      // Opens the Notifications pane in System Settings (macOS 13+) or System Preferences
      Process.run('open', [
        'x-apple.systempreferences:com.apple.preference.notifications',
      ]);
    }
  }
}
