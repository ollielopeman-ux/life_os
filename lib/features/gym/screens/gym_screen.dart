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

enum _CardState { completed, upNext, scheduled }

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

    // Completed gym workout dates → rating colour for week strip
    final allTasks = ref.watch(scheduleProvider);
    final completedDates = Map.fromEntries(
      allTasks.where((t) => t.done && t.title.endsWith('· Gym')).map((t) {
        final rating = t.workoutData?['rating'] as String?;
        final color = switch (rating) {
          'red' => const Color(0xFFFF453A),
          'yellow' => const Color(0xFFFF9F0A),
          'green' => const Color(0xFF34C759),
          _ => const Color(0xFF5B7FA8),
        };
        return MapEntry(_dateKey(t.date), color);
      }),
    );

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
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).push(
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
            const SizedBox(height: 8),

            // Resume banner (when workout paused)
            _ResumeBanner(),

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

    // Assign states — first non-done non-rest day is "up next"
    bool foundUpNext = false;
    final infos = sorted.map((d) {
      final done = isDone(d);
      final _CardState state;
      if (done) {
        state = _CardState.completed;
      } else if (!foundUpNext && !d.isRestDay && d.exercises.isNotEmpty) {
        state = _CardState.upNext;
        foundUpNext = true;
      } else {
        state = _CardState.scheduled;
      }
      return (day: d, state: state, label: _dayAbbr(d, today));
    }).toList();

    // Split into "this week" (weekday >= today) and "next week" (weekday < today)
    final thisWeek = infos
        .where((i) =>
            i.day.weekdays.isEmpty || i.day.weekdays.any((w) => w >= today))
        .toList();
    final nextWeek = infos
        .where((i) =>
            i.day.weekdays.isNotEmpty && i.day.weekdays.every((w) => w < today))
        .toList();

    final children = <Widget>[];

    if (thisWeek.isNotEmpty) {
      children.add(const _SectionLabel('THIS WEEK'));
      for (final info in thisWeek) {
        children.add(_WorkoutCard(
          day: info.day,
          state: info.state,
          dayLabel: info.label,
          onTap: tapFor(info.day),
        ));
      }
    }

    if (nextWeek.isNotEmpty) {
      children.add(const SizedBox(height: 4));
      children.add(const _SectionLabel('NEXT WEEK'));
      for (int i = 0; i < nextWeek.length; i += 2) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _GridWorkoutCard(
                  day: nextWeek[i].day,
                  state: nextWeek[i].state,
                  dayLabel: nextWeek[i].label,
                  onTap: tapFor(nextWeek[i].day),
                ),
              ),
              if (i + 1 < nextWeek.length) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _GridWorkoutCard(
                    day: nextWeek[i + 1].day,
                    state: nextWeek[i + 1].state,
                    dayLabel: nextWeek[i + 1].label,
                    onTap: tapFor(nextWeek[i + 1].day),
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 0, 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── Full-width Workout Card (This Week) ────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final WorkoutDay day;
  final _CardState state;
  final String dayLabel;
  final VoidCallback? onTap;
  const _WorkoutCard({
    required this.day,
    required this.state,
    required this.dayLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRest = day.isRestDay;
    final hasExercises = day.exercises.isNotEmpty;

    final cardBg = switch (state) {
      _CardState.completed => const Color(0xFF111316),
      _CardState.upNext => const Color(0xFF13192A),
      _CardState.scheduled => const Color(0xFF161618),
    };

    final borderColor = switch (state) {
      _CardState.completed => const Color(0xFF1E2026),
      _CardState.upNext => const Color(0xFF2A4068),
      _CardState.scheduled => const Color(0xFF242426),
    };

    final labelColor = switch (state) {
      _CardState.completed => const Color(0xFF34C759),
      _CardState.upNext => const Color(0xFF5B7FA8),
      _CardState.scheduled => Colors.white30,
    };

    final labelText = switch (state) {
      _CardState.completed => 'COMPLETED · $dayLabel',
      _CardState.upNext => 'UP NEXT · $dayLabel',
      _CardState.scheduled => 'SCHEDULED · $dayLabel',
    };

    final nameColor = switch (state) {
      _CardState.completed => Colors.white38,
      _CardState.upNext => Colors.white,
      _CardState.scheduled => Colors.white54,
    };

    final subtitleColor = switch (state) {
      _CardState.completed => Colors.white24,
      _ => Colors.white38,
    };

    final subtitle = isRest
        ? 'Rest & Recovery'
        : !hasExercises
            ? 'No exercises added yet'
            : state == _CardState.upNext
                ? '${day.exercises.first.name}${day.exercises.length > 1 ? '  ·  +${day.exercises.length - 1} more' : ''}'
                : '${day.exercises.length} exercise${day.exercises.length == 1 ? '' : 's'}';

    final Widget btn = switch (state) {
      _CardState.completed => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3526),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF34C759), size: 22),
        ),
      _CardState.upNext => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7FA8).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isRest ? Icons.bedtime_outlined : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      _CardState.scheduled => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF242428),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isRest ? Icons.bedtime_outlined : Icons.play_arrow_rounded,
            color: Colors.white24,
            size: 22,
          ),
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    day.name,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            btn,
          ],
        ),
      ),
    );
  }
}

// ── Compact Grid Card (Next Week) ──────────────────────────────────────────────

class _GridWorkoutCard extends StatelessWidget {
  final WorkoutDay day;
  final _CardState state;
  final String dayLabel;
  final VoidCallback? onTap;
  const _GridWorkoutCard({
    required this.day,
    required this.state,
    required this.dayLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRest = day.isRestDay;
    final isDone = state == _CardState.completed;
    final muted = isDone || isRest;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: muted ? const Color(0xFF111316) : const Color(0xFF161618),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: muted ? const Color(0xFF1E2026) : const Color(0xFF242426),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      color: muted ? Colors.white24 : Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.name,
                    style: TextStyle(
                      color: muted ? Colors.white30 : Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isDone
                  ? Icons.check_rounded
                  : isRest
                      ? Icons.bedtime_outlined
                      : Icons.play_arrow_rounded,
              color: muted ? Colors.white24 : Colors.white30,
              size: 18,
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
  if (days.any((d) => d.weekdays.isEmpty)) return days;
  final sorted = [...days];
  sorted.sort((a, b) {
    final aMin = a.weekdays.reduce((x, y) => x < y ? x : y);
    final bMin = b.weekdays.reduce((x, y) => x < y ? x : y);
    return ((aMin - today + 7) % 7).compareTo((bMin - today + 7) % 7);
  });
  return sorted;
}

String _dayAbbr(WorkoutDay d, int today) {
  const abbrs = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  if (d.weekdays.isEmpty) return '';
  final sorted = [...d.weekdays]..sort();
  final thisWeek = sorted.where((w) => w >= today).toList();
  final wd = thisWeek.isNotEmpty ? thisWeek.first : sorted.first;
  return abbrs[wd];
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
