import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'task_form_screen.dart';
import 'stats_screen.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: false,
        actions: [
          // ── Sort popup ─────────────────────────────────────────────────
          if (_tabIndex == 0) _SortMenu(provider: provider),

          // ── Theme toggle ───────────────────────────────────────────────
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => provider.toggleTheme(brightness),
          ),
        ],
      ),

      // ── Bottom nav ─────────────────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
        ],
      ),

      // ── FAB — only on Tasks tab ────────────────────────────────────────
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              tooltip: 'Add a new task',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New task'),
            )
          : null,

      // ── Body: IndexedStack keeps both tabs alive ───────────────────────
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _TasksTab(),
          _StatsTab(),
        ],
      ),
    );
  }
}

// ── Tasks tab ─────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final visible = provider.visibleTasks;
    final hasAnyTasks = provider.totalCount > 0;

    return Column(
      children: [
        // ── Filter controls header ─────────────────────────────────────
        _FilterHeader(provider: provider),

        // ── List or Empty state with smooth transition ──────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: visible.isEmpty
                ? _EmptyState(
                    key: ValueKey('empty-${hasAnyTasks ? 'filtered' : 'all'}'),
                    hasAnyTasks: hasAnyTasks,
                  )
                : ListView.builder(
                    key: const ValueKey('list'),
                    padding: const EdgeInsets.only(top: 4, bottom: 96),
                    itemCount: visible.length,
                    itemBuilder: (_, i) => TaskTile(task: visible[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Filter header ─────────────────────────────────────────────────────────────

class _FilterHeader extends StatefulWidget {
  final TaskProvider provider;
  const _FilterHeader({required this.provider});

  @override
  State<_FilterHeader> createState() => _FilterHeaderState();
}

class _FilterHeaderState extends State<_FilterHeader> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.provider.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _FilterHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.provider.searchQuery) {
      _searchController.text = widget.provider.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Search TextField
          TextField(
            controller: _searchController,
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search tasks',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: provider.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // 2. Full-width SegmentedButton (All / Active / Done)
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TaskFilter>(
              segments: const [
                ButtonSegment(value: TaskFilter.all, label: Text('All')),
                ButtonSegment(value: TaskFilter.active, label: Text('Active')),
                ButtonSegment(value: TaskFilter.done, label: Text('Done')),
              ],
              selected: {provider.filter},
              onSelectionChanged: (set) => provider.setFilter(set.first),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Horizontally scrollable row of ChoiceChips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All categories'),
                  selected: provider.selectedCategory == null,
                  onSelected: (_) => provider.setSelectedCategory(null),
                ),
                const SizedBox(width: 8),
                ...kCategories.map((cat) {
                  final isSelected = provider.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        provider.setSelectedCategory(selected ? cat : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasAnyTasks;
  const _EmptyState({super.key, required this.hasAnyTasks});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final icon = hasAnyTasks
        ? Icons.search_off_rounded
        : Icons.task_alt_rounded;
    final title = hasAnyTasks ? 'No matching tasks' : 'No tasks yet';
    final hint = hasAnyTasks
        ? 'Try adjusting your filters or search.'
        : 'Tap "New task" to add your first task.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: cs.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(
              title,
              style: tt.titleLarge?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) => const StatsScreen();
}

// ── Sort popup menu ───────────────────────────────────────────────────────────

class _SortMenu extends StatelessWidget {
  final TaskProvider provider;
  const _SortMenu({required this.provider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskSort>(
      tooltip: 'Sort by',
      icon: const Icon(Icons.sort_rounded),
      initialValue: provider.sort,
      onSelected: provider.setSort,
      itemBuilder: (_) => [
        _sortItem(TaskSort.dueDate, 'Due date', provider.sort),
        _sortItem(TaskSort.priority, 'Priority', provider.sort),
        _sortItem(TaskSort.newest, 'Newest', provider.sort),
      ],
    );
  }

  PopupMenuItem<TaskSort> _sortItem(
    TaskSort value,
    String label,
    TaskSort current,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (current == value)
            const Icon(Icons.check_rounded, size: 18),
        ],
      ),
    );
  }
}
