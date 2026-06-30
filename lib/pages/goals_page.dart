import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/premium_dialog.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/models/goal.dart';
import 'package:workout_tracker/models/goal_progress.dart';
import 'package:workout_tracker/theme/app_theme.dart';

// Goals page — lets the user set targets like "Bench Press 100kg" or
// "lose 5kg" and tracks live progress against them using existing exercise
// PR / bodyweight history data. Reached from the navbar.
class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  String _fmtWeight(double kg) {
    final sign = kg < 0 ? '-' : '';
    final abs = kg.abs();
    if (abs == abs.roundToDouble()) return '$sign${abs.toInt()}';
    return '$sign${abs.toStringAsFixed(1)}';
  }

  // ── add goal ───────────────────────────────────────────────────────────

  void _openAddGoalDialog(BuildContext context) {
    final data = Provider.of<WorkoutData>(context, listen: false);
    final targetController = TextEditingController();
    GoalType selectedType = GoalType.exercise;
    GoalDirection bwDirection = GoalDirection.decrease;
    TextEditingController? exerciseFieldController;

    showPremiumDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 12,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            title: const Text('add goal', style: TextStyle(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _typeChip(
                          'exercise',
                          selectedType == GoalType.exercise,
                          () => setDialogState(() => selectedType = GoalType.exercise),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _typeChip(
                          'bodyweight',
                          selectedType == GoalType.bodyweight,
                          () => setDialogState(() => selectedType = GoalType.bodyweight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedType == GoalType.exercise) ...[
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        final known = data.getKnownExerciseNames();
                        if (textEditingValue.text.isEmpty) return known;
                        return known.where(
                          (name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                        );
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                        exerciseFieldController = controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'exercise name',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 6,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 280),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Text(option, style: const TextStyle(color: AppColors.textPrimary)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'target weight',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        suffixText: 'kg',
                        suffixStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _typeChip(
                            'lose',
                            bwDirection == GoalDirection.decrease,
                            () => setDialogState(() => bwDirection = GoalDirection.decrease),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _typeChip(
                            'gain',
                            bwDirection == GoalDirection.increase,
                            () => setDialogState(() => bwDirection = GoalDirection.increase),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: targetController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'amount',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        suffixText: 'kg',
                        suffixStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.currentBodyWeight != null
                          ? 'current bodyweight: ${_fmtWeight(data.currentBodyWeight!)}'
                          : 'log your bodyweight on the bodyweight page first to set this goal',
                      style: TextStyle(
                        color: data.currentBodyWeight != null ? AppColors.textSecondary : AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  final value = double.tryParse(targetController.text.trim());
                  if (value == null || value <= 0) return;

                  if (selectedType == GoalType.exercise) {
                    final name = (exerciseFieldController?.text ?? '').trim();
                    if (name.isEmpty) return;
                    data.addExerciseGoal(name, value);
                  } else {
                    if (data.currentBodyWeight == null) return;
                    data.addBodyWeightGoal(bwDirection, value);
                  }
                  Navigator.pop(context);
                },
                child: const Text('add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              MaterialButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _typeChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.18) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── edit goal ──────────────────────────────────────────────────────────

  void _openEditGoalDialog(BuildContext context, GoalProgress gp) {
    final controller = TextEditingController(text: _fmtNum(gp.goal.targetValue));
    final oldTarget = gp.goal.targetValue;

    showPremiumDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        title: Text('edit ${gp.goal.label.toLowerCase()} goal', style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'target weight',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            suffixText: 'kg',
            suffixStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              Provider.of<WorkoutData>(context, listen: false).editGoal(gp.goal.id, value);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 5),
                  backgroundColor: AppColors.surfaceLight,
                  behavior: SnackBarBehavior.floating,
                  content: const Text('goal updated', style: TextStyle(color: AppColors.textPrimary)),
                  action: SnackBarAction(
                    label: 'undo',
                    textColor: AppColors.primary,
                    onPressed: () {
                      Provider.of<WorkoutData>(context, listen: false).editGoal(gp.goal.id, oldTarget);
                    },
                  ),
                ),
              );
            },
            child: const Text('save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  String _fmtNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // ── delete goal ────────────────────────────────────────────────────────

  void _deleteGoal(BuildContext context, GoalProgress gp) {
    final data = Provider.of<WorkoutData>(context, listen: false);
    final goals = data.getGoals();
    final index = goals.indexWhere((g) => g.id == gp.goal.id);
    final goal = gp.goal;

    data.deleteGoal(goal.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        content: Text('${goal.label} goal removed', style: const TextStyle(color: AppColors.textPrimary)),
        action: SnackBarAction(
          label: 'undo',
          textColor: AppColors.primary,
          onPressed: () => data.restoreGoal(index, goal),
        ),
      ),
    );
  }

  // ── tile ───────────────────────────────────────────────────────────────

  Widget _goalTile(BuildContext context, GoalProgress gp) {
    final goal = gp.goal;
    final isExercise = goal.type == GoalType.exercise;
    final icon = isExercise ? Icons.fitness_center_rounded : Icons.monitor_weight_rounded;
    final title = isExercise
        ? goal.exerciseName!
        : (goal.direction == GoalDirection.decrease ? 'lose weight' : 'gain weight');
    final accent = gp.isAchieved ? const Color(0xFF10B981) : AppColors.primary;
    final subtitle = '${_fmtWeight(gp.currentValue)} \u2192 ${_fmtWeight(goal.targetValue)}';

    return Slidable(
      key: ValueKey(goal.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.45,
        children: [
          SlidableAction(
            onPressed: (context) => _openEditGoalDialog(context, gp),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'edit',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          ),
          SlidableAction(
            onPressed: (context) => _deleteGoal(context, gp),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: gp.isAchieved ? Border.all(color: accent.withValues(alpha: 0.4)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (gp.isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: accent, size: 14),
                        const SizedBox(width: 4),
                        Text('done', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  Text(
                    '${_fmtWeight(gp.remaining)} to go',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: gp.progressFraction,
                minHeight: 8,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, value, child) {
        final goals = value.getGoalsWithProgress();

        return Scaffold(
          appBar: AppBar(title: const Text('goals')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              if (goals.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 16),
                  child: Column(
                    children: [
                      Icon(Icons.flag_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'set a goal like "bench press 100kg" or "lose 5kg"\nto start tracking it',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...goals.map((gp) => _goalTile(context, gp)),

              const SizedBox(height: 6),

              // inline "add goal" button — matches the "add workout"/"add
              // exercise" convention used elsewhere in the app
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _openAddGoalDialog(context),
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'add goal',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
