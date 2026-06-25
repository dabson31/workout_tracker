import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final weightController = TextEditingController();

  // log todays weight from the input field
  void logWeight() {
    final text = weightController.text.trim();
    if (text.isEmpty) return;

    final parsed = double.tryParse(text);
    if (parsed == null) return;

    Provider.of<WorkoutData>(context, listen: false).logBodyWeight(parsed);
    weightController.clear();
    FocusScope.of(context).unfocus();
  }

  // builds the line chart from history entries
  Widget buildChart(List<MapEntry<DateTime, double>> history) {
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].value));
    }

    final minWeight = history.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxWeight = history.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    // add a little padding above/below so the line doesnt touch the edges
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

              // chart or empty state
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

              // recent entries list, most recent first
              if (history.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'history',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                ...history.reversed.map((entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
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
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}