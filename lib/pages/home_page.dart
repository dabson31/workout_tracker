import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/components/heat_map.dart';
import 'package:workout_tracker/components/premium_dialog.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/datetime/date_time.dart';
import 'package:workout_tracker/theme/app_theme.dart';
import 'package:workout_tracker/utils/format_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // the day shown in the inline log view below the heatmap
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Provider.of<WorkoutData>(context, listen: false).initializeWorkoutList();
  }

  // ── stats strip ──────────────────────────────────────────────────────────────

  Widget _buildStatsStrip(WorkoutData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          _statCell('${data.getWorkoutsThisMonth()}', 'workouts\nthis month', Icons.calendar_month_rounded),
          _divider(),
          _statCell('${data.getWorkoutsAllTime()}', 'workouts\nall time', Icons.emoji_events_rounded),
          _divider(),
          _statCell('${data.getCurrentStreak()}', 'current\nday streak', Icons.local_fire_department_rounded),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label, IconData icon) => Expanded(
    child: Column(children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
    ]),
  );

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.surfaceLight);

  // ── inline day view ───────────────────────────────────────────────────────────

  /// "Tue, Jun 30" format
  String _formatDate(DateTime d) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months  = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  Widget _buildLogChip(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.primary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]),
  );

  // "8" -> "8 reps", but "set 1: 8  set 2: 6" stays as-is (already self-explanatory)
  String _repsLabel(String raw) {
    final formatted = formatPerSetValue(raw);
    return formatted.contains('set ') ? formatted : '$formatted reps';
  }

  // ── log dialogs ───────────────────────────────────────────────────────────────

  Widget _exerciseOptionsList(AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        elevation: 6,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220, maxWidth: 280),
          child: options.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'no matching exercises \u2014 you can still type a new name',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (_, i) => InkWell(
                    onTap: () => onSelected(options.elementAt(i)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(options.elementAt(i), style: const TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // matches the field styling used by the workout page's log dialog
  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  final _editNameCtrl = TextEditingController();

  void _editLog(String ddmmyyyy, Map<String, String> log) {
    final oldName   = log['exercise']!;
    final oldWeight = log['weight']!;
    final oldReps   = log['reps']!;
    final oldSets   = log['sets']!;

    _editNameCtrl.text = oldName;

    // support both old single-value ("25" / "8") and new per-set
    // ("20,22.5,25" / "8,8,6") formats
    final prevWeightClean = oldWeight.replaceAll(RegExp(r'kg$', caseSensitive: false), '');
    final prevWeightParts = prevWeightClean.split(',').map((s) => s.trim()).toList();
    final prevRepsParts = oldReps.split(',').map((s) => s.trim()).toList();

    final setsController = TextEditingController(text: oldSets);
    List<TextEditingController> weightControllers = List.generate(
      prevWeightParts.isEmpty ? 1 : prevWeightParts.length,
      (i) => TextEditingController(text: i < prevWeightParts.length ? prevWeightParts[i] : ''),
    );
    List<TextEditingController> repsControllers = List.generate(
      prevRepsParts.isEmpty ? 1 : prevRepsParts.length,
      (i) => TextEditingController(text: i < prevRepsParts.length ? prevRepsParts[i] : ''),
    );

    showPremiumDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // keep weight/reps controllers in sync with the sets field, same
          // as the workout page's log dialog
          int setsCount = int.tryParse(setsController.text) ?? 1;
          if (setsCount < 1) setsCount = 1;
          if (setsCount > 20) setsCount = 20;

          if (weightControllers.length != setsCount) {
            final existing = weightControllers;
            weightControllers = List.generate(setsCount, (i) {
              if (i < existing.length) return existing[i];
              final seed = prevWeightParts.isNotEmpty ? prevWeightParts.last : '';
              return TextEditingController(text: seed);
            });
          }
          if (repsControllers.length != setsCount) {
            final existing = repsControllers;
            repsControllers = List.generate(setsCount, (i) {
              if (i < existing.length) return existing[i];
              final seed = prevRepsParts.isNotEmpty ? prevRepsParts.last : '';
              return TextEditingController(text: seed);
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 12,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            title: const Text('edit logged exercise', style: TextStyle(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (tv) {
                      final known = Provider.of<WorkoutData>(context, listen: false).getKnownExerciseNames();
                      if (tv.text.isEmpty) return known;
                      return known.where((n) => n.toLowerCase().contains(tv.text.toLowerCase()));
                    },
                    initialValue: TextEditingValue(text: _editNameCtrl.text),
                    onSelected: (s) => _editNameCtrl.text = s,
                    fieldViewBuilder: (_, fc, fn, _) {
                      fc.text = _editNameCtrl.text;
                      fc.addListener(() => _editNameCtrl.text = fc.text);
                      return TextField(
                        controller: fc, focusNode: fn, autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: fieldDecoration('exercise name'),
                      );
                    },
                    optionsViewBuilder: (_, onSel, opts) => _exerciseOptionsList(onSel, opts),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'previous: $oldWeight, $oldReps reps, $oldSets sets',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: fieldDecoration('sets'),
                    onChanged: (_) => setDialogState(() {}),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'reps & weight per set',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // one reps + weight row per set
                  ...List.generate(setsCount, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: repsControllers[i],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: fieldDecoration('set ${i + 1} reps'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightControllers[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: fieldDecoration('set ${i + 1} weight').copyWith(
                              suffixText: 'kg',
                              suffixStyle: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  final setsN = int.tryParse(setsController.text) ?? 1;
                  // build comma-separated weight/reps strings, one value per set
                  final weightString = List.generate(
                    setsN.clamp(1, weightControllers.length),
                    (i) => '${weightControllers[i].text}kg',
                  ).join(',');
                  final repsString = List.generate(
                    setsN.clamp(1, repsControllers.length),
                    (i) => repsControllers[i].text,
                  ).join(',');

                  Provider.of<WorkoutData>(context, listen: false).editLoggedExercise(
                    ddmmyyyy, log['workout']!, oldName, _editNameCtrl.text,
                    weightString, repsString, setsController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 5),
                      backgroundColor: AppColors.surfaceLight,
                      behavior: SnackBarBehavior.floating,
                      content: const Text('log updated', style: TextStyle(color: AppColors.textPrimary)),
                      action: SnackBarAction(
                        label: 'undo',
                        textColor: AppColors.primary,
                        onPressed: () {
                          Provider.of<WorkoutData>(context, listen: false).editLoggedExercise(
                            ddmmyyyy, log['workout']!, _editNameCtrl.text,
                            oldName, oldWeight, oldReps, oldSets,
                          );
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
          );
        },
      ),
    );
  }

  final _addNameCtrl = TextEditingController();

  void _addLog(String ddmmyyyy) {
    _addNameCtrl.clear();

    final setsController = TextEditingController(text: '1');
    List<TextEditingController> weightControllers = [TextEditingController()];
    List<TextEditingController> repsControllers = [TextEditingController()];

    showPremiumDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // keep weight/reps controllers in sync with the sets field, same
          // as the workout page's log dialog
          int setsCount = int.tryParse(setsController.text) ?? 1;
          if (setsCount < 1) setsCount = 1;
          if (setsCount > 20) setsCount = 20;

          if (weightControllers.length != setsCount) {
            final existing = weightControllers;
            weightControllers = List.generate(setsCount, (i) {
              if (i < existing.length) return existing[i];
              return TextEditingController();
            });
          }
          if (repsControllers.length != setsCount) {
            final existing = repsControllers;
            repsControllers = List.generate(setsCount, (i) {
              if (i < existing.length) return existing[i];
              return TextEditingController();
            });
          }

          // fills the sets/reps/weight fields with the most recent logged
          // values for the chosen exercise, so picking a known exercise
          // from the heatmap day view doesn't start from a blank slate.
          void prefillFromExercise(String name) {
            final entry = Provider.of<WorkoutData>(context, listen: false)
                .getMostRecentLogForExercise(name.trim());
            if (entry == null) return;

            final weightParts = entry.weight.split(',').map((p) => stripWeightUnit(p.trim())).toList();
            final repsParts = entry.reps.split(',').map((p) => p.trim()).toList();

            setDialogState(() {
              setsController.text = entry.sets;
              weightControllers = List.generate(
                weightParts.isEmpty ? 1 : weightParts.length,
                (i) => TextEditingController(text: i < weightParts.length ? weightParts[i] : ''),
              );
              repsControllers = List.generate(
                repsParts.isEmpty ? 1 : repsParts.length,
                (i) => TextEditingController(text: i < repsParts.length ? repsParts[i] : ''),
              );
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 12,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            title: const Text('add to this day', style: TextStyle(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<String>(
                    optionsBuilder: (tv) {
                      final known = Provider.of<WorkoutData>(context, listen: false).getKnownExerciseNames();
                      if (tv.text.isEmpty) return known;
                      return known.where((n) => n.toLowerCase().contains(tv.text.toLowerCase()));
                    },
                    onSelected: (s) {
                      _addNameCtrl.text = s;
                      prefillFromExercise(s);
                    },
                    fieldViewBuilder: (_, fc, fn, _) {
                      fc.addListener(() => _addNameCtrl.text = fc.text);
                      return TextField(
                        controller: fc, focusNode: fn, autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: fieldDecoration('exercise name'),
                        // typing a name that exactly matches a known
                        // exercise (without picking it from the dropdown)
                        // also prefills, e.g. resuming a previous entry
                        onSubmitted: (v) => prefillFromExercise(v),
                      );
                    },
                    optionsViewBuilder: (_, onSel, opts) => _exerciseOptionsList(onSel, opts),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: fieldDecoration('sets'),
                    onChanged: (_) => setDialogState(() {}),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'reps & weight per set',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // one reps + weight row per set
                  ...List.generate(setsCount, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: repsControllers[i],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: fieldDecoration('set ${i + 1} reps'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightControllers[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: fieldDecoration('set ${i + 1} weight').copyWith(
                              suffixText: 'kg',
                              suffixStyle: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  if (_addNameCtrl.text.trim().isEmpty) return;
                  final setsN = int.tryParse(setsController.text) ?? 1;
                  final weightString = List.generate(
                    setsN.clamp(1, weightControllers.length),
                    (i) => '${weightControllers[i].text}kg',
                  ).join(',');
                  final repsString = List.generate(
                    setsN.clamp(1, repsControllers.length),
                    (i) => repsControllers[i].text,
                  ).join(',');

                  Provider.of<WorkoutData>(context, listen: false).addLoggedExercise(
                    ddmmyyyy, 'Standalone', _addNameCtrl.text.trim(),
                    weightString, repsString, setsController.text,
                  );
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

  void _showNoteDialog(String ddmmyyyy, String? existingNote) {
    final isRest   = existingNote != null && existingNote.startsWith('__REST__');
    final noteText = isRest ? existingNote.substring('__REST__'.length).trim() : (existingNote ?? '');
    final noteCtrl = TextEditingController(text: noteText);
    bool restDay   = isRest;

    showPremiumDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          title: const Text('day note', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => setDs(() => restDay = !restDay),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: restDay ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: restDay ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent),
                  ),
                  child: Row(children: [
                    Icon(Icons.bedtime_rounded, color: restDay ? AppColors.primary : AppColors.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text('mark as rest day', style: TextStyle(color: restDay ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (restDay) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'add a note (optional)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ]),
          ),
          actions: [
            if (existingNote != null)
              MaterialButton(
                onPressed: () {
                  Provider.of<WorkoutData>(ctx, listen: false).deleteDayNote(ddmmyyyy);
                  Navigator.pop(ctx);
                },
                child: const Text('remove', style: TextStyle(color: AppColors.danger)),
              ),
            MaterialButton(
              onPressed: () {
                final text   = noteCtrl.text.trim();
                final stored = restDay ? '__REST__$text' : text;
                if (stored.isEmpty || stored == '__REST__') {
                  Provider.of<WorkoutData>(ctx, listen: false).deleteDayNote(ddmmyyyy);
                } else {
                  Provider.of<WorkoutData>(ctx, listen: false).saveDayNote(ddmmyyyy, stored);
                }
                Navigator.pop(ctx);
              },
              child: const Text('save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            MaterialButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── inline day section ────────────────────────────────────────────────────────

  Widget _buildInlineDaySection(WorkoutData data) {
    final ddmmyyyy = convertDateTimeObjectToDDMMYYYY(_selectedDate);
    final logs     = data.getLogsForDate(ddmmyyyy);
    final note     = data.getDayNote(ddmmyyyy);
    final isRest   = note != null && note.startsWith('__REST__');
    final noteText = note != null
        ? (isRest ? note.substring('__REST__'.length).trim() : note)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // date header row
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.edit_note_rounded,
                  color: note != null ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                tooltip: 'note / rest day',
                onPressed: () => _showNoteDialog(ddmmyyyy, note),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 22),
                tooltip: 'add exercise',
                onPressed: () => _addLog(ddmmyyyy),
              ),
            ],
          ),
        ),

        // rest day / note badge
        if (isRest || (noteText != null && noteText.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isRest ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: isRest ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
            ),
            child: Row(children: [
              Icon(
                isRest ? Icons.bedtime_rounded : Icons.notes_rounded,
                color: isRest ? AppColors.primary : AppColors.textSecondary,
                size: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRest
                      ? (noteText != null && noteText.isNotEmpty ? 'rest day · $noteText' : 'rest day')
                      : noteText!,
                  style: TextStyle(
                    color: isRest ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ]),
          ),

        // empty state
        if (logs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'nothing logged this day',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),

        // exercise log tiles
        ...logs.map((log) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.4,
              children: [
                SlidableAction(
                  onPressed: (_) => _editLog(ddmmyyyy, log),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: Icons.edit_rounded,
                  label: 'edit',
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                SlidableAction(
                  onPressed: (_) {
                    final snap = Map<String, String>.from(log);
                    Provider.of<WorkoutData>(context, listen: false)
                        .deleteLoggedExercise(ddmmyyyy, log['workout']!, log['exercise']!);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 5),
                        backgroundColor: AppColors.surfaceLight,
                        behavior: SnackBarBehavior.floating,
                        content: Text('"${snap['exercise']}" removed', style: const TextStyle(color: AppColors.textPrimary)),
                        action: SnackBarAction(
                          label: 'undo',
                          textColor: AppColors.primary,
                          onPressed: () {
                            Provider.of<WorkoutData>(context, listen: false).addLoggedExercise(
                              ddmmyyyy, snap['workout']!, snap['exercise']!,
                              snap['weight']!, snap['reps']!, snap['sets']!,
                            );
                          },
                        ),
                      ),
                    );
                  },
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_rounded,
                  label: 'delete',
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      log['exercise']!,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _buildLogChip(formatPerSetValue(log['weight']!), Icons.scale_rounded),
                      _buildLogChip(_repsLabel(log['reps']!), Icons.repeat_rounded),
                      _buildLogChip('${log['sets']} sets', Icons.layers_rounded),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        )),
      ],
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, data, _) => Scaffold(
        appBar: AppBar(title: const Text('home')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          children: [
            _buildStatsStrip(data),
            MyHeatMap(
              datasets: data.heatMapDataSet,
              selectedDate: _selectedDate,
              onDayTap: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 20),
            _buildInlineDaySection(data),
          ],
        ),
      ),
    );
  }
}
