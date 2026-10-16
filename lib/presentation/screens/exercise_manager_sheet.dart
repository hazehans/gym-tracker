import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_master.dart';
import '../../providers/workout_providers.dart';

class ExerciseManagerScreen extends ConsumerStatefulWidget {
  const ExerciseManagerScreen({super.key});

  @override
  ConsumerState<ExerciseManagerScreen> createState() => _ExerciseManagerScreenState();
}

class _ExerciseManagerScreenState extends ConsumerState<ExerciseManagerScreen> {
  String _selectedSession = AppConstants.sessionTuesday;
  bool _showArchived = false;

  void _openExerciseFormModal(BuildContext context, {ExerciseMaster? existingExercise}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingExercise?.exerciseName ?? '');
    final muscleController = TextEditingController(text: existingExercise?.targetMuscle ?? '');
    final repsController = TextEditingController(text: existingExercise?.targetReps ?? '4 x 12');
    final equipController = TextEditingController(text: existingExercise?.equipment ?? '');

    String session = existingExercise?.sessionDay ?? _selectedSession;
    String status = existingExercise?.status ?? 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNeon.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fitness_center_rounded, color: AppColors.primaryNeon, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            existingExercise == null ? 'Add New Exercise' : 'Edit Exercise',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Session Day Dropdown
                      const Text('Target Session Day', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: session,
                            isExpanded: true,
                            dropdownColor: AppColors.surfaceCard,
                            items: AppConstants.sessionDays.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => session = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Exercise Name
                      const Text('Exercise Name *', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(hintText: 'e.g. Incline Dumbbell Press'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Exercise name is required!';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Target Muscle
                      const Text('Target Muscle *', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: muscleController,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(hintText: 'e.g. Upper Chest / Anterior Delts'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Target muscle is required!';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Target Reps
                      const Text('Target Reps *', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: repsController,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(hintText: 'e.g. 4 x 12 or 3 x 15 or 1 min'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Target reps is required!';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Equipment Guide
                      const Text('Equipment Guide *', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: equipController,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(hintText: 'e.g. Incline Bench & Dumbbells'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Equipment is required!';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Status Toggle
                      Row(
                        children: [
                          const Text('Movement Status: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Active', style: TextStyle(fontSize: 11)),
                            selected: status == 'Active',
                            selectedColor: AppColors.primaryNeon.withOpacity(0.2),
                            onSelected: (_) => setModalState(() => status = 'Active'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Archived', style: TextStyle(fontSize: 11)),
                            selected: status == 'Archived',
                            selectedColor: AppColors.accentRed.withOpacity(0.2),
                            onSelected: (_) => setModalState(() => status = 'Archived'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNeon,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final repo = ref.read(workoutRepositoryProvider);
                          final exercisesInSession = repo.getExercises(sessionDay: session, activeOnly: false);

                          if (existingExercise == null) {
                            // Generate new ID
                            final allEx = repo.getExercises(activeOnly: false);
                            final newIndex = allEx.length + 1;
                            final newId = 'EXE-${newIndex.toString().padLeft(3, '0')}';

                            final newExercise = ExerciseMaster(
                              exerciseId: newId,
                              sessionDay: session,
                              sortOrder: exercisesInSession.length + 1,
                              exerciseName: nameController.text.trim(),
                              targetMuscle: muscleController.text.trim(),
                              targetReps: repsController.text.trim(),
                              equipment: equipController.text.trim(),
                              status: status,
                            );

                            await repo.addExercise(newExercise);
                          } else {
                            final updated = existingExercise.copyWith(
                              sessionDay: session,
                              exerciseName: nameController.text.trim(),
                              targetMuscle: muscleController.text.trim(),
                              targetReps: repsController.text.trim(),
                              equipment: equipController.text.trim(),
                              status: status,
                            );

                            await repo.updateExercise(updated);
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.primaryNeon,
                                content: Text(
                                  existingExercise == null ? '✓ Exercise created!' : '✓ Exercise updated!',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          existingExercise == null ? 'CREATE EXERCISE' : 'SAVE CHANGES',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepositoryProvider);
    ref.watch(exercisesStreamProvider);

    final exercises = repo.getExercises(
      sessionDay: _selectedSession,
      activeOnly: !_showArchived,
    );

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
              child: const Icon(Icons.settings_suggest_rounded, color: AppColors.primaryNeon, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise Manager',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Movement Library CRUD',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Hide Archived' : 'Show Archived',
            icon: Icon(
              _showArchived ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNeon,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openExerciseFormModal(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session filter pills
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.sessionDays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final s = AppConstants.sessionDays[index];
                  final isSelected = s == _selectedSession;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSession = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryNeon : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColors.primaryNeon : AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          s.split('•').first.trim(),
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Exercise count
            Row(
              children: [
                Text(
                  '${exercises.length} Exercises in $_selectedSession',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_showArchived)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Showing Archived', style: TextStyle(color: AppColors.accentRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Exercise Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ex = exercises[index];
                return _buildExerciseTile(context, ex);
              },
            ),

            const SizedBox(height: 80), // Fab space
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(BuildContext context, ExerciseMaster ex) {
    final isArchived = ex.status == 'Archived';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isArchived ? AppColors.accentRed.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Order badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${ex.sortOrder}',
              style: const TextStyle(color: AppColors.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ex.exerciseId,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 6),
                    if (isArchived)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Archived', style: TextStyle(color: AppColors.accentRed, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ex.exerciseName,
                  style: TextStyle(
                    color: isArchived ? AppColors.textSecondary : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: isArchived ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ex.targetReps ?? '-'} • ${ex.targetMuscle ?? 'General'} • ${ex.equipment ?? 'Custom'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),

          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
            onPressed: () => _openExerciseFormModal(context, existingExercise: ex),
          ),

          // Archive / Unarchive toggle
          IconButton(
            icon: Icon(
              isArchived ? Icons.unarchive_rounded : Icons.archive_outlined,
              color: isArchived ? AppColors.primaryNeon : AppColors.textMuted,
              size: 18,
            ),
            tooltip: isArchived ? 'Activate Movement' : 'Archive Movement',
            onPressed: () async {
              await ref.read(workoutRepositoryProvider).toggleExerciseStatus(ex.exerciseId, !isArchived);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: isArchived ? AppColors.primaryNeon : AppColors.surfaceHighlight,
                    content: Text(
                      isArchived ? 'Movement activated!' : 'Movement archived!',
                      style: TextStyle(color: isArchived ? Colors.black : AppColors.textPrimary),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

