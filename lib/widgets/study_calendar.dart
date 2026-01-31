import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class StudyCalendar extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, double> dailyHours;
  final ValueChanged<DateTime>? onDayTapped;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  const StudyCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.dailyHours,
    this.onDayTapped,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final intensityColors =
        isDark ? AppColors.darkCalendarIntensity : AppColors.lightCalendarIntensity;

    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sun=0
    final totalDays = lastDay.day;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Text(
                DateFormat('yyyy년 M월').format(firstDay),
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday headers
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: d == '일'
                                ? const Color(0xFFE57373)
                                : d == '토'
                                    ? const Color(0xFF64B5F6)
                                    : null,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          ...List.generate(
            ((startWeekday + totalDays + 6) ~/ 7),
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (weekday) {
                  final dayIndex = week * 7 + weekday - startWeekday + 1;

                  if (dayIndex < 1 || dayIndex > totalDays) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final date = DateTime(year, month, dayIndex);
                  final hours = dailyHours[date] ?? 0;
                  final intensity = AppColors.intensityIndex(hours);
                  final isToday = date == today;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDayTapped?.call(date),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: intensity > 0
                              ? intensityColors[intensity]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(
                                  color: colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$dayIndex',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isToday ? FontWeight.w600 : FontWeight.w400,
                                  color: isToday
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              if (hours > 0)
                                Text(
                                  '${hours.toStringAsFixed(1)}h',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Legend
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('적음 ', style: theme.textTheme.labelSmall),
              ...List.generate(
                6,
                (i) => Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? colorScheme.outline.withOpacity(0.2)
                        : intensityColors[i],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(' 많음', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
