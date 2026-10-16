import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/constants/app_constants.dart';
import '../data/models/app_user.dart';
import '../data/models/exercise_master.dart';
import '../data/models/workout_log.dart';
import '../data/models/weekly_progression.dart';
import '../data/repositories/workout_repository.dart';

// 1. Repository Singleton Provider
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

// 2. Users Provider
final usersProvider = Provider<List<AppUser>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getUsers();
});

// 3. Active Athlete ID Provider ('USR-001' Hans or 'USR-002' Cute lil baby)
final activeUserIdProvider = StateProvider<String>((ref) {
  return AppConstants.userHansId;
});

// 4. Active Athlete Provider
final activeUserProvider = Provider<AppUser>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  final activeId = ref.watch(activeUserIdProvider);
  return repo.getUserById(activeId) ?? repo.getUsers().first;
});

// 5. Partner Athlete Provider
final partnerUserProvider = Provider<AppUser>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  final activeId = ref.watch(activeUserIdProvider);
  final partnerId = activeId == AppConstants.userHansId
      ? AppConstants.userBabyId
      : AppConstants.userHansId;
  return repo.getUserById(partnerId) ?? repo.getUsers().last;
});

// 6. Duo Mode Toggle (Single athlete vs Tandem live view)
final isDuoModeActiveProvider = StateProvider<bool>((ref) {
  return false;
});

// 7. Auto Session Day Detection Provider
String detectCurrentSessionDay() {
  final now = DateTime.now();
  switch (now.weekday) {
    case DateTime.tuesday:
      return AppConstants.sessionTuesday;
    case DateTime.thursday:
      return AppConstants.sessionThursday;
    case DateTime.friday:
      return AppConstants.sessionFriday;
    case DateTime.saturday:
      return AppConstants.sessionSaturday;
    default:
      return AppConstants.sessionTuesday;
  }
}

final selectedSessionDayProvider = StateProvider<String>((ref) {
  return detectCurrentSessionDay();
});

// 8. Selected Workout Date Provider
final selectedWorkoutDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// 9. Reactive Streams for Exercises and Logs
final exercisesStreamProvider = StreamProvider<List<ExerciseMaster>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchExercises();
});

final workoutLogsStreamProvider = StreamProvider<List<WorkoutLog>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchWorkoutLogs();
});

// 10. Filtered Workout Logs for History Screen
final logFilterAthleteProvider = StateProvider<String?>((ref) => null);
final logFilterSessionProvider = StateProvider<String?>((ref) => null);
final logFilterFromDateProvider = StateProvider<DateTime?>((ref) => null);
final logFilterToDateProvider = StateProvider<DateTime?>((ref) => null);

// 11. Rest Timer State & Controller
class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isFinished;

  const RestTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    this.isFinished = false,
  });

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isFinished,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier()
      : super(const RestTimerState(
          remainingSeconds: AppConstants.defaultRestSeconds,
          totalSeconds: AppConstants.defaultRestSeconds,
          isRunning: false,
        ));

  void start({int? durationSeconds}) {
    final seconds = durationSeconds ?? state.totalSeconds;
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: true,
      isFinished: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(
          remainingSeconds: 0,
          isRunning: false,
          isFinished: true,
        );
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    if (state.remainingSeconds <= 0) return;
    start(durationSeconds: state.remainingSeconds);
  }

  void reset({int? durationSeconds}) {
    _timer?.cancel();
    final seconds = durationSeconds ?? state.totalSeconds;
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: false,
      isFinished: false,
    );
  }

  void dismiss() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isFinished: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

// 12. Weekly Progression Provider
final weeklyProgressionProvider =
    FutureProvider.family<List<WeeklyProgression>, String>((ref, userId) async {
  final repo = ref.watch(workoutRepositoryProvider);
  // Watch logs so progression re-computes on log change
  ref.watch(workoutLogsStreamProvider);
  return repo.calculateWeeklyProgression(userId);
});
