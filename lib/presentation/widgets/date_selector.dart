import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';

class DateSelector extends StatelessWidget {
  const DateSelector({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final List<DateTime> dates;
  final String selectedDate;
  final ValueChanged<String> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final key = formatDateKey(date);
          final selected = key == selectedDate;

          return GestureDetector(
            onTap: () => onSelectDate(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                color: selected ? AppColors.navy500 : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    getDayLabel(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white70 : AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${getDayNumber(date)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selected ? AppColors.white : AppColors.navy500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
