class WorkoutLog {
  final String logId;
  final String workoutDate; // 'YYYY-MM-DD'
  final String userId;
  final String exerciseId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final double volumeKg;
  final double est1rm;
  final String? notes;
  final DateTime? createdAt;

  const WorkoutLog({
    required this.logId,
    required this.workoutDate,
    required this.userId,
    required this.exerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.volumeKg,
    required this.est1rm,
    this.notes,
    this.createdAt,
  });

  // Calculate live Epley formula: weight * (1 + reps / 30)
  static double calculateEst1rm(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0.0;
    final val = weight * (1.0 + reps / 30.0);
    return double.parse(val.toStringAsFixed(1));
  }

  // Calculate volume: weight * reps
  static double calculateVolume(double weight, int reps) {
    return double.parse((weight * reps).toStringAsFixed(2));
  }

  factory WorkoutLog.create({
    required String logId,
    required String workoutDate,
    required String userId,
    required String exerciseId,
    required int setNumber,
    required double weightKg,
    required int reps,
    String? notes,
  }) {
    return WorkoutLog(
      logId: logId,
      workoutDate: workoutDate,
      userId: userId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      weightKg: weightKg,
      reps: reps,
      volumeKg: calculateVolume(weightKg, reps),
      est1rm: calculateEst1rm(weightKg, reps),
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    final wt = (json['weight_kg'] as num?)?.toDouble() ?? 0.0;
    final r = (json['reps'] as num?)?.toInt() ?? 0;
    final vol = (json['volume_kg'] as num?)?.toDouble() ?? calculateVolume(wt, r);
    final oneRm = (json['est_1rm'] as num?)?.toDouble() ?? calculateEst1rm(wt, r);

    return WorkoutLog(
      logId: json['log_id'] as String,
      workoutDate: json['workout_date'] is String
          ? (json['workout_date'] as String).substring(0, 10)
          : json['workout_date'].toString(),
      userId: json['user_id'] as String,
      exerciseId: json['exercise_id'] as String,
      setNumber: (json['set_number'] as num).toInt(),
      weightKg: wt,
      reps: r,
      volumeKg: vol,
      est1rm: oneRm,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'workout_date': workoutDate,
      'user_id': userId,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'weight_kg': weightKg,
      'reps': reps,
      'notes': notes,
    };
  }

  WorkoutLog copyWith({
    String? logId,
    String? workoutDate,
    String? userId,
    String? exerciseId,
    int? setNumber,
    double? weightKg,
    int? reps,
    double? volumeKg,
    double? est1rm,
    String? notes,
    DateTime? createdAt,
  }) {
    final newWeight = weightKg ?? this.weightKg;
    final newReps = reps ?? this.reps;
    return WorkoutLog(
      logId: logId ?? this.logId,
      workoutDate: workoutDate ?? this.workoutDate,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: newWeight,
      reps: newReps,
      volumeKg: volumeKg ?? calculateVolume(newWeight, newReps),
      est1rm: est1rm ?? calculateEst1rm(newWeight, newReps),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

