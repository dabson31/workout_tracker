import 'package:workout_tracker/data/hive_database.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/models/exercise.dart';
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

}
