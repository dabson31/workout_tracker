import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/premium_dialog.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final weightController = TextEditingController();

  void logWeight() {
    final text = weightController.text.trim();
    if (text.isEmpty) return;
    final parsed = double.tryParse(text);
    if (parsed == null) return;
    Provider.of<WorkoutData>(context, listen: false).logBodyWeight(parsed);
    weightController.clear();
    FocusScope.of(context).unfocus();
  }

  // edit a single historical bodyweight entry
  void editEntry(MapEntry<DateTime, double> entry) {
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(entry.key);
    final ctrl = TextEditingController(text: entry.value.toStringAsFixed(1));
    final oldValue = entry.value;

    showPremiumDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: const Text('edit weight', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            suffixText: 'kg',
            suffixStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              final parsed = double.tryParse(ctrl.text.trim());
              if (parsed == null) return;
              Provider.of<WorkoutData>(context, listen: false).editBodyWeight(ddmmyyyy, parsed);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 5),
                  backgroundColor: AppColors.surfaceLight,
                  behavior: SnackBarBehavior.floating,
                  content: const Text('weight updated', style: TextStyle(color: AppColors.textPrimary)),
                  action: SnackBarAction(
                    label: 'undo',
                    textColor: AppColors.primary,
                    onPressed: () {
                      Provider.of<WorkoutData>(context, listen: false).editBodyWeight(ddmmyyyy, oldValue);
                    },
                  ),
                ),
              );
            },
            child: const Text('save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // delete a bodyweight entry with undo
  void deleteEntry(MapEntry<DateTime, double> entry) {
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(entry.key);
    final oldValue = entry.value;

    Provider.of<WorkoutData>(context, listen: false).deleteBodyWeight(ddmmyyyy);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        content: Text('${oldValue.toStringAsFixed(1)} kg removed', style: const TextStyle(color: AppColors.textPrimary)),
        action: SnackBarAction(
          label: 'undo',
          textColor: AppColors.primary,
          onPressed: () {
            Provider.of<WorkoutData>(context, listen: false).editBodyWeight(ddmmyyyy, oldValue);
          },
        ),
      ),
    );
  }

  Widget buildChart(List<MapEntry<DateTime, double>> history) {
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].value));
    }

    final minWeight = history.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxWeight = history.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final padding = ((maxWeight - minWeight) * 0.2).clamp(1, 10);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minWeight - padding,
          maxY: maxWeight + padding,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 36),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => AppColors.surfaceLight,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = history[spot.x.toInt()].key;
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}kg\n${date.day}/${date.month}/${date.year}',
                    const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        final history = value.getBodyWeightHistory();

        return Scaffold(
          appBar: AppBar(title: const Text('bodyweight')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // log input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'todays weight',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        suffixText: 'kg',
                        suffixStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: logWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('log', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.show_chart_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'log your weight to start seeing your trend',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: buildChart(history),
                ),

              const SizedBox(height: 24),

              // history list — swipe left to edit/delete
              if (history.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'history',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                ...history.reversed.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Slidable(
                        key: ValueKey(entry.key),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.45,
                          children: [
                            SlidableAction(
                              onPressed: (context) => editEntry(entry),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              icon: Icons.edit_rounded,
                              label: 'edit',
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                            ),
                            SlidableAction(
                              onPressed: (context) => deleteEntry(entry),
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'delete',
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${entry.key.day.toString().padLeft(2, '0')}/${entry.key.month.toString().padLeft(2, '0')}/${entry.key.year}',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              Text(
                                '${entry.value.toStringAsFixed(1)} kg',
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}
