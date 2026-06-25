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

      loadHeatMap();
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

    notifyListeners();
    db.saveToDatabase(workoutList);
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

    notifyListeners();
    db.saveToDatabase(workoutList);

    loadHeatMap();
  }

  // undo a logged exercise for today, unchecking it
  void unlogExercise(String workoutName, String exerciseName) {
    Exercise relevantExercise = getRelevantExercise(workoutName, exerciseName);
    relevantExercise.isCompleted = false;

    notifyListeners();
    db.saveToDatabase(workoutList);

    loadHeatMap();
  }

  // fetch everything logged on a given date, used when tapping a heatmap day
  List<Map<String, String>> getLogsForDate(String ddmmyyyy) {
    return db.getExerciseLogsForDate(ddmmyyyy);
  }

  // delete a single exercise from a workout
  void deleteExercise(String workoutName, String exerciseName) {
    Workout relevantWorkout = getRelevantWorkout(workoutName);
    relevantWorkout.exercises.removeWhere((exercise) => exercise.name == exerciseName);

    notifyListeners();
    db.saveToDatabase(workoutList);
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
  heatMapDataSet.clear();

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

    heatMapDataSet.addEntries(percentForEachDay.entries);
  }
}

}