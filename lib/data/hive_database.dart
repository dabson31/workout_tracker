import 'package:hive/hive.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/exercise_log_entry.dart';
import 'package:workout_tracker/models/goal.dart';
import 'package:workout_tracker/models/workout.dart';

class HiveDatabase {

  final _myBox = Hive.box('workout_database');

bool previousDataExists() {
    if (_myBox.isEmpty) {
      _myBox.put("START_DATE", todaysDateDDMMYYYY());
      return false;
    } else {
      return true;
    }
}

String getStartDate() {
  return _myBox.get("START_DATE");
}

// if ddmmyyyy is earlier than the current START_DATE, pull START_DATE back
// to it. This ensures that logging an exercise on a date before the app's
// original start date still gets picked up by the heatmap and all stats
// (which all iterate forward from START_DATE).
void extendStartDateIfEarlier(String ddmmyyyy) {
  final currentDate = createDateTimeObject(getStartDate());
  final newDate = createDateTimeObject(ddmmyyyy);
  if (newDate.isBefore(currentDate)) {
    _myBox.put("START_DATE", ddmmyyyy);
  }
}

void saveToDatabase(List<Workout> workouts) {
  final workoutList = convertObjectToWorkoutList(workouts);
  final exerciseList = convertObjectToExerciseList(workouts);
  _myBox.put("WORKOUTS", workoutList);
  _myBox.put("EXERCISES", exerciseList);
  // Completion status is NOT written here — it is owned exclusively by
  // recomputeCompletionStatus(), which reads from actual log data.
  // This prevents saveToDatabase from ever stomping the status.
}

  List<Workout> readFromDatabase() {
    List<Workout> mySavedWorkout = [];

    List<String> workoutNames = _myBox.get("WORKOUTS");
    final exerciseDetails = _myBox.get("EXERCISES");

    for (int i = 0; i < workoutNames.length; i++) {
      List<Exercise> exercisesInEachWorkout = [];

      for(int j = 0; j < exerciseDetails[i].length; j++ ) {
        exercisesInEachWorkout.add(
          Exercise(
            name: exerciseDetails[i][j][0],
            weight: exerciseDetails[i][j][1],
            reps: exerciseDetails[i][j][2],
            sets: exerciseDetails[i][j][3],
            isCompleted: exerciseDetails[i][j][4] == "true" ? true:false,
          )
        );
      }

      Workout workout = Workout(name: workoutNames[i],exercises: exercisesInEachWorkout);
      mySavedWorkout.add(workout);
    }

    return mySavedWorkout;
  }

bool exerciseCompleted(List<Workout> workouts) {
    for (var workout in workouts) {
      for(var exercise in workout.exercises) {
        if(exercise.isCompleted) {
          return true;
        }
      }
    }
    return false;
}

int getCompletionStatus(String ddmmyyyy) {
  int completionStatus = _myBox.get("COMPLETION_STATUS_$ddmmyyyy") ?? 0;
  return completionStatus;
}

bool isNewDay() {
  final today = todaysDateDDMMYYYY();
  final lastResetDate = _myBox.get("LAST_RESET_DATE");

  if (lastResetDate == today) {
    return false;
  }

  _myBox.put("LAST_RESET_DATE", today);
  return true;
}

List<String> convertObjectToWorkoutList(List<Workout> workouts) {
    List<String> workoutList = [];
    for (int i = 0; i < workouts.length; i++) {
      workoutList.add(workouts[i].name);
    }
    return workoutList;
}

List<List<List<String>>> convertObjectToExerciseList(List<Workout> workouts) {
    List<List<List<String>>> exerciseList = [];

    for(int i = 0; i < workouts.length; i++) {
      List<Exercise> exercisesInWorkout = workouts[i].exercises;
      List<List<String>> individualWorkout = [];

      for(int j = 0; j < exercisesInWorkout.length; j++) {
        List<String> individualExercise = [];
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

// logs are stored as 'workout|exercise|weight|reps|sets|loggedAtMillis'.
// the trailing timestamp field is appended on save so we know *when* (not
// just which day) an exercise was logged, which powers the workout-duration
// stats. Older logs saved before this field existed simply won't have it.
void saveExerciseLog(String ddmmyyyy, String workoutName, String exerciseName, String weight, String reps, String sets) {
  extendStartDateIfEarlier(ddmmyyyy);

  List<String> existingLogs = List<String>.from(_myBox.get("LOG_$ddmmyyyy") ?? []);

  existingLogs.removeWhere((log) {
    final parts = log.split('|');
    return parts[0] == workoutName && parts[1] == exerciseName;
  });

  final loggedAt = DateTime.now().millisecondsSinceEpoch;
  existingLogs.add('$workoutName|$exerciseName|$weight|$reps|$sets|$loggedAt');
  _myBox.put("LOG_$ddmmyyyy", existingLogs);
}

void updateExerciseLog(String ddmmyyyy, String workoutName, String oldExerciseName, String newExerciseName, String weight, String reps, String sets) {
  List<String> existingLogs = List<String>.from(_myBox.get("LOG_$ddmmyyyy") ?? []);

  for (int i = 0; i < existingLogs.length; i++) {
    final parts = existingLogs[i].split('|');
    if (parts[0] == workoutName && parts[1] == oldExerciseName) {
      // keep the original logged-at timestamp rather than resetting it,
      // since editing details after the fact shouldn't move when it
      // "happened" for duration-tracking purposes.
      final timestamp = parts.length > 5 ? parts[5] : '${DateTime.now().millisecondsSinceEpoch}';
      existingLogs[i] = '$workoutName|$newExerciseName|$weight|$reps|$sets|$timestamp';
      break;
    }
  }

  _myBox.put("LOG_$ddmmyyyy", existingLogs);
}

// renames every historical log entry for [oldName] (across every day,
// regardless of which workout it was logged under) to [newName]. Used so
// that renaming an exercise in a workout keeps its whole log history,
// PRs, and progress tracking attached to the new name instead of
// silently splitting it into two exercises.
void renameExerciseInAllLogs(String oldName, String newName) {
  if (oldName == newName) return;

  final start = createDateTimeObject(getStartDate());
  final now = DateTime.now();
  final days = now.difference(start).inDays + 1;

  for (int i = 0; i < days; i++) {
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(start.add(Duration(days: i)));
    final key = "LOG_$ddmmyyyy";
    final existingLogs = List<String>.from(_myBox.get(key) ?? []);
    if (existingLogs.isEmpty) continue;

    bool changed = false;
    for (int j = 0; j < existingLogs.length; j++) {
      final parts = existingLogs[j].split('|');
      if (parts[1] == oldName) {
        parts[1] = newName;
        existingLogs[j] = parts.join('|');
        changed = true;
      }
    }

    if (changed) _myBox.put(key, existingLogs);
  }
}

void deleteExerciseLog(String ddmmyyyy, String workoutName, String exerciseName) {
  List<String> existingLogs = List<String>.from(_myBox.get("LOG_$ddmmyyyy") ?? []);

  existingLogs.removeWhere((log) {
    final parts = log.split('|');
    return parts[0] == workoutName && parts[1] == exerciseName;
  });

  _myBox.put("LOG_$ddmmyyyy", existingLogs);
}

List<Map<String, String>> getExerciseLogsForDate(String ddmmyyyy) {
  List<String> rawLogs = List<String>.from(_myBox.get("LOG_$ddmmyyyy") ?? []);

  return rawLogs.map((log) {
    final parts = log.split('|');
    return {
      'workout': parts[0],
      'exercise': parts[1],
      'weight': parts[2],
      'reps': parts[3],
      'sets': parts[4],
      // may be absent on logs saved before timestamps were tracked
      'timestamp': parts.length > 5 ? parts[5] : '',
    };
  }).toList();
}

// scans every day from START_DATE to today and groups every logged
// exercise entry by exercise name, sorted oldest -> newest within each
// group (since the day loop itself runs oldest -> newest). Used for
// per-exercise progress tracking and PRs.
Map<String, List<ExerciseLogEntry>> getAllExerciseLogsGrouped() {
  final start = createDateTimeObject(getStartDate());
  final now = DateTime.now();
  final days = now.difference(start).inDays + 1;
  final Map<String, List<ExerciseLogEntry>> grouped = {};

  for (int i = 0; i < days; i++) {
    final dt = start.add(Duration(days: i));
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(dt);
    for (final log in getExerciseLogsForDate(ddmmyyyy)) {
      final name = log['exercise']!;
      grouped.putIfAbsent(name, () => []).add(
        ExerciseLogEntry(
          date: dt,
          workoutName: log['workout']!,
          exerciseName: name,
          weight: log['weight']!,
          reps: log['reps']!,
          sets: log['sets']!,
        ),
      );
    }
  }

  return grouped;
}

void recomputeCompletionStatus(String ddmmyyyy) {
  // rest days count as "completed" (value 2) so the heatmap shows them differently
  final note = getDayNote(ddmmyyyy);
  final isRestDay = note != null && note.startsWith('__REST__');
  if (isRestDay) {
    _myBox.put("COMPLETION_STATUS_$ddmmyyyy", 2);
    return;
  }
  final hasLogs = getExerciseLogsForDate(ddmmyyyy).isNotEmpty;
  _myBox.put("COMPLETION_STATUS_$ddmmyyyy", hasLogs ? 1 : 0);
}

  // ── Day notes & rest days ──────────────────────────────────────────────────

  // note is stored raw; rest days are prefixed with __REST__ followed by optional text
void saveDayNote(String ddmmyyyy, String note) {
  _myBox.put("NOTE_$ddmmyyyy", note);
  recomputeCompletionStatus(ddmmyyyy);
}

String? getDayNote(String ddmmyyyy) {
  return _myBox.get("NOTE_$ddmmyyyy") as String?;
}

void deleteDayNote(String ddmmyyyy) {
  _myBox.delete("NOTE_$ddmmyyyy");
  recomputeCompletionStatus(ddmmyyyy);
}

  // ── Bodyweight ─────────────────────────────────────────────────────────────

void saveBodyWeight(String ddmmyyyy, double weightKg) {
  Map<String, double> history = Map<String, double>.from(_myBox.get("BODYWEIGHT_HISTORY") ?? {});
  history[ddmmyyyy] = weightKg;
  _myBox.put("BODYWEIGHT_HISTORY", history);
}

void deleteBodyWeight(String ddmmyyyy) {
  Map<String, double> history = Map<String, double>.from(_myBox.get("BODYWEIGHT_HISTORY") ?? {});
  history.remove(ddmmyyyy);
  _myBox.put("BODYWEIGHT_HISTORY", history);
}

List<MapEntry<DateTime, double>> getBodyWeightHistory() {
  Map<dynamic, dynamic> rawHistory = _myBox.get("BODYWEIGHT_HISTORY") ?? {};

  List<MapEntry<DateTime, double>> entries = rawHistory.entries.map((entry) {
    return MapEntry(createDateTimeObject(entry.key as String), (entry.value as num).toDouble());
  }).toList();

  entries.sort((a, b) => a.key.compareTo(b.key));
  return entries;
}

  // ── Stats helpers ──────────────────────────────────────────────────────────

  // A day counts as a workout day if its completion status is 1 OR if it
  // has at least one exercise log saved (belt-and-suspenders: guards against
  // any edge case where the status key wasn't written but logs exist).
  bool _isDayWorkedOut(String ddmmyyyy) {
    if (getCompletionStatus(ddmmyyyy) == 1) return true;
    return getExerciseLogsForDate(ddmmyyyy).isNotEmpty;
  }

  // returns how many distinct days have a completion status of 1 (worked out)
  // within the current calendar month
int workoutsThisMonth() {
  final now = DateTime.now();
  int count = 0;
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  for (int d = 1; d <= daysInMonth; d++) {
    final dt = DateTime(now.year, now.month, d);
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(dt);
    if (_isDayWorkedOut(ddmmyyyy)) count++;
  }
  return count;
}

  // total workout days since the start date
int workoutsAllTime() {
  final start = createDateTimeObject(getStartDate());
  final now = DateTime.now();
  final days = now.difference(start).inDays + 1;
  int count = 0;
  for (int i = 0; i < days; i++) {
    final dt = start.add(Duration(days: i));
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(dt);
    if (_isDayWorkedOut(ddmmyyyy)) count++;
  }
  return count;
}

  // sum of all weight * reps across every set in every exercise log ever
  // saved. Both weight and reps may be comma-separated per-set values
  // ("20kg,22.5kg,25kg" / "8,8,6") or a single value applied to every set
  // (older logs, or logs where every set was the same); weight strings may
  // end in "kg" — we strip that before parsing.
double totalWeightLifted() {
  final start = createDateTimeObject(getStartDate());
  final now = DateTime.now();
  final days = now.difference(start).inDays + 1;
  double total = 0;

  for (int i = 0; i < days; i++) {
    final dt = start.add(Duration(days: i));
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(dt);
    for (final log in getExerciseLogsForDate(ddmmyyyy)) {
      final weightParts = (log['weight'] ?? '').split(',');
      final repsParts = (log['reps'] ?? '').split(',');
      for (int s = 0; s < weightParts.length; s++) {
        final w = double.tryParse(weightParts[s].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        // use this set's own reps if present, otherwise fall back to the
        // last known reps value (mirrors how per-set weight falls back)
        final repsStr = s < repsParts.length ? repsParts[s] : (repsParts.isNotEmpty ? repsParts.last : '0');
        final r = double.tryParse(repsStr) ?? 0;
        total += w * r;
      }
    }
  }
  return total;
}

  // count of unique exercise names logged across all time
int uniqueExercisesLogged() {
  final start = createDateTimeObject(getStartDate());
  final now = DateTime.now();
  final days = now.difference(start).inDays + 1;
  final names = <String>{};

  for (int i = 0; i < days; i++) {
    final dt = start.add(Duration(days: i));
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(dt);
    for (final log in getExerciseLogsForDate(ddmmyyyy)) {
      names.add(log['exercise']!);
    }
  }
  return names.length;
}

  // total individual exercise sets logged all time
int totalSetsLogged() {
  final start = createDateTimeObject(getStartDate());
  final now = DateTime.now();
  final days = now.difference(start).inDays + 1;
  int total = 0;

  for (int i = 0; i < days; i++) {
    final dt = start.add(Duration(days: i));
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(dt);
    for (final log in getExerciseLogsForDate(ddmmyyyy)) {
      final s = int.tryParse(log['sets'] ?? '') ?? 0;
      total += s;
    }
  }
  return total;
}

  // ── Workout duration ─────────────────────────────────────────────────────
  //
  // a "session" on a given day is built from the logged-at timestamps of
  // that day's exercise logs: sorted oldest -> newest, a gap of 2 hours or
  // more between two consecutive logs starts a new session (e.g. a morning
  // lift and an evening lift on the same day count as two separate
  // workouts, not one 12-hour one). Each session's duration is its last
  // timestamp minus its first; a day with only one logged exercise (or no
  // timestamps at all, e.g. legacy logs) contributes a zero-length session
  // for that single point, since there's no second point to measure a span.
  Duration _sumSessionDurations(List<int> sortedTimestamps) {
    if (sortedTimestamps.isEmpty) return Duration.zero;
    const twoHoursMs = 2 * 60 * 60 * 1000;

    int totalMs = 0;
    int sessionStart = sortedTimestamps.first;
    int prev = sortedTimestamps.first;

    for (int i = 1; i < sortedTimestamps.length; i++) {
      final t = sortedTimestamps[i];
      if (t - prev >= twoHoursMs) {
        totalMs += prev - sessionStart;
        sessionStart = t;
      }
      prev = t;
    }
    totalMs += prev - sessionStart;
    return Duration(milliseconds: totalMs);
  }

  // total time worked out on a given day, or null if that day has no
  // timestamped logs to measure (no logs, or only legacy logs without a
  // recorded time).
  Duration? workoutDurationForDate(String ddmmyyyy) {
    final timestamps = getExerciseLogsForDate(ddmmyyyy)
        .map((l) => l['timestamp'] ?? '')
        .where((t) => t.isNotEmpty)
        .map(int.parse)
        .toList()
      ..sort();
    if (timestamps.isEmpty) return null;
    return _sumSessionDurations(timestamps);
  }

  List<Duration> _allWorkoutDurations() {
    final start = createDateTimeObject(getStartDate());
    final now = DateTime.now();
    final days = now.difference(start).inDays + 1;
    final durations = <Duration>[];

    for (int i = 0; i < days; i++) {
      final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(start.add(Duration(days: i)));
      final d = workoutDurationForDate(ddmmyyyy);
      if (d != null) durations.add(d);
    }
    return durations;
  }

  // sum of every day's workout duration, all time
  Duration totalWorkoutTime() {
    final durations = _allWorkoutDurations();
    if (durations.isEmpty) return Duration.zero;
    return durations.reduce((a, b) => a + b);
  }

  // average workout duration per day that has timestamped logs, or null if
  // there's no timestamped data yet
  Duration? averageWorkoutTime() {
    final durations = _allWorkoutDurations();
    if (durations.isEmpty) return null;
    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  // current streak in days (consecutive workout days ending today or yesterday)
int currentStreak() {
  final now = DateTime.now();
  int streak = 0;
  DateTime cursor = DateTime(now.year, now.month, now.day);

  while (true) {
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(cursor);
    if (_isDayWorkedOut(ddmmyyyy)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
}

  // ── Goals ──────────────────────────────────────────────────────────────────

List<Goal> getGoals() {
  final raw = List<String>.from(_myBox.get("GOALS") ?? []);
  return raw.map((line) => Goal.fromStorageString(line)).toList();
}

void saveGoals(List<Goal> goals) {
  final raw = goals.map((g) => g.toStorageString()).toList();
  _myBox.put("GOALS", raw);
}

}
