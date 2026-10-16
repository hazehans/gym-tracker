import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/app_user.dart';
import '../models/exercise_master.dart';
import '../models/workout_log.dart';
import '../models/weekly_progression.dart';
import 'initial_data.dart';

class WorkoutRepository {
  // In-memory fallback / cache for fast UI updates & offline gym mode
  final List<AppUser> _users = List.from(InitialData.users);
  final List<ExerciseMaster> _exercises = List.from(InitialData.exercises);
  final List<WorkoutLog> _logs = InitialData.getWorkoutLogs();

  // Stream controllers for realtime reactivity
  final _logsStreamController = StreamController<List<WorkoutLog>>.broadcast();
  final _exercisesStreamController = StreamController<List<ExerciseMaster>>.broadcast();

  WorkoutRepository() {
    _initSupabaseRealtime();
    _broadcastCurrent();
  }

  void _broadcastCurrent() {
    _logsStreamController.add(List.unmodifiable(_logs));
    _exercisesStreamController.add(List.unmodifiable(_exercises));
  }

  void _initSupabaseRealtime() {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      // Subscribe to Realtime changes on workout_logs
      client
          .channel('public:workout_logs')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'workout_logs',
            callback: (payload) {
              debugPrint('⚡ Supabase Realtime Log Change: ${payload.eventType}');
              fetchWorkoutLogsFromRemote();
            },
          )
          .subscribe();

      // Subscribe to Realtime changes on exercises_master
      client
          .channel('public:exercises_master')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'exercises_master',
            callback: (payload) {
              debugPrint('⚡ Supabase Realtime Exercise Change: ${payload.eventType}');
              fetchExercisesFromRemote();
            },
          )
          .subscribe();

      // Initial fetch from remote
      fetchWorkoutLogsFromRemote();
      fetchExercisesFromRemote();
    } catch (e) {
      debugPrint('Realtime subscription note: $e');
    }
  }

  Future<void> fetchWorkoutLogsFromRemote() async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      final response = await client
          .from('workout_logs')
          .select()
          .order('workout_date', ascending: false)
          .order('created_at', ascending: false);

      final remoteLogs = (response as List)
          .map((item) => WorkoutLog.fromJson(item as Map<String, dynamic>))
          .toList();

      _logs.clear();
      _logs.addAll(remoteLogs);
      _broadcastCurrent();
    } catch (e) {
      debugPrint('Fetch logs error: $e');
    }
  }

  Future<void> fetchExercisesFromRemote() async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      final response = await client
          .from('exercises_master')
          .select()
          .order('sort_order', ascending: true);

      final remoteExercises = (response as List)
          .map((item) => ExerciseMaster.fromJson(item as Map<String, dynamic>))
          .toList();

      _exercises.clear();
      _exercises.addAll(remoteExercises);
      _broadcastCurrent();
    } catch (e) {
      debugPrint('Fetch exercises error: $e');
    }
  }

  // --- Users ---
  List<AppUser> getUsers() => List.unmodifiable(_users);

  AppUser? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u.userId == userId);
    } catch (_) {
      return null;
    }
  }

  // --- Exercises ---
  Stream<List<ExerciseMaster>> watchExercises() => _exercisesStreamController.stream;

  List<ExerciseMaster> getExercises({String? sessionDay, bool activeOnly = true}) {
    return _exercises.where((e) {
      if (sessionDay != null && e.sessionDay != sessionDay) return false;
      if (activeOnly && e.status != 'Active') return false;
      return true;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  ExerciseMaster? getExerciseById(String exerciseId) {
    try {
      return _exercises.firstWhere((e) => e.exerciseId == exerciseId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addExercise(ExerciseMaster exercise) async {
    _exercises.add(exercise);
    _broadcastCurrent();

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('exercises_master').insert(exercise.toJson());
      } catch (e) {
        debugPrint('Supabase insert exercise error: $e');
      }
    }
  }

  Future<void> updateExercise(ExerciseMaster exercise) async {
    final index = _exercises.indexWhere((e) => e.exerciseId == exercise.exerciseId);
    if (index != -1) {
      _exercises[index] = exercise;
      _broadcastCurrent();
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client
            .from('exercises_master')
            .update(exercise.toJson())
            .eq('exercise_id', exercise.exerciseId);
      } catch (e) {
        debugPrint('Supabase update exercise error: $e');
      }
    }
  }

  Future<void> toggleExerciseStatus(String exerciseId, bool isArchived) async {
    final status = isArchived ? 'Archived' : 'Active';
    final index = _exercises.indexWhere((e) => e.exerciseId == exerciseId);
    if (index != -1) {
      _exercises[index] = _exercises[index].copyWith(status: status);
      _broadcastCurrent();
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client
            .from('exercises_master')
            .update({'status': status})
            .eq('exercise_id', exerciseId);
      } catch (e) {
        debugPrint('Supabase toggle status error: $e');
      }
    }
  }

  // --- Workout Logs ---
  Stream<List<WorkoutLog>> watchWorkoutLogs() => _logsStreamController.stream;

  List<WorkoutLog> getWorkoutLogs({
    String? userId,
    String? sessionDay,
    String? exerciseId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _logs.where((log) {
      if (userId != null && log.userId != userId) return false;
      if (exerciseId != null && log.exerciseId != exerciseId) return false;

      if (sessionDay != null) {
        final ex = getExerciseById(log.exerciseId);
        if (ex?.sessionDay != sessionDay) return false;
      }

      final logDate = DateTime.tryParse(log.workoutDate);
      if (logDate != null) {
        if (fromDate != null && logDate.isBefore(fromDate)) return false;
        if (toDate != null && logDate.isAfter(toDate.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final dComp = b.workoutDate.compareTo(a.workoutDate);
        if (dComp != 0) return dComp;
        return a.setNumber.compareTo(b.setNumber);
      });
  }

  Future<void> saveWorkoutLogs(List<WorkoutLog> newLogs) async {
    _logs.addAll(newLogs);
    _broadcastCurrent();

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final payloads = newLogs.map((l) => l.toJson()).toList();
        await client.from('workout_logs').insert(payloads);
      } catch (e) {
        debugPrint('Supabase save logs error: $e');
      }
    }
  }

  Future<void> updateWorkoutLog(WorkoutLog log) async {
    final index = _logs.indexWhere((l) => l.logId == log.logId);
    if (index != -1) {
      _logs[index] = log;
      _broadcastCurrent();
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client
            .from('workout_logs')
            .update(log.toJson())
            .eq('log_id', log.logId);
      } catch (e) {
        debugPrint('Supabase update log error: $e');
      }
    }
  }

  Future<void> deleteWorkoutLog(String logId) async {
    _logs.removeWhere((l) => l.logId == logId);
    _broadcastCurrent();

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.from('workout_logs').delete().eq('log_id', logId);
      } catch (e) {
        debugPrint('Supabase delete log error: $e');
      }
    }
  }

  // --- Auto-Fill & Smart Progressive Overload ---

  /// Finds the last recorded weight for the athlete in this exercise
  double? getLastWeightForExercise(String userId, String exerciseId) {
    final exLogs = _logs
        .where((l) => l.userId == userId && l.exerciseId == exerciseId && l.weightKg > 0)
        .toList()
      ..sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

    if (exLogs.isEmpty) return null;
    final latestDate = exLogs.first.workoutDate;
    final latestSessionLogs = exLogs.where((l) => l.workoutDate == latestDate).toList();

    // Return the max weight used in that latest session
    return latestSessionLogs.map((l) => l.weightKg).reduce((a, b) => a > b ? a : b);
  }

  /// Checks if progressive overload (+2.5 kg) should be suggested
  /// Condition: In the athlete's most recent session for this exercise, did they complete
  /// all sets with target repetitions?
  bool checkProgressiveOverload(String userId, String exerciseId, String? targetReps) {
    if (targetReps == null || targetReps == '-') return false;

    // Parse target reps (e.g., '4 x 12' -> 12 reps; '3 x 15' -> 15 reps; '1 min' -> false)
    final match = RegExp(r'(\d+)\s*x\s*(\d+)').firstMatch(targetReps.toLowerCase());
    if (match == null) return false;
    final targetRepCount = int.tryParse(match.group(2) ?? '');
    if (targetRepCount == null) return false;

    final exLogs = _logs
        .where((l) => l.userId == userId && l.exerciseId == exerciseId && l.weightKg > 0)
        .toList()
      ..sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

    if (exLogs.isEmpty) return false;
    final latestDate = exLogs.first.workoutDate;
    final latestSessionLogs = exLogs.where((l) => l.workoutDate == latestDate).toList();

    if (latestSessionLogs.isEmpty) return false;

    // Check if every set in that session reached or exceeded target rep count
    return latestSessionLogs.every((l) => l.reps >= targetRepCount);
  }

  // --- 4-Week Progression Tracker Logic ---
  List<WeeklyProgression> calculateWeeklyProgression(String userId) {
    final userLogs = _logs.where((l) => l.userId == userId && l.weightKg > 0).toList();
    final user = getUserById(userId);
    final userName = user?.name ?? 'Athlete';

    // Find the min date across all logs to establish week 1
    DateTime minDate = DateTime(2026, 10, 6);
    if (_logs.isNotEmpty) {
      final parsedDates = _logs
          .map((l) => DateTime.tryParse(l.workoutDate))
          .whereType<DateTime>()
          .toList();
      if (parsedDates.isNotEmpty) {
        parsedDates.sort();
        minDate = parsedDates.first;
      }
    }

    // Group logs by exerciseId and weekNumber (1..4)
    final Map<String, Map<int, double>> exerciseWeekWeights = {};

    for (final l in userLogs) {
      final logDate = DateTime.tryParse(l.workoutDate);
      if (logDate == null) continue;

      final diffDays = logDate.difference(minDate).inDays;
      final weekNum = (diffDays ~/ 7) + 1;
      if (weekNum < 1 || weekNum > 4) continue;

      exerciseWeekWeights.putIfAbsent(l.exerciseId, () => {});
      final currentMax = exerciseWeekWeights[l.exerciseId]![weekNum] ?? 0.0;
      if (l.weightKg > currentMax) {
        exerciseWeekWeights[l.exerciseId]![weekNum] = l.weightKg;
      }
    }

    final List<WeeklyProgression> progressions = [];

    for (final ex in _exercises) {
      final weeksMap = exerciseWeekWeights[ex.exerciseId] ?? {};
      final w1 = weeksMap[1];
      final w2 = weeksMap[2];
      final w3 = weeksMap[3];
      final w4 = weeksMap[4];

      String trend = 'none';
      if (w2 != null && w1 != null) {
        if (w2 > w1) {
          trend = 'up';
        } else if (w2 < w1) {
          trend = 'down';
        } else {
          trend = 'flat';
        }
      } else if (w1 != null) {
        trend = 'flat';
      }

      progressions.add(WeeklyProgression(
        exerciseId: ex.exerciseId,
        exerciseName: ex.exerciseName,
        sessionDay: ex.sessionDay,
        sortOrder: ex.sortOrder,
        targetMuscle: ex.targetMuscle,
        targetReps: ex.targetReps,
        equipment: ex.equipment,
        status: ex.status,
        userId: userId,
        userName: userName,
        week1Kg: w1,
        week2Kg: w2,
        week3Kg: w3,
        week4Kg: w4,
        weightTrend: trend,
      ));
    }

    return progressions;
  }

  // --- Statistics for Module 3 (Daily Workout Log & History) ---
  int getUniqueSessionsCount({String? userId}) {
    final logsToCount = userId != null ? _logs.where((l) => l.userId == userId) : _logs;
    final Set<String> sessionKeys = {};

    for (final l in logsToCount) {
      final ex = getExerciseById(l.exerciseId);
      final session = ex?.sessionDay ?? 'Unknown';
      sessionKeys.add('${l.workoutDate}__$session');
    }

    return sessionKeys.length;
  }

  double getTotalVolumeKg({String? userId}) {
    final logsToSum = userId != null ? _logs.where((l) => l.userId == userId) : _logs;
    return logsToSum.fold(0.0, (sum, l) => sum + l.volumeKg);
  }

  String getLastWorkoutDate({String? userId}) {
    final logs = userId != null ? _logs.where((l) => l.userId == userId).toList() : _logs;
    if (logs.isEmpty) return '-';
    final dates = logs.map((l) => l.workoutDate).toList()..sort();
    return dates.last;
  }
}
