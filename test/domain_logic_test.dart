import 'package:flutter_test/flutter_test.dart';
import 'package:grit_fitness_tracker/data/models/workout_log.dart';
import 'package:grit_fitness_tracker/data/repositories/workout_repository.dart';

void main() {
  group('Epley 1RM Formula & Volume Tests', () {
    test('Calculates 1RM matching spreadsheet formula exactly', () {
      // 40 kg * (1 + 10 / 30) = 53.3
      final est1rm = WorkoutLog.calculateEst1rm(40.0, 10);
      expect(est1rm, 53.3);

      // 45 kg * (1 + 8 / 30) = 57.0
      expect(WorkoutLog.calculateEst1rm(45.0, 8), 57.0);

      // 15 kg * (1 + 15 / 30) = 22.5
      expect(WorkoutLog.calculateEst1rm(15.0, 15), 22.5);

      // 2.5 kg * (1 + 12 / 30) = 3.5
      expect(WorkoutLog.calculateEst1rm(2.5, 12), 3.5);
    });

    test('Calculates volume matching spreadsheet', () {
      expect(WorkoutLog.calculateVolume(40.0, 10), 400.0);
      // Corrected LOG-036: 2.5 kg * 12 = 30.0 (not 37.5)
      expect(WorkoutLog.calculateVolume(2.5, 12), 30.0);
    });
  });

  group('Workout Repository In-Memory & Seeding Tests', () {
    final repo = WorkoutRepository();

    test('Initial data contains 2 users', () {
      final users = repo.getUsers();
      expect(users.length, 2);
      expect(users.any((u) => u.userId == 'USR-001' && u.name == 'Hans'), isTrue);
      expect(users.any((u) => u.userId == 'USR-002' && u.name == 'Cute lil baby'), isTrue);
    });

    test('Initial data contains 33 synchronized exercises', () {
      final exercises = repo.getExercises(activeOnly: false);
      expect(exercises.length, 33);

      // Verify Plank
      final plank = repo.getExerciseById('EXE-010');
      expect(plank?.exerciseName, 'Plank');
      expect(plank?.targetMuscle, 'Abs / Core');

      // Verify Straight Arm Pulldown
      final pulldown = repo.getExerciseById('EXE-026');
      expect(pulldown?.exerciseName, 'Straight Arm Pulldown');
      expect(pulldown?.equipment, 'Cable Tower');

      // Verify Barbbell Squat
      final squat = repo.getExerciseById('EXE-033');
      expect(squat?.exerciseName, 'Barbbell Squat');
      expect(squat?.targetReps, '4 x 15');
    });

    test('Initial data contains 113 reconciled logs', () {
      final logs = repo.getWorkoutLogs();
      expect(logs.length, 113);
    });

    test('Unique sessions count calculates correctly (not 1)', () {
      final count = repo.getUniqueSessionsCount();
      expect(count, greaterThan(1));
    });
  });
}

