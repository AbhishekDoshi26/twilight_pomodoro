import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerDisplay extends StatelessWidget {
  final double progress;
  final int secondsRemaining;
  final String mode;
  final bool isEyeBreak;
  final String formattedTime;

  const TimerDisplay({
    super.key,
    required this.progress,
    required this.secondsRemaining,
    required this.mode,
    required this.isEyeBreak,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(
              isEyeBreak
                  ? const Color(0xFF24DDFF)
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEyeBreak)
              Icon(
                Icons.remove_red_eye_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 30,
              ),
            Text(
              formattedTime,
              style: GoogleFonts.outfit(
                fontSize: 84,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                letterSpacing: -3,
              ),
            ),
            Text(
              isEyeBreak ? 'LOOK 20 FEET AWAY' : mode.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: isEyeBreak ? 2 : 6,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
