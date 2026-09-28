// Unit tests for TaskProvider — no Flutter widgets needed, so we use
// flutter_test purely for the test runner. SharedPreferences is mocked
// via setMockInitialValues so no platform channel is required.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/providers/task_provider.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

Task makeTask({
  required String id,
  required String title,
  Priority priority = Priority.medium,
  DateTime? dueDate,
  bool isDone = false,
  DateTime? completedAt,
  String category = 'Work',
  String notes = '',
}) {
  return Task(
    id: id,
    title: title,
    notes: notes,
    priority: priority,
    category: category,
    dueDate: dueDate,
    isDone: isDone,
    createdAt: DateTime(2026, 1, 1),
    completedAt: completedAt,
  );
}

Future<TaskProvider> buildProvider(List<Task> tasks) async {
  SharedPreferences.setMockInitialValues({'tasks_v1': '[]'});
  final p = TaskProvider();
  await p.load(); // starts empty
  for (final t in tasks) {
    p.add(t);
  }
  return p;
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('toggle()', () {
    test('marks task as done and sets completedAt', () async {
      final p = await buildProvider([makeTask(id: '1', title: 'T1')]);

      p.toggle('1');
      final task = p.visibleTasks.first;

      expect(task.isDone, isTrue);
      expect(task.completedAt, isNotNull);
      expect(
        task.completedAt!.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('unmarks task as done and clears completedAt', () async {
      final p = await buildProvider([
        makeTask(
          id: '1',
          title: 'T1',
          isDone: true,
          completedAt: DateTime(2026, 9, 1),
        ),
      ]);

      p.toggle('1');
      final task = p.visibleTasks.first;

      expect(task.isDone, isFalse);
      expect(task.completedAt, isNull);
    });

    test('toggle twice returns to original state', () async {
      final p = await buildProvider([makeTask(id: '1', title: 'T1')]);

      p.toggle('1');
      p.toggle('1');
      final task = p.visibleTasks.first;

      expect(task.isDone, isFalse);
      expect(task.completedAt, isNull);
    });
  });

  group('visibleTasks sorting — dueDate', () {
    test('tasks with no due date go last', () async {
      final soon = DateTime(2026, 10, 1);
      final later = DateTime(2026, 12, 31);

      final p = await buildProvider([
        makeTask(id: '3', title: 'No due', dueDate: null),
        makeTask(id: '1', title: 'Soon', dueDate: soon),
        makeTask(id: '2', title: 'Later', dueDate: later),
      ]);

      p.setSort(TaskSort.dueDate);
      final ids = p.visibleTasks.map((t) => t.id).toList();

      expect(ids, ['1', '2', '3']);
    });

    test('done tasks always sink below active tasks', () async {
      final soon = DateTime(2026, 10, 1);

      final p = await buildProvider([
        makeTask(id: 'done', title: 'Done', dueDate: soon, isDone: true, completedAt: DateTime.now()),
        makeTask(id: 'active', title: 'Active', dueDate: null),
      ]);

      p.setSort(TaskSort.dueDate);
      final ids = p.visibleTasks.map((t) => t.id).toList();

      expect(ids.first, 'active');
      expect(ids.last, 'done');
    });
  });

  group('visibleTasks sorting — priority', () {
    test('sorts high > medium > low', () async {
      final p = await buildProvider([
        makeTask(id: 'lo', title: 'Low', priority: Priority.low),
        makeTask(id: 'hi', title: 'High', priority: Priority.high),
        makeTask(id: 'me', title: 'Med', priority: Priority.medium),
      ]);

      p.setSort(TaskSort.priority);
      final ids = p.visibleTasks.map((t) => t.id).toList();

      expect(ids, ['hi', 'me', 'lo']);
    });
  });

  group('visibleTasks sorting — newest', () {
    test('most recently created task comes first', () async {
      final p = TaskProvider();
      SharedPreferences.setMockInitialValues({'tasks_v1': '[]'});
      await p.load();

      // Add tasks with explicit createdAt via makeTask's fixed date — we
      // override by adding in order and checking the reversed result with
      // tasks having different IDs used as a proxy.
      final t1 = Task(
        id: '1', title: 'Old', notes: '', priority: Priority.medium,
        category: 'Work', createdAt: DateTime(2026, 1, 1),
      );
      final t2 = Task(
        id: '2', title: 'New', notes: '', priority: Priority.medium,
        category: 'Work', createdAt: DateTime(2026, 9, 1),
      );
      p.add(t1);
      p.add(t2);

      p.setSort(TaskSort.newest);
      final ids = p.visibleTasks.map((t) => t.id).toList();

      expect(ids.first, '2'); // newer createdAt comes first
      expect(ids.last, '1');
    });
  });

  group('visibleTasks filtering', () {
    test('filter active hides done tasks', () async {
      final p = await buildProvider([
        makeTask(id: '1', title: 'Active'),
        makeTask(id: '2', title: 'Done', isDone: true, completedAt: DateTime.now()),
      ]);

      p.setFilter(TaskFilter.active);

      expect(p.visibleTasks.length, 1);
      expect(p.visibleTasks.first.id, '1');
    });

    test('filter done shows only done tasks', () async {
      final p = await buildProvider([
        makeTask(id: '1', title: 'Active'),
        makeTask(id: '2', title: 'Done', isDone: true, completedAt: DateTime.now()),
      ]);

      p.setFilter(TaskFilter.done);

      expect(p.visibleTasks.length, 1);
      expect(p.visibleTasks.first.id, '2');
    });

    test('search filters by title case-insensitively', () async {
      final p = await buildProvider([
        makeTask(id: '1', title: 'Buy Groceries'),
        makeTask(id: '2', title: 'Call Doctor'),
      ]);

      p.setSearchQuery('grocer');

      expect(p.visibleTasks.length, 1);
      expect(p.visibleTasks.first.id, '1');
    });

    test('search filters by notes', () async {
      final p = await buildProvider([
        makeTask(id: '1', title: 'Task', notes: 'secret note here'),
        makeTask(id: '2', title: 'Other', notes: ''),
      ]);

      p.setSearchQuery('secret');

      expect(p.visibleTasks.length, 1);
    });

    test('category filter works', () async {
      final p = await buildProvider([
        makeTask(id: '1', title: 'Work task', category: 'Work'),
        makeTask(id: '2', title: 'Study task', category: 'Study'),
      ]);

      p.setSelectedCategory('Study');

      expect(p.visibleTasks.length, 1);
      expect(p.visibleTasks.first.category, 'Study');
    });
  });

  group('restore()', () {
    test('re-inserts deleted task', () async {
      final task = makeTask(id: '1', title: 'Deleted');
      final p = await buildProvider([task]);

      p.delete('1');
      expect(p.visibleTasks, isEmpty);

      p.restore(task);
      expect(p.visibleTasks.length, 1);
    });

    test('ignores duplicate restore', () async {
      final task = makeTask(id: '1', title: 'Existing');
      final p = await buildProvider([task]);

      p.restore(task); // already present
      expect(p.visibleTasks.length, 1);
    });
  });

  group('stats', () {
    test('completionRate is 0 when no tasks', () async {
      final p = await buildProvider([]);
      expect(p.completionRate, 0.0);
    });

    test('completionRate is correct', () async {
      final p = await buildProvider([
        makeTask(id: '1', title: 'A'),
        makeTask(id: '2', title: 'B', isDone: true, completedAt: DateTime.now()),
      ]);
      expect(p.completionRate, 0.5);
    });

    test('completedLast7Days returns 7 entries', () async {
      final p = await buildProvider([]);
      expect(p.completedLast7Days.length, 7);
    });

    test('completedLast7Days counts today correctly', () async {
      final now = DateTime.now();
      final p = await buildProvider([
        makeTask(
          id: '1', title: 'Done today',
          isDone: true,
          completedAt: DateTime(now.year, now.month, now.day, 9),
        ),
      ]);
      // index 6 = today
      expect(p.completedLast7Days[6], 1);
    });

    test('overdueCount only counts non-done past-due tasks', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final p = await buildProvider([
        makeTask(id: '1', title: 'Overdue', dueDate: yesterday),
        makeTask(id: '2', title: 'Done overdue', dueDate: yesterday, isDone: true, completedAt: DateTime.now()),
      ]);
      expect(p.overdueCount, 1);
    });
  });
}
