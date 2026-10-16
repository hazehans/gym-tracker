class WeeklyProgression {
  final String exerciseId;
  final String exerciseName;
  final String sessionDay;
  final int sortOrder;
  final String? targetMuscle;
  final String? targetReps;
  final String? equipment;
  final String status;
  final String userId;
  final String userName;
  final double? week1Kg;
  final double? week2Kg;
  final double? week3Kg;
  final double? week4Kg;
  final String weightTrend; // 'up', 'down', 'flat', 'none'

  const WeeklyProgression({
    required this.exerciseId,
    required this.exerciseName,
    required this.sessionDay,
    required this.sortOrder,
    this.targetMuscle,
    this.targetReps,
    this.equipment,
    required this.status,
    required this.userId,
    required this.userName,
    this.week1Kg,
    this.week2Kg,
    this.week3Kg,
    this.week4Kg,
    required this.weightTrend,
  });

  factory WeeklyProgression.fromJson(Map<String, dynamic> json) {
    return WeeklyProgression(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String,
      sessionDay: json['session_day'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      targetMuscle: json['target_muscle'] as String?,
      targetReps: json['target_reps'] as String?,
      equipment: json['equipment'] as String?,
      status: json['status'] as String? ?? 'Active',
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      week1Kg: (json['week_1_kg'] as num?)?.toDouble(),
      week2Kg: (json['week_2_kg'] as num?)?.toDouble(),
      week3Kg: (json['week_3_kg'] as num?)?.toDouble(),
      week4Kg: (json['week_4_kg'] as num?)?.toDouble(),
      weightTrend: json['weight_trend'] as String? ?? 'none',
    );
  }
}

