import 'package:flutter/foundation.dart';

enum Priority { low, medium, high }

const kCategories = ['Work', 'Study', 'Personal', 'Health'];

@immutable
class Task {
  final String id;
  final String title;
  final String notes;
  final Priority priority;
  final String category;
  final DateTime? dueDate;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.priority = Priority.medium,
    this.category = 'Personal',
    this.dueDate,
    this.isDone = false,
    required this.createdAt,
    this.completedAt,
  });

  /// A task is overdue when it has a due date in the past and is not completed.
  bool get isOverdue {
    if (isDone || dueDate == null) return false;
    final today = DateTime.now();
    final due = dueDate!;
    return DateTime(due.year, due.month, due.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    Priority? priority,
    String? category,
    Object? dueDate = _sentinel,
    bool? isDone,
    DateTime? createdAt,
    Object? completedAt = _sentinel,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      completedAt:
          completedAt == _sentinel ? this.completedAt : completedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'priority': priority.name,
        'category': category,
        'dueDate': dueDate?.toIso8601String(),
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? _generateFallbackId(),
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      priority: _parsePriority(json['priority'] as String?),
      category: _parseCategory(json['category'] as String?),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      isDone: json['isDone'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  static Priority _parsePriority(String? raw) {
    return Priority.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => Priority.medium,
    );
  }

  static String _parseCategory(String? raw) {
    if (raw != null && kCategories.contains(raw)) return raw;
    return kCategories.first;
  }

  static String _generateFallbackId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Sentinel value used in [Task.copyWith] to distinguish null from "not provided".
const Object _sentinel = Object();
