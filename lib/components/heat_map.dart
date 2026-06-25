import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:workout_tracker/theme/app_theme.dart';

// calendar-style heatmap, one month on screen at a time, like a normal
// calendar grid with weekday headers -- always opens on the current month,
// swipe left/right on it to browse other months
class MyHeatMap extends StatelessWidget {
  final Map<DateTime, int>? datasets;
  final Function(DateTime)? onDayTap;

  const MyHeatMap({
    super.key,
    required this.datasets,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: HeatMapCalendar(
        // only used the first time this mounts -- once the user swipes to
        // another month, rebuilds (e.g. from logging a workout) won't yank
        // them back to today
        initDate: DateTime.now(),
        datasets: datasets,
        flexible: true,
        colorMode: ColorMode.color,
        defaultColor: AppColors.surfaceLight,
        textColor: AppColors.textPrimary,
        weekTextColor: AppColors.textSecondary,
        monthFontSize: 16,
        fontSize: 13,
        borderRadius: 8,
        showColorTip: false,
        onClick: onDayTap,
        colorsets: const {
          1: AppColors.primary,
        },
      ),
    );
  }
}
