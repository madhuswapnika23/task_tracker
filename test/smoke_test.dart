import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker/providers/task_provider.dart';
import 'package:task_tracker/screens/home_screen.dart';

Widget buildApp(TaskProvider provider) {
  return ChangeNotifierProvider<TaskProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'tasks_v1': '[]'});
  });

  testWidgets('App boots and shows "No tasks yet" empty state', (tester) async {
    final provider = TaskProvider();
    await provider.load();

    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    // Verify the empty state headline is shown
    expect(find.text('No tasks yet'), findsOneWidget);

    // Verify the helper hint is shown
    expect(find.text('Tap "New task" to add your first task.'), findsOneWidget);

    // Verify FAB is visible
    expect(find.text('New task'), findsOneWidget);
  });

  testWidgets('Adds a task through the form and it appears in the list',
      (tester) async {
    final provider = TaskProvider();
    await provider.load();

    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    // Open new-task form
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();

    // Verify we are on the form screen
    expect(find.text('New Task'), findsOneWidget);

    // Enter a task title
    await tester.enterText(
        find.byType(TextFormField).first, 'Write Sprint 7 tests');
    await tester.pumpAndSettle();

    // Submit the form
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    // Task should now appear in the list
    expect(find.text('Write Sprint 7 tests'), findsOneWidget);

    // Empty state should be gone
    expect(find.text('No tasks yet'), findsNothing);

    // Provider state is consistent
    expect(provider.totalCount, 1);
    expect(provider.visibleTasks.first.title, 'Write Sprint 7 tests');
  });
}
