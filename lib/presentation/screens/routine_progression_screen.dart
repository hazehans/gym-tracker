import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/weekly_progression.dart';
import '../../providers/workout_providers.dart';

class RoutineProgressionScreen extends ConsumerStatefulWidget {
  const RoutineProgressionScreen({super.key});

  @override
  ConsumerState<RoutineProgressionScreen> createState() => _RoutineProgressionScreenState();
}

class _RoutineProgressionScreenState extends ConsumerState<RoutineProgressionScreen> {
  String _selectedSessionFilter = AppConstants.sessionTuesday;

  @override
  Widget build(BuildContext context) {
    final activeUserId = ref.watch(activeUserIdProvider);
    final repo = ref.watch(workoutRepositoryProvider);
    ref.watch(workoutLogsStreamProvider); // trigger reactivity

    final progressions = repo.calculateWeeklyProgression(activeUserId);
    final allExercises = repo.getExercises(activeOnly: false);
    final activeCount = allExercises.where((e) => e.status == 'Active').length;
    final archivedCount = allExercises.where((e) => e.status == 'Archived').length;

    // Filter by session
    final filteredProgressions = progressions
        .where((p) => p.sessionDay == _selectedSessionFilter)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Progress in active session: exercises that have at least one set logged
    final completedInSession = filteredProgressions
        .where((p) => p.week1Kg != null || p.week2Kg != null || p.week3Kg != null || p.week4Kg != null)
        .length;

    final isHans = activeUserId == AppConstants.userHansId;
    final athleteColor = isHans ? AppColors.athleteHans : AppColors.athleteBaby;

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
              child: const Icon(Icons.bar_chart_rounded, color: AppColors.primaryNeon, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '4-Week Routine & Progression',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Grit Periodization Tracker',
                  style: TextStyle(fontSize: 11, color: athleteColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Quick Switch Athlete
          PopupMenuButton<String>(
            icon: Icon(Icons.person_pin_rounded, color: athleteColor),
            color: AppColors.surfaceHighlight,
            tooltip: 'Switch Athlete',
            onSelected: (uid) {
              ref.read(activeUserIdProvider.notifier).state = uid;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AppConstants.userHansId,
                child: Row(
                  children: const [
                    Icon(Icons.person, color: AppColors.athleteHans, size: 18),
                    SizedBox(width: 8),
                    Text('Hans'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppConstants.userBabyId,
                child: Row(
                  children: const [
                    Icon(Icons.favorite, color: AppColors.athleteBaby, size: 18),
                    SizedBox(width: 8),
                    Text('Cute lil baby'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Metric Summary Cards
            _buildMetricCards(
              totalSessions: 4,
              totalExercises: allExercises.length,
              completedCount: completedInSession,
              totalInSession: filteredProgressions.length,
              activeCount: activeCount,
              archivedCount: archivedCount,
            ),

            const SizedBox(height: 16),

            // 2. Athlete Banner
            _buildAthleteBanner(isHans, athleteColor),

            const SizedBox(height: 16),

            // 3. Session Day Filter Tabs
            _buildSessionFilterTabs(),

            const SizedBox(height: 16),

            // 4. Exercise Progression List
            _buildProgressionList(filteredProgressions),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards({
    required int totalSessions,
    required int totalExercises,
    required int completedCount,
    required int totalInSession,
    required int activeCount,
    required int archivedCount,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      children: [
        _buildMetricCard(
          title: 'TOTAL SESSIONS',
          value: '$totalSessions Sessions',
          subtitle: 'Per Training Week',
          icon: Icons.calendar_month_rounded,
          iconColor: AppColors.accentCyan,
        ),
        _buildMetricCard(
          title: 'TOTAL EXERCISES',
          value: '$totalExercises Movements',
          subtitle: 'Across 4 Routine Days',
          icon: Icons.fitness_center_rounded,
          iconColor: AppColors.primaryNeon,
        ),
        _buildMetricCard(
          title: 'WORKOUT PROGRESS',
          value: '✓ $completedCount / $totalInSession',
          subtitle: 'Completed in this session',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.primaryNeon,
        ),
        _buildMetricCard(
          title: 'EXERCISE STATUS',
          value: '$activeCount Active',
          subtitle: '$archivedCount Archived',
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.accentAmber,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteBanner(bool isHans, Color athleteColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: athleteColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: athleteColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(isHans ? Icons.person_rounded : Icons.favorite_rounded, color: athleteColor, size: 18),
          const SizedBox(width: 8),
          Text(
            'Progression Log for: ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          Text(
            isHans ? 'Hans Aufa (USR-001)' : 'Cute lil baby (USR-002)',
            style: TextStyle(color: athleteColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionFilterTabs() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.sessionDays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final session = AppConstants.sessionDays[index];
          final isSelected = session == _selectedSessionFilter;

          // Short label for tab
          String shortLabel = session;
          if (session.contains('Tuesday')) shortLabel = '🔥 Tuesday';
          if (session.contains('Thursday')) shortLabel = '⚡ Thursday';
          if (session.contains('Friday')) shortLabel = '🚀 Friday';
          if (session.contains('Saturday')) shortLabel = '🦵 Saturday';

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSessionFilter = session;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryNeon : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primaryNeon : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  shortLabel,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressionList(List<WeeklyProgression> list) {
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('No exercises found in this session.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              SizedBox(width: 24, child: Text('#', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 4, child: Text('Exercise', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Center(child: Text('W1', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Center(child: Text('W2', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Center(child: Text('W3', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
              Expanded(flex: 2, child: Center(child: Text('W4', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)))),
              SizedBox(width: 32, child: Center(child: Text('Trend', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List of Exercise Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final p = list[index];
            return _buildProgressionRow(p);
          },
        ),
      ],
    );
  }

  Widget _buildProgressionRow(WeeklyProgression p) {
    final hasLogged = p.week1Kg != null || p.week2Kg != null || p.week3Kg != null || p.week4Kg != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLogged ? AppColors.border : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // Sort order
          SizedBox(
            width: 24,
            child: Text(
              '${p.sortOrder}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),

          // Exercise info
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.exerciseName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${p.targetReps ?? '-'} • ${p.targetMuscle ?? ''}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // W1
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                p.week1Kg != null ? '${p.week1Kg}k' : '-',
                style: TextStyle(
                  color: p.week1Kg != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: p.week1Kg != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          // W2
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                p.week2Kg != null ? '${p.week2Kg}k' : '-',
                style: TextStyle(
                  color: p.week2Kg != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: p.week2Kg != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          // W3
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                p.week3Kg != null ? '${p.week3Kg}k' : '-',
                style: TextStyle(
                  color: p.week3Kg != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: p.week3Kg != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          // W4
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                p.week4Kg != null ? '${p.week4Kg}k' : '-',
                style: TextStyle(
                  color: p.week4Kg != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: p.week4Kg != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          // Weight Trend Indicator
          SizedBox(
            width: 32,
            child: Center(
              child: _buildTrendIcon(p.weightTrend),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_upward_rounded, color: AppColors.primaryNeon, size: 14),
        );
      case 'down':
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.accentRed.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_downward_rounded, color: AppColors.accentRed, size: 14),
        );
      case 'flat':
        return const Icon(Icons.trending_flat_rounded, color: AppColors.accentAmber, size: 16);
      default:
        return const Text('-', style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
  }
}

