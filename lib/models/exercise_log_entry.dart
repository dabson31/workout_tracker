// a single historical log of an exercise on a specific day, used for
// progress tracking and PRs (separate from the live `Exercise` in a
// workout, which only holds today's/most-recent values)
class ExerciseLogEntry {
  final DateTime date;
  final String workoutName;
  final String exerciseName;
  final String weight;
  final String reps;
  final String sets;

  ExerciseLogEntry({
    required this.date,
    required this.workoutName,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
  });

  // numeric weight in kg, stripping any unit suffix like "kg".
  // if this entry stores per-set weights (comma-separated, e.g. "20kg,22.5kg,25kg")
  // we return the heaviest set — that's what counts for a PR.
  double get weightKg {
    final parts = weight.split(',');
    return parts
        .map((p) => double.tryParse(p.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0)
        .fold(0.0, (max, v) => v > max ? v : max);
  }

  // all per-set weights as a list of doubles (single-weight logs return [weightKg])
  List<double> get perSetWeights {
    final parts = weight.split(',');
    return parts.map((p) => double.tryParse(p.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0).toList();
  }

  // all per-set reps as a list of ints (single-reps logs return [repsCount])
  List<int> get perSetReps {
    final parts = reps.split(',');
    return parts.map((p) => int.tryParse(p.trim()) ?? 0).toList();
  }

  // total reps across every set in this log (sum, not just one set's count)
  int get repsCount => perSetReps.fold(0, (sum, r) => sum + r);
  int get setsCount => int.tryParse(sets) ?? 0;
}
