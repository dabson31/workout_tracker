import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/models/exercise_progress.dart';
import 'package:workout_tracker/pages/exercise_progress_page.dart';
import 'package:workout_tracker/theme/app_theme.dart';

// reached from the "progress" tile on the Stats page. Shows the overall
// average % change across every exercise with enough history, then a
// full list of every exercise's individual progress underneath.
class ProgressOverviewPage extends StatelessWidget {
  const ProgressOverviewPage({super.key});

  String _fmtWeight(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()}kg';
    return '${kg.toStringAsFixed(1)}kg';
  }

  void _openExercise(BuildContext context, ExerciseProgress p) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ExerciseProgressPage(progress: p)));
  }

  Widget _overallCard(double? overallPercent) {
    Color color = AppColors.textSecondary;
    String valueText = 'not enough data yet';
    if (overallPercent != null) {
      color = overallPercent > 0
          ? const Color(0xFF10B981)
          : (overallPercent < 0 ? AppColors.danger : AppColors.textSecondary);
      valueText = '${overallPercent > 0 ? '+' : ''}${overallPercent.toStringAsFixed(0)}%';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.18), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'average change across all exercises',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            valueText,
            style: TextStyle(
              color: overallPercent != null ? color : AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'comparing each exercise\'s earliest logs to its latest',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _exerciseTile(BuildContext context, ExerciseProgress p) {
    final pct = p.percentChange;
    Color badgeColor = AppColors.textSecondary;
    String badgeText = 'new';
    if (p.hasEnoughData && pct != null) {
      badgeColor = pct > 0 ? const Color(0xFF10B981) : (pct < 0 ? AppColors.danger : AppColors.textSecondary);
      badgeText = '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(0)}%';
    }

    return InkWell(
      onTap: () => _openExercise(context, p),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.exerciseName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    p.hasEnoughData
                        ? '${_fmtWeight(p.firstAvgWeight)} \u2192 ${_fmtWeight(p.latestAvgWeight)} avg'
                        : 'log a few more times to see progress',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badgeText, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        final progress = value.getExerciseProgressList();
        final overallPercent = value.getOverallProgressPercent();

        return Scaffold(
          appBar: AppBar(title: const Text('progress')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _overallCard(overallPercent),
              const SizedBox(height: 20),
              if (progress.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.trending_up_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'log some exercises to start tracking progress',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else ...[
                const Padding(
                  padding: EdgeInsets.only(left: 2, bottom: 8),
                  child: Text(
                    'by exercise',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                ...progress.map((p) => _exerciseTile(context, p)),
              ],
            ],
          ),
        );
      },
    );
  }
}
