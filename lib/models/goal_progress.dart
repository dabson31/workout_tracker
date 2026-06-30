import 'goal.dart';

// computed progress for a single goal, derived from the latest exercise PR
// or latest bodyweight entry (see WorkoutData.getGoalsWithProgress). Kept
// separate from Goal itself so the stored goal stays a simple snapshot and
// all the "how close am I" math lives in one place.
class GoalProgress {
  final Goal goal;
  final double currentValue; // current PR (exercise) or latest bodyweight (bodyweight)

  GoalProgress({required this.goal, required this.currentValue});

  bool get isAchieved => goal.direction == GoalDirection.increase
      ? currentValue >= goal.targetValue
      : currentValue <= goal.targetValue;

  // how much is left to reach the target (never negative)
  double get remaining {
    final diff = goal.direction == GoalDirection.increase
        ? goal.targetValue - currentValue
        : currentValue - goal.targetValue;
    return diff < 0 ? 0 : diff;
  }

  // 0.0 - 1.0, how far along from the starting snapshot towards the target
  double get progressFraction {
    final span = goal.direction == GoalDirection.increase
        ? goal.targetValue - goal.startingValue
        : goal.startingValue - goal.targetValue;
    if (span <= 0) return isAchieved ? 1.0 : 0.0;

    final progressed = goal.direction == GoalDirection.increase
        ? currentValue - goal.startingValue
        : goal.startingValue - currentValue;

    return (progressed / span).clamp(0.0, 1.0);
  }
}
