import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_master.dart';
import '../../data/models/workout_log.dart';
import '../../providers/workout_providers.dart';
import '../widgets/progressive_overload_badge.dart';

class SetRowData {
  final int setNumber;
  double weight;
  int reps;
  bool isCompleted;

  SetRowData({
    required this.setNumber,
    this.weight = 0.0,
    this.reps = 0,
    this.isCompleted = false,
  });

  double get volume => double.parse((weight * reps).toStringAsFixed(2));
  double get est1rm => WorkoutLog.calculateEst1rm(weight, reps);
}

class DuoWorkoutFormScreen extends ConsumerStatefulWidget {
  const DuoWorkoutFormScreen({super.key});

  @override
  ConsumerState<DuoWorkoutFormScreen> createState() => _DuoWorkoutFormScreenState();
}

class _DuoWorkoutFormScreenState extends ConsumerState<DuoWorkoutFormScreen> {
  // Separate 5-set state for Hans and Cute lil baby
  final Map<String, List<SetRowData>> _athleteSets = {
    AppConstants.userHansId: List.generate(5, (i) => SetRowData(setNumber: i + 1)),
    AppConstants.userBabyId: List.generate(5, (i) => SetRowData(setNumber: i + 1)),
  };

  // Controllers for text inputs: [athleteId][setIndex][field]
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};

  final TextEditingController _notesController = TextEditingController();

  String? _selectedExerciseId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final uid in [AppConstants.userHansId, AppConstants.userBabyId]) {
      _weightControllers[uid] = List.generate(5, (_) => TextEditingController());
      _repsControllers[uid] = List.generate(5, (_) => TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final list in _weightControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final list in _repsControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    _notesController.dispose();
    super.dispose();
  }

  void _onExerciseChanged(String? newExId) {
    if (newExId == null) return;
    setState(() {
      _selectedExerciseId = newExId;
    });

    final repo = ref.read(workoutRepositoryProvider);
    final ex = repo.getExerciseById(newExId);
    if (ex == null) return;

    // Auto-fill target weights for both athletes from their last recorded session
    for (final uid in [AppConstants.userHansId, AppConstants.userBabyId]) {
      final lastWt = repo.getLastWeightForExercise(uid, newExId);
      if (lastWt != null && lastWt > 0) {
        for (int i = 0; i < 5; i++) {
          final row = _athleteSets[uid]![i];
          if (!row.isCompleted) {
            row.weight = lastWt;
            _weightControllers[uid]![i].text = lastWt.toString();
          }
        }
      }
    }
  }

  void _applyProgressiveOverload(String uid) {
    final sets = _athleteSets[uid]!;
    for (int i = 0; i < sets.length; i++) {
      if (!sets[i].isCompleted) {
        sets[i].weight += AppConstants.progressiveOverloadIncrement;
        _weightControllers[uid]![i].text = sets[i].weight.toString();
      }
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryNeon,
        content: Text(
          '+${AppConstants.progressiveOverloadIncrement} kg applied to upcoming sets! 💪',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onSetCompletedChanged(String uid, int index, bool? checked) {
    setState(() {
      _athleteSets[uid]![index].isCompleted = checked ?? false;
    });

    if (checked == true) {
      HapticFeedback.mediumImpact();
      // Start auto-rest timer!
      ref.read(restTimerProvider.notifier).start(durationSeconds: AppConstants.defaultRestSeconds);
    }
  }

  Future<void> _submitWorkout(String uid) async {
    if (_isSubmitting) return; // Debounce protection

    final selectedExId = _selectedExerciseId;
    if (selectedExId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentRed,
          content: Text('Please select an exercise first!'),
        ),
      );
      return;
    }

    final setsToSave = _athleteSets[uid]!.where((s) => s.isCompleted || (s.weight > 0 && s.reps > 0)).toList();

    if (setsToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentAmber,
          content: Text('Please check at least one set or enter weight & reps!'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final selectedDate = ref.read(selectedWorkoutDateProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      final List<WorkoutLog> newLogs = [];
      for (final s in setsToSave) {
        newLogs.add(WorkoutLog.create(
          logId: 'LOG-${DateTime.now().millisecondsSinceEpoch}-${uid.substring(uid.length - 3)}-${s.setNumber}',
          workoutDate: dateStr,
          userId: uid,
          exerciseId: selectedExId,
          setNumber: s.setNumber,
          weightKg: s.weight,
          reps: s.reps,
          notes: notes,
        ));
      }

      await repo.saveWorkoutLogs(newLogs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryNeon,
            content: Text(
              '✓ Saved ${newLogs.length} sets to database! 🔥',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Reset set rows for this athlete
        setState(() {
          _athleteSets[uid] = List.generate(5, (i) => SetRowData(setNumber: i + 1));
          for (final c in _weightControllers[uid]!) {
            c.clear();
          }
          for (final c in _repsControllers[uid]!) {
            c.clear();
          }
          _notesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accentRed,
            content: Text('Error saving: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUserId = ref.watch(activeUserIdProvider);
    final selectedSession = ref.watch(selectedSessionDayProvider);
    final selectedDate = ref.watch(selectedWorkoutDateProvider);
    final repo = ref.watch(workoutRepositoryProvider);
    final isDuoSplit = ref.watch(isDuoModeActiveProvider);

    // List of exercises for selected session
    final sessionExercises = repo.getExercises(sessionDay: selectedSession, activeOnly: true);

    if (_selectedExerciseId == null && sessionExercises.isNotEmpty) {
      _selectedExerciseId = sessionExercises.first.exerciseId;
    }

    final currentExercise = _selectedExerciseId != null
        ? repo.getExerciseById(_selectedExerciseId!)
        : null;

    final isHansActive = activeUserId == AppConstants.userHansId;
    final activeColor = isHansActive ? AppColors.athleteHans : AppColors.athleteBaby;

    final hasProgressiveOverload = currentExercise != null &&
        repo.checkProgressiveOverload(activeUserId, currentExercise.exerciseId, currentExercise.targetReps);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fitness_center_rounded, color: AppColors.primaryNeon, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grit Workout Form',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Tandem & Duo Sync',
                  style: TextStyle(fontSize: 11, color: activeColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Split Duo View Toggle
          IconButton(
            tooltip: isDuoSplit ? 'Switch to Single Tab' : 'Switch to Duo Split View',
            icon: Icon(
              isDuoSplit ? Icons.view_agenda_rounded : Icons.splitscreen_rounded,
              color: isDuoSplit ? AppColors.primaryNeon : AppColors.textSecondary,
            ),
            onPressed: () {
              ref.read(isDuoModeActiveProvider.notifier).state = !isDuoSplit;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Session & Date Row
            _buildSessionAndDateSelectors(context, selectedSession, selectedDate),

            const SizedBox(height: 16),

            // 2. Athlete Segmented Toggle (Hans vs Cute lil baby)
            _buildAthleteToggle(activeUserId, isHansActive),

            const SizedBox(height: 16),

            // 3. Exercise Selector & Metadata Card
            _buildExerciseSelectorCard(sessionExercises, currentExercise, hasProgressiveOverload, activeUserId),

            const SizedBox(height: 16),

            // 4. Sets Table (or Duo Split)
            if (isDuoSplit) ...[
              _buildDuoSplitView(currentExercise),
            ] else ...[
              _buildSetsCard(activeUserId, currentExercise, activeColor),
            ],

            const SizedBox(height: 20),

            // 5. Notes & Submit Button
            _buildSubmitSection(activeUserId),

            const SizedBox(height: 60), // Spacing for floating timer
          ],
        ),
      ),
    );
  }

  Widget _buildSessionAndDateSelectors(BuildContext context, String selectedSession, DateTime selectedDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Session Dropdown
          Expanded(
            flex: 3,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSession,
                isExpanded: true,
                dropdownColor: AppColors.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryNeon),
                items: AppConstants.sessionDays.map((day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newSession) {
                  if (newSession != null) {
                    ref.read(selectedSessionDayProvider.notifier).state = newSession;
                    setState(() {
                      _selectedExerciseId = null;
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 28, color: AppColors.border),
          const SizedBox(width: 8),

          // Date Picker Button
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primaryNeon,
                        onPrimary: Colors.black,
                        surface: AppColors.surfaceCard,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(selectedWorkoutDateProvider.notifier).state = picked;
              }
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: AppColors.primaryNeon, size: 16),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM').format(selectedDate),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteToggle(String activeUserId, bool isHansActive) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Hans Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(activeUserIdProvider.notifier).state = AppConstants.userHansId;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isHansActive ? AppColors.athleteHans.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isHansActive ? Border.all(color: AppColors.athleteHans, width: 1.2) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: isHansActive ? AppColors.athleteHans : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hans (USR-001)',
                      style: TextStyle(
                        color: isHansActive ? AppColors.athleteHans : AppColors.textSecondary,
                        fontWeight: isHansActive ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Cute lil baby Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(activeUserIdProvider.notifier).state = AppConstants.userBabyId;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isHansActive ? AppColors.athleteBaby.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: !isHansActive ? Border.all(color: AppColors.athleteBaby, width: 1.2) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: !isHansActive ? AppColors.athleteBaby : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cute lil baby',
                      style: TextStyle(
                        color: !isHansActive ? AppColors.athleteBaby : AppColors.textSecondary,
                        fontWeight: !isHansActive ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSelectorCard(
    List<ExerciseMaster> sessionExercises,
    ExerciseMaster? currentExercise,
    bool hasProgressiveOverload,
    String activeUserId,
  ) {
    final repo = ref.read(workoutRepositoryProvider);
    final lastWt = currentExercise != null
        ? repo.getLastWeightForExercise(activeUserId, currentExercise.exerciseId)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_rounded, color: AppColors.primaryNeon, size: 18),
              const SizedBox(width: 8),
              const Text(
                'TARGET EXERCISE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (lastWt != null && lastWt > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Last Session: ${lastWt}kg',
                    style: const TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Exercise Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedExerciseId,
                isExpanded: true,
                dropdownColor: AppColors.surfaceCard,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryNeon),
                items: sessionExercises.map((ex) {
                  return DropdownMenuItem<String>(
                    value: ex.exerciseId,
                    child: Text(
                      '${ex.sortOrder}. ${ex.exerciseName}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _onExerciseChanged,
              ),
            ),
          ),

          if (currentExercise != null) ...[
            const SizedBox(height: 12),
            // Metadata chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (currentExercise.targetReps != null)
                  _buildMetadataChip(Icons.repeat_rounded, 'Reps: ${currentExercise.targetReps}'),
                if (currentExercise.targetMuscle != null)
                  _buildMetadataChip(Icons.accessibility_new_rounded, currentExercise.targetMuscle!),
                if (currentExercise.equipment != null)
                  _buildMetadataChip(Icons.fitness_center_outlined, currentExercise.equipment!),
              ],
            ),
          ],

          if (hasProgressiveOverload) ...[
            const SizedBox(height: 12),
            ProgressiveOverloadBadge(
              onTapApply: () => _applyProgressiveOverload(activeUserId),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsCard(String uid, ExerciseMaster? currentExercise, Color activeColor) {
    final sets = _athleteSets[uid]!;
    final completedSets = sets.where((s) => s.isCompleted).length;
    final validSets = sets.where((s) => s.weight > 0 && s.reps > 0).toList();
    final totalVol = sets.fold(0.0, (sum, s) => sum + s.volume);
    final avgWt = validSets.isNotEmpty
        ? (validSets.fold(0.0, (sum, s) => sum + s.weight) / validSets.length)
        : 0.0;
    final maxEst1rm = sets.fold(0.0, (max, s) => s.est1rm > max ? s.est1rm : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_list_rounded, color: AppColors.primaryNeon, size: 18),
              const SizedBox(width: 8),
              Text(
                'WORKOUT SET DETAILS (SET 1 - 5)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$completedSets / 5 Sets Done',
                  style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Table Header
          Row(
            children: const [
              SizedBox(width: 48, child: Text('Set', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Center(child: Text('Wt (kg)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
              SizedBox(width: 6),
              Expanded(flex: 3, child: Center(child: Text('Reps', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
              SizedBox(width: 6),
              Expanded(flex: 3, child: Center(child: Text('Vol (kg)', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
              SizedBox(width: 6),
              Expanded(flex: 3, child: Center(child: Text('1RM', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
              SizedBox(width: 36, child: Center(child: Text('✓', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)))),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),

          // Rows 1 to 5
          for (int i = 0; i < 5; i++) ...[
            _buildSetRow(uid, i, activeColor),
            if (i < 4) const SizedBox(height: 8),
          ],

          const Divider(),
          const SizedBox(height: 8),

          // Summary Row (TOTAL Sets, Avg Wt, Total Vol, Max Est 1RM)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 50,
                  child: Text(
                    'TOTAL',
                    style: TextStyle(color: AppColors.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Avg ${avgWt.toStringAsFixed(1)}k',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '${sets.where((s) => s.isCompleted).length} Sets',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '${totalVol.toStringAsFixed(0)} kg',
                      style: const TextStyle(color: AppColors.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Max ${maxEst1rm.toStringAsFixed(1)}',
                      style: const TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(String uid, int index, Color activeColor) {
    final set = _athleteSets[uid]![index];
    final wtController = _weightControllers[uid]![index];
    final repsController = _repsControllers[uid]![index];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: set.isCompleted ? activeColor.withOpacity(0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set label
          SizedBox(
            width: 48,
            child: Text(
              'Set ${index + 1}',
              style: TextStyle(
                color: set.isCompleted ? activeColor : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Wt input
          Expanded(
            flex: 3,
            child: TextField(
              controller: wtController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                setState(() {
                  set.weight = parsed;
                });
              },
            ),
          ),

          const SizedBox(width: 6),

          // Reps input
          Expanded(
            flex: 3,
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                setState(() {
                  set.reps = parsed;
                });
              },
            ),
          ),

          const SizedBox(width: 6),

          // Live Volume
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                set.volume > 0 ? set.volume.toStringAsFixed(0) : '-',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Live 1RM
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                set.est1rm > 0 ? set.est1rm.toStringAsFixed(1) : '-',
                style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Checkbox status
          SizedBox(
            width: 36,
            child: Checkbox(
              value: set.isCompleted,
              activeColor: activeColor,
              checkColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (checked) => _onSetCompletedChanged(uid, index, checked),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuoSplitView(ExerciseMaster? currentExercise) {
    return Column(
      children: [
        _buildSetsCard(AppConstants.userHansId, currentExercise, AppColors.athleteHans),
        const SizedBox(height: 16),
        _buildSetsCard(AppConstants.userBabyId, currentExercise, AppColors.athleteBaby),
      ],
    );
  }

  Widget _buildSubmitSection(String activeUserId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _notesController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Notes (e.g. Focus on tempo, felt easy, grip was slipping)',
              prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitWorkout(activeUserId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNeon,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'SAVE WORKOUT TO SUPABASE',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
