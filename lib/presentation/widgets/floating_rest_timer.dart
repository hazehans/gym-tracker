import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/workout_providers.dart';

class FloatingRestTimer extends ConsumerWidget {
  const FloatingRestTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isRunning && timerState.remainingSeconds == timerState.totalSeconds && !timerState.isFinished) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(restTimerProvider.notifier);
    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = timerState.totalSeconds > 0
        ? timerState.remainingSeconds / timerState.totalSeconds
        : 0.0;

    if (timerState.isFinished) {
      HapticFeedback.vibrate();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: timerState.isFinished
              ? AppColors.primaryNeon
              : AppColors.accentCyan.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (timerState.isFinished ? AppColors.primaryNeon : AppColors.accentCyan)
                .withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3.5,
                  backgroundColor: AppColors.surfaceHighlight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timerState.isFinished ? AppColors.primaryNeon : AppColors.accentCyan,
                  ),
                ),
                Icon(
                  timerState.isFinished
                      ? Icons.check_circle_rounded
                      : Icons.timer_outlined,
                  color: timerState.isFinished ? AppColors.primaryNeon : AppColors.accentCyan,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Time and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      timerState.isFinished ? 'REST COMPLETE!' : 'REST TIMER',
                      style: TextStyle(
                        color: timerState.isFinished
                            ? AppColors.primaryNeon
                            : AppColors.accentCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!timerState.isFinished)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${timerState.totalSeconds}s',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timerState.isFinished ? 'Ready for next set! 🔥' : timeStr,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Quick presets / Controls
          if (!timerState.isFinished) ...[
            IconButton(
              icon: Icon(
                timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
              onPressed: () {
                if (timerState.isRunning) {
                  notifier.pause();
                } else {
                  notifier.resume();
                }
              },
            ),
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_time_rounded, color: AppColors.textSecondary, size: 20),
              color: AppColors.surfaceHighlight,
              onSelected: (seconds) => notifier.start(durationSeconds: seconds),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 60, child: Text('60s Rest')),
                const PopupMenuItem(value: 90, child: Text('90s Rest (Default)')),
                const PopupMenuItem(value: 120, child: Text('120s Rest')),
              ],
            ),
          ],

          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
            onPressed: () => notifier.dismiss(),
          ),
        ],
      ),
    );
  }
}

