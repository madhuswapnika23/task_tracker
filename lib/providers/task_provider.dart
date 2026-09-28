import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

// ─── Filter / Sort enums ──────────────────────────────────────────────────────

enum TaskFilter { all, active, done }

enum TaskSort { dueDate, priority, newest }

// ─── Provider ────────────────────────────────────────────────────────────────

class TaskProvider extends ChangeNotifier {
  // ── Persistence keys ──────────────────────────────────────────────────────
  static const _tasksKey = 'tasks_v1';
  static const _themeKey = 'theme_mode';

  // ── Internal state ────────────────────────────────────────────────────────
  List<Task> _tasks = [];
  ThemeMode _themeMode = ThemeMode.system;

  // ── Filter state ──────────────────────────────────────────────────────────
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.dueDate;
  String _searchQuery = '';
  String? _selectedCategory;

  // ── Public getters ────────────────────────────────────────────────────────
  ThemeMode get themeMode => _themeMode;
  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  // ── Filter / sort setters ─────────────────────────────────────────────────

  void setFilter(TaskFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }

  void setSort(TaskSort s) {
    if (_sort == s) return;
    _sort = s;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    if (_searchQuery == q) return;
    _searchQuery = q;
    notifyListeners();
  }

  void setSelectedCategory(String? cat) {
    if (_selectedCategory == cat) return;
    _selectedCategory = cat;
    notifyListeners();
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  /// Toggles between light and dark; if [current] is already dark, goes light.
  void toggleTheme(Brightness current) {
    _themeMode =
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  // ── visibleTasks ──────────────────────────────────────────────────────────

  List<Task> get visibleTasks {
    var result = _tasks.toList();

    // 1. Category filter
    if (_selectedCategory != null) {
      result = result.where((t) => t.category == _selectedCategory).toList();
    }

    // 2. Done/active filter
    if (_filter == TaskFilter.active) {
      result = result.where((t) => !t.isDone).toList();
    } else if (_filter == TaskFilter.done) {
      result = result.where((t) => t.isDone).toList();
    }

    // 3. Search (title + notes, case-insensitive)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.notes.toLowerCase().contains(q))
          .toList();
    }

    // 4. Sort — done tasks always sink to the bottom
    result.sort((a, b) {
      // Done tasks go last
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;

      switch (_sort) {
        case TaskSort.dueDate:
          return _compareDueDate(a, b);
        case TaskSort.priority:
          return _comparePriority(a, b);
        case TaskSort.newest:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return result;
  }

  /// Tasks with no due date go last; otherwise ascending.
  int _compareDueDate(Task a, Task b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;
    return a.dueDate!.compareTo(b.dueDate!);
  }

  /// High → Medium → Low.
  int _comparePriority(Task a, Task b) {
    return b.priority.index.compareTo(a.priority.index);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  int get totalCount => _tasks.length;
  int get doneCount => _tasks.where((t) => t.isDone).length;
  int get activeCount => _tasks.where((t) => !t.isDone).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;

  double get completionRate =>
      _tasks.isEmpty ? 0.0 : doneCount / _tasks.length;

  /// Returns a list of 7 ints (oldest first) — how many tasks were completed
  /// each day over the last 7 days (day 0 = 6 days ago, day 6 = today).
  List<int> get completedLast7Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List.filled(7, 0);

    for (final t in _tasks) {
      if (!t.isDone || t.completedAt == null) continue;
      final completed =
          DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day);
      final diff = today.difference(completed).inDays;
      if (diff >= 0 && diff < 7) {
        // diff 0 = today (index 6), diff 6 = oldest (index 0)
        counts[6 - diff]++;
      }
    }
    return counts;
  }

  /// Returns {category: [doneCount, totalCount]} for every known category.
  Map<String, List<int>> get categoryBreakdown {
    final map = <String, List<int>>{};
    for (final cat in kCategories) {
      map[cat] = [0, 0];
    }
    for (final t in _tasks) {
      final entry = map.putIfAbsent(t.category, () => [0, 0]);
      entry[1]++;
      if (t.isDone) entry[0]++;
    }
    return map;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void add(Task task) {
    _tasks.add(task);
    _persist();
    notifyListeners();
  }

  void update(Task updated) {
    final idx = _tasks.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    _tasks[idx] = updated;
    _persist();
    notifyListeners();
  }

  /// Flips [isDone]. Sets [completedAt] when marking done, clears it when undone.
  void toggle(String id) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final task = _tasks[idx];
    _tasks[idx] = task.copyWith(
      isDone: !task.isDone,
      completedAt: !task.isDone ? DateTime.now() : null,
    );
    _persist();
    notifyListeners();
  }

  void delete(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _persist();
    notifyListeners();
  }

  /// Re-inserts a previously deleted task (for undo). Ignores duplicates.
  void restore(Task task) {
    if (_tasks.any((t) => t.id == task.id)) return;
    _tasks.add(task);
    _persist();
    notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  /// Loads tasks and theme from shared_preferences. Must be called once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Tasks
    final raw = prefs.getString(_tasksKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _tasks = list
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Corrupted JSON — start fresh
        _tasks = [];
      }
    } else {
      _tasks = [];
    }

    // Theme
    final savedTheme = prefs.getString(_themeKey);
    _themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await _persistSync(prefs);
  }

  /// Writes tasks using an already-open [SharedPreferences] instance.
  Future<void> _persistSync(SharedPreferences prefs) async {
    final encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, encoded);
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (_themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_themeKey, value);
  }
}
