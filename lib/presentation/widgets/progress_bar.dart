import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.percentage,
    this.color = AppColors.navy500,
    this.height = 6,
    this.backgroundColor = AppColors.gray100,
  });

  final int percentage;
  final Color color;
  final double height;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0, 100);

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: clamped / 100,
          minHeight: height,
          backgroundColor: backgroundColor,
          color: color,
        ),
      ),
    );
  }
}
