import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/format.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? initialTask;

  const TaskFormScreen({super.key, this.initialTask});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _notes;
  late Priority _priority;
  late String _category;
  DateTime? _dueDate;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _title = t?.title ?? '';
    _notes = t?.notes ?? '';
    _priority = t?.priority ?? Priority.medium;
    _category = t?.category ?? kCategories.first;
    _dueDate = t?.dueDate;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = context.read<TaskProvider>();

    if (_isEditing) {
      final updated = widget.initialTask!.copyWith(
        title: _title.trim(),
        notes: _notes.trim(),
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
      );
      provider.update(updated);
    } else {
      final now = DateTime.now();
      final newTask = Task(
        id: now.millisecondsSinceEpoch.toString(),
        title: _title.trim(),
        notes: _notes.trim(),
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        createdAt: now,
      );
      provider.add(newTask);
    }

    Navigator.pop(context);
  }

  void _delete() {
    if (!_isEditing) return;
    final taskToDelete = widget.initialTask!;
    final provider = context.read<TaskProvider>();
    // Capture messenger before pop — using context after Navigator.pop is unsafe
    final messenger = ScaffoldMessenger.of(context);

    provider.delete(taskToDelete.id);
    Navigator.pop(context);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${taskToDelete.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => provider.restore(taskToDelete),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete task',
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Title ────────────────────────────────────────────────────────
            TextFormField(
              initialValue: _title,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              onSaved: (val) => _title = val ?? '',
            ),
            const SizedBox(height: 16),

            // ── Notes ────────────────────────────────────────────────────────
            TextFormField(
              initialValue: _notes,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add details, subtasks, or links...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onSaved: (val) => _notes = val ?? '',
            ),
            const SizedBox(height: 24),

            // ── Priority ─────────────────────────────────────────────────────
            Text('Priority', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            SegmentedButton<Priority>(
              segments: const [
                ButtonSegment(
                  value: Priority.low,
                  label: Text('Low'),
                  icon: Icon(Icons.flag_outlined, color: Colors.green),
                ),
                ButtonSegment(
                  value: Priority.medium,
                  label: Text('Medium'),
                  icon: Icon(Icons.flag_outlined, color: Colors.orange),
                ),
                ButtonSegment(
                  value: Priority.high,
                  label: Text('High'),
                  icon: Icon(Icons.flag_rounded, color: Colors.red),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (newSelection) {
                setState(() => _priority = newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            // ── Category ─────────────────────────────────────────────────────
            Text('Category', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kCategories.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _category = cat);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Due Date ─────────────────────────────────────────────────────
            Text('Due Date', style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(
                    _dueDate != null ? formatDate(_dueDate!) : 'Set due date',
                  ),
                ),
                if (_dueDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Clear due date',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _dueDate = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // ── Save Button ──────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
              label: Text(_isEditing ? 'Save changes' : 'Add task'),
            ),
          ],
        ),
      ),
    );
  }
}
