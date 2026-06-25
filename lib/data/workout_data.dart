import 'package:workout_tracker/data/hive_database.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/workout.dart';
import 'package:flutter/foundation.dart';

class WorkoutData extends ChangeNotifier {

final db = HiveDatabase();

  /*
  Workout struct

  list contains all diff workouts
  each workout has a name and list of exercises (upper, lower etc)
  */

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

  // if there are workouts, read them
  void initializeWorkoutList() {
      if(db.previousDataExists()) {
        workoutList = db.readFromDatabase();
      }
      // otherwise use default ones
       else { 
        db.saveToDatabase(workoutList);
      }

      // a new day has started since we last opened the app -- uncheck
      // everything so todays workout starts fresh. weight/reps/sets are left
      // alone (they keep showing the previous lift), and past history logs
      // and heatmap entries are untouched, this only clears todays checkmarks
      if (db.isNewDay()) {
        resetDailyCompletion();
      }

      loadHeatMap();
  }

  // uncheck every exercise in every workout
  // NOTE: deliberately no notifyListeners() here -- this only ever runs from
  // initState() (via initializeWorkoutList), which always completes before
  // that widget's own build() runs. The first build already reflects this
  // reset state, and calling notifyListeners() mid-initState fires while
  // Flutter is still in the middle of building the tree, which throws
  // "setState() or markNeedsBuild() called during build".
  void resetDailyCompletion() {
    for (var workout in workoutList) {
      for (var exercise in workout.exercises) {
        exercise.isCompleted = false;
      }
    }

    db.saveToDatabase(workoutList);
  }


  // method to get the list of workouts -
  List<Workout> getWorkoutList() {
    return workoutList;
  }

  // length of workout
  int numberOfExercisesInWorkout(String workoutName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);

    // return length of exercises in workout
    return relevantWorkout.exercises.length;
  }

  // add workouts in app (with exercises etc)
  void addWorkout(String name) {
    workoutList.add(Workout(name: name, exercises: []));

    notifyListeners();
    // save to db
    db.saveToDatabase(workoutList);
  }

  // rename an existing workout
  void editWorkoutName(String oldName, String newName) {
    Workout relevantWorkout = getRelevantWorkout(oldName);
    relevantWorkout.name = newName;

    notifyListeners();
    db.saveToDatabase(workoutList);
  }

  // delete a workout entirely
  void deleteWorkout(String workoutName) {
    workoutList.removeWhere((workout) => workout.name == workoutName);

    db.saveToDatabase(workoutList);

    // saveToDatabase already recomputes today's completion status (false if
    // no exercises are left anywhere), but the heatmap dataset is only
    // refreshed by reloading it here -- otherwise today's square stays lit
    // until something else (e.g. logging an exercise) triggers a reload.
    // notifyListeners() must come after this, otherwise Provider rebuilds
    // the UI with the old heatMapDataSet and never gets told to do it again
    loadHeatMap();
    notifyListeners();
  }

  // add exercise here
  void addExercise(String workoutName, String exerciseName, String weight, String reps, String sets) {
    // find workout
  Workout relevantWorkout = getRelevantWorkout(workoutName);

    // add exercise to workout
    relevantWorkout.exercises.add(
      Exercise(
        name: exerciseName, 
        weight: weight, 
        reps: reps, 
        sets: sets
        ));
    notifyListeners();
    // save to db
    db.saveToDatabase(workoutList);
  }

  // log what was actually performed today, this becomes the new "previous" lift
  void logExercise(String workoutName, String exerciseName, String weight, String reps, String sets) {
    Exercise relevantExercise = getRelevantExercise(workoutName, exerciseName);

    // update the live exercise so next time it shows this as the previous lift
    relevantExercise.weight = weight;
    relevantExercise.reps = reps;
    relevantExercise.sets = sets;
    relevantExercise.isCompleted = true;

    // save todays performance to the history log, kept separate from live values
    db.saveExerciseLog(todaysDateDDMMYYYY(), workoutName, exerciseName, weight, reps, sets);

    db.saveToDatabase(workoutList);
    loadHeatMap();
    notifyListeners();
  }

  // undo a logged exercise for today, unchecking it
  void unlogExercise(String workoutName, String exerciseName) {
    Exercise relevantExercise = getRelevantExercise(workoutName, exerciseName);
    relevantExercise.isCompleted = false;

    db.saveToDatabase(workoutList);
    loadHeatMap();
    notifyListeners();
  }

  // manually add a logged exercise entry for any date (used from the heatmap
  // day sheet, e.g. backfilling a past day or adding to today by hand)
  void addLoggedExercise(String ddmmyyyy, String workoutName, String exerciseName, String weight, String reps, String sets) {
    db.saveExerciseLog(ddmmyyyy, workoutName, exerciseName, weight, reps, sets);

    // a new log always means the day now has at least one entry
    db.recomputeCompletionStatus(ddmmyyyy);
    loadHeatMap();
    notifyListeners();
  }

  // edit a logged exercise entry for a specific past date (from the heatmap day sheet)
  void editLoggedExercise(String ddmmyyyy, String workoutName, String oldExerciseName, String newExerciseName, String weight, String reps, String sets) {
    db.updateExerciseLog(ddmmyyyy, workoutName, oldExerciseName, newExerciseName, weight, reps, sets);

    // editing never empties the day's logs, but recompute anyway for safety
    // and to pick up the corresponding heatmap square if its status changed
    db.recomputeCompletionStatus(ddmmyyyy);
    loadHeatMap();
    notifyListeners();
  }

  // delete a logged exercise entry for a specific past date (from the heatmap day sheet)
  void deleteLoggedExercise(String ddmmyyyy, String workoutName, String exerciseName) {
    db.deleteExerciseLog(ddmmyyyy, workoutName, exerciseName);

    // if that was the last log for the day, this flips its completion status
    // back to 0 so the heatmap square for that day goes dark
    db.recomputeCompletionStatus(ddmmyyyy);
    loadHeatMap();
    notifyListeners();
  }

  // fetch everything logged on a given date, used when tapping a heatmap day
  List<Map<String, String>> getLogsForDate(String ddmmyyyy) {
    return db.getExerciseLogsForDate(ddmmyyyy);
  }

  // delete a single exercise from a workout
  void deleteExercise(String workoutName, String exerciseName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    relevantWorkout.exercises.removeWhere((exercise) => exercise.name == exerciseName);

    db.saveToDatabase(workoutList);

    // same reasoning as deleteWorkout -- refresh before notifying, so the
    // rebuild Provider triggers actually has the updated heatmap dataset
    loadHeatMap();
    notifyListeners();
  }

  // rename an existing exercise
  void editExerciseName(String workoutName, String oldName, String newName) {
    Exercise relevantExercise = getRelevantExercise(workoutName, oldName);
    relevantExercise.name = newName;

    notifyListeners();
    db.saveToDatabase(workoutList);
  }

  // log todays bodyweight, overwrites if already logged today
  void logBodyWeight(double weightKg) {
    db.saveBodyWeight(todaysDateDDMMYYYY(), weightKg);
    notifyListeners();
  }

  // returns full bodyweight history, oldest first
  List<MapEntry<DateTime, double>> getBodyWeightHistory() {
    return db.getBodyWeightHistory();
  }


  //helpers

  //return relevent workout (name search)
  Workout getRelevantWorkout(String workoutName) {
    Workout relevantWorkout =
      workoutList.firstWhere((workout) => workout.name == workoutName);
    return relevantWorkout;
  }

  //return relevent workout (name search for both workout and exercise)
  Exercise getRelevantExercise(String workoutName, String exerciseName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);

    Exercise relevantExercise = relevantWorkout.exercises.firstWhere((exercise) => exercise.name == exerciseName);
    return relevantExercise;
  }


  // get start date
  String getStartDate() {
    return db.getStartDate();
  }

Map<DateTime, int> heatMapDataSet = {};

void loadHeatMap() {
  // build into a fresh map rather than mutating heatMapDataSet in place --
  // the heatmap widget compares the datasets map by reference between
  // rebuilds, so reusing the same instance (even with different contents)
  // means it thinks nothing changed and skips redrawing the grid
  final newHeatMapDataSet = <DateTime, int>{};

  DateTime startDate = createDateTimeObject(getStartDate());

  int daysInBetween = DateTime.now().difference(startDate).inDays;

  for(int i=0; i < daysInBetween+1; i++) {
    String ddmmyyyy = convertDateTimeObjectToDDMMYYYY(startDate.add(Duration(days: i)));

    int completionStatus = db.getCompletionStatus(ddmmyyyy);

    // year
    int year = startDate.add(Duration(days: i)).year;

    // month
    int month = startDate.add(Duration(days: i)).month;

    // day
    int day = startDate.add(Duration(days: i)).day;

    final percentForEachDay = <DateTime, int> {
      DateTime(year, month, day): completionStatus
    };

    newHeatMapDataSet.addEntries(percentForEachDay.entries);
  }

  heatMapDataSet = newHeatMapDataSet;
}

}