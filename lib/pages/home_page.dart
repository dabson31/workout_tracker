import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/heat_map.dart';
import 'package:workout_tracker/components/premium_dialog.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/models/workout.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/pages/workout_page.dart';
import 'package:workout_tracker/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    Provider.of<WorkoutData>(context, listen: false).initializeWorkoutList();
  }

  final newWorkoutController  = TextEditingController();
  final editWorkoutController = TextEditingController();

  // ── workout CRUD ────────────────────────────────────────────────────────────

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
              Provider.of<WorkoutData>(context, listen: false)
                  .editWorkoutName(oldName, newName);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceLight,
                  behavior: SnackBarBehavior.floating,
                  content: const Text('workout renamed', style: TextStyle(color: AppColors.textPrimary)),
                  action: SnackBarAction(
                    label: 'undo',
                    textColor: AppColors.primary,
                    onPressed: () {
                      Provider.of<WorkoutData>(context, listen: false)
                          .editWorkoutName(newName, oldName);
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
          )
        ],
      ),
    );
  }

  void deleteWorkout(String workoutName) {
    final data = Provider.of<WorkoutData>(context, listen: false);
    // snapshot the whole workout for undo
    final workout = data.getRelevantWorkout(workoutName);
    final snapshotExercises = workout.exercises.map((e) => Exercise(
      name: e.name, weight: e.weight, reps: e.reps, sets: e.sets, isCompleted: e.isCompleted,
    )).toList();
    final snapshotIndex = data.getWorkoutList().indexOf(workout);

    data.deleteWorkout(workoutName);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        content: Text('"$workoutName" deleted', style: const TextStyle(color: AppColors.textPrimary)),
        action: SnackBarAction(
          label: 'undo',
          textColor: AppColors.primary,
          onPressed: () {
            final d = Provider.of<WorkoutData>(context, listen: false);
            final restored = Workout(name: workoutName, exercises: snapshotExercises);
            d.restoreWorkout(snapshotIndex, restored);
          },
        ),
      ),
    );
  }

  void goToWorkoutPage(String workoutName) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutPage(workoutName: workoutName)));
  }

  void save() {
    String newWorkoutName = newWorkoutController.text;
    Provider.of<WorkoutData>(context, listen: false).addWorkout(newWorkoutName);
    newWorkoutController.clear();
    Navigator.pop(context);
  }

  void cancel() {
    newWorkoutController.clear();
    Navigator.pop(context);
  }

  Widget buildWorkoutTile(String workoutName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.45,
          children: [
            SlidableAction(
              onPressed: (context) => editWorkout(workoutName),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'edit',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            SlidableAction(
              onPressed: (context) => deleteWorkout(workoutName),
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
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
            onTap: () => goToWorkoutPage(workoutName),
          ),
        ),
      ),
    );
  }

  // ── stats strip ─────────────────────────────────────────────────────────────

  Widget buildStatsStrip(WorkoutData value) {
    final thisMonth  = value.getWorkoutsThisMonth();
    final allTime    = value.getWorkoutsAllTime();
    final streak     = value.getCurrentStreak();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _statCell('$thisMonth', 'workouts\nthis month', Icons.calendar_month_rounded),
          _vertDivider(),
          _statCell('$allTime', 'workouts\nall time', Icons.emoji_events_rounded),
          _vertDivider(),
          _statCell('$streak', 'current\nday streak', Icons.local_fire_department_rounded),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _vertDivider() {
    return Container(width: 1, height: 40, color: AppColors.surfaceLight);
  }

  // ── day log sheet (heatmap tap) ──────────────────────────────────────────────

  final editLogNameController   = TextEditingController();
  final editLogWeightController = TextEditingController();
  final editLogRepsController   = TextEditingController();
  final editLogSetsController   = TextEditingController();

  void editDayLog(String ddmmyyyy, Map<String, String> log, VoidCallback onSaved) {
    editLogNameController.text   = log['exercise']!;
    editLogWeightController.text = log['weight']!;
    editLogRepsController.text   = log['reps']!;
    editLogSetsController.text   = log['sets']!;

    // snapshot for undo
    final oldName   = log['exercise']!;
    final oldWeight = log['weight']!;
    final oldReps   = log['reps']!;
    final oldSets   = log['sets']!;

    showPremiumDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: const Text('edit logged exercise', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editLogNameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'name',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: editLogWeightController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'weight',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: editLogRepsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'reps',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: editLogSetsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'sets',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Provider.of<WorkoutData>(context, listen: false).editLoggedExercise(
                ddmmyyyy,
                log['workout']!,
                oldName,
                editLogNameController.text,
                editLogWeightController.text,
                editLogRepsController.text,
                editLogSetsController.text,
              );
              Navigator.pop(context);
              onSaved();

              // undo
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceLight,
                  behavior: SnackBarBehavior.floating,
                  content: const Text('log updated', style: TextStyle(color: AppColors.textPrimary)),
                  action: SnackBarAction(
                    label: 'undo',
                    textColor: AppColors.primary,
                    onPressed: () {
                      Provider.of<WorkoutData>(context, listen: false).editLoggedExercise(
                        ddmmyyyy,
                        log['workout']!,
                        editLogNameController.text,
                        oldName, oldWeight, oldReps, oldSets,
                      );
                      onSaved();
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
          )
        ],
      ),
    );
  }

  final addLogWorkoutController = TextEditingController();
  final addLogNameController    = TextEditingController();
  final addLogWeightController  = TextEditingController();
  final addLogRepsController    = TextEditingController();
  final addLogSetsController    = TextEditingController();

  void addDayLog(String ddmmyyyy, VoidCallback onSaved) {
    addLogNameController.clear();
    addLogWeightController.clear();
    addLogRepsController.clear();
    addLogSetsController.clear();

    showPremiumDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: const Text('add to this day', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addLogNameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'exercise name',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addLogWeightController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'weight',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addLogRepsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'reps',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addLogSetsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'sets',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              if (addLogNameController.text.trim().isEmpty) return;
              Provider.of<WorkoutData>(context, listen: false).addLoggedExercise(
                ddmmyyyy,
                'Standalone',
                addLogNameController.text.trim(),
                addLogWeightController.text,
                addLogRepsController.text,
                addLogSetsController.text,
              );
              Navigator.pop(context);
              onSaved();
            },
            child: const Text('add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
          )
        ],
      ),
    );
  }

  // note/rest-day dialog  
  void showNoteDialog(String ddmmyyyy, String? existingNote, VoidCallback onSaved) {
    final isRest = existingNote != null && existingNote.startsWith('__REST__');
    final noteText = isRest ? existingNote.substring('__REST__'.length).trim() : (existingNote ?? '');

    final noteCtrl = TextEditingController(text: noteText);
    bool restDay = isRest;

    showPremiumDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          title: const Text('day note', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // rest day toggle
              GestureDetector(
                onTap: () => setDialogState(() => restDay = !restDay),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: restDay ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: restDay ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bedtime_rounded, color: restDay ? AppColors.primary : AppColors.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'mark as rest day',
                        style: TextStyle(
                          color: restDay ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (restDay) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'add a note (optional)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          ),
          actions: [
            if (existingNote != null)
              MaterialButton(
                onPressed: () {
                  Provider.of<WorkoutData>(ctx, listen: false).deleteDayNote(ddmmyyyy);
                  Navigator.pop(ctx);
                  onSaved();
                },
                child: const Text('remove', style: TextStyle(color: AppColors.danger)),
              ),
            MaterialButton(
              onPressed: () {
                final text = noteCtrl.text.trim();
                final stored = restDay ? '__REST__$text' : text;
                if (stored.isEmpty || stored == '__REST__') {
                  Provider.of<WorkoutData>(ctx, listen: false).deleteDayNote(ddmmyyyy);
                } else {
                  Provider.of<WorkoutData>(ctx, listen: false).saveDayNote(ddmmyyyy, stored);
                }
                Navigator.pop(ctx);
                onSaved();
              },
              child: const Text('save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            MaterialButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  void showDayLogSheet(DateTime date) {
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Consumer<WorkoutData>(
        builder: (context, value, _) {
          final logs = value.getLogsForDate(ddmmyyyy);
          final existingWorkoutNames = value.getWorkoutList().map((w) => w.name).toList();
          final note = value.getDayNote(ddmmyyyy);
          final isRestDay = note != null && note.startsWith('__REST__');
          final noteText = note != null
              ? (isRestDay ? note.substring('__REST__'.length).trim() : note)
              : null;
          void setSheetState(VoidCallback fn) { fn(); }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: ListView(
                controller: scrollController,
                children: [
                  // header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          // note/rest day button
                          IconButton(
                            onPressed: () => showNoteDialog(ddmmyyyy, note, () => setSheetState(() {})),
                            icon: Icon(
                              Icons.edit_note_rounded,
                              color: note != null ? AppColors.primary : AppColors.textSecondary,
                            ),
                            tooltip: 'add note / rest day',
                          ),
                          // add exercise log
                          IconButton(
                            onPressed: () => addDayLog(ddmmyyyy, () => setSheetState(() {})),
                            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // rest day / note badge
                  if (isRestDay || (noteText != null && noteText.isNotEmpty))
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isRestDay
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: isRestDay
                            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRestDay ? Icons.bedtime_rounded : Icons.notes_rounded,
                            color: isRestDay ? AppColors.primary : AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isRestDay
                                  ? (noteText != null && noteText.isNotEmpty ? 'rest day · $noteText' : 'rest day')
                                  : noteText!,
                              style: TextStyle(
                                color: isRestDay ? AppColors.primary : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 6),

                  // exercise logs
                  if (logs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: const Text('nothing logged this day', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    ...logs.map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Slidable(
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.4,
                              children: [
                                SlidableAction(
                                  onPressed: (context) => editDayLog(ddmmyyyy, log, () => setSheetState(() {})),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit_rounded,
                                  label: 'edit',
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                ),
                                SlidableAction(
                                  onPressed: (context) {
                                    // snapshot for undo
                                    final snap = Map<String, String>.from(log);
                                    Provider.of<WorkoutData>(context, listen: false)
                                        .deleteLoggedExercise(ddmmyyyy, log['workout']!, log['exercise']!);
                                    setSheetState(() {});

                                    ScaffoldMessenger.of(this.context).clearSnackBars();
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.surfaceLight,
                                        behavior: SnackBarBehavior.floating,
                                        content: Text('"${snap['exercise']}" removed', style: const TextStyle(color: AppColors.textPrimary)),
                                        action: SnackBarAction(
                                          label: 'undo',
                                          textColor: AppColors.primary,
                                          onPressed: () {
                                            Provider.of<WorkoutData>(this.context, listen: false)
                                                .addLoggedExercise(ddmmyyyy, snap['workout']!, snap['exercise']!, snap['weight']!, snap['reps']!, snap['sets']!);
                                            setSheetState(() {});
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete_rounded,
                                  label: 'delete',
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['exercise']!,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _buildLogStatChip(log['weight']!, Icons.scale_rounded),
                                            _buildLogStatChip('${log['reps']} reps', Icons.repeat_rounded),
                                            _buildLogStatChip('${log['sets']} sets', Icons.layers_rounded),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        final workouts = value.getWorkoutList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('workout tracker'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              // stats strip
              buildStatsStrip(value),

              // heat map
              MyHeatMap(
                datasets: value.heatMapDataSet,
                onDayTap: (date) => showDayLogSheet(date),
              ),

              const SizedBox(height: 16),

              if (workouts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.bedtime_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'no workouts yet, tap + to start one',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...workouts.map((workout) => buildWorkoutTile(workout.name)),

              const SizedBox(height: 12),

              // inline "add workout" button, sits right under the workout
              // list/empty-state instead of floating over the screen
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: createNewWorkout,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'add workout',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}