import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/providers/task_provider.dart';
import 'package:task_tracker/screens/home_screen.dart';

Widget buildTestApp(TaskProvider provider) {
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

  testWidgets('Search input filters task list in UI', (tester) async {
    final provider = TaskProvider();
    await provider.load();
    provider.add(Task(id: '1', title: 'Buy Groceries', notes: '', priority: Priority.medium, category: 'Personal', createdAt: DateTime.now()));
    provider.add(Task(id: '2', title: 'Read Book', notes: '', priority: Priority.medium, category: 'Study', createdAt: DateTime.now()));

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Buy Groceries'), findsOneWidget);
    expect(find.text('Read Book'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Book');
    await tester.pumpAndSettle();

    expect(find.text('Buy Groceries'), findsNothing);
    expect(find.text('Read Book'), findsOneWidget);
  });

  testWidgets('Category chips filter tasks and tapping again clears filter', (tester) async {
    final provider = TaskProvider();
    await provider.load();
    provider.add(Task(id: '1', title: 'Work Task', notes: '', priority: Priority.medium, category: 'Work', createdAt: DateTime.now()));
    provider.add(Task(id: '2', title: 'Study Task', notes: '', priority: Priority.medium, category: 'Study', createdAt: DateTime.now()));

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    // Tap Study chip
    await tester.tap(find.widgetWithText(ChoiceChip, 'Study'));
    await tester.pumpAndSettle();

    expect(find.text('Work Task'), findsNothing);
    expect(find.text('Study Task'), findsOneWidget);

    // Tap Study chip again to toggle off
    await tester.tap(find.widgetWithText(ChoiceChip, 'Study'));
    await tester.pumpAndSettle();

    expect(find.text('Work Task'), findsOneWidget);
    expect(find.text('Study Task'), findsOneWidget);
  });

  testWidgets('Status filter toggles between All, Active, and Done', (tester) async {
    final provider = TaskProvider();
    await provider.load();
    provider.add(Task(id: '1', title: 'Active Task', notes: '', priority: Priority.medium, category: 'Work', createdAt: DateTime.now()));
    provider.add(Task(id: '2', title: 'Done Task', notes: '', priority: Priority.medium, category: 'Work', isDone: true, completedAt: DateTime.now(), createdAt: DateTime.now()));

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    // Tap Active segment
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    expect(find.text('Active Task'), findsOneWidget);
    expect(find.text('Done Task'), findsNothing);

    // Tap Done segment
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Active Task'), findsNothing);
    expect(find.text('Done Task'), findsOneWidget);
  });
}
