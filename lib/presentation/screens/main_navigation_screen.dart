import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/floating_rest_timer.dart';
import 'duo_workout_form_screen.dart';
import 'routine_progression_screen.dart';
import 'workout_log_history_screen.dart';
import 'exercise_manager_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DuoWorkoutFormScreen(),
    RoutineProgressionScreen(),
    WorkoutLogHistoryScreen(),
    ExerciseManagerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Screen content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating Auto-Rest Timer overlay
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingRestTimer(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: 'Duo Form',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: '4-Wk Routine',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_suggest_rounded),
              label: 'Exercises',
            ),
          ],
        ),
      ),
    );
  }
}

