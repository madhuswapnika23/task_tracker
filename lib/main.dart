import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/task_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskTrackerApp());
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // load() is called immediately; the UI rebuilds once data is ready.
      create: (_) => TaskProvider()..load(),
      child: const _AppView(),
    );
  }
}

/// Separate widget so it can listen to [TaskProvider.themeMode] without
/// rebuilding the provider itself.
class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<TaskProvider, ThemeMode>(
      (p) => p.themeMode,
    );

    const seedColor = Colors.indigo;

    return MaterialApp(
      title: 'Task Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,

      // ── Light theme ────────────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      ),

      // ── Dark theme ─────────────────────────────────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
