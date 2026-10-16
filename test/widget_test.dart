import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grit_fitness_tracker/main.dart';

void main() {
  testWidgets('Grit Fitness App launches and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GritFitnessApp(),
      ),
    );

    // Verify main navigation loads
    expect(find.text('Grit Workout Form'), findsOneWidget);
    expect(find.text('Duo Form'), findsOneWidget);
    expect(find.text('4-Wk Routine'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
  });
}
