class ExerciseMaster {
  final String exerciseId;
  final String sessionDay;
  final int sortOrder;
  final String exerciseName;
  final String? targetMuscle;
  final String? targetReps;
  final String? equipment;
  final String status;

  const ExerciseMaster({
    required this.exerciseId,
    required this.sessionDay,
    required this.sortOrder,
    required this.exerciseName,
    this.targetMuscle,
    this.targetReps,
    this.equipment,
    this.status = 'Active',
  });

  bool get isActive => status == 'Active';

  factory ExerciseMaster.fromJson(Map<String, dynamic> json) {
    return ExerciseMaster(
      exerciseId: json['exercise_id'] as String,
      sessionDay: json['session_day'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      exerciseName: json['exercise_name'] as String,
      targetMuscle: json['target_muscle'] as String?,
      targetReps: json['target_reps'] as String?,
      equipment: json['equipment'] as String?,
      status: json['status'] as String? ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'session_day': sessionDay,
      'sort_order': sortOrder,
      'exercise_name': exerciseName,
      'target_muscle': targetMuscle,
      'target_reps': targetReps,
      'equipment': equipment,
      'status': status,
    };
  }

  ExerciseMaster copyWith({
    String? exerciseId,
    String? sessionDay,
    int? sortOrder,
    String? exerciseName,
    String? targetMuscle,
    String? targetReps,
    String? equipment,
    String? status,
  }) {
    return ExerciseMaster(
      exerciseId: exerciseId ?? this.exerciseId,
      sessionDay: sessionDay ?? this.sessionDay,
      sortOrder: sortOrder ?? this.sortOrder,
      exerciseName: exerciseName ?? this.exerciseName,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      targetReps: targetReps ?? this.targetReps,
      equipment: equipment ?? this.equipment,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseMaster &&
          runtimeType == other.runtimeType &&
          exerciseId == other.exerciseId;

  @override
  int get hashCode => exerciseId.hashCode;
}

