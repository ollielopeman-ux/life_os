import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cardio_models.dart';
import '../models/plyo_models.dart';
import '../providers/cardio_provider.dart';
import '../providers/plyo_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../../shared/widgets/week_strip.dart';
import 'edit_cardio_screen.dart';

class CardioScreen extends ConsumerStatefulWidget {
  const CardioScreen({super.key});

  @override
  ConsumerState<CardioScreen> createState() => _CardioScreenState();
}

class _CardioScreenState extends ConsumerState<CardioScreen> {
  DateTime _weekStart = WeekStrip.mondayOf(DateTime.now());
  String _mode = 'cardio'; // 'cardio' or 'plyo'

  @override
  Widget build(BuildContext context) {
    final cardio = ref.watch(cardioProvider);
    final plyo = ref.watch(plyoProvider);
    final today = DateTime.now().weekday;

    final allTasks = ref.watch(scheduleProvider);
    final completedDates = allTasks
        .where((t) =>
            t.done &&
            (t.title.endsWith('· Cardio') || t.title.endsWith('· Plyo')))
        .map((t) => _dateKey(t.date))
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
                  Expanded(
                    child: Text(
                      _mode == 'cardio'
                          ? (cardio.selectedSplit?.name ?? 'Cardio')
                          : (plyo.selectedPlan?.name ?? 'Plyo'),
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white38),
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (_) => const EditCardioScreen()),
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
            const SizedBox(height: 16),

            // Mode toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'Cardio',
                      icon: Icons.directions_run_rounded,
                      selected: _mode == 'cardio',
                      onTap: () => setState(() => _mode = 'cardio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeButton(
                      label: 'Plyo',
                      icon: Icons.flash_on_rounded,
                      selected: _mode == 'plyo',
                      onTap: () => setState(() => _mode = 'plyo'),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _mode == 'cardio'
                  ? _CardioContent(
                      cardio: cardio,
                      today: today,
                    )
                  : _PlyoContent(
                      plyo: plyo,
                      today: today,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode Button ────────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1C1C1E) : const Color(0xFF171719),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF5B7FA8).withValues(alpha: 0.5)
                : const Color(0xFF242426),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF5B7FA8) : Colors.white24,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white38,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cardio Content ─────────────────────────────────────────────────────────────

class _CardioContent extends ConsumerWidget {
  final CardioState cardio;
  final int today;
  const _CardioContent({required this.cardio, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final split = cardio.selectedSplit;
    if (split == null) return _EmptyState(message: 'No cardio plans yet', sub: 'Tap the edit icon to get started');
    if (split.sessions.isEmpty) return _EmptyState(message: 'No sessions in this plan', sub: 'Tap the edit icon to add sessions');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: split.sessions.length,
      itemBuilder: (_, i) {
        final session = split.sessions[i];
        final isToday =
            session.weekdays.isNotEmpty && session.weekdays.contains(today);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SessionCard(
            session: session,
            isToday: isToday,
            onLog: () =>
                ref.read(cardioProvider.notifier).logSession(split.id, session),
          ),
        );
      },
    );
  }
}

// ── Plyo Content ───────────────────────────────────────────────────────────────

class _PlyoContent extends ConsumerWidget {
  final PlyoState plyo;
  final int today;
  const _PlyoContent({required this.plyo, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plyo.workouts.isEmpty) {
      return _EmptyState(
          message: 'No plyo workouts yet',
          sub: 'Tap the edit icon to create one');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: plyo.workouts.length,
      itemBuilder: (_, i) {
        final workout = plyo.workouts[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PlyoWorkoutCard(
            workout: workout,
            onLog: () =>
                ref.read(plyoProvider.notifier).logWorkout(workout),
          ),
        );
      },
    );
  }
}

class _PlyoWorkoutCard extends StatefulWidget {
  final PlyoWorkout workout;
  final VoidCallback onLog;
  const _PlyoWorkoutCard({required this.workout, required this.onLog});

  @override
  State<_PlyoWorkoutCard> createState() => _PlyoWorkoutCardState();
}

class _PlyoWorkoutCardState extends State<_PlyoWorkoutCard> {
  bool _justLogged = false;

  void _handleLog() {
    widget.onLog();
    setState(() => _justLogged = true);
    Future.delayed(const Duration(seconds: 3),
        () { if (mounted) setState(() => _justLogged = false); });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFF1C1C1E),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222226),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('⚡', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(w.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            w.exercises.isEmpty
                                ? 'No exercises — tap edit to add'
                                : w.exercises
                                    .map((e) => e.name)
                                    .join('  ·  '),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _handleLog,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 60,
                color: _justLogged
                    ? const Color(0xFF1E3555)
                    : const Color(0xFF5B7FA8),
                alignment: Alignment.center,
                child: _justLogged
                    ? const Icon(Icons.check,
                        color: Color(0xFF7FA8C8), size: 22)
                    : const Text('LOG',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session Card ───────────────────────────────────────────────────────────────

class _SessionCard extends StatefulWidget {
  final CardioSession session;
  final bool isToday;
  final VoidCallback onLog;
  const _SessionCard(
      {required this.session, required this.isToday, required this.onLog});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _justLogged = false;

  void _handleLog() {
    widget.onLog();
    setState(() => _justLogged = true);
    Future.delayed(const Duration(seconds: 3),
        () { if (mounted) setState(() => _justLogged = false); });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final subtitle = [
      if (s.distanceKm != null) '${s.distanceKm}km',
      if (s.durationMinutes != null) '${s.durationMinutes}min',
    ].join(' · ');

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isToday
              ? const Color(0xFF5B7FA8).withValues(alpha: 0.5)
              : const Color(0xFF2C2C2E),
          width: widget.isToday ? 1.5 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFF1C1C1E),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222226),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                          child: Text(_typeEmoji(s.type),
                              style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(s.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18)),
                              if (widget.isToday) ...[
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
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _IntensityBadge(s.intensity),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(subtitle,
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 12)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _handleLog,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 60,
                color: _justLogged
                    ? const Color(0xFF1E3555)
                    : const Color(0xFF5B7FA8),
                alignment: Alignment.center,
                child: _justLogged
                    ? const Icon(Icons.check,
                        color: Color(0xFF7FA8C8), size: 22)
                    : const Text('LOG',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntensityBadge extends StatelessWidget {
  final String intensity;
  const _IntensityBadge(this.intensity);

  @override
  Widget build(BuildContext context) {
    final color = switch (intensity) {
      'Easy' => const Color(0xFF4CAF50),
      'Moderate' => const Color(0xFFFF9800),
      'Hard' => const Color(0xFFFF5252),
      'Race Pace' => const Color(0xFFE040FB),
      _ => Colors.white38,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(intensity,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final String sub;
  const _EmptyState({required this.message, required this.sub});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.directions_run, size: 52, color: Colors.white12),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          Text(sub,
              style: const TextStyle(color: Colors.white24, fontSize: 13)),
        ]),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _typeEmoji(String type) => switch (type) {
      'Running' => '🏃',
      'Cycling' => '🚴',
      'Swimming' => '🏊',
      'Rowing' => '🚣',
      'Walking' => '🚶',
      'HIIT' => '⚡',
      _ => '💪',
    };

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
