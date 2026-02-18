import 'package:flutter/material.dart';
import 'control_button.dart';

class TimerControls extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onReset;
  final VoidCallback onToggle;
  final VoidCallback onSettings;

  const TimerControls({
    super.key,
    required this.isRunning,
    required this.onReset,
    required this.onToggle,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ControlButton(
          icon: Icons.refresh_rounded,
          onTap: onReset,
          isSmall: true,
        ),
        const SizedBox(width: 30),
        ControlButton(
          icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onTap: onToggle,
          isLarge: true,
        ),
        const SizedBox(width: 30),
        ControlButton(
          icon: Icons.settings_rounded,
          onTap: onSettings,
          isSmall: true,
        ),
      ],
    );
  }
}
