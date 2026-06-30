enum GoalType { exercise, bodyweight }

enum GoalDirection { increase, decrease }

// a target the user is working towards — either lifting a given exercise
// up to a target weight (e.g. "Bench Press 100kg"), or moving their
// bodyweight towards a target (e.g. "lose 5kg"). Progress is computed
// elsewhere (see GoalProgress) by comparing against live exercise/bodyweight
// data, so the goal itself only stores the target and a snapshot of where
// things stood when it was created.
class Goal {
  final String id;
  final GoalType type;
  final String? exerciseName; // set only when type == GoalType.exercise
  final double targetValue; // kg
  final double startingValue; // kg, snapshot taken when the goal was created
  final GoalDirection direction;
  final DateTime createdDate;

  Goal({
    required this.id,
    required this.type,
    this.exerciseName,
    required this.targetValue,
    required this.startingValue,
    required this.direction,
    required this.createdDate,
  });

  // display label, e.g. "Bench Press" or "Bodyweight"
  String get label => type == GoalType.exercise ? (exerciseName ?? 'exercise') : 'Bodyweight';

  Goal copyWith({double? targetValue, double? startingValue, GoalDirection? direction, String? exerciseName}) {
    return Goal(
      id: id,
      type: type,
      exerciseName: exerciseName ?? this.exerciseName,
      targetValue: targetValue ?? this.targetValue,
      startingValue: startingValue ?? this.startingValue,
      direction: direction ?? this.direction,
      createdDate: createdDate,
    );
  }

  // serializes to a single pipe-delimited string for storage in a
  // List<String> hive entry, matching the convention used for exercise logs
  String toStorageString() {
    return [
      id,
      type.name,
      exerciseName ?? '',
      targetValue.toString(),
      startingValue.toString(),
      direction.name,
      createdDate.millisecondsSinceEpoch.toString(),
    ].join('|');
  }

  static Goal fromStorageString(String raw) {
    final parts = raw.split('|');
    return Goal(
      id: parts[0],
      type: GoalType.values.byName(parts[1]),
      exerciseName: parts[2].isEmpty ? null : parts[2],
      targetValue: double.tryParse(parts[3]) ?? 0,
      startingValue: double.tryParse(parts[4]) ?? 0,
      direction: GoalDirection.values.byName(parts[5]),
      createdDate: DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[6]) ?? 0),
    );
  }
}
