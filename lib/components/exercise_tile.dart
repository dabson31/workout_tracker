import 'package:flutter/material.dart';
import 'package:workout_tracker/theme/app_theme.dart';
import 'package:workout_tracker/utils/format_utils.dart';

class ExerciseTile extends StatelessWidget {
  final String exerciseName;
  final String weight;
  final String reps;
  final String sets;
  final bool isCompleted;
  final Function(bool?) onCheckBoxChanged;

  const ExerciseTile({
    super.key,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.isCompleted,
    required this.onCheckBoxChanged,
  });

  // "8" -> "8 reps", but "set 1: 8  set 2: 6" stays as-is (already self-explanatory)
  String _repsLabel(String raw) {
    final formatted = formatPerSetValue(raw);
    return formatted.contains('set ') ? formatted : '$formatted reps';
  }

  // small pill used for weight/reps/sets stats
  Widget buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          exerciseName,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            decorationColor: AppColors.textSecondary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            children: [
              buildStatChip(formatPerSetValue(weight), Icons.fitness_center_rounded),
              buildStatChip(_repsLabel(reps), Icons.repeat_rounded),
              buildStatChip('$sets sets', Icons.layers_rounded),
            ],
          ),
        ),
        trailing: Transform.scale(
          scale: 1.15,
          child: Checkbox(
            value: isCompleted,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (value) => onCheckBoxChanged(value),
          ),
        ),
      ),
    );
  }
}