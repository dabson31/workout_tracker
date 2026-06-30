import 'package:flutter/material.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class MyHeatMap extends StatefulWidget {
  final Map<DateTime, int>? datasets;
  final Function(DateTime)? onDayTap;
  final DateTime? selectedDate;

  const MyHeatMap({
    super.key,
    required this.datasets,
    this.onDayTap,
    this.selectedDate,
  });

  @override
  State<MyHeatMap> createState() => _MyHeatMapState();
}

class _MyHeatMapState extends State<MyHeatMap> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _prev() => setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _next() => setState(() => _month = DateTime(_month.year, _month.month + 1));

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  Color _cellColor(int? value) {
    switch (value) {
      case 1:  return AppColors.primary;
      case 2:  return AppColors.primary.withValues(alpha: 0.35);
      default: return AppColors.surfaceLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedDate != null
        ? DateTime(widget.selectedDate!.year, widget.selectedDate!.month, widget.selectedDate!.day)
        : null;

    final leadingBlanks = _month.weekday - 1;
    final daysInMonth   = DateUtils.getDaysInMonth(_month.year, _month.month);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // month header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                onPressed: _prev,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Expanded(
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onPressed: _next,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // weekday headers
          Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 6),

          // day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (_, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();

              final day        = index - leadingBlanks + 1;
              final date       = DateTime(_month.year, _month.month, day);
              final isSelected = selected != null && date == selected;
              final value      = widget.datasets?[date];
              final fill       = _cellColor(value);
              // every day from the app's start date onward has an entry in
              // the dataset (defaulting to 0), so `value != null` is true
              // even for days with nothing logged — only days outside the
              // tracked range are actually null. What we really want is
              // "did anything happen this day" (logged = 1, rest day = 2).
              final hasActivity = value == 1 || value == 2;

              return GestureDetector(
                onTap: () => widget.onDayTap?.call(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (value == 1
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: hasActivity ? 0.15 : 0.03))
                        : fill,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: hasActivity ? 1.0 : 0.3),
                            width: hasActivity ? 2 : 1.5,
                          )
                        : null,
                    boxShadow: isSelected && hasActivity
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: isSelected ? 12 : 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                        color: isSelected
                            ? (hasActivity ? Colors.white : AppColors.textPrimary)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
