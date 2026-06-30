import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/premium_dialog.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/workout.dart';
import 'package:workout_tracker/pages/workout_page.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class WorkoutsListPage extends StatefulWidget {
  const WorkoutsListPage({super.key});

  @override
  State<WorkoutsListPage> createState() => _WorkoutsListPageState();
}

class _WorkoutsListPageState extends State<WorkoutsListPage> {
  final newWorkoutController  = TextEditingController();
  final editWorkoutController = TextEditingController();

  // ── workout CRUD ─────────────────────────────────────────────────────────────

  void createNewWorkout() {
    newWorkoutController.clear();
    showPremiumDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: const Text('create new workout', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: newWorkoutController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. push day',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              final name = newWorkoutController.text.trim();
              if (name.isEmpty) return;
              Provider.of<WorkoutData>(context, listen: false).addWorkout(name);
              newWorkoutController.clear();
              Navigator.pop(context);
            },
            child: const Text('save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          MaterialButton(
            onPressed: () {
              newWorkoutController.clear();
              Navigator.pop(context);
            },
            child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void editWorkout(String oldName) {
    editWorkoutController.text = oldName;
    showPremiumDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: const Text('rename workout', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: editWorkoutController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              final newName = editWorkoutController.text.trim();
              Provider.of<WorkoutData>(context, listen: false).editWorkoutName(oldName, newName);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 5),
                  backgroundColor: AppColors.surfaceLight,
                  behavior: SnackBarBehavior.floating,
                  content: const Text('workout renamed', style: TextStyle(color: AppColors.textPrimary)),
                  action: SnackBarAction(
                    label: 'undo',
                    textColor: AppColors.primary,
                    onPressed: () => Provider.of<WorkoutData>(context, listen: false).editWorkoutName(newName, oldName),
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

  void deleteWorkout(String workoutName) {
    final data = Provider.of<WorkoutData>(context, listen: false);
    final workout = data.getRelevantWorkout(workoutName);
    final snapshotExercises = workout.exercises.map((e) => Exercise(
      name: e.name, weight: e.weight, reps: e.reps, sets: e.sets, isCompleted: e.isCompleted,
    )).toList();
    final snapshotIndex = data.getWorkoutList().indexOf(workout);

    data.deleteWorkout(workoutName);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        content: Text('"$workoutName" deleted', style: const TextStyle(color: AppColors.textPrimary)),
        action: SnackBarAction(
          label: 'undo',
          textColor: AppColors.primary,
          onPressed: () {
            final d = Provider.of<WorkoutData>(context, listen: false);
            d.restoreWorkout(snapshotIndex, Workout(name: workoutName, exercises: snapshotExercises));
          },
        ),
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────────

  /// Last completed date string for a workout, or null if never logged.
  String? _lastCompletedLabel(WorkoutData data, String workoutName) {
    final grouped = data.db.getAllExerciseLogsGrouped();
    DateTime? latest;
    for (final logs in grouped.values) {
      for (final log in logs) {
        if (log.workoutName == workoutName) {
          if (latest == null || log.date.isAfter(latest)) latest = log.date;
        }
      }
    }
    if (latest == null) return null;
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(latest.year, latest.month, latest.day))
        .inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '$diff days ago';
  }

  Widget _buildWorkoutTile(WorkoutData data, String workoutName) {
    final exerciseCount = data.numberOfExercisesInWorkout(workoutName);
    final lastLabel     = _lastCompletedLabel(data, workoutName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.45,
          children: [
            SlidableAction(
              onPressed: (_) => editWorkout(workoutName),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'edit',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            SlidableAction(
              onPressed: (_) => deleteWorkout(workoutName),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'delete',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 20),
            ),
            title: Text(
              workoutName,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              exerciseCount == 0
                  ? 'no exercises yet'
                  : '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}${lastLabel != null ? ' · last done $lastLabel' : ''}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WorkoutPage(workoutName: workoutName)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: createNewWorkout,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('add workout', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, data, _) {
        final workouts = data.getWorkoutList();

        return Scaffold(
          appBar: AppBar(title: const Text('workouts')),
          body: workouts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center_rounded,
                          color: AppColors.textSecondary.withValues(alpha: 0.4), size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'no workouts yet',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'tap below to create your first workout',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      _buildAddButton(),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: workouts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == workouts.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildAddButton(),
                      );
                    }
                    return _buildWorkoutTile(data, workouts[index].name);
                  },
                ),
        );
      },
    );
  }
}
