import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/pages/personal_records_page.dart';
import 'package:workout_tracker/pages/progress_overview_page.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        final allTime      = value.getWorkoutsAllTime();
        final thisMonth    = value.getWorkoutsThisMonth();
        final streak       = value.getCurrentStreak();
        final totalWeight  = value.getTotalWeightLifted();
        final uniqueEx     = value.getUniqueExercisesLogged();
        final totalSets    = value.getTotalSetsLogged();
        final bwHistory    = value.getBodyWeightHistory();
        final workoutCount = value.getWorkoutList().length;
        final overallProgressPercent = value.getOverallProgressPercent();
        final prCount = value.getExerciseProgressList().length;
        final totalTime    = value.getTotalWorkoutTime();
        final avgTime      = value.getAverageWorkoutTime();

        // format total weight nicely
        String formatWeight(double kg) {
          if (kg >= 1000) {
            return '${(kg / 1000).toStringAsFixed(1)}t';
          }
          return '${kg.toStringAsFixed(0)}kg';
        }

        // format a duration as e.g. "1h 24m", "45m", or "—" for no data
        String formatDuration(Duration? d) {
          if (d == null) return '—';
          final h = d.inHours;
          final m = d.inMinutes % 60;
          if (h > 0) return '${h}h ${m}m';
          return '${m}m';
        }

        return Scaffold(
          appBar: AppBar(title: const Text('stats')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [

              // ── workout frequency ──────────────────────────────────────────
              _sectionHeader('workout frequency'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _bigStatCard('$thisMonth', 'workouts\nthis month', Icons.calendar_month_rounded, AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _bigStatCard('$allTime', 'workouts\nall time', Icons.emoji_events_rounded, const Color(0xFFF59E0B))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _bigStatCard('$streak', 'current\nday streak', Icons.local_fire_department_rounded, const Color(0xFFEF4444))),
                  const SizedBox(width: 10),
                  Expanded(child: _bigStatCard('$workoutCount', 'exercise\nroutines', Icons.fitness_center_rounded, const Color(0xFF10B981))),
                ],
              ),

              const SizedBox(height: 24),

              // ── time worked out ────────────────────────────────────────────
              _sectionHeader('time worked out'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _bigStatCard(formatDuration(avgTime), 'average\nper day', Icons.timer_rounded, const Color(0xFF06B6D4))),
                  const SizedBox(width: 10),
                  Expanded(child: _bigStatCard(formatDuration(totalTime), 'total time\nlogged', Icons.hourglass_bottom_rounded, const Color(0xFF8B5CF6))),
                ],
              ),

              const SizedBox(height: 24),

              // ── volume ─────────────────────────────────────────────────────
              _sectionHeader('volume'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _bigStatCard(formatWeight(totalWeight), 'total weight\nlifted', Icons.monitor_weight_rounded, AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _bigStatCard('$totalSets', 'total sets\ncompleted', Icons.layers_rounded, const Color(0xFF8B5CF6))),
                ],
              ),

              const SizedBox(height: 24),

              // ── exercise variety ───────────────────────────────────────────
              _sectionHeader('exercise variety'),
              const SizedBox(height: 10),
              _wideStatCard(
                '$uniqueEx',
                'unique exercises ever logged',
                Icons.shuffle_rounded,
                const Color(0xFF06B6D4),
              ),

              const SizedBox(height: 24),

              // ── progress & PRs (sub-pages) ──────────────────────────────────
              _sectionHeader('more'),
              const SizedBox(height: 10),
              _navTile(
                context: context,
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.primary,
                title: 'progress',
                subtitle: overallProgressPercent != null
                    ? 'avg change across all exercises'
                    : 'compare your earliest lifts to your latest',
                trailingText: overallProgressPercent != null
                    ? '${overallProgressPercent > 0 ? '+' : ''}${overallProgressPercent.toStringAsFixed(0)}%'
                    : null,
                trailingColor: overallProgressPercent == null
                    ? null
                    : (overallProgressPercent > 0
                        ? const Color(0xFF10B981)
                        : (overallProgressPercent < 0 ? AppColors.danger : AppColors.textSecondary)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressOverviewPage())),
              ),
              const SizedBox(height: 8),
              _navTile(
                context: context,
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'personal records',
                subtitle: prCount > 0 ? '$prCount exercise${prCount == 1 ? '' : 's'} tracked' : 'no PRs yet',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalRecordsPage())),
              ),

              const SizedBox(height: 24),

              // ── bodyweight ─────────────────────────────────────────────────
              if (bwHistory.isNotEmpty) ...[
                _sectionHeader('bodyweight'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _bigStatCard(
                      '${bwHistory.last.value.toStringAsFixed(1)} kg',
                      'current\nbodyweight',
                      Icons.person_rounded,
                      AppColors.primary,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: () {
                      final first = bwHistory.first.value;
                      final last  = bwHistory.last.value;
                      final diff  = last - first;
                      final sign  = diff > 0 ? '+' : '';
                      final color = diff < 0 ? const Color(0xFF10B981) : diff > 0 ? const Color(0xFFEF4444) : AppColors.textSecondary;
                      return _bigStatCard(
                        '$sign${diff.toStringAsFixed(1)} kg',
                        'total weight\nchange',
                        Icons.trending_up_rounded,
                        color,
                      );
                    }()),
                  ],
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _bigStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _navTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
    Color? trailingColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (trailingText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (trailingColor ?? AppColors.textSecondary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trailingText,
                  style: TextStyle(color: trailingColor ?? AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _wideStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
