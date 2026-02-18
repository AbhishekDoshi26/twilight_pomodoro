import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_slider.dart';

class SettingsDialog extends StatefulWidget {
  final int workTime;
  final int shortBreakTime;
  final int longBreakTime;
  final String mode;
  final Function(int) onWorkTimeChanged;
  final Function(int) onShortBreakTimeChanged;
  final Function(int) onLongBreakTimeChanged;

  const SettingsDialog({
    super.key,
    required this.workTime,
    required this.shortBreakTime,
    required this.longBreakTime,
    required this.mode,
    required this.onWorkTimeChanged,
    required this.onShortBreakTimeChanged,
    required this.onLongBreakTimeChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _localWorkTime;
  late int _localShortBreakTime;
  late int _localLongBreakTime;

  @override
  void initState() {
    super.initState();
    _localWorkTime = widget.workTime;
    _localShortBreakTime = widget.shortBreakTime;
    _localLongBreakTime = widget.longBreakTime;
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
}
