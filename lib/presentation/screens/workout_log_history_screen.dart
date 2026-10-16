import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/workout_log.dart';
import '../../providers/workout_providers.dart';

class WorkoutLogHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutLogHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutLogHistoryScreen> createState() => _WorkoutLogHistoryScreenState();
}

class _WorkoutLogHistoryScreenState extends ConsumerState<WorkoutLogHistoryScreen> {
  String? _selectedAthlete;
  String? _selectedSession;
  DateTime? _filterDate;

  void _showEditLogDialog(BuildContext context, WorkoutLog log) {
    final wtController = TextEditingController(text: log.weightKg.toString());
    final repsController = TextEditingController(text: log.reps.toString());
    final notesController = TextEditingController(text: log.notes ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Log Set #${log.setNumber}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wtController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNeon,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final newWt = double.tryParse(wtController.text) ?? log.weightKg;
                final newReps = int.tryParse(repsController.text) ?? log.reps;
                final newNotes = notesController.text.trim().isEmpty ? null : notesController.text.trim();

                final updatedLog = log.copyWith(
                  weightKg: newWt,
                  reps: newReps,
                  notes: newNotes,
                );

                await ref.read(workoutRepositoryProvider).updateWorkoutLog(updatedLog);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteLog(BuildContext context, WorkoutLog log) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Workout Set', style: TextStyle(color: AppColors.accentRed, fontSize: 16)),
          content: Text(
            'Are you sure you want to delete Set #${log.setNumber} (${log.weightKg} kg × ${log.reps} reps)?',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await ref.read(workoutRepositoryProvider).deleteWorkoutLog(log.logId);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepositoryProvider);
    ref.watch(workoutLogsStreamProvider); // trigger reactivity

    final logs = repo.getWorkoutLogs(
      userId: _selectedAthlete,
      sessionDay: _selectedSession,
      fromDate: _filterDate,
      toDate: _filterDate,
    );

    final totalSessions = repo.getUniqueSessionsCount(userId: _selectedAthlete);
    final totalVolume = repo.getTotalVolumeKg(userId: _selectedAthlete);
    final lastWorkout = repo.getLastWorkoutDate(userId: _selectedAthlete);

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
              child: const Icon(Icons.history_rounded, color: AppColors.primaryNeon, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Workout Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Activity & Set History',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Metric Summary Cards
            _buildMetricCards(totalSessions, totalVolume, lastWorkout),

            const SizedBox(height: 16),

            // 2. Filters Row
            _buildFilterSection(),

            const SizedBox(height: 16),

            // 3. Logs Count Header
            Row(
              children: [
                Text(
                  '${logs.length} Recorded Sets',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedAthlete != null || _selectedSession != null || _filterDate != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    icon: const Icon(Icons.clear_all_rounded, size: 16, color: AppColors.accentRed),
                    label: const Text('Reset Filters', style: TextStyle(color: AppColors.accentRed, fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _selectedAthlete = null;
                        _selectedSession = null;
                        _filterDate = null;
                      });
                    },
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // 4. Log Cards List
            if (logs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Text('No workout logs match current filters.', style: TextStyle(color: AppColors.textMuted)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final ex = repo.getExerciseById(log.exerciseId);
                  final isHans = log.userId == AppConstants.userHansId;
                  final athleteColor = isHans ? AppColors.athleteHans : AppColors.athleteBaby;
                  final athleteName = isHans ? 'Hans' : 'Cute lil baby';

                  return _buildLogCard(context, log, ex, athleteName, athleteColor);
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards(int totalSessions, double totalVolume, String lastWorkout) {
    return Row(
      children: [
        Expanded(
          child: _buildSingleMetric(
            title: 'TOTAL SESSIONS',
            value: '$totalSessions Sessions',
            icon: Icons.calendar_today_rounded,
            color: AppColors.accentCyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSingleMetric(
            title: 'TOTAL VOLUME',
            value: '${totalVolume.toStringAsFixed(0)} kg',
            icon: Icons.fitness_center_rounded,
            color: AppColors.primaryNeon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSingleMetric(
            title: 'LAST WORKOUT',
            value: lastWorkout,
            icon: Icons.access_time_rounded,
            color: AppColors.accentAmber,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Athlete filter chips
          Row(
            children: [
              const Text('Athlete: ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(width: 6),
              _buildFilterChip('All', _selectedAthlete == null, () {
                setState(() => _selectedAthlete = null);
              }),
              const SizedBox(width: 6),
              _buildFilterChip('Hans', _selectedAthlete == AppConstants.userHansId, () {
                setState(() => _selectedAthlete = AppConstants.userHansId);
              }, activeColor: AppColors.athleteHans),
              const SizedBox(width: 6),
              _buildFilterChip('Cute lil baby', _selectedAthlete == AppConstants.userBabyId, () {
                setState(() => _selectedAthlete = AppConstants.userBabyId);
              }, activeColor: AppColors.athleteBaby),
            ],
          ),

          const SizedBox(height: 10),

          // Session & Date dropdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedSession,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceCard,
                      hint: const Text('All Sessions', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Sessions', style: TextStyle(fontSize: 11))),
                        ...AppConstants.sessionDays.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedSession = val);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Date Filter
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _filterDate ?? DateTime(2026, 10, 8),
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  setState(() => _filterDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filterDate != null ? AppColors.primaryNeon.withOpacity(0.15) : AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(8),
                    border: _filterDate != null ? Border.all(color: AppColors.primaryNeon) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: _filterDate != null ? AppColors.primaryNeon : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _filterDate != null ? DateFormat('dd MMM').format(_filterDate!) : 'Date',
                        style: TextStyle(
                          color: _filterDate != null ? AppColors.primaryNeon : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? activeColor}) {
    final color = activeColor ?? AppColors.primaryNeon;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 1.2) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(
    BuildContext context,
    WorkoutLog log,
    dynamic ex,
    String athleteName,
    Color athleteColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Athlete Indicator Bar
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: athleteColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // Exercise & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      athleteName,
                      style: TextStyle(color: athleteColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${log.workoutDate}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Set ${log.setNumber}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  ex?.exerciseName ?? log.exerciseId,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${log.weightKg} kg × ${log.reps} reps',
                      style: const TextStyle(color: AppColors.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Vol: ${log.volumeKg.toStringAsFixed(0)}kg',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '1RM: ${log.est1rm}kg',
                      style: const TextStyle(color: AppColors.accentCyan, fontSize: 10),
                    ),
                  ],
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📝 ${log.notes}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Edit / Delete Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
            onPressed: () => _showEditLogDialog(context, log),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.accentRed),
            onPressed: () => _confirmDeleteLog(context, log),
          ),
        ],
      ),
    );
  }
}

