import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_models.dart';
import '../providers/gym_provider.dart';
import '../providers/active_workout_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../../shared/widgets/week_strip.dart';
import 'active_workout_screen.dart';
import 'edit_split_screen.dart';
import 'pr_screen.dart';

class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({super.key});

  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen> {
  DateTime _weekStart = WeekStrip.mondayOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final gym = ref.watch(gymProvider);
    final split = gym.selectedSplit;
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun

    // Completed gym workout dates for week strip
    final allTasks = ref.watch(scheduleProvider);
    final completedDates = allTasks
        .where((t) => t.done && t.title.endsWith('· Gym'))
        .map((t) => _dateKey(t.date))
        .toSet();

    // Completed day names for the selected week (to mark day cards done)
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final doneThisWeek = allTasks
        .where((t) =>
            t.done &&
            t.title.endsWith('· Gym') &&
            !t.date.isBefore(_weekStart) &&
            !t.date.isAfter(weekEnd))
        .map((t) => t.title.replaceAll(' · Gym', '').toLowerCase())
        .toSet();

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(child: _SplitHeader(gym: gym)),
                  IconButton(
                    icon: const Icon(Icons.emoji_events_outlined,
                        color: Colors.white38),
                    tooltip: 'PRs',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PRScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white38),
                    onPressed: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const EditSplitScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Week strip
            WeekStrip(
              weekStart: _weekStart,
              completedDates: completedDates,
              onWeekChanged: (w) => setState(() => _weekStart = w),
            ),
            const SizedBox(height: 12),

            // Resume banner (when workout paused)
            _ResumeBanner(),
            const SizedBox(height: 4),

            // Day list
            Expanded(
              child: split == null
                  ? _EmptyState()
                  : split.days.isEmpty
                      ? _NoDaysState()
                      : _buildDayList(split, today, doneThisWeek),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayList(GymSplit split, int today, Set<String> doneThisWeek) {
    final sorted = _reorderFromToday(split.days, today);
    final n = sorted.length;

    bool isToday(WorkoutDay d) =>
        d.weekdays.isNotEmpty && d.weekdays.contains(today);
    bool isDone(WorkoutDay d) => doneThisWeek.contains(d.name.toLowerCase());
    VoidCallback? tapFor(WorkoutDay d) {
      if (d.isRestDay || d.exercises.isEmpty) return null;
      return () {
        ref.read(activeWorkoutProvider.notifier).startWorkout(split.id, d);
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
        );
      };
    }

    Widget fullCard(WorkoutDay d) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _DayCard(
            day: d,
            isToday: isToday(d),
            isDone: isDone(d),
            onTap: tapFor(d),
          ),
        );

    final children = <Widget>[];

    // First 3: full-width cards
    for (int i = 0; i < n && i < 3; i++) {
      children.add(fullCard(sorted[i]));
    }

    if (n >= 7) {
      // Compact row for days 4–6
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 3; i < 6; i++) ...[
            if (i > 3) const SizedBox(width: 8),
            Expanded(
              child: _CompactDayCard(
                day: sorted[i],
                isToday: isToday(sorted[i]),
                isDone: isDone(sorted[i]),
                onTap: tapFor(sorted[i]),
              ),
            ),
          ],
        ],
      ));
      // Thin strip for day 7
      children.add(const SizedBox(height: 8));
      children.add(_ThinDayCard(
        day: sorted[6],
        isDone: isDone(sorted[6]),
        onTap: tapFor(sorted[6]),
      ));
    } else if (n > 3) {
      // 4–6 days: compact row for the remainder
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 3; i < n; i++) ...[
            if (i > 3) const SizedBox(width: 8),
            Expanded(
              child: _CompactDayCard(
                day: sorted[i],
                isToday: isToday(sorted[i]),
                isDone: isDone(sorted[i]),
                onTap: tapFor(sorted[i]),
              ),
            ),
          ],
        ],
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

// ── Resume Banner ──────────────────────────────────────────────────────────────

class _ResumeBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF5B7FA8).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF5B7FA8).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline,
                color: Color(0xFF5B7FA8), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WORKOUT PAUSED',
                      style: TextStyle(
                          color: Color(0xFF5B7FA8),
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700)),
                  Text(workout.day.name,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Text('Resume',
                style: TextStyle(
                    color: Color(0xFF5B7FA8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: Color(0xFF5B7FA8), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Split Header ───────────────────────────────────────────────────────────────

class _SplitHeader extends ConsumerWidget {
  final GymState gym;
  const _SplitHeader({required this.gym});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = gym.selectedSplit?.name ?? 'Gym';

    if (gym.splits.length <= 1) {
      return Text(name,
          style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white));
    }

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SplitPickerSheet(
          splits: gym.splits,
          selectedId: gym.selectedSplitId,
          onSelect: (id) => ref.read(gymProvider.notifier).selectSplit(id),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more, color: Colors.white38, size: 22),
        ],
      ),
    );
  }
}

class _SplitPickerSheet extends StatelessWidget {
  final List<GymSplit> splits;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const _SplitPickerSheet(
      {required this.splits,
      required this.selectedId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select Split',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 12),
          ...splits.map((s) => ListTile(
                title: Text(s.name,
                    style: const TextStyle(color: Colors.white)),
                trailing: s.id == selectedId
                    ? const Icon(Icons.check, color: Color(0xFF5B7FA8))
                    : null,
                onTap: () {
                  onSelect(s.id);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

// ── Day Card ───────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final WorkoutDay day;
  final bool isToday;
  final bool isDone;
  final VoidCallback? onTap;
  const _DayCard({
    required this.day,
    required this.isToday,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRest = day.isRestDay;
    final hasExercises = day.exercises.isNotEmpty;
    final dimmed = !isToday && !isDone && !isRest;
    final weekdayLabel = _weekdayStr(day.weekdays);

    final cardBg = isDone
        ? const Color(0xFF060E1C)
        : dimmed
            ? const Color(0xFF171719)
            : const Color(0xFF1C1C1E);

    final stripBg = isDone
        ? const Color(0xFF0D2140)
        : isRest
            ? const Color(0xFF222226)
            : hasExercises
                ? dimmed
                    ? const Color(0xFF1E3555)
                    : const Color(0xFF5B7FA8)
                : const Color(0xFF2C2C2E);

    final iconColor = isDone
        ? const Color(0xFF7FA8C8)
        : isRest
            ? Colors.white24
            : hasExercises
                ? dimmed
                    ? Colors.white38
                    : Colors.white
                : Colors.white12;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone
                ? const Color(0xFF5B7FA8).withValues(alpha: 0.4)
                : isToday
                    ? const Color(0xFF5B7FA8).withValues(alpha: 0.5)
                    : const Color(0xFF242426),
            width: (isDone || isToday) ? 1.5 : 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: cardBg,
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(day.name,
                              style: TextStyle(
                                  color: isDone
                                      ? const Color(0xFF7FA8C8)
                                      : dimmed
                                          ? Colors.white54
                                          : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22)),
                          if (isToday && !isDone) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B7FA8),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text('TODAY',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                          if (isDone) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B7FA8)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: const Color(0xFF5B7FA8)
                                        .withValues(alpha: 0.5)),
                              ),
                              child: const Text('DONE',
                                  style: TextStyle(
                                      color: Color(0xFF7FA8C8),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                      if (weekdayLabel.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(weekdayLabel,
                            style: TextStyle(
                                color: isDone
                                    ? Colors.white24
                                    : isToday
                                        ? const Color(0xFF5B7FA8)
                                            .withValues(alpha: 0.8)
                                        : Colors.white30,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3)),
                      ],
                      if (!isDone) ...[
                        const SizedBox(height: 4),
                        Text(
                          isRest
                              ? 'Rest & Recovery'
                              : hasExercises
                                  ? day.exercises
                                      .map((e) => e.name)
                                      .join('  ·  ')
                                  : 'No exercises — tap edit to add',
                          style: TextStyle(
                              color: dimmed
                                  ? Colors.white24
                                  : Colors.white38,
                              fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                width: 60,
                color: stripBg,
                alignment: Alignment.center,
                child: Icon(
                  isDone
                      ? Icons.check_rounded
                      : isRest
                          ? Icons.bedtime_outlined
                          : Icons.play_arrow_rounded,
                  color: iconColor,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact Day Card (row of 3) ────────────────────────────────────────────────

class _CompactDayCard extends StatelessWidget {
  final WorkoutDay day;
  final bool isToday;
  final bool isDone;
  final VoidCallback? onTap;
  const _CompactDayCard({
    required this.day,
    required this.isToday,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRest = day.isRestDay;
    final hasExercises = day.exercises.isNotEmpty;
    final weekdayLabel = _weekdayStr(day.weekdays);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFF0A1528) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? const Color(0xFF5B7FA8).withValues(alpha: 0.4)
                : isToday
                    ? const Color(0xFF5B7FA8).withValues(alpha: 0.5)
                    : const Color(0xFF242426),
            width: (isDone || isToday) ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day.name,
              style: TextStyle(
                color: isDone ? const Color(0xFF7FA8C8) : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (weekdayLabel.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(weekdayLabel,
                  style: TextStyle(
                      color: isDone
                          ? Colors.white24
                          : isToday
                              ? const Color(0xFF5B7FA8).withValues(alpha: 0.8)
                              : Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF5B7FA8).withValues(alpha: 0.2)
                      : isRest
                          ? const Color(0xFF222226)
                          : hasExercises
                              ? const Color(0xFF5B7FA8)
                              : const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDone
                      ? Icons.check_rounded
                      : isRest
                          ? Icons.bedtime_outlined
                          : Icons.play_arrow_rounded,
                  color: isDone
                      ? const Color(0xFF7FA8C8)
                      : isRest
                          ? Colors.white24
                          : hasExercises
                              ? Colors.white
                              : Colors.white12,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thin Day Strip (7th day) ───────────────────────────────────────────────────

class _ThinDayCard extends StatelessWidget {
  final WorkoutDay day;
  final bool isDone;
  final VoidCallback? onTap;
  const _ThinDayCard({
    required this.day,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekdayLabel = _weekdayStr(day.weekdays);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF242426), width: 1),
        ),
        child: Row(
          children: [
            Text(
              day.name,
              style: TextStyle(
                color: isDone ? const Color(0xFF7FA8C8) : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (weekdayLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              const Text('·',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
              const SizedBox(width: 8),
              Text(weekdayLabel,
                  style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
            const Spacer(),
            Icon(
              isDone
                  ? Icons.check_rounded
                  : day.isRestDay
                      ? Icons.bedtime_outlined
                      : Icons.play_arrow_rounded,
              color: isDone ? const Color(0xFF7FA8C8) : Colors.white12,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty States ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.fitness_center, size: 52, color: Colors.white12),
          SizedBox(height: 16),
          Text('No splits yet',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
          SizedBox(height: 8),
          Text('Tap the settings icon to get started',
              style: TextStyle(color: Colors.white24, fontSize: 13)),
        ]),
      );
}

class _NoDaysState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.calendar_today_outlined, size: 52, color: Colors.white12),
          SizedBox(height: 16),
          Text('No days in this split',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
          SizedBox(height: 8),
          Text('Tap the settings icon to add days',
              style: TextStyle(color: Colors.white24, fontSize: 13)),
        ]),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

List<WorkoutDay> _reorderFromToday(List<WorkoutDay> days, int today) {
  if (days.length < 2) return days;
  // If any day has no weekday assignment, keep original order
  if (days.any((d) => d.weekdays.isEmpty)) return days;
  final sorted = [...days];
  sorted.sort((a, b) {
    final aMin = a.weekdays.reduce((x, y) => x < y ? x : y);
    final bMin = b.weekdays.reduce((x, y) => x < y ? x : y);
    return ((aMin - today + 7) % 7).compareTo((bMin - today + 7) % 7);
  });
  return sorted;
}

String _weekdayStr(List<int> weekdays) {
  const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if (weekdays.isEmpty) return '';
  final sorted = [...weekdays]..sort();
  return sorted.map((d) => names[d]).join(' · ');
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
