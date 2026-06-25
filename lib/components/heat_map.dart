import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class MyHeatMap extends StatefulWidget {
  final Map<DateTime, int>? datasets;
  final String startDateDDMMYYYY;
  final Function(DateTime)? onDayTap;

  const MyHeatMap({
  super.key,
  required this.datasets,
  required this.startDateDDMMYYYY,
  this.onDayTap,
  });

  @override
  State<MyHeatMap> createState() => _MyHeatMapState();
}

class _MyHeatMapState extends State<MyHeatMap> {
  // matches the size + default margin used by the HeatMap blocks below,
  // used to estimate which week column is currently in view
  static const double blockSize = 28;
  static const double blockMargin = 2;
  static const double columnWidth = blockSize + (blockMargin * 2);

  late int visibleYear;
  late DateTime startDate;

  @override
  void initState() {
    super.initState();
    startDate = createDateTimeObject(widget.startDateDDMMYYYY);
    // HeatMap auto-scrolls to the end (today) on load, so start with todays year
    visibleYear = DateTime.now().year;
  }

  // estimates the date currently scrolled into view, given a horizontal offset
  void updateVisibleYearFromOffset(double offset) {
    final weeksScrolled = offset / columnWidth;
    final daysScrolled = (weeksScrolled * 7).round();
    final estimatedDate = startDate.add(Duration(days: daysScrolled));

    if (estimatedDate.year != visibleYear) {
      setState(() {
        visibleYear = estimatedDate.year;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // year label, updates as the heatmap is scrolled left/right
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              visibleYear.toString(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.horizontal) {
                updateVisibleYearFromOffset(notification.metrics.pixels);
              }
              return false;
            },
            child: HeatMap(
              startDate: startDate,
              endDate: DateTime.now().add(const Duration(days: 0)),
              datasets: widget.datasets,
              colorMode: ColorMode.color,
              defaultColor: AppColors.surfaceLight,
              textColor: AppColors.textPrimary,
              showColorTip: false,
              showText: true,
              scrollable: true,
              size: blockSize,
              borderRadius: 6,
              onClick: widget.onDayTap,
              colorsets: const {
                1: AppColors.primary,
              },
            ),
          ),
        ],
      ),
    );
  }
}