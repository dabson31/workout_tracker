
import 'package:flutter/material.dart'; 

class ExerciseTile extends StatelessWidget {
      final String exerciseName;
    final String weight;
    final String reps;
    final String sets;
    final bool isCompleted;
    final Function(bool?) onCheckBoxChanged;
  const ExerciseTile({super.key, required this.exerciseName, required this.weight, required this.reps, required this.sets, required this.isCompleted, required this.onCheckBoxChanged});
  

  @override
  Widget build(BuildContext context) {


    return Container(
          color: const Color.fromARGB(255, 149, 0, 212),
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(exerciseName),
            subtitle: Row(
              children: [
                // weight
                Chip(
                label: Text(weight),
                ),
                // reps
                Chip(
                label: Text(
                "$reps reps"),
                ),
                // sets
                Chip(
                label: Text(
                "$sets sets"),
                )
              ]
            ),
            trailing: Checkbox(
              value: isCompleted,
              onChanged: (value) => onCheckBoxChanged(value),
            ),
          ),
        );
  }
}