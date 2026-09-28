import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/format.dart';

import '../screens/task_form_screen.dart';

/// A Material 3 card representing a single task in the list.
class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      label: 'Task: ${task.title}. ${task.isDone ? 'Completed' : 'Active'}. Swipe left to delete.',
      child: Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.onError, semanticLabel: 'Delete'),
      ),
      onDismissed: (_) {
        final provider = context.read<TaskProvider>();
        provider.delete(task.id);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${task.title}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => provider.restore(task),
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskFormScreen(initialTask: task),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Checkbox ──────────────────────────────────────────────
                Semantics(
                  label: task.isDone
                      ? 'Mark ${task.title} as active'
                      : 'Mark ${task.title} as done',
                  child: Checkbox(
                    value: task.isDone,
                    onChanged: (_) {
                      HapticFeedback.lightImpact();
                      context.read<TaskProvider>().toggle(task.id);
                    },
                  ),
                ),

                // ── Content ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: tt.bodyLarge?.copyWith(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isDone
                              ? cs.onSurface.withValues(alpha: 0.45)
                              : cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Notes preview
                      if (task.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.notes,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Pills row
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _CategoryPill(task.category, cs),
                          if (task.dueDate != null)
                            _DuePill(task, cs),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Priority flag ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4),
                  child: Icon(
                    Icons.flag_rounded,
                    size: 18,
                    color: _priorityColor(task.priority, cs),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Color _priorityColor(Priority p, ColorScheme cs) => switch (p) {
        Priority.high => cs.error,
        Priority.medium => const Color(0xFFE07B00), // accessible orange
        Priority.low => const Color(0xFF2E7D32),    // accessible green
      };
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _CategoryPill(this.label, this.cs);

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: label,
      bg: cs.secondaryContainer,
      fg: cs.onSecondaryContainer,
    );
  }
}

class _DuePill extends StatelessWidget {
  final Task task;
  final ColorScheme cs;
  const _DuePill(this.task, this.cs);

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    return _Pill(
      label: dueLabel(task.dueDate!),
      bg: isOverdue ? cs.errorContainer : cs.tertiaryContainer,
      fg: isOverdue ? cs.onErrorContainer : cs.onTertiaryContainer,
      icon: Icons.schedule_rounded,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
