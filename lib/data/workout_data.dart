import 'package:workout_tracker/data/hive_database.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/exercise_log_entry.dart';
import 'package:workout_tracker/models/exercise_progress.dart';
import 'package:workout_tracker/models/goal.dart';
import 'package:workout_tracker/models/goal_progress.dart';
import 'package:workout_tracker/models/workout.dart';
import 'package:flutter/foundation.dart';

class WorkoutData extends ChangeNotifier {

final db = HiveDatabase();

  List<Workout> workoutList = [
    Workout(
      name: "Upper Body",
      exercises: [
        Exercise(
          name: "Bench Press",
          weight: "25kg",
          reps: "8",
          sets: "2"
        )
      ]
    ),
  ];

  void initializeWorkoutList() {
      if(db.previousDataExists()) {
        workoutList = db.readFromDatabase();
      } else {
        db.saveToDatabase(workoutList);
      }

      if (db.isNewDay()) {
        resetDailyCompletion();
      }

      loadHeatMap();
  }

  void resetDailyCompletion() {
    for (var workout in workoutList) {
      for (var exercise in workout.exercises) {
        exercise.isCompleted = false;
      }
    }
    db.saveToDatabase(workoutList);
  }

  List<Workout> getWorkoutList() {
    return workoutList;
  }

  int numberOfExercisesInWorkout(String workoutName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    return relevantWorkout.exercises.length;
  }

  void addWorkout(String name) {
    workoutList.add(Workout(name: name, exercises: []));
    notifyListeners();
    db.saveToDatabase(workoutList);
  }

  void editWorkoutName(String oldName, String newName) {
    Workout relevantWorkout = getRelevantWorkout(oldName);
    relevantWorkout.name = newName;
    notifyListeners();
    db.saveToDatabase(workoutList);
  }

  void deleteWorkout(String workoutName) {
    workoutList.removeWhere((workout) => workout.name == workoutName);
    db.saveToDatabase(workoutList);
    loadHeatMap();
    notifyListeners();
  }

  void addExercise(String workoutName, String exerciseName, String weight, String reps, String sets) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    relevantWorkout.exercises.add(
      Exercise(
        name: exerciseName,
        weight: weight,
        reps: reps,
        sets: sets
        ));
    notifyListeners();
    db.saveToDatabase(workoutList);
  }

  void logExercise(String workoutName, String exerciseName, String weight, String reps, String sets) {
    Exercise relevantExercise = getRelevantExercise(workoutName, exerciseName);
    relevantExercise.weight = weight;
    relevantExercise.reps = reps;
    relevantExercise.sets = sets;
    relevantExercise.isCompleted = true;

    final today = todaysDateDDMMYYYY();
    db.saveExerciseLog(today, workoutName, exerciseName, weight, reps, sets);
    db.saveToDatabase(workoutList);
    db.recomputeCompletionStatus(today);
    loadHeatMap();
    notifyListeners();
  }

  void unlogExercise(String workoutName, String exerciseName) {
    Exercise relevantExercise = getRelevantExercise(workoutName, exerciseName);
    relevantExercise.isCompleted = false;
    db.saveToDatabase(workoutList);
    db.recomputeCompletionStatus(todaysDateDDMMYYYY());
    loadHeatMap();
    notifyListeners();
  }

  void addLoggedExercise(String ddmmyyyy, String workoutName, String exerciseName, String weight, String reps, String sets) {
    db.saveExerciseLog(ddmmyyyy, workoutName, exerciseName, weight, reps, sets);
    db.recomputeCompletionStatus(ddmmyyyy);
    loadHeatMap();
    notifyListeners();
  }

  void editLoggedExercise(String ddmmyyyy, String workoutName, String oldExerciseName, String newExerciseName, String weight, String reps, String sets) {
    db.updateExerciseLog(ddmmyyyy, workoutName, oldExerciseName, newExerciseName, weight, reps, sets);
    db.recomputeCompletionStatus(ddmmyyyy);
    loadHeatMap();
    notifyListeners();
  }

  void deleteLoggedExercise(String ddmmyyyy, String workoutName, String exerciseName) {
    db.deleteExerciseLog(ddmmyyyy, workoutName, exerciseName);
    db.recomputeCompletionStatus(ddmmyyyy);
    loadHeatMap();
    notifyListeners();
  }

  List<Map<String, String>> getLogsForDate(String ddmmyyyy) {
    return db.getExerciseLogsForDate(ddmmyyyy);
  }

  void deleteExercise(String workoutName, String exerciseName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    relevantWorkout.exercises.removeWhere((exercise) => exercise.name == exerciseName);
    db.saveToDatabase(workoutList);
    loadHeatMap();
    notifyListeners();
  }

  void editExerciseName(String workoutName, String oldName, String newName) {
    Exercise relevantExercise = getRelevantExercise(workoutName, oldName);
    relevantExercise.name = newName;

    // keep every historical log (and any goal tracking this exercise)
    // attached to the renamed exercise rather than letting them split
    // off under the old name.
    db.renameExerciseInAllLogs(oldName, newName);
    final goals = db.getGoals();
    bool goalsChanged = false;
    for (int i = 0; i < goals.length; i++) {
      if (goals[i].type == GoalType.exercise && goals[i].exerciseName == oldName) {
        goals[i] = goals[i].copyWith(exerciseName: newName);
        goalsChanged = true;
      }
    }
    if (goalsChanged) db.saveGoals(goals);

    loadHeatMap();
    notifyListeners();
    db.saveToDatabase(workoutList);
  }

  // updates an existing exercise's weight/reps/sets in place (used by the
  // "edit exercise" dialog and its undo action)
  void updateExerciseDetails(String workoutName, String exerciseName, String weight, String reps, String sets) {
    final ex = getRelevantExercise(workoutName, exerciseName);
    ex.weight = weight;
    ex.reps = reps;
    ex.sets = sets;
    db.saveToDatabase(workoutList);
    notifyListeners();
  }

  // re-inserts a previously deleted workout at the given index (undo)
  void restoreWorkout(int index, Workout workout) {
    final insertAt = index.clamp(0, workoutList.length);
    workoutList.insert(insertAt, workout);
    db.saveToDatabase(workoutList);
    loadHeatMap();
    notifyListeners();
  }

  // re-inserts a previously deleted exercise at the given index (undo)
  void restoreExercise(String workoutName, int index, Exercise exercise) {
    final exercises = getRelevantWorkout(workoutName).exercises;
    final insertAt = index.clamp(0, exercises.length);
    exercises.insert(insertAt, exercise);
    db.saveToDatabase(workoutList);
    loadHeatMap();
    notifyListeners();
  }

  // reorder an exercise within a workout (drag to reorder)
  void reorderExercise(String workoutName, int oldIndex, int newIndex) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    final exercises = relevantWorkout.exercises;
    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);
    notifyListeners();
    db.saveToDatabase(workoutList);
  }

  // ── Day notes & rest days ────────────────────────────────────────────────

  void saveDayNote(String ddmmyyyy, String note) {
    db.saveDayNote(ddmmyyyy, note);
    loadHeatMap();
    notifyListeners();
  }

  String? getDayNote(String ddmmyyyy) {
    return db.getDayNote(ddmmyyyy);
  }

  void deleteDayNote(String ddmmyyyy) {
    db.deleteDayNote(ddmmyyyy);
    loadHeatMap();
    notifyListeners();
  }

  // ── Bodyweight ───────────────────────────────────────────────────────────

  void logBodyWeight(double weightKg) {
    db.saveBodyWeight(todaysDateDDMMYYYY(), weightKg);
    notifyListeners();
  }

  void editBodyWeight(String ddmmyyyy, double weightKg) {
    db.saveBodyWeight(ddmmyyyy, weightKg);
    notifyListeners();
  }

  void deleteBodyWeight(String ddmmyyyy) {
    db.deleteBodyWeight(ddmmyyyy);
    notifyListeners();
  }

  List<MapEntry<DateTime, double>> getBodyWeightHistory() {
    return db.getBodyWeightHistory();
  }

  // ── Stats ────────────────────────────────────────────────────────────────

  int getWorkoutsThisMonth() => db.workoutsThisMonth();
  int getWorkoutsAllTime()   => db.workoutsAllTime();
  double getTotalWeightLifted() => db.totalWeightLifted();
  int getUniqueExercisesLogged() => db.uniqueExercisesLogged();
  int getTotalSetsLogged() => db.totalSetsLogged();
  int getCurrentStreak() => db.currentStreak();
  Duration getTotalWorkoutTime() => db.totalWorkoutTime();
  Duration? getAverageWorkoutTime() => db.averageWorkoutTime();

  // ── Exercise progress & PRs ─────────────────────────────────────────────

  // for every exercise that's ever been logged, compares the average
  // weight of its earliest logs against its most recent logs (up to 10
  // each; fewer if there isn't 10+ worth of history yet) and surfaces its
  // all-time PR (heaviest weight ever logged for that exercise).
  List<ExerciseProgress> getExerciseProgressList() {
    final grouped = db.getAllExerciseLogsGrouped();
    final List<ExerciseProgress> result = [];

    grouped.forEach((name, logs) {
      // logs are already sorted oldest -> newest by getAllExerciseLogsGrouped
      if (logs.isEmpty) return;

      // use windows of 10 once there's enough history (20+ logs), otherwise
      // split whatever's there into non-overlapping first/last halves so
      // newer exercises still show a (rougher) comparison instead of nothing
      final windowSize = logs.length >= 20 ? 10 : logs.length ~/ 2;

      final firstWindow = windowSize > 0 ? logs.take(windowSize).toList() : <ExerciseLogEntry>[];
      final latestWindow = windowSize > 0 ? logs.skip(logs.length - windowSize).toList() : <ExerciseLogEntry>[];

      final firstAvg = firstWindow.isEmpty
          ? 0.0
          : firstWindow.map((e) => e.weightKg).reduce((a, b) => a + b) / firstWindow.length;
      final latestAvg = latestWindow.isEmpty
          ? 0.0
          : latestWindow.map((e) => e.weightKg).reduce((a, b) => a + b) / latestWindow.length;

      final pr = logs.reduce((a, b) => a.weightKg >= b.weightKg ? a : b);

      result.add(ExerciseProgress(
        exerciseName: name,
        allLogs: logs,
        windowSize: windowSize,
        firstAvgWeight: firstAvg,
        latestAvgWeight: latestAvg,
        prEntry: pr,
      ));
    });

    // most-recently-logged exercises first
    result.sort((a, b) => b.allLogs.last.date.compareTo(a.allLogs.last.date));
    return result;
  }

  // average % change across every exercise that has enough history to
  // compare (used for the quick at-a-glance summary on the Stats page).
  // returns null if no exercise has enough data yet.
  double? getOverallProgressPercent() {
    final progress = getExerciseProgressList();
    final eligible = progress.where((p) => p.hasEnoughData && p.percentChange != null).toList();
    if (eligible.isEmpty) return null;
    final total = eligible.map((p) => p.percentChange!).reduce((a, b) => a + b);
    return total / eligible.length;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Workout getRelevantWorkout(String workoutName) {
    Workout relevantWorkout =
      workoutList.firstWhere((workout) => workout.name == workoutName);
    return relevantWorkout;
  }

  Exercise getRelevantExercise(String workoutName, String exerciseName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    Exercise relevantExercise = relevantWorkout.exercises.firstWhere((exercise) => exercise.name == exerciseName);
    return relevantExercise;
  }

  String getStartDate() {
    return db.getStartDate();
  }

Map<DateTime, int> heatMapDataSet = {};

void loadHeatMap() {
  final newHeatMapDataSet = <DateTime, int>{};

  DateTime startDate = createDateTimeObject(getStartDate());
  int daysInBetween = DateTime.now().difference(startDate).inDays;

  for(int i=0; i < daysInBetween+1; i++) {
    String ddmmyyyy = convertDateTimeObjectToDDMMYYYY(startDate.add(Duration(days: i)));
    // Use logs as the source of truth: if logs exist, the day is completed (1)
    // regardless of what the status key says. This ensures the heatmap always
    // reflects reality even if COMPLETION_STATUS_ was never written or was stomped.
    final hasLogs = db.getExerciseLogsForDate(ddmmyyyy).isNotEmpty;
    int completionStatus = hasLogs ? 1 : db.getCompletionStatus(ddmmyyyy);

    int year = startDate.add(Duration(days: i)).year;
    int month = startDate.add(Duration(days: i)).month;
    int day = startDate.add(Duration(days: i)).day;

    final percentForEachDay = <DateTime, int> {
      DateTime(year, month, day): completionStatus
    };

    newHeatMapDataSet.addEntries(percentForEachDay.entries);
  }

  heatMapDataSet = newHeatMapDataSet;
}

  // ── Goals ────────────────────────────────────────────────────────────────

  // every exercise name that's either in a current routine or has ever been
  // logged — used to populate the exercise picker when adding a goal, so
  // goals stay tied to real exercises rather than arbitrary free text.
  List<String> getKnownExerciseNames() {
    final names = <String>{};
    for (final workout in workoutList) {
      for (final exercise in workout.exercises) {
        names.add(exercise.name);
      }
    }
    names.addAll(db.getAllExerciseLogsGrouped().keys);
    final list = names.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  // current PR (heaviest weight ever logged) for an exercise, or null if
  // it's never been logged yet
  double? currentExercisePr(String exerciseName) {
    final logs = db.getAllExerciseLogsGrouped()[exerciseName];
    if (logs == null || logs.isEmpty) return null;
    return logs.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
  }

  // the most recent historical log for a given exercise name (across every
  // workout/day it's ever been logged on), or null if it's never been
  // logged. Used to prefill weight/reps/sets when adding a new log for an
  // exercise that's already been done before — logs are sorted oldest ->
  // newest by getAllExerciseLogsGrouped, so the last entry is the latest.
  ExerciseLogEntry? getMostRecentLogForExercise(String exerciseName) {
    final logs = db.getAllExerciseLogsGrouped()[exerciseName];
    if (logs == null || logs.isEmpty) return null;
    return logs.last;
  }

  double? get currentBodyWeight {
    final history = db.getBodyWeightHistory();
    return history.isEmpty ? null : history.last.value;
  }

  List<Goal> getGoals() => db.getGoals();

  // adds a goal targeting a given weight for an exercise, e.g. "Bench Press
  // 100kg". startingValue snapshots the current PR so progress can be shown
  // even if the exercise has never been logged yet (starts at 0).
  void addExerciseGoal(String exerciseName, double targetWeightKg) {
    final goals = db.getGoals();
    goals.add(Goal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: GoalType.exercise,
      exerciseName: exerciseName,
      targetValue: targetWeightKg,
      startingValue: currentExercisePr(exerciseName) ?? 0,
      direction: GoalDirection.increase,
      createdDate: DateTime.now(),
    ));
    db.saveGoals(goals);
    notifyListeners();
  }

  // adds a bodyweight goal, e.g. "lose 5kg" (direction: decrease, amountKg:
  // 5) or "gain 3kg" (direction: increase). The absolute target is computed
  // from the current bodyweight at the moment the goal is created.
  void addBodyWeightGoal(GoalDirection direction, double amountKg) {
    final current = currentBodyWeight ?? 0;
    final target = direction == GoalDirection.decrease ? current - amountKg : current + amountKg;

    final goals = db.getGoals();
    goals.add(Goal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: GoalType.bodyweight,
      targetValue: target,
      startingValue: current,
      direction: direction,
      createdDate: DateTime.now(),
    ));
    db.saveGoals(goals);
    notifyListeners();
  }

  // updates an existing goal's target weight in place (used by the "edit
  // goal" dialog and its undo action)
  void editGoal(String id, double newTargetValue) {
    final goals = db.getGoals();
    final index = goals.indexWhere((g) => g.id == id);
    if (index == -1) return;
    goals[index] = goals[index].copyWith(targetValue: newTargetValue);
    db.saveGoals(goals);
    notifyListeners();
  }

  void deleteGoal(String id) {
    final goals = db.getGoals();
    goals.removeWhere((g) => g.id == id);
    db.saveGoals(goals);
    notifyListeners();
  }

  // re-inserts a previously deleted goal at the given index (undo)
  void restoreGoal(int index, Goal goal) {
    final goals = db.getGoals();
    final insertAt = index.clamp(0, goals.length);
    goals.insert(insertAt, goal);
    db.saveGoals(goals);
    notifyListeners();
  }

  // every goal paired with its live progress, computed against the latest
  // exercise PRs / bodyweight history. Unfinished goals first (most recently
  // created first within each group), achieved goals last.
  List<GoalProgress> getGoalsWithProgress() {
    final list = db.getGoals().map((g) {
      final current = g.type == GoalType.exercise
          ? (currentExercisePr(g.exerciseName!) ?? g.startingValue)
          : (currentBodyWeight ?? g.startingValue);
      return GoalProgress(goal: g, currentValue: current);
    }).toList();

    list.sort((a, b) {
      if (a.isAchieved != b.isAchieved) return a.isAchieved ? 1 : -1;
      return b.goal.createdDate.compareTo(a.goal.createdDate);
    });
    return list;
  }

}
