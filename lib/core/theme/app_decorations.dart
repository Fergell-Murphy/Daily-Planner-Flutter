import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppDecorations {
  static BoxDecoration card({
    Color color = AppColors.white,
    double radius = 20,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.gray200.withValues(alpha: 0.7)),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: AppColors.navy500.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration gradientIcon() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy500, Color(0xFF2D5A8E)],
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy500.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration sectionCard() {
    return card(radius: 18);
  }
}
