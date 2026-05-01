import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cardio_models.dart';
import '../models/plyo_models.dart';
import '../providers/cardio_provider.dart';
import '../providers/plyo_provider.dart';
import '../providers/active_plyo_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../../shared/widgets/week_strip.dart';
import '../../../shared/services/location_service.dart';
import 'edit_cardio_screen.dart';
import 'active_plyo_screen.dart';
import 'interval_timer_screen.dart';

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
    final completedDates = Map.fromEntries(
      allTasks
          .where((t) =>
              t.done &&
              (t.title.endsWith('· Cardio') || t.title.endsWith('· Plyo')))
          .map((t) => MapEntry(_dateKey(t.date), const Color(0xFF5B7FA8))),
    );

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
                  Expanded(
                    child: Text(
                      _mode == 'cardio'
                          ? (cardio.selectedSplit?.name ?? 'Cardio')
                          : 'Plyo',
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.timer_outlined, color: Colors.white38),
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          builder: (_) => const IntervalTimerScreen()),
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

typedef _LogCallback = void Function({String? rating, String? location});

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
          padding: const EdgeInsets.only(bottom: 6),
          child: _SessionCard(
            session: session,
            isToday: isToday,
            onLog: ({rating, location}) => ref
                .read(cardioProvider.notifier)
                .logSession(split.id, session, rating: rating, location: location),
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
          padding: const EdgeInsets.only(bottom: 6),
          child: _PlyoWorkoutCard(workout: workout),
        );
      },
    );
  }
}

class _PlyoWorkoutCard extends ConsumerWidget {
  final PlyoWorkout workout;
  const _PlyoWorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = workout;
    final subtitle = w.exercises.isEmpty
        ? 'No exercises — tap edit to add'
        : '${w.exercises.first.name}${w.exercises.length > 1 ? '  ·  +${w.exercises.length - 1} more' : ''}';

    return GestureDetector(
      onTap: () {
        ref.read(activePlyoProvider.notifier).startWorkout(w);
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => const ActivePlyoScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF242426), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PLYO',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(w.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF242428),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.flash_on_rounded,
                  color: Colors.white38, size: 22),
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
  final _LogCallback onLog;
  const _SessionCard(
      {required this.session, required this.isToday, required this.onLog});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _justLogged = false;

  Future<void> _handleLog() async {
    final res = await showDialog<({String? rating, String? location})>(
      context: context,
      builder: (_) => const _CardioLogDialog(),
    );
    if (!mounted) return;
    widget.onLog(rating: res?.rating, location: res?.location);
    setState(() => _justLogged = true);
    Future.delayed(const Duration(seconds: 3),
        () { if (mounted) setState(() => _justLogged = false); });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final isToday = widget.isToday;
    final subtitle = [
      if (s.distanceKm != null) '${s.distanceKm} km',
      if (s.durationMinutes != null) '${s.durationMinutes} min',
    ].join('  ·  ');

    const weekdays = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dayAbbr = s.weekdays.isNotEmpty ? weekdays[s.weekdays.first] : '';
    final labelText = isToday ? 'TODAY · $dayAbbr' : dayAbbr;
    final labelColor = isToday ? const Color(0xFF5B7FA8) : Colors.white30;
    final cardBg = isToday ? const Color(0xFF13192A) : const Color(0xFF161618);
    final borderColor = isToday
        ? const Color(0xFF2A4068)
        : const Color(0xFF242426);

    return GestureDetector(
      onTap: _handleLog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: _justLogged ? const Color(0xFF1A3526) : cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _justLogged
                ? const Color(0xFF34C759).withValues(alpha: 0.4)
                : borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (labelText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        labelText,
                        style: TextStyle(
                          color: _justLogged
                              ? const Color(0xFF34C759)
                              : labelColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  Text(
                    s.name,
                    style: TextStyle(
                      color: _justLogged ? Colors.white54 : Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
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
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _justLogged
                    ? const Color(0xFF1A3526)
                    : isToday
                        ? const Color(0xFF5B7FA8)
                        : const Color(0xFF242428),
                borderRadius: BorderRadius.circular(14),
                border: _justLogged
                    ? Border.all(
                        color: const Color(0xFF34C759).withValues(alpha: 0.5))
                    : null,
              ),
              child: Icon(
                _justLogged ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: _justLogged
                    ? const Color(0xFF34C759)
                    : isToday
                        ? Colors.white
                        : Colors.white24,
                size: 22,
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

// ── Cardio / Plyo Log Dialog ──────────────────────────────────────────────────

class _CardioLogDialog extends StatefulWidget {
  const _CardioLogDialog();
  @override
  State<_CardioLogDialog> createState() => _CardioLogDialogState();
}

class _CardioLogDialogState extends State<_CardioLogDialog> {
  String? _rating;
  String? _location;
  bool _locLoading = true;

  @override
  void initState() {
    super.initState();
    LocationService.fetchPlaceName().then((v) {
      if (mounted) setState(() { _location = v; _locLoading = false; });
    });
  }

  void _submit() => Navigator.pop(context, (rating: _rating, location: _location));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was it?',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LogRatingBtn(icon: Icons.sentiment_very_dissatisfied,
                    color: const Color(0xFFFF453A), selected: _rating == 'red',
                    onTap: () => setState(() => _rating = _rating == 'red' ? null : 'red')),
                _LogRatingBtn(icon: Icons.sentiment_neutral,
                    color: const Color(0xFFFF9F0A), selected: _rating == 'yellow',
                    onTap: () => setState(() => _rating = _rating == 'yellow' ? null : 'yellow')),
                _LogRatingBtn(icon: Icons.sentiment_very_satisfied,
                    color: const Color(0xFF34C759), selected: _rating == 'green',
                    onTap: () => setState(() => _rating = _rating == 'green' ? null : 'green')),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  _locLoading
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38))
                      : Text(
                          _location ?? 'Location unavailable',
                          style: TextStyle(
                            color: _location != null ? Colors.white70 : Colors.white24,
                            fontSize: 13),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('Save',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogRatingBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _LogRatingBtn({
    required this.icon, required this.color,
    required this.onTap, this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.22 : 0.1),
          shape: BoxShape.circle,
          border: Border.all(
              color: color.withValues(alpha: selected ? 0.9 : 0.3),
              width: selected ? 2.5 : 1.5),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
