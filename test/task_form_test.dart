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

  testWidgets('FAB opens TaskFormScreen for new task', (tester) async {
    final provider = TaskProvider();
    await provider.load();

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('New Task'), findsNothing);

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();

    expect(find.text('New Task'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);
  });

  testWidgets('Adding a new task updates provider list', (tester) async {
    final provider = TaskProvider();
    await provider.load();

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Buy Milk');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Buy Milk'), findsOneWidget);
    expect(provider.totalCount, 1);
  });

  testWidgets('Tapping a task opens form in edit mode and updates task', (tester) async {
    final provider = TaskProvider();
    await provider.load();
    provider.add(Task(
      id: 'task-1',
      title: 'Original Title',
      notes: '',
      priority: Priority.medium,
      category: 'Work',
      createdAt: DateTime.now(),
    ));

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Original Title'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Updated Title');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Title'), findsOneWidget);
    expect(find.text('Original Title'), findsNothing);
  });

  testWidgets('Swipe to delete task shows snackbar with undo', (tester) async {
    final provider = TaskProvider();
    await provider.load();
    provider.add(Task(
      id: 'task-1',
      title: 'Task to Delete',
      notes: '',
      priority: Priority.low,
      category: 'Personal',
      createdAt: DateTime.now(),
    ));

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('Task to Delete'), findsOneWidget);

    // Swipe left
    await tester.drag(find.text('Task to Delete'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Task to Delete'), findsNothing);
    expect(find.text('Deleted "Task to Delete"'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Task to Delete'), findsOneWidget);
  });
}
