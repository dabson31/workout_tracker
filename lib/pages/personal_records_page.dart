import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/models/exercise_progress.dart';
import 'package:workout_tracker/pages/exercise_progress_page.dart';
import 'package:workout_tracker/theme/app_theme.dart';
import 'package:workout_tracker/utils/format_utils.dart';

// reached from the "personal records" tile on the Stats page. A trophy
// list of the heaviest weight ever logged per exercise, heaviest first.
class PersonalRecordsPage extends StatelessWidget {
  const PersonalRecordsPage({super.key});

  String _fmtWeight(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()}kg';
    return '${kg.toStringAsFixed(1)}kg';
  }

  void _openExercise(BuildContext context, ExerciseProgress p) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ExerciseProgressPage(progress: p)));
  }

  Widget _prTile(BuildContext context, ExerciseProgress p, int rank) {
    final isTopThree = rank < 3;
    final medalColors = [const Color(0xFFF59E0B), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];

    return InkWell(
      onTap: () => _openExercise(context, p),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isTopThree ? Border.all(color: medalColors[rank].withValues(alpha: 0.35)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isTopThree ? medalColors[rank] : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: isTopThree ? medalColors[rank] : const Color(0xFFF59E0B),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.exerciseName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text(
                    '${formatPerSetValue(p.prEntry.reps)} reps \u00b7 ${p.prEntry.sets} sets \u00b7 ${p.prEntry.date.day.toString().padLeft(2, '0')}/${p.prEntry.date.month.toString().padLeft(2, '0')}/${p.prEntry.date.year}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtWeight(p.prEntry.weightKg),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(width: 4),
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
        final progress = List<ExerciseProgress>.from(value.getExerciseProgressList())
          ..sort((a, b) => b.prEntry.weightKg.compareTo(a.prEntry.weightKg));

        return Scaffold(
          appBar: AppBar(title: const Text('personal records')),
          body: progress.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'log an exercise to start setting PRs',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: progress.length,
                  itemBuilder: (context, index) => _prTile(context, progress[index], index),
                ),
        );
      },
    );
  }
}
