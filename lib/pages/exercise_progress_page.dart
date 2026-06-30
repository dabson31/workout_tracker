import 'package:flutter/material.dart';
import 'package:workout_tracker/models/exercise_log_entry.dart';
import 'package:workout_tracker/models/exercise_progress.dart';
import 'package:workout_tracker/theme/app_theme.dart';
import 'package:workout_tracker/utils/format_utils.dart';

// shown when tapping an exercise's progress stat on the Stats page.
// shows the PR, the first-vs-latest average comparison, and every
// historical log for that exercise (newest first).
class ExerciseProgressPage extends StatelessWidget {
  final ExerciseProgress progress;
  const ExerciseProgressPage({super.key, required this.progress});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtWeight(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()}kg';
    return '${kg.toStringAsFixed(1)}kg';
  }

  Widget _prCard() {
    final pr = progress.prEntry;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.18),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('personal record', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _fmtWeight(pr.weightKg),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${formatPerSetValue(pr.reps)} reps · ${pr.sets} sets · ${_fmtDate(pr.date)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final pct = progress.percentChange;
    final hasData = progress.hasEnoughData;

    Color badgeColor = AppColors.textSecondary;
    if (pct != null) {
      badgeColor = pct > 0 ? const Color(0xFF10B981) : (pct < 0 ? AppColors.danger : AppColors.textSecondary);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('progress', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              if (hasData && pct != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(0)}%',
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            const Text(
              'not enough history yet to compare \u2014 log this exercise a few more times',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('first ${progress.windowSize}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_fmtWeight(progress.firstAvgWeight),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('latest ${progress.windowSize}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.right),
                      const SizedBox(height: 4),
                      Text(_fmtWeight(progress.latestAvgWeight),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _logRow(ExerciseLogEntry log, {required bool isPr, required bool inFirstWindow, required bool inLatestWindow}) {
    String? tag;
    Color? tagColor;
    if (isPr) {
      tag = 'PR';
      tagColor = const Color(0xFFF59E0B);
    } else if (inLatestWindow) {
      tag = 'latest';
      tagColor = const Color(0xFF10B981);
    } else if (inFirstWindow) {
      tag = 'first';
      tagColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isPr ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmtDate(log.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  '${formatPerSetValue(log.weight)} · ${formatPerSetValue(log.reps)} reps · ${log.sets} sets',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor!.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tag, style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsNewestFirst = progress.allLogs.reversed.toList();
    final firstWindowDates = progress.firstWindowLogs.map((e) => e.date).toSet();
    final latestWindowDates = progress.latestWindowLogs.map((e) => e.date).toSet();
    final prDate = progress.prEntry.date;

    return Scaffold(
      appBar: AppBar(title: Text(progress.exerciseName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _prCard(),
          const SizedBox(height: 12),
          _progressCard(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'history (${progress.totalLogs} logged)',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ...logsNewestFirst.map((log) => _logRow(
                log,
                isPr: log.date == prDate && log.weightKg == progress.prEntry.weightKg,
                inFirstWindow: firstWindowDates.contains(log.date),
                inLatestWindow: latestWindowDates.contains(log.date),
              )),
        ],
      ),
    );
  }
}
