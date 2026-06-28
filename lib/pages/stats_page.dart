import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/data/workout_data.dart';
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

        // format total weight nicely
        String formatWeight(double kg) {
          if (kg >= 1000) {
            return '${(kg / 1000).toStringAsFixed(1)}t';
          }
          return '${kg.toStringAsFixed(0)}kg';
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
