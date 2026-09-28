import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/format.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // ── 1. Completion ring card ─────────────────────────────────────
        _SectionCard(
          child: Row(
            children: [
              _CompletionRing(
                rate: provider.completionRate,
                colorScheme: cs,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.doneCount} of ${provider.totalCount} '
                      '${provider.totalCount == 1 ? 'task' : 'tasks'} done',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurface.withValues(alpha: 0.65)),
                    ),
                    if (provider.totalCount == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Add your first task to get started.',
                          style: tt.bodySmall?.copyWith(
                            color: cs.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 2. Three stat mini-cards ────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                label: 'Active',
                value: provider.activeCount,
                icon: Icons.radio_button_unchecked_rounded,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniCard(
                label: 'Done',
                value: provider.doneCount,
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniCard(
                label: 'Overdue',
                value: provider.overdueCount,
                icon: Icons.warning_amber_rounded,
                color: cs.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── 3. Last 7 days bar chart ────────────────────────────────────
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last 7 Days',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Tasks completed per day',
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 16),
              _BarChart(
                data: provider.completedLast7Days,
                colorScheme: cs,
                textTheme: tt,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── 4. By category ─────────────────────────────────────────────
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By Category',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...kCategories.map((cat) {
                final counts = provider.categoryBreakdown[cat] ?? [0, 0];
                final done = counts[0];
                final total = counts[1];
                return _CategoryRow(
                  category: cat,
                  done: done,
                  total: total,
                  colorScheme: cs,
                  textTheme: tt,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Completion ring ───────────────────────────────────────────────────────────

class _CompletionRing extends StatelessWidget {
  final double rate; // 0.0 – 1.0
  final ColorScheme colorScheme;

  const _CompletionRing({required this.rate, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).round();
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(110, 110),
            painter: _RingPainter(
              progress: rate,
              trackColor: colorScheme.surfaceContainerHighest,
              fillColor: colorScheme.primary,
              strokeWidth: 10,
            ),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (full circle)
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc — guard against zero so we still draw cleanly
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor;
}

// ── Mini stat card ────────────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<int> data; // 7 entries, oldest → today
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _BarChart({
    required this.data,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = data.reduce(math.max);
    final today = DateTime.now();
    const maxBarHeight = 80.0;
    const minBarHeight = 4.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final count = data[i];
        final day = today.subtract(Duration(days: 6 - i));
        final label = i == 6 ? 'Today' : weekdayShort(day);
        final isToday = i == 6;

        // Scale bar height — if maxVal is 0 all bars show as minHeight
        final barHeight = maxVal == 0
            ? minBarHeight
            : math.max(minBarHeight, (count / maxVal) * maxBarHeight);

        final barColor = isToday
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.45);

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Count above bar (hide when 0 to keep it clean)
              Text(
                count > 0 ? '$count' : '',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),

              // Animated bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Day label below bar
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                  color: isToday
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String category;
  final int done;
  final int total;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _CategoryRow({
    required this.category,
    required this.done,
    required this.total,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against division-by-zero
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$done / $total',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared section card wrapper ───────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
