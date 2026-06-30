import 'package:flutter/material.dart';
import 'package:workout_tracker/theme/app_theme.dart';

// strict picker for exercise names: only lets the user choose from
// exercises that already exist (in a workout or in log history) rather
// than typing a free-text name. Used anywhere an exercise needs to be
// selected (logging from the heatmap, setting an exercise goal, etc.)
// so that everything stays tied to one canonical name per exercise.
class ExercisePicker extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String label;

  const ExercisePicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label = 'exercise',
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'no exercises yet \u2014 add one to a workout first',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    // if the current value isn't one of the known options (e.g. an old
    // log holding a name that no longer matches any exercise), fall back
    // to no selection rather than crashing the dropdown.
    final dropdownValue = options.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: dropdownValue,
      isExpanded: true,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: AppColors.textPrimary),
      icon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      hint: const Text('select an exercise', style: TextStyle(color: AppColors.textSecondary)),
      items: options
          .map((name) => DropdownMenuItem<String>(
                value: name,
                child: Text(name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
