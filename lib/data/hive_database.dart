import 'package:hive/hive.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/workout.dart';

class HiveDatabase {


  // reference to our box
  final _myBox = Hive.box('workout_database');


  // check if data exists, if not record start date
bool previousDataExists() {
    if (_myBox.isEmpty) {
      print("previous data doesn't exist");
      _myBox.put("START_DATE", todaysDateDDMMYYYY());
      return false;
    } else {
      print("previous data does exist");
      return true;
    }
  }


  // return start date as dd mm yyyy
String getStartDate() {
  return _myBox.get("START_DATE");
} 

  // write data
void saveToDatabase(List<Workout> workouts) {
  // converts workouts obj to list of strings so we save in hive
  final workoutList = convertObjectToWorkoutList(workouts);
  final exerciseList = convertObjectToExerciseList(workouts);

  // check if any have been done, we will put 0/1 for each date
  if (exerciseCompleted(workouts)) {
    _myBox.put("COMPLETION_STATUS_" + todaysDateDDMMYYYY(), 1);
  } else {
    _myBox.put("COMPLETION_STATUS_" + todaysDateDDMMYYYY(), 0);
  }
  // so it is COMPLETION_STATUS_29/05/2026


  _myBox.put("WORKOUTS", workoutList);
  _myBox.put("EXERCISES", exerciseList);

}

  // read data and reutnr list of workouts
  List<Workout> readFromDatabase() {
    List<Workout> mySavedWorkout = [];

    List<String> workoutNames = _myBox.get("WORKOUTS");
    final exerciseDetails = _myBox.get("EXERCISE");

    // create workouts obj
    for (int i = 0; i < workoutNames.length; i++) {
      // each workout can have many exercises (one to many)
      List<Exercise> exercisesInEachWorkout = [];

      for(int j = 0; j < exerciseDetails[i].length; j++ ) {
        // add each to a list
        exercisesInEachWorkout.add(
          Exercise( // the amount of dimensions will end me
            name: exerciseDetails[i][j][0],
            weight: exerciseDetails[i][j][1],
            reps: exerciseDetails[i][j][2],
            sets: exerciseDetails[i][j][3],
            isCompleted: exerciseDetails[i][j][4] == "true" ? true:false,
          )
        );
      }

      // create individual workout
      Workout workout = Workout(name: workoutNames[i],exercises: exercisesInEachWorkout);

      // add to overall list
      mySavedWorkout.add(workout);
    }

    return mySavedWorkout;
  }


  // check if any exercise is completed
bool exerciseCompleted(List<Workout> workouts) {
    // go through each workout
      for (var workout in workouts) {
        // go through every exercise in workout
        for(var exercise in workout.exercises) {
          if(exercise.isCompleted) {
            return true;
          }
        }
      }
      return false;
  }

  // return completion status of a given date dd mm yyyy
int getCompletionStatus(String ddmmyyyy) {
  // return 0/1 if null its 0
  int completionStatus = _myBox.get("COMPLETION_STATUS_" + ddmmyyyy) ?? 0;
  return completionStatus;
}


  // convert workout objects into a list for example [ upperbody, lowerbody, calisthenics ]
List<String> convertObjectToWorkoutList(List<Workout> workouts) {
    List<String> workoutList = [

    ];

    for (int i = 0; i < workouts.length; i++) {
      workoutList.add(workouts[i].name);
    }
    return workoutList;
  }


  // conerts exercise list to string to store in database
List<List<List<String>>> convertObjectToExerciseList(List<Workout> workouts) {
    List<List<List<String>>> exerciseList = [
    ];

    // go through every workout and add the exercise list to the exerciseList
    for(int i =0; i < workouts.length; i++) {
      // get exercises from each workout
      List<Exercise> exercisesInWorkout = workouts[i].exercises;

      List<List<String>> individualWorkout = [
        // upper body

        // [[biceps, 10kg, 8reps , 2sets], [triceps, 10kg, 8reps, 2sets]]
      ];

      for(int j = 0; j < exercisesInWorkout.length; j++) {
        List<String> individualExercise = [
          // [biceps, 10kg, 8 reps, 2 sets]
        ];
        individualExercise.addAll(
          [
            exercisesInWorkout[j].name,
            exercisesInWorkout[j].weight,
            exercisesInWorkout[j].reps,
            exercisesInWorkout[j].sets,
            exercisesInWorkout[j].isCompleted.toString(),
          ]
        );
        individualWorkout.add(individualExercise);
      }
      exerciseList.add(individualWorkout);

      
    }

    return exerciseList;
  }

}