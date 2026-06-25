import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/exercise_tile.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class WorkoutPage extends StatefulWidget {
  final String workoutName;
  const WorkoutPage({super.key, required this.workoutName});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {

  // shared style for the dialog inputs
  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  // called when the checkbox on an exercise tile changes
  void onCheckBoxChanged(String workoutName, String exerciseName, bool? newValue, String prevWeight, String prevReps, String prevSets) {
    if (newValue == true) {
      // checking it off opens the log dialog so we record what was actually done
      openLogDialog(workoutName, exerciseName, prevWeight, prevReps, prevSets);
    } else {
      // unchecking just clears todays completion, history stays intact
      Provider.of<WorkoutData>(context, listen: false).unlogExercise(workoutName, exerciseName);
    }
  }

  // dialog to enter todays actual weight/reps/sets, prefilled with the previous lift
  void openLogDialog(String workoutName, String exerciseName, String prevWeight, String prevReps, String prevSets) {
    // strip any existing "kg" so the prefilled field just shows the number
    final prevWeightNumberOnly = prevWeight.replaceAll(RegExp(r'kg$', caseSensitive: false), '');

    final weightController = TextEditingController(text: prevWeightNumberOnly);
    final repsController = TextEditingController(text: prevReps);
    final setsController = TextEditingController(text: prevSets);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('log $exerciseName', style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // shows what was previously lifted for reference
            Text(
              'previous: $prevWeight, $prevReps reps, $prevSets sets',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('weight').copyWith(
                suffixText: 'kg',
                suffixStyle: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: repsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('reps'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: setsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('sets'),
            ),
          ],
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Provider.of<WorkoutData>(context, listen: false).logExercise(
                workoutName,
                exerciseName,
                '${weightController.text}kg',
                repsController.text,
                setsController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('log it', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  final editExerciseController = TextEditingController();

  // dialog to rename an existing exercise
  void editExercise(String workoutName, String oldName) {
    editExerciseController.text = oldName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('rename exercise', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: editExerciseController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: fieldDecoration('exercise name'),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Provider.of<WorkoutData>(context, listen: false)
                  .editExerciseName(workoutName, oldName, editExerciseController.text);
              Navigator.pop(context);
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

  // confirm before permanently removing an exercise
  void confirmDeleteExercise(String workoutName, String exerciseName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('delete exercise?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'this will permanently remove "$exerciseName"',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Provider.of<WorkoutData>(context, listen: false).deleteExercise(workoutName, exerciseName);
              Navigator.pop(context);
            },
            child: const Text('delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // text controllers for adding a brand new exercise
  final exerciseNameController = TextEditingController();
  final weightController = TextEditingController();
  final repsController = TextEditingController();
  final setsController = TextEditingController();

  void createNewExercise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('add new exercise', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: exerciseNameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('exercise name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('weight').copyWith(
                suffixText: 'kg',
                suffixStyle: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: repsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('reps'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: setsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('sets'),
            ),
          ],
        ),
        actions: [
          MaterialButton(
            onPressed: save,
            child: const Text('save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          MaterialButton(
            onPressed: cancel,
            child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
          )
        ],
      ),
    );
  }

  void save() {
    Provider.of<WorkoutData>(context, listen: false).addExercise(
      widget.workoutName,
      exerciseNameController.text,
      '${weightController.text}kg',
      repsController.text,
      setsController.text,
    );

    exerciseNameController.clear();
    weightController.clear();
    repsController.clear();
    setsController.clear();

    Navigator.pop(context);
  }

  void cancel() {
    exerciseNameController.clear();
    weightController.clear();
    repsController.clear();
    setsController.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        final exerciseCount = value.numberOfExercisesInWorkout(widget.workoutName);

        return Scaffold(
          appBar: AppBar(title: Text(widget.workoutName)),
          floatingActionButton: FloatingActionButton(
            onPressed: createNewExercise,
            child: const Icon(Icons.add),
          ),
          body: exerciseCount == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.textSecondary.withValues(alpha: 0.6), size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'no exercises yet, tap + to add your first one',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                  itemCount: exerciseCount,
                  itemBuilder: (context, index) {
                    final exercise = value.getRelevantWorkout(widget.workoutName).exercises[index];

                    return Slidable(
                      // swipe left to reveal edit and delete
                      key: ValueKey(exercise.name),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.45,
                        children: [
                          SlidableAction(
                            onPressed: (context) => editExercise(widget.workoutName, exercise.name),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            icon: Icons.edit_rounded,
                            label: 'edit',
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                          ),
                          SlidableAction(
                            onPressed: (context) => confirmDeleteExercise(widget.workoutName, exercise.name),
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_rounded,
                            label: 'delete',
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                          ),
                        ],
                      ),
                      child: ExerciseTile(
                        exerciseName: exercise.name,
                        weight: exercise.weight,
                        reps: exercise.reps,
                        sets: exercise.sets,
                        isCompleted: exercise.isCompleted,
                        onCheckBoxChanged: (val) => onCheckBoxChanged(
                          widget.workoutName,
                          exercise.name,
                          val,
                          exercise.weight,
                          exercise.reps,
                          exercise.sets,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}