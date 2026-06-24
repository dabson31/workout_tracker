import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/exercise_tile.dart';
import 'package:workout_tracker/data/workout_data.dart';

class WorkoutPage extends StatefulWidget {
  final String workoutName;
  const WorkoutPage({super.key, required this.workoutName});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

// clicked is completed


class _WorkoutPageState extends State<WorkoutPage> {

void onCheckBoxChanged(String workoutName, String exerciseName) {
  Provider.of<WorkoutData>(context, listen: false).checkOffExercise(workoutName, exerciseName);
}

// text controllers
final exerciseNameController = TextEditingController();
final weightController = TextEditingController();
final repsController = TextEditingController();
final setsController = TextEditingController();

void createNewExercise() {
  showDialog(context: context, builder: (context) => AlertDialog(
    title: Text('add new exercise'),
    content: Column(
      mainAxisSize:MainAxisSize.min,
      children: [
      //exercise name
      TextField(
        controller: exerciseNameController,
      ),

      // weight
      TextField(
        controller: weightController,
      ),
      // reps
      TextField(
        controller: repsController,
      ),
      // sets
      TextField(
        controller: setsController,
      ),
    ]),
    actions: [
        //save button
        MaterialButton(
          onPressed: save,
          child: Text("Save"),
        ),
        //cancel button
        MaterialButton(
          onPressed: cancel,
          child: Text("Cancel"),
        )
      // cancel

    ]
  ),
  );
  }



 void save() {
    // the text from text field using controller
    String newWorkoutName = exerciseNameController.text;
    // add the new exercise to the list using provider
    Provider.of<WorkoutData>(context, listen: false).addExercise(
      widget.workoutName, 
      exerciseNameController.text, 
      weightController.text, 
      repsController.text, 
      setsController.text
    );
    
    //clear the text field after saving
    exerciseNameController.clear();
    weightController.clear();
    repsController.clear();
    setsController.clear();

    Navigator.pop(context); // Close the dialog after saving

  }
  // cancel func
  void cancel() {
    exerciseNameController.clear(); // clear the text field when canceling
    weightController.clear();
    repsController.clear();
    setsController.clear();
    Navigator.pop(context); // close the dialog when canceling
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) =>  Scaffold(
      appBar: AppBar(title: Text(widget.workoutName)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createNewExercise();
        },
        child: Icon(Icons.add),
      ),
      body: ListView.builder( 
        itemCount: value.numberOfExercisesInWorkout(widget.workoutName), 
        itemBuilder: (context, index) => ExerciseTile(
          exerciseName: value.getRelevantWorkout(widget.workoutName).exercises[index].name,
          weight: value.getRelevantWorkout(widget.workoutName).exercises[index].weight,
          reps: value.getRelevantWorkout(widget.workoutName).exercises[index].reps,
          sets: value.getRelevantWorkout(widget.workoutName).exercises[index].sets,
          isCompleted: value.getRelevantWorkout(widget.workoutName).exercises[index].isCompleted,
          onCheckBoxChanged: (val) => onCheckBoxChanged(widget.workoutName, value.getRelevantWorkout(widget.workoutName).exercises[index].name)
        )
      )
    ),
    );
  }
}