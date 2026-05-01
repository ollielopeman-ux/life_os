import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/checklist_provider.dart';
import '../models/checklist_item.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../gym/providers/gym_provider.dart';
import '../../gym/providers/active_workout_provider.dart';
import '../../gym/screens/active_workout_screen.dart';
import '../../gym/models/gym_models.dart';
import '../../body/providers/body_provider.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  late DateTime _weekStart;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _weekStart = _monday(_selected);
  }

  static DateTime _monday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(checklistProvider);
    final allTasks = ref.watch(scheduleProvider);

    final items = allItems
        .where((i) =>
            i.date.year == _selected.year &&
            i.date.month == _selected.month &&
            i.date.day == _selected.day)
        .toList()
      ..sort((a, b) {
        if (a.time == null && b.time == null) return 0;
        if (a.time == null) return 1;
        if (b.time == null) return -1;
        return a.time!.compareTo(b.time!);
      });

    final itemTitles = items.map((i) => i.title.toLowerCase()).toSet();

    final dayTasks = allTasks
        .where((t) =>
            t.date.year == _selected.year &&
            t.date.month == _selected.month &&
            t.date.day == _selected.day)
        .toList();

    final hasGym = dayTasks.any((t) => t.isWorkout);
    final gymDoneToday = dayTasks.any((t) => t.isWorkout && t.done);
    final hasCardio = dayTasks.any((t) => t.title.endsWith('· Cardio'));

    final gym = ref.watch(gymProvider);
    final bodyEntries = ref.watch(bodyProvider);
    final todayNormalized =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isViewingToday = _selected == todayNormalized;
    WorkoutDay? todayGymDay;
    if (isViewingToday && gym.selectedSplit != null) {
      final matches = gym.selectedSplit!.days.where((d) =>
          !d.isRestDay &&
          d.exercises.isNotEmpty &&
          d.weekdays.contains(DateTime.now().weekday));
      if (matches.isNotEmpty) todayGymDay = matches.first;
    }
    final showGymCard = todayGymDay != null && !gymDoneToday;
    final hasReading = dayTasks.any((t) =>
        t.title.startsWith('Started:') || t.title.startsWith('Finished:'));

    // Auto-completed items derived from the selected day's activity
    final autoItems = <_AutoItem>[];
    for (final t in dayTasks.where((t) => t.isWorkout && t.done)) {
      autoItems.add(_AutoItem(
        label: t.title.replaceAll(' · Gym', '').trim(),
        icon: Icons.fitness_center,
        color: const Color(0xFF5B7FA8),
      ));
    }
    for (final t in dayTasks.where((t) => t.done && t.title.endsWith('· Cardio'))) {
      autoItems.add(_AutoItem(
        label: t.title.replaceAll(' · Cardio', '').trim(),
        icon: Icons.directions_run,
        color: const Color(0xFFE07B54),
      ));
    }
    for (final t in dayTasks.where((t) => t.done && t.title.endsWith('· Plyo'))) {
      autoItems.add(_AutoItem(
        label: t.title.replaceAll(' · Plyo', '').trim(),
        icon: Icons.flash_on_rounded,
        color: const Color(0xFF9B7FD4),
      ));
    }
    final weightToday = bodyEntries.any((e) =>
        e.date.year == _selected.year &&
        e.date.month == _selected.month &&
        e.date.day == _selected.day &&
        e.weight != null);
    if (weightToday) {
      autoItems.add(const _AutoItem(
        label: 'Weight logged',
        icon: Icons.monitor_weight_outlined,
        color: Color(0xFF34C759),
      ));
    }
    for (final t in dayTasks.where((t) => t.done &&
        (t.title.startsWith('Started:') || t.title.startsWith('Finished:')))) {
      autoItems.add(_AutoItem(
        label: t.title,
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF9B7FD4),
      ));
    }

    // Recents: up to 3 unique titles from past days not already in today's list
    final recentItems = <String>[];
    {
      final seenLower = {...itemTitles};
      final sorted = [...allItems]..sort((a, b) => b.date.compareTo(a.date));
      for (final item in sorted) {
        if (item.date.year == _selected.year &&
            item.date.month == _selected.month &&
            item.date.day == _selected.day) { continue; }
        final lower = item.title.toLowerCase();
        if (!seenLower.contains(lower)) {
          seenLower.add(lower);
          recentItems.add(item.title);
          if (recentItems.length >= 3) break;
        }
      }
    }

    final suggestions = <_Suggestion>[];
    if (!hasGym && !itemTitles.contains('gym') && !showGymCard) {
      suggestions.add(const _Suggestion(
          'Gym', Icons.fitness_center, Color(0xFF5B7FA8)));
    }
    if (!hasCardio && !itemTitles.contains('cardio')) {
      suggestions.add(const _Suggestion(
          'Cardio', Icons.directions_run, Color(0xFFE07B54)));
    }
    if (!hasReading && !itemTitles.contains('reading')) {
      suggestions.add(const _Suggestion(
          'Reading', Icons.menu_book_rounded, Color(0xFF9B7FD4)));
    }
    for (final s in [
      const _Suggestion('Journal', Icons.edit_note_rounded, Colors.white54),
      const _Suggestion(
          'Walk', Icons.directions_walk, Colors.white54),
      const _Suggestion(
          'Meditate', Icons.self_improvement, Colors.white54),
    ]) {
      if (!itemTitles.contains(s.label.toLowerCase())) {
        suggestions.add(s);
      }
    }

    final weekDays =
        List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('CHECKLIST',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5)),
                    if (items.isNotEmpty)
                      Positioned(
                        right: 0,
                        child: Text(
                          '${items.where((i) => i.done).length}/${items.length}',
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _WeekCard(
                weekStart: _weekStart,
                days: weekDays,
                selected: _selected,
                onPrev: () => setState(() {
                  _weekStart =
                      _weekStart.subtract(const Duration(days: 7));
                  _selected = _weekStart;
                }),
                onNext: () => setState(() {
                  _weekStart = _weekStart.add(const Duration(days: 7));
                  _selected = _weekStart;
                }),
                onDayTap: (d) => setState(() => _selected = d),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                children: [
                  if (autoItems.isNotEmpty) ...[
                    ...autoItems.map((a) => _AutoTile(item: a)),
                    const SizedBox(height: 8),
                  ],
                  if (items.isEmpty &&
                      suggestions.isEmpty &&
                      !showGymCard &&
                      recentItems.isEmpty)
                    const _EmptyState()
                  else ...[
                    ...items.map((item) => _ChecklistTile(item: item)),

                    // ── QUICK ADD ───────────────────────────────────────────
                    if (showGymCard || suggestions.isNotEmpty) ...[
                      SizedBox(height: items.isEmpty ? 0 : 24),
                      const Text(
                        'QUICK ADD',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (showGymCard) ...[
                        _WorkoutQuickCard(
                          day: todayGymDay,
                          splitId: gym.selectedSplit!.id,
                        ),
                        if (suggestions.isNotEmpty)
                          const SizedBox(height: 8),
                      ],
                      if (suggestions.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: suggestions
                              .map((s) => _SuggestionChip(
                                    suggestion: s,
                                    onTap: () => ref
                                        .read(checklistProvider.notifier)
                                        .addItem(s.label, _selected),
                                  ))
                              .toList(),
                        ),
                    ],

                    // ── RECENTS ─────────────────────────────────────────────
                    if (recentItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'RECENTS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentItems
                            .map((title) => _RecentChip(
                                  title: title,
                                  onTap: () => ref
                                      .read(checklistProvider.notifier)
                                      .addItem(title, _selected),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week Card ─────────────────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  final DateTime weekStart;
  final List<DateTime> days;
  final DateTime selected;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDayTap;

  const _WeekCard({
    required this.weekStart,
    required this.days,
    required this.selected,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final end = weekStart.add(const Duration(days: 6));
    final label =
        '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM').format(end)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
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
                  label,
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
          const SizedBox(height: 8),
          Row(
            children: days
                .map((d) => Expanded(
                      child: _DayCell(
                        day: d,
                        isSelected: d.year == selected.year &&
                            d.month == selected.month &&
                            d.day == selected.day,
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

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell(
      {required this.day, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDay = DateTime(day.year, day.month, day.day);
    final isToday = thisDay == today;
    final isPast = thisDay.isBefore(today);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 38,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF5B7FA8)
                  : Colors.transparent,
            ),
            child: Center(
              child: isSelected && isToday
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: (isToday || isSelected)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? const Color(0xFF5B7FA8)
                                : isPast
                                    ? Colors.white70
                                    : Colors.white30,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Checklist Tile ────────────────────────────────────────────────────────────

class _ChecklistTile extends ConsumerWidget {
  final ChecklistItem item;
  const _ChecklistTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () =>
            ref.read(checklistProvider.notifier).toggleItem(item.id),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2C2C2E)),
          ),
          child: Row(
            children: [
              _CheckCircle(done: item.done),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: item.done ? Colors.white38 : Colors.white,
                        fontSize: 15,
                        decoration: item.done
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.white24,
                      ),
                    ),
                    if (item.formattedTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11,
                              color: Color(0xFF5B7FA8)),
                          const SizedBox(width: 3),
                          Text(
                            item.formattedTime!,
                            style: const TextStyle(
                                color: Color(0xFF5B7FA8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ref
                    .read(checklistProvider.notifier)
                    .deleteItem(item.id),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline,
                      size: 18, color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  final bool done;
  const _CheckCircle({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? const Color(0xFF5B7FA8) : Colors.white24,
          width: 2,
        ),
        color: done ? const Color(0xFF5B7FA8) : Colors.transparent,
      ),
      child: done
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

// ── Suggestion Chip ───────────────────────────────────────────────────────────

class _Suggestion {
  final String label;
  final IconData icon;
  final Color color;
  const _Suggestion(this.label, this.icon, this.color);
}

class _SuggestionChip extends StatelessWidget {
  final _Suggestion suggestion;
  final VoidCallback onTap;
  const _SuggestionChip({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(suggestion.icon, size: 16, color: suggestion.color),
            const SizedBox(width: 6),
            Text(
              suggestion.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Chip ───────────────────────────────────────────────────────────────

class _RecentChip extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _RecentChip({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Workout Quick Card ────────────────────────────────────────────────────────

class _WorkoutQuickCard extends ConsumerWidget {
  final WorkoutDay day;
  final String splitId;
  const _WorkoutQuickCard({required this.day, required this.splitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: GestureDetector(
        onTap: () {
          ref.read(activeWorkoutProvider.notifier).startWorkout(splitId, day);
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF5B7FA8).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B7FA8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TODAY'S WORKOUT",
                        style: TextStyle(
                            color: Color(0xFF5B7FA8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 2),
                    Text(day.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    if (day.exercises.isNotEmpty)
                      Text(
                        day.exercises.map((e) => e.name).join('  ·  '),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFF5B7FA8), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Auto Item & Tile ──────────────────────────────────────────────────────────

class _AutoItem {
  final String label;
  final IconData icon;
  final Color color;
  const _AutoItem({required this.label, required this.icon, required this.color});
}

class _AutoTile extends StatelessWidget {
  final _AutoItem item;
  const _AutoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color,
              ),
              child: const Icon(Icons.check, size: 13, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Icon(item.icon, size: 15, color: item.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: item.color.withValues(alpha: 0.7),
                  fontSize: 15,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: item.color.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.checklist_rounded, size: 44, color: Colors.white12),
            SizedBox(height: 12),
            Text('Nothing here yet',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

