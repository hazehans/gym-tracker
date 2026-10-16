class AppConstants {
  // App Identity
  static const String appName = 'Grit Fitness';
  static const String appSubtitle = 'Duo Workout & Progression Tracker';

  // Users
  static const String userHansId = 'USR-001';
  static const String userHansName = 'Hans';
  static const String userHansProfile = 'Hans Aufa (Primary Athlete)';

  static const String userBabyId = 'USR-002';
  static const String userBabyName = 'Cute lil baby';
  static const String userBabyProfile = 'Partner Athlete (Consolidated Log)';

  // Standard Workout Sessions
  static const String sessionTuesday = 'Tuesday • Heavy Full Body';
  static const String sessionThursday = 'Thursday • Push Day';
  static const String sessionFriday = 'Friday • Pull Day';
  static const String sessionSaturday = 'Saturday • Leg Day';

  static const List<String> sessionDays = [
    sessionTuesday,
    sessionThursday,
    sessionFriday,
    sessionSaturday,
  ];

  // Progressive Overload
  static const double progressiveOverloadIncrement = 2.5;

  // Auto-Rest Timer Durations (seconds)
  static const int defaultRestSeconds = 90;
  static const List<int> restTimerOptions = [60, 90, 120];
}

