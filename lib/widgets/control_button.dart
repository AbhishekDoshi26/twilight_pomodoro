import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLarge;
  final bool isSmall;

  const ControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isLarge = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    double size = isLarge ? 80 : 50;
    double iconSize = isLarge ? 36 : 24;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: isLarge ? 0.12 : 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: isLarge ? 0.2 : 0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: iconSize,
        ),
      ),
    );
  }
}
