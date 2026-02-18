import 'package:flutter/material.dart';
import 'background_blob.dart';

class PomodoroBackground extends StatelessWidget {
  const PomodoroBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
            ),
          ),
        ),
        const BackgroundBlob(
          color: Color(0xFF6366F1),
          top: -120,
          right: -60,
          size: 450,
        ),
        const BackgroundBlob(
          color: Color(0xFFD946EF),
          bottom: -80,
          left: -40,
          size: 350,
        ),
        const BackgroundBlob(
          color: Color(0xFF06B6D4),
          top: 250,
          left: -120,
          size: 300,
        ),
        const BackgroundBlob(
          color: Color(0xFF10B981),
          bottom: 150,
          right: -80,
          size: 250,
        ),
      ],
    );
  }
}
