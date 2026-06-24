import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/workout.dart';
import 'package:flutter/foundation.dart';

class WorkoutData extends ChangeNotifier {

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
    Workout(
      name: "Upper Body 2",
      exercises: [
        Exercise(
          name: "Bench Press",
          weight: "25kg",
          reps: "8",
          sets: "2"
        )
      ]
    ),
    Workout(
      name: "Lower Body",
      exercises: [
        Exercise(
          name: "Bench Press",
          weight: "25kg",
          reps: "8",
          sets: "2"
        )
      ]
    ),
        Workout(
      name: "Lower Body 2",
      exercises: [
        Exercise(
          name: "Bench Press",
          weight: "25kg",
          reps: "8",
          sets: "2"
        )
      ]
    )
  ];
  
  // if there are workouts, read them, otherwise use default ones


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
  }

  // check exercise
  void checkOffExercise(String workoutName, String exerciseName) {
    //find relevent workout (reused method)
  Exercise relevantExercise = getRelevantExercise(workoutName, exerciseName);

  // bool to show completed exercise
  relevantExercise.isCompleted = !relevantExercise.isCompleted;

    notifyListeners();


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
}

