import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/heat_map.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/datetime/date_time.dart';
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

  final newWorkoutController = TextEditingController();
  final editWorkoutController = TextEditingController();

  // new workout
  void createNewWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

  // edit existing workout name
  void editWorkout(String oldName) {
    editWorkoutController.text = oldName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('rename workout', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: editWorkoutController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Provider.of<WorkoutData>(context, listen: false)
                  .editWorkoutName(oldName, editWorkoutController.text);
              Navigator.pop(context);
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

  // confirm before deleting
  void confirmDelete(String workoutName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('delete workout?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'this will permanently remove "$workoutName"',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Provider.of<WorkoutData>(context, listen: false).deleteWorkout(workoutName);
              Navigator.pop(context);
            },
            child: const Text('delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
          )
        ],
      ),
    );
  }

  // go to workout page
  void goToWorkoutPage(String workoutName) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutPage(workoutName: workoutName)));
  }

  // save func
  void save() {
    String newWorkoutName = newWorkoutController.text;
    Provider.of<WorkoutData>(context, listen: false).addWorkout(newWorkoutName);
    newWorkoutController.clear();
    Navigator.pop(context);
  }

  // cancel func
  void cancel() {
    newWorkoutController.clear();
    Navigator.pop(context);
  }

  // builds a single swipeable workout tile
  Widget buildWorkoutTile(String workoutName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        // swipe left to reveal these actions
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
              onPressed: (context) => confirmDelete(workoutName),
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

  // shows everything logged on a tapped heatmap day
  void showDayLogSheet(WorkoutData value, DateTime date) {
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(date);
    final logs = value.getLogsForDate(ddmmyyyy);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            if (logs.isEmpty)
              const Text('nothing logged this day', style: TextStyle(color: AppColors.textSecondary))
            else
              ...logs.map((log) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${log['exercise']} — ${log['weight']}, ${log['reps']} reps, ${log['sets']} sets',
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 10),
          ],
        ),
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
          floatingActionButton: FloatingActionButton(
            onPressed: createNewWorkout,
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            children: [
              // heat map showing daily completion history
              MyHeatMap(
                datasets: value.heatMapDataSet,
                startDateDDMMYYYY: value.getStartDate(),
                onDayTap: (date) => showDayLogSheet(value, date),
              ),

              const SizedBox(height: 16),

              // empty state when no workouts exist yet
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
                // workout list, one swipeable tile per workout
                ...workouts.map((workout) => buildWorkoutTile(workout.name)),
            ],
          ),
        );
      },
    );
  }
}