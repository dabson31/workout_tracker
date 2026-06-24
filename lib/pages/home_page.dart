import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/pages/workout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final newWorkoutController = TextEditingController();


  // new workout
  void createNewWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create New Workout"),
        content: TextField(
          controller: newWorkoutController, // access the text field value
        ),
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
        ]
      ),
    );
  }

  // go to workout page
  void goToWorkoutPage(String workoutName) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutPage(workoutName: workoutName)));
  }

  // save func
  void save() {
    // the text from text field using controller
    String newWorkoutName = newWorkoutController.text;
    // add the new workout to the list using provider
    Provider.of<WorkoutData>(context, listen: false).addWorkout(newWorkoutName);
    
    //clear the text field after saving
    newWorkoutController.clear();

    Navigator.pop(context); // Close the dialog after saving

  }
  // cancel func
  void cancel() {
    newWorkoutController.clear(); // clear the text field when canceling
    Navigator.pop(context); // close the dialog when canceling
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(builder: (context, value, child) =>  Scaffold(
      appBar: AppBar(
        title: Text('Workout Tracker'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewWorkout,
        child: const Icon(Icons.add)
      ),
      body: ListView.builder(
        itemCount: value.getWorkoutList().length, // Example item count
        itemBuilder: (context, index) => ListTile(
            title: Text(value.getWorkoutList()[index].name),
            trailing: IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: () => goToWorkoutPage(value.getWorkoutList()[index].name),
            ),
          ),
      ),
    ),
    );
  }
}