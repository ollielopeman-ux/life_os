import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/gym_models.dart';
import '../providers/gym_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../body/providers/body_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _rangeDays = 90;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final gym = ref.watch(gymProvider);
    final bodyEntries = ref.watch(bodyProvider);
    final allTasks = ref.watch(scheduleProvider);

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: _rangeDays));

    final weightPoints = bodyEntries
        .where((e) => e.weight != null && !e.date.isBefore(cutoff))
        .map((e) => (date: e.date, value: e.weight!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final gymDates = allTasks
        .where((t) =>
            t.done &&
            t.title.endsWith('· Gym') &&
            !t.date.isBefore(cutoff))
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .toList()
      ..sort();

    final prs = _computePRs(gym);

    // Summary metrics
    final sessionCount = gymDates.length;
    double? weightDelta;
    if (weightPoints.length >= 2) {
      weightDelta = weightPoints.last.value - weightPoints.first.value;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF161618),
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Stats',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RangeSelector(
                    selected: _rangeDays,
                    onChanged: (v) => setState(() => _rangeDays = v),
                  ),
                  const SizedBox(height: 20),

                  // Summary row
                  Row(
                    children: [
                      _KpiChip(
                        label: 'Workouts',
                        value: '$sessionCount',
                        icon: Icons.fitness_center,
                        color: const Color(0xFF34C759),
                      ),
                      const SizedBox(width: 10),
                      if (weightDelta != null)
                        _KpiChip(
                          label: 'Weight',
                          value: '${weightDelta > 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)}kg',
                          icon: weightDelta <= 0
                              ? Icons.trending_down_rounded
                              : Icons.trending_up_rounded,
                          color: weightDelta <= 0 ? const Color(0xFF34C759) : accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (weightPoints.isNotEmpty || gymDates.isNotEmpty)
                    _ProgressChart(
                      weightPoints: weightPoints,
                      gymDates: gymDates,
                      rangeDays: _rangeDays,
                      accent: accent,
                    )
                  else
                    const SizedBox(
                      height: 140,
                      child: Center(
                        child: Text(
                          'No data in this period',
                          style: TextStyle(color: Colors.white24, fontSize: 14),
                        ),
                      ),
                    ),

                  const SizedBox(height: 36),

                  if (prs.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'Personal Records',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          if (prs.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == prs.length) return const SizedBox(height: 100);
                  return _PRRow(
                    entry: prs[i],
                    showDivider: i < prs.length - 1,
                    accent: accent,
                  );
                },
                childCount: prs.length + 1,
              ),
            ),

          if (prs.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 44, color: Colors.white12),
                      SizedBox(height: 12),
                      Text(
                        'No PRs yet',
                        style: TextStyle(color: Colors.white38, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Complete a workout to start tracking',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_PREntry> _computePRs(GymState gym) {
    final map = <String, _PREntry>{};
    for (final split in gym.splits) {
      for (final day in split.days) {
        for (final ex in day.exercises) {
          if (ex.history.isEmpty) continue;
          final best = ex.history.reduce((a, b) =>
              a.weight > b.weight ||
                      (a.weight == b.weight && a.reps > b.reps)
                  ? a
                  : b);
          final existing = map[ex.name];
          if (existing == null ||
              best.weight > existing.pr.weight ||
              (best.weight == existing.pr.weight &&
                  best.reps > existing.pr.reps)) {
            map[ex.name] = _PREntry(name: ex.name, pr: best);
          }
        }
      }
    }
    final list = map.values.toList()
      ..sort((a, b) {
        // Sort by most recently broken first
        return b.pr.date.compareTo(a.pr.date);
      });
    return list;
  }
}

// ── Range Selector ─────────────────────────────────────────────────────────────

class _RangeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [(30, '1M'), (90, '3M'), (180, '6M'), (365, '1Y')];
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.map((opt) {
          final (days, label) = opt;
          final sel = selected == days;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(days),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF3A3A3C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: sel ? Colors.white : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── KPI Chip ───────────────────────────────────────────────────────────────────

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Progress Chart ─────────────────────────────────────────────────────────────

class _ProgressChart extends StatelessWidget {
  final List<({DateTime date, double value})> weightPoints;
  final List<DateTime> gymDates;
  final int rangeDays;
  final Color accent;

  const _ProgressChart({
    required this.weightPoints,
    required this.gymDates,
    required this.rangeDays,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            if (weightPoints.isNotEmpty) ...[
              Container(
                width: 20,
                height: 2.5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text('Body weight',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 18),
            ],
            if (gymDates.isNotEmpty) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Gym session',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Weight stats
        if (weightPoints.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${weightPoints.last.value.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'now',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        SizedBox(
          height: 160,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ChartPainter(
              weightPoints: weightPoints,
              gymDates: gymDates,
              rangeDays: rangeDays,
              accent: accent,
            ),
          ),
        ),

        // Date labels
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _dateLabels(rangeDays)
                .map((l) => Text(
                      l,
                      style: const TextStyle(
                          color: Colors.white24, fontSize: 10),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  List<String> _dateLabels(int days) {
    final now = DateTime.now();
    if (days <= 30) {
      return [
        DateFormat('d MMM').format(now.subtract(Duration(days: days))),
        DateFormat('d MMM').format(now.subtract(Duration(days: days ~/ 2))),
        'Today',
      ];
    } else if (days <= 90) {
      return [
        DateFormat('MMM').format(now.subtract(Duration(days: days))),
        DateFormat('MMM').format(now.subtract(Duration(days: days ~/ 2))),
        DateFormat('MMM').format(now),
      ];
    } else {
      return [
        DateFormat('MMM yy').format(now.subtract(Duration(days: days))),
        DateFormat('MMM yy').format(now.subtract(Duration(days: days ~/ 2))),
        DateFormat('MMM yy').format(now),
      ];
    }
  }
}

class _ChartPainter extends CustomPainter {
  final List<({DateTime date, double value})> weightPoints;
  final List<DateTime> gymDates;
  final int rangeDays;
  final Color accent;

  const _ChartPainter({
    required this.weightPoints,
    required this.gymDates,
    required this.rangeDays,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: rangeDays));
    final chartH = size.height - 16;

    double xOf(DateTime d) {
      final ratio = d.difference(start).inMinutes /
          Duration(days: rangeDays).inMinutes;
      return ratio.clamp(0.0, 1.0) * size.width;
    }

    // Gym dots at the bottom
    if (gymDates.isNotEmpty) {
      final dotPaint = Paint()
        ..color = const Color(0xFF34C759)
        ..style = PaintingStyle.fill;
      for (final d in gymDates) {
        canvas.drawCircle(Offset(xOf(d), size.height - 4), 3, dotPaint);
      }
    }

    // Weight line
    if (weightPoints.length >= 2) {
      final weights = weightPoints.map((p) => p.value).toList();
      final minW = weights.reduce(math.min);
      final maxW = weights.reduce(math.max);
      final range = (maxW - minW).abs();

      double yOf(double w) {
        if (range < 0.3) return chartH * 0.5;
        return chartH - ((w - minW) / range * chartH * 0.75 + chartH * 0.1);
      }

      // Fill gradient under line
      final fillPath = Path();
      final first = Offset(xOf(weightPoints.first.date), yOf(weightPoints.first.value));
      fillPath.moveTo(first.dx, chartH);
      fillPath.lineTo(first.dx, first.dy);
      for (int i = 1; i < weightPoints.length; i++) {
        final p = weightPoints[i];
        final x0 = xOf(weightPoints[i - 1].date);
        final y0 = yOf(weightPoints[i - 1].value);
        final x1 = xOf(p.date);
        final y1 = yOf(p.value);
        final cpX = (x0 + x1) / 2;
        fillPath.cubicTo(cpX, y0, cpX, y1, x1, y1);
      }
      final last = Offset(xOf(weightPoints.last.date), yOf(weightPoints.last.value));
      fillPath.lineTo(last.dx, chartH);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartH))
          ..style = PaintingStyle.fill,
      );

      // Smooth line
      final linePath = Path();
      linePath.moveTo(xOf(weightPoints.first.date), yOf(weightPoints.first.value));
      for (int i = 1; i < weightPoints.length; i++) {
        final x0 = xOf(weightPoints[i - 1].date);
        final y0 = yOf(weightPoints[i - 1].value);
        final x1 = xOf(weightPoints[i].date);
        final y1 = yOf(weightPoints[i].value);
        final cpX = (x0 + x1) / 2;
        linePath.cubicTo(cpX, y0, cpX, y1, x1, y1);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // End dot
      canvas.drawCircle(last, 4, Paint()..color = accent..style = PaintingStyle.fill);
    } else if (weightPoints.length == 1) {
      // Single point — just a dot
      final weights = weightPoints.map((p) => p.value).toList();
      final minW = weights.reduce(math.min);
      final maxW = weights.reduce(math.max);
      final range = (maxW - minW).abs();
      double yOf(double w) {
        if (range < 0.3) return chartH * 0.5;
        return chartH - ((w - minW) / range * chartH * 0.75 + chartH * 0.1);
      }
      final pt = Offset(xOf(weightPoints.first.date), yOf(weightPoints.first.value));
      canvas.drawCircle(pt, 5, Paint()..color = accent..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.rangeDays != rangeDays ||
      old.accent != accent ||
      old.weightPoints.length != weightPoints.length ||
      old.gymDates.length != gymDates.length;
}

// ── PR Row ─────────────────────────────────────────────────────────────────────

class _PRRow extends StatelessWidget {
  final _PREntry entry;
  final bool showDivider;
  final Color accent;
  const _PRRow({
    required this.entry,
    required this.showDivider,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final pr = entry.pr;
    final w = pr.weight % 1 == 0 ? '${pr.weight.toInt()}' : '${pr.weight}';
    final e1rm = pr.weight * (1 + pr.reps / 30);
    final e1rmStr =
        e1rm % 1 < 0.05 ? '${e1rm.round()}' : e1rm.toStringAsFixed(1);

    final daysSince = DateTime.now().difference(pr.date).inDays;
    final sinceStr = daysSince == 0
        ? 'Today'
        : daysSince == 1
            ? 'Yesterday'
            : daysSince < 7
                ? '${daysSince}d ago'
                : daysSince < 30
                    ? '${(daysSince / 7).round()}w ago'
                    : daysSince < 365
                        ? '${(daysSince / 30.4).round()}mo ago'
                        : '${(daysSince / 365).round()}y ago';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.emoji_events_outlined,
                    color: Color(0xFFFFD700), size: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sinceStr  ·  ${DateFormat('d MMM yyyy').format(pr.date)}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${w}kg',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '× ${pr.reps}  ·  e1RM ${e1rmStr}kg',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 0.5,
            indent: 66,
            color: Color(0xFF2C2C2E),
          ),
      ],
    );
  }
}

// ── Data Model ─────────────────────────────────────────────────────────────────

class _PREntry {
  final String name;
  final SetEntry pr;
  const _PREntry({required this.name, required this.pr});
}
