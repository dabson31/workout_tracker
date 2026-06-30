import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/exercise_tile.dart';
import 'package:workout_tracker/components/premium_dialog.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class WorkoutPage extends StatefulWidget {
  final String workoutName;
  const WorkoutPage({super.key, required this.workoutName});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {

  // toggle reorder mode
  bool _reorderMode = false;

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

  void onCheckBoxChanged(String workoutName, String exerciseName, bool? newValue, String prevWeight, String prevReps, String prevSets) {
    if (newValue == true) {
      openLogDialog(workoutName, exerciseName, prevWeight, prevReps, prevSets);
    } else {
      Provider.of<WorkoutData>(context, listen: false).unlogExercise(workoutName, exerciseName);
    }
  }

  void openLogDialog(String workoutName, String exerciseName, String prevWeight, String prevReps, String prevSets) {
    final prevWeightClean = prevWeight.replaceAll(RegExp(r'kg$', caseSensitive: false), '');

    // support both old single-weight ("25") and new per-set ("20,22.5,25") formats
    final prevWeightParts = prevWeightClean.split(',').map((s) => s.trim()).toList();
    final prevRepsParts = prevReps.split(',').map((s) => s.trim()).toList();

    final setsController = TextEditingController(text: prevSets);

    showPremiumDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // keep weight/reps controllers in sync with the sets field
          int setsCount = int.tryParse(setsController.text) ?? 1;
          if (setsCount < 1) setsCount = 1;
          if (setsCount > 20) setsCount = 20;

          // lazily initialise once; grow/shrink as setsCount changes
          if (!_weightControllers.containsKey(exerciseName) ||
              _weightControllers[exerciseName]!.length != setsCount) {
            final existing = _weightControllers[exerciseName] ?? <TextEditingController>[];
            final next = List.generate(setsCount, (i) {
              if (i < existing.length) return existing[i];
              final seed = i < prevWeightParts.length ? prevWeightParts[i] : (prevWeightParts.isNotEmpty ? prevWeightParts.last : '');
              return TextEditingController(text: seed);
            });
            _weightControllers[exerciseName] = next;
          }
          if (!_repsControllers.containsKey(exerciseName) ||
              _repsControllers[exerciseName]!.length != setsCount) {
            final existing = _repsControllers[exerciseName] ?? <TextEditingController>[];
            final next = List.generate(setsCount, (i) {
              if (i < existing.length) return existing[i];
              final seed = i < prevRepsParts.length ? prevRepsParts[i] : (prevRepsParts.isNotEmpty ? prevRepsParts.last : '');
              return TextEditingController(text: seed);
            });
            _repsControllers[exerciseName] = next;
          }
          final weightControllers = _weightControllers[exerciseName]!;
          final repsControllers = _repsControllers[exerciseName]!;

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 12,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            title: Text('log $exerciseName', style: const TextStyle(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'previous: $prevWeight, $prevReps reps, $prevSets sets',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: fieldDecoration('sets'),
                    onChanged: (_) => setDialogState(() {}),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'reps & weight per set',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // one reps + weight row per set
                  ...List.generate(setsCount, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: repsControllers[i],
                            autofocus: i == 0,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: fieldDecoration('set ${i + 1} reps'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightControllers[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: fieldDecoration('set ${i + 1} weight').copyWith(
                              suffixText: 'kg',
                              suffixStyle: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  final setsN = int.tryParse(setsController.text) ?? 1;
                  final wControllers = _weightControllers[exerciseName] ?? [];
                  final rControllers = _repsControllers[exerciseName] ?? [];
                  // build comma-separated weight/reps strings, one value per set
                  final weightString = List.generate(
                    setsN.clamp(1, wControllers.length),
                    (i) => '${wControllers[i].text}kg',
                  ).join(',');
                  final repsString = List.generate(
                    setsN.clamp(1, rControllers.length),
                    (i) => rControllers[i].text,
                  ).join(',');

                  Provider.of<WorkoutData>(context, listen: false).logExercise(
                    workoutName,
                    exerciseName,
                    weightString,
                    repsString,
                    setsController.text,
                  );
                  _weightControllers.remove(exerciseName);
                  _repsControllers.remove(exerciseName);
                  Navigator.pop(context);
                },
                child: const Text('log it', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              MaterialButton(
                onPressed: () {
                  _weightControllers.remove(exerciseName);
                  _repsControllers.remove(exerciseName);
                  Navigator.pop(context);
                },
                child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          );
        },
      ),
    );
  }

  // temporary per-exercise weight/reps controller maps, keyed by exercise
  // name. stored at State level so they survive dialog rebuilds
  // (StatefulBuilder re-runs the builder on every setDialogState call).
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};

  final editExerciseController = TextEditingController();

  void editExercise(String workoutName, Exercise exercise) {
    // snapshot for undo
    final oldName   = exercise.name;
    final oldWeight = exercise.weight;
    final oldReps   = exercise.reps;
    final oldSets   = exercise.sets;

    final nameCtrl   = TextEditingController(text: oldName);
    final weightCtrl = TextEditingController(text: oldWeight.replaceAll(RegExp(r'kg$', caseSensitive: false), ''));
    final repsCtrl   = TextEditingController(text: oldReps);
    final setsCtrl   = TextEditingController(text: oldSets);

    showPremiumDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: const Text('edit exercise', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('exercise name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('weight').copyWith(
                suffixText: 'kg',
                suffixStyle: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: repsCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('reps'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: setsCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: fieldDecoration('sets'),
            ),
          ],
        ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              final data = Provider.of<WorkoutData>(context, listen: false);
              final newName = nameCtrl.text.trim();

              // apply all changes
              if (newName != oldName) {
                data.editExerciseName(workoutName, oldName, newName);
              }
              // update weight/reps/sets directly
              try {
                data.updateExerciseDetails(workoutName, newName, '${weightCtrl.text}kg', repsCtrl.text, setsCtrl.text);
              } catch (_) {}

              Navigator.pop(context);

              // undo snackbar
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 5),
                  backgroundColor: AppColors.surfaceLight,
                  behavior: SnackBarBehavior.floating,
                  content: const Text('exercise updated', style: TextStyle(color: AppColors.textPrimary)),
                  action: SnackBarAction(
                    label: 'undo',
                    textColor: AppColors.primary,
                    onPressed: () {
                      try {
                        final d = Provider.of<WorkoutData>(context, listen: false);
                        if (newName != oldName) d.editExerciseName(workoutName, newName, oldName);
                        d.updateExerciseDetails(workoutName, oldName, oldWeight, oldReps, oldSets);
                      } catch (_) {}
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

  void deleteExercise(String workoutName, Exercise exercise) {
    // snapshot for undo
    final snapshot = Exercise(
      name: exercise.name,
      weight: exercise.weight,
      reps: exercise.reps,
      sets: exercise.sets,
      isCompleted: exercise.isCompleted,
    );
    // find current index for restore
    final data = Provider.of<WorkoutData>(context, listen: false);
    final idx = data.getRelevantWorkout(workoutName).exercises.indexWhere((e) => e.name == exercise.name);

    data.deleteExercise(workoutName, exercise.name);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        content: Text('"${snapshot.name}" deleted', style: const TextStyle(color: AppColors.textPrimary)),
        action: SnackBarAction(
          label: 'undo',
          textColor: AppColors.primary,
          onPressed: () {
            final d = Provider.of<WorkoutData>(context, listen: false);
            d.restoreExercise(workoutName, idx, snapshot);
          },
        ),
      ),
    );
  }

  final exerciseNameController = TextEditingController();
  final weightController = TextEditingController();
  final repsController = TextEditingController();
  final setsController = TextEditingController();

  void createNewExercise() {
    showPremiumDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: const Text('add new exercise', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
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

  Widget _buildAddExerciseButton() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: createNewExercise,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'add exercise',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        final exerciseCount = value.numberOfExercisesInWorkout(widget.workoutName);
        final exercises = value.getRelevantWorkout(widget.workoutName).exercises;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.workoutName),
            actions: [
              if (exerciseCount > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _reorderMode = !_reorderMode),
                    icon: Icon(
                      _reorderMode ? Icons.check_rounded : Icons.reorder_rounded,
                      size: 18,
                      color: _reorderMode ? AppColors.primary : AppColors.textSecondary,
                    ),
                    label: Text(
                      _reorderMode ? 'done' : 'reorder',
                      style: TextStyle(
                        color: _reorderMode ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
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
                          'no exercises yet, tap below to add your first one',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        _buildAddExerciseButton(),
                      ],
                    ),
                  ),
                )
              : _reorderMode
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                      itemCount: exerciseCount,
                      onReorderItem: (oldIndex, newIndex) {
                        value.reorderExercise(widget.workoutName, oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return Container(
                          key: ValueKey(exercise.name),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: const Icon(Icons.drag_handle_rounded, color: AppColors.textSecondary),
                            title: Text(
                              exercise.name,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${exercise.weight} · ${exercise.reps} reps · ${exercise.sets} sets',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                      itemCount: exerciseCount + 1,
                      itemBuilder: (context, index) {
                        // trailing inline "add exercise" button, sits right
                        // under the exercise list instead of floating
                        if (index == exerciseCount) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _buildAddExerciseButton(),
                          );
                        }

                        final exercise = exercises[index];

                        return Slidable(
                          key: ValueKey(exercise.name),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.45,
                            children: [
                              SlidableAction(
                                onPressed: (context) => editExercise(widget.workoutName, exercise),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                icon: Icons.edit_rounded,
                                label: 'edit',
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              ),
                              SlidableAction(
                                onPressed: (context) => deleteExercise(widget.workoutName, exercise),
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
