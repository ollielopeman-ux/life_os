import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../models/task.dart';
import '../../reading/providers/reading_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _weekStart;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _weekStart = _monday(DateTime.now());
  }

  static DateTime _monday(DateTime d) {
    final n = DateTime(d.year, d.month, d.day);
    return n.subtract(Duration(days: n.weekday - 1));
  }

  bool _sameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(scheduleProvider);
    final allBooks = ref.watch(booksProvider);

    // KPIs — current year counts
    final currentYear = DateTime.now().year;
    final gymSessions =
        allTasks.where((t) => t.isWorkout && t.date.year == currentYear).length;
    final cardioRuns = allTasks
        .where((t) =>
            t.title.endsWith('· Cardio') && t.date.year == currentYear)
        .length;
    final booksRead = allBooks
        .where((b) =>
            b.status == 'done' &&
            (b.completedDate?.year ?? 0) == currentYear)
        .length;

    // Build activity map: dateKey → set of dot types
    final activityMap = <String, Set<String>>{};
    for (final task in allTasks) {
      final key = _dateKey(task.date);
      activityMap.putIfAbsent(key, () => {});
      if (task.isWorkout) {
        activityMap[key]!.add('gym');
        if (task.workoutPRs.isNotEmpty) activityMap[key]!.add('pr');
      } else if (task.title.endsWith('· Cardio')) {
        activityMap[key]!.add('cardio');
      } else if (task.title.startsWith('Started:') ||
          task.title.startsWith('Finished:')) {
        activityMap[key]!.add('book');
      }
    }

    final days = List.generate(14, (i) => _weekStart.add(Duration(days: i)));

    final selectedTasks = _selected == null
        ? <Task>[]
        : allTasks
            .where((t) =>
                t.date.year == _selected!.year &&
                t.date.month == _selected!.month &&
                t.date.day == _selected!.day)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Center(
                child: Text('CALENDAR',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TwoWeekCard(
                      days: days,
                      selected: _selected,
                      activityMap: activityMap,
                      onPrev: () => setState(() {
                        _weekStart =
                            _weekStart.subtract(const Duration(days: 14));
                        _selected = null;
                      }),
                      onNext: () => setState(() {
                        _weekStart =
                            _weekStart.add(const Duration(days: 14));
                        _selected = null;
                      }),
                      onDayTap: (d) => setState(() {
                        _selected = _sameDay(d, _selected) ? null : d;
                      }),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeInOut,
                      child: _selected == null
                          ? const SizedBox(width: double.infinity)
                          : _DayPanel(
                              day: _selected!,
                              tasks: selectedTasks,
                            ),
                    ),
                    const SizedBox(height: 28),
                    const _YearDotsSection(),
                    const SizedBox(height: 20),
                    _KpiRow(
                      gym: gymSessions,
                      books: booksRead,
                      cardio: cardioRuns,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Two-Week Card ──────────────────────────────────────────────────────────────

class _TwoWeekCard extends StatelessWidget {
  final List<DateTime> days;
  final DateTime? selected;
  final Map<String, Set<String>> activityMap;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDayTap;

  const _TwoWeekCard({
    required this.days,
    required this.selected,
    required this.activityMap,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = days.first;
    final last = days.last;
    final String monthLabel;
    if (first.month == last.month) {
      monthLabel = DateFormat('MMMM yyyy').format(first);
    } else {
      monthLabel =
          '${DateFormat('MMM').format(first)} / ${DateFormat('MMM yyyy').format(last)}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Navigation row
          Row(
            children: [
              GestureDetector(
                onTap: onPrev,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left,
                      color: Colors.white60, size: 22),
                ),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onNext,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right,
                      color: Colors.white60, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Weekday headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((h) => Expanded(
                      child: Text(h,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Week 1
          Row(
            children: days
                .take(7)
                .map((d) => Expanded(
                      child: _DayCell(
                        day: d,
                        isSelected: selected != null &&
                            d.year == selected!.year &&
                            d.month == selected!.month &&
                            d.day == selected!.day,
                        activities: activityMap[_dateKey(d)] ?? {},
                        onTap: () => onDayTap(d),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 2),
          // Week 2
          Row(
            children: days
                .skip(7)
                .map((d) => Expanded(
                      child: _DayCell(
                        day: d,
                        isSelected: selected != null &&
                            d.year == selected!.year &&
                            d.month == selected!.month &&
                            d.day == selected!.day,
                        activities: activityMap[_dateKey(d)] ?? {},
                        onTap: () => onDayTap(d),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Day Cell ───────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final Set<String> activities;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.activities,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDay = DateTime(day.year, day.month, day.day);
    final isToday = thisDay == today;
    final isPast = thisDay.isBefore(today);

    final hasGym = activities.contains('gym');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5B7FA8)
                      : isToday
                          ? const Color(0xFF5B7FA8).withValues(alpha: 0.15)
                          : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? const Color(0xFF5B7FA8)
                                : isPast
                                    ? Colors.white70
                                    : Colors.white30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ActivityDots(activities: activities, isSelected: isSelected),
                  ],
                ),
              ),
              if (hasGym)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: const Color(0xFF5B7FA8).withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Activity Dots ──────────────────────────────────────────────────────────────

class _ActivityDots extends StatelessWidget {
  final Set<String> activities;
  final bool isSelected;

  const _ActivityDots({required this.activities, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final dots = <Color>[];
    if (activities.contains('gym')) dots.add(const Color(0xFF5B7FA8));
    if (activities.contains('cardio')) dots.add(const Color(0xFFE07B54));
    if (activities.contains('book')) dots.add(const Color(0xFF9B7FD4));
    if (activities.contains('pr')) dots.add(const Color(0xFFFFD700));

    return SizedBox(
      height: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: dots
            .map((c) => Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : c,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Day Panel ─────────────────────────────────────────────────────────────────

class _DayPanel extends StatelessWidget {
  final DateTime day;
  final List<Task> tasks;

  const _DayPanel({required this.day, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, d MMMM').format(day),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Nothing logged',
                    style:
                        TextStyle(color: Colors.white38, fontSize: 14)),
              )
            else
              ...tasks.map((t) => _DayTaskTile(task: t)),
          ],
        ),
      ),
    );
  }
}

// ── Day Task Tile ─────────────────────────────────────────────────────────────

class _DayTaskTile extends StatelessWidget {
  final Task task;
  const _DayTaskTile({required this.task});

  (IconData, Color, String) _meta() {
    if (task.isWorkout) {
      return (
        Icons.fitness_center,
        const Color(0xFF5B7FA8),
        task.title.replaceAll(' · Gym', ''),
      );
    }
    if (task.title.endsWith('· Cardio')) {
      return (
        Icons.directions_run,
        const Color(0xFFE07B54),
        task.title.replaceAll(' · Cardio', ''),
      );
    }
    if (task.title.startsWith('Started:') ||
        task.title.startsWith('Finished:')) {
      return (Icons.menu_book_rounded, const Color(0xFF9B7FD4), task.title);
    }
    return (Icons.check_circle_outline, Colors.white54, task.title);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _meta();
    final tappable = task.isWorkout;

    return GestureDetector(
      onTap: tappable
          ? () => showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _WorkoutDetailSheet(task: task),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            if (task.workoutPRs.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${task.workoutPRs.length} PR',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (tappable)
              const Icon(Icons.chevron_right,
                  size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

// ── Year Dots Section ─────────────────────────────────────────────────────────

class _YearDotsSection extends StatelessWidget {
  const _YearDotsSection();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final year = today.year;
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year + 1, 1, 1);
    final daysInYear = yearEnd.difference(yearStart).inDays;
    final dayOfYear =
        DateTime(today.year, today.month, today.day).difference(yearStart).inDays +
            1;
    final daysLeft = daysInYear - dayOfYear;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$year',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$daysLeft days left',
              style:
                  const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 26,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: daysInYear,
          itemBuilder: (_, i) {
            final idx = i + 1;
            final Color color;
            if (idx == dayOfYear) {
              color = const Color(0xFF5B7FA8);
            } else if (idx < dayOfYear) {
              color = Colors.white.withValues(alpha: 0.5);
            } else {
              color = const Color(0xFF252527);
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Workout Detail Sheet ───────────────────────────────────────────────────────

class _WorkoutDetailSheet extends ConsumerWidget {
  final Task task;
  const _WorkoutDetailSheet({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = task.workoutSets;
    final prs = task.workoutPRs.toSet();
    final dayName = task.title.replaceAll(' · Gym', '');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B7FA8)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fitness_center,
                            color: Color(0xFF5B7FA8), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            DateFormat('EEEE, d MMM · h:mm a')
                                .format(task.date),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF2C2C2E)),
                  const SizedBox(height: 16),
                  if (sets.isEmpty)
                    const Text('No sets logged',
                        style: TextStyle(color: Colors.white38)),
                  ...sets.entries.map((entry) {
                    final name = entry.key;
                    final exSets = entry.value;
                    final isPR = prs.contains(name);
                    final maxW = exSets.isEmpty
                        ? 0.0
                        : exSets
                            .map((s) => (s['weight'] as num).toDouble())
                            .reduce(max);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ),
                              if (isPR)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFFFD700)
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: const Text('NEW PR',
                                      style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: exSets.asMap().entries.map((e) {
                              final s = e.value;
                              final w =
                                  (s['weight'] as num).toDouble();
                              final r = s['reps'] as int;
                              final isTop = w == maxW;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isTop
                                      ? const Color(0xFF5B7FA8)
                                          .withValues(alpha: 0.12)
                                      : const Color(0xFF242428),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: isTop
                                      ? Border.all(
                                          color: const Color(0xFF5B7FA8)
                                              .withValues(alpha: 0.3))
                                      : null,
                                ),
                                child: Text(
                                  '${_fmtW(w)}kg × $r',
                                  style: TextStyle(
                                    color: isTop
                                        ? const Color(0xFF5B7FA8)
                                        : Colors.white60,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── KPI Row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final int gym;
  final int books;
  final int cardio;

  const _KpiRow(
      {required this.gym, required this.books, required this.cardio});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Gym Sessions',
            value: '$gym',
            icon: Icons.fitness_center,
            color: const Color(0xFF5B7FA8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'Books Read',
            value: '$books',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF9B7FD4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            label: 'Cardio Runs',
            value: '$cardio',
            icon: Icons.directions_run,
            color: const Color(0xFFE07B54),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtW(double w) => w % 1 == 0 ? '${w.toInt()}' : '$w';

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
