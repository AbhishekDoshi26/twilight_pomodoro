import 'package:flutter/material.dart';
import 'mode_button.dart';

class ModeSelector extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModeButton(
              title: 'Work',
              isSelected: currentMode == 'Work',
              onTap: () => onModeChanged('Work'),
            ),
            ModeButton(
              title: 'Short',
              isSelected: currentMode == 'Short',
              onTap: () => onModeChanged('Short'),
            ),
            ModeButton(
              title: 'Long',
              isSelected: currentMode == 'Long',
              onTap: () => onModeChanged('Long'),
            ),
            ModeButton(
              title: '20-20-20',
              isSelected:
                  currentMode == 'Eye Care' || currentMode == 'Eye Break',
              onTap: () => onModeChanged('Eye Care'),
            ),
          ],
        ),
      ),
    );
  }
}
