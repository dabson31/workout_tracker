import 'exercise_log_entry.dart';

// computed progress summary for one exercise, derived from its full
// history of logs (see WorkoutData.getExerciseProgressList)
class ExerciseProgress {
  final String exerciseName;
  final List<ExerciseLogEntry> allLogs; // sorted oldest -> newest
  final int windowSize; // how many logs make up the "first" and "latest" windows
  final double firstAvgWeight;
  final double latestAvgWeight;
  final ExerciseLogEntry prEntry; // heaviest weight ever logged

  ExerciseProgress({
    required this.exerciseName,
    required this.allLogs,
    required this.windowSize,
    required this.firstAvgWeight,
    required this.latestAvgWeight,
    required this.prEntry,
  });

  int get totalLogs => allLogs.length;

  // % change from first window avg to latest window avg. null if the
  // first window average is 0 (can't compute a meaningful percentage).
  double? get percentChange {
    if (firstAvgWeight == 0) return null;
    return ((latestAvgWeight - firstAvgWeight) / firstAvgWeight) * 100;
  }

  // whether there's enough history to show a meaningful comparison.
  // windowSize 0 means fewer than 2 logs total exist.
  bool get hasEnoughData => windowSize > 0;

  // the logs that make up the "first" window (earliest entries)
  List<ExerciseLogEntry> get firstWindowLogs =>
      allLogs.take(windowSize).toList();

  // the logs that make up the "latest" window (most recent entries)
  List<ExerciseLogEntry> get latestWindowLogs =>
      allLogs.skip(allLogs.length - windowSize).toList();
}
