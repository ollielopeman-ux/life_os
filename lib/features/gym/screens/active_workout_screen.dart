import 'dart:async';
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/active_workout_provider.dart';
import '../models/gym_models.dart';
import '../../../shared/services/location_service.dart';
import '../../settings/providers/settings_provider.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late final Stopwatch _stopwatch;
  Timer? _ticker;
  int _restSecondsLeft = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    final seconds = ref.read(settingsProvider).restTimerSeconds;
    if (seconds == 0) return;
    setState(() => _restSecondsLeft = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _restSecondsLeft--;
        if (_restSecondsLeft <= 0) {
          _restSecondsLeft = 0;
          _restTimer?.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restSecondsLeft = 0);
  }

  String get _restLabel {
    final m = (_restSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_restSecondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _elapsed {
    final e = _stopwatch.elapsed;
    final m = e.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = e.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<({String? rating, String? location})?> _askRating() {
    final workout = ref.read(activeWorkoutProvider);
    double totalWeight = 0;
    int newPrs = 0;

    if (workout != null) {
      for (final ex in workout.day.exercises) {
        final sets = workout.setsFor(ex.name);
        for (final s in sets) {
          totalWeight += s.weight * s.reps;
        }
        if (sets.isNotEmpty) {
          final sessionBest = sets.reduce((a, b) =>
              a.weight > b.weight ||
                      (a.weight == b.weight && a.reps >= b.reps)
                  ? a
                  : b);
          if (ex.history.isNotEmpty) {
            final histBest = ex.history.reduce((a, b) =>
                a.weight > b.weight ||
                        (a.weight == b.weight && a.reps >= b.reps)
                    ? a
                    : b);
            if (sessionBest.weight > histBest.weight ||
                (sessionBest.weight == histBest.weight &&
                    sessionBest.reps > histBest.reps)) {
              newPrs++;
            }
          } else {
            newPrs++;
          }
        }
      }
    }

    return showDialog<({String? rating, String? location})>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RatingDialog(
        elapsed: _elapsed,
        totalWeightKg: totalWeight > 0 ? totalWeight : null,
        newPrCount: newPrs,
      ),
    );
  }

  // X button menu — tap outside to dismiss
  void _showCancelSheet() {
    final workout = ref.read(activeWorkoutProvider);
    final isLast = workout?.isLastExercise ?? false;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dlgCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLast) ...[
                _OptionTile(
                  icon: Icons.check_circle_outline,
                  label: 'End Workout',
                  subtitle: 'Save and finish',
                  color: const Color(0xFF5B7FA8),
                  onTap: () async {
                    Navigator.of(dlgCtx).pop();
                    final res = await _askRating();
                    if (!mounted) return;
                    ref.read(activeWorkoutProvider.notifier).endWorkout(
                      rating: res?.rating, location: res?.location,
                      durationMinutes: _stopwatch.elapsed.inMinutes,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(color: Color(0xFF2C2C2E), height: 1),
              ] else ...[
                _OptionTile(
                  icon: Icons.flag_outlined,
                  label: 'Finish Early',
                  subtitle: 'Save progress so far',
                  color: const Color(0xFF5B7FA8),
                  onTap: () async {
                    Navigator.of(dlgCtx).pop();
                    final res = await _askRating();
                    if (!mounted) return;
                    ref.read(activeWorkoutProvider.notifier).endWorkout(
                      rating: res?.rating, location: res?.location,
                      durationMinutes: _stopwatch.elapsed.inMinutes,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(color: Color(0xFF2C2C2E), height: 1),
              ],
              _OptionTile(
                icon: Icons.pause_circle_outline,
                label: 'Pause',
                subtitle: 'Your sets are saved — resume anytime',
                onTap: () {
                  Navigator.of(dlgCtx).pop();
                  Navigator.of(context).pop();
                },
              ),
              const Divider(color: Color(0xFF2C2C2E), height: 1),
              _OptionTile(
                icon: Icons.delete_outline,
                label: 'Delete Workout',
                subtitle: 'Abandon without saving',
                color: const Color(0xFFFF6B6B),
                onTap: () {
                  ref.read(activeWorkoutProvider.notifier).abandon();
                  Navigator.of(dlgCtx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // END button: Save options
  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _OptionTile(
              icon: Icons.close,
              label: 'Cancel',
              subtitle: 'Keep going',
              onTap: () => Navigator.of(sheetCtx).pop(),
            ),
            const Divider(color: Color(0xFF2C2C2E), height: 1),
            _OptionTile(
              icon: Icons.pause_circle_outline,
              label: 'Pause',
              subtitle: 'Your sets are saved — resume anytime',
              onTap: () {
                Navigator.of(sheetCtx).pop();
                Navigator.of(context).pop();
              },
            ),
            const Divider(color: Color(0xFF2C2C2E), height: 1),
            _OptionTile(
              icon: Icons.check_circle_outline,
              label: 'Save & End',
              subtitle: 'Finish and save all logged sets',
              color: const Color(0xFF5B7FA8),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final res = await _askRating();
                if (!mounted) return;
                ref.read(activeWorkoutProvider.notifier).endWorkout(
                  rating: res?.rating, location: res?.location,
                  durationMinutes: _stopwatch.elapsed.inMinutes,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _customWeightDialog(double current) async {
    final ctrl = TextEditingController(text: _fmtW(current));
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _InputDialog(
        title: 'Custom Weight (kg)',
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
    if (result != null && mounted) {
      ref.read(activeWorkoutProvider.notifier).selectWeight(result);
    }
  }

  Future<void> _customRepsDialog(int current) async {
    final ctrl = TextEditingController(text: '$current');
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _InputDialog(
        title: 'Custom Reps',
        controller: ctrl,
        keyboardType: TextInputType.number,
      ),
    );
    if (result != null && mounted) {
      ref.read(activeWorkoutProvider.notifier).selectReps(result.toInt());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final workout = ref.watch(activeWorkoutProvider);

    // Null only if something unexpected happened — show blank, no auto-pop
    // (auto-pop caused double-pop crash; all exits are explicit via _showOptionsSheet)
    if (workout == null) {
      return const Scaffold();
    }

    final exercise = workout.currentExercise;
    final exercises = workout.day.exercises;
    final idx = workout.currentIndex;
    final sessionSets = workout.setsFor(exercise.name);

    const repOptions = [5, 6, 8, 10, 12, 15];

    final allSetsForPR = [...exercise.history, ...sessionSets];
    final prSet = allSetsForPR.isNotEmpty
        ? allSetsForPR.reduce((a, b) =>
            a.weight > b.weight ||
                    (a.weight == b.weight && a.reps >= b.reps)
                ? a
                : b)
        : null;

    final step = ref.watch(settingsProvider.select((s) => s.weightStep));
    final weightOptions = [
      exercise.usualWeight - step * 2,
      exercise.usualWeight - step,
      exercise.usualWeight,
      exercise.usualWeight + step,
      exercise.usualWeight + step * 2,
    ].where((w) => w >= 0).toList();
    // Gold "PR challenge" button: PR weight + 2.5kg (before Custom)
    final prChallengeWeight = prSet != null ? prSet.weight + 2.5 : null;

    final wRow1 = weightOptions.take(4).toList();
    final wRow2 = weightOptions.skip(4).toList();
    const rRow1 = [5, 6, 8, 10];
    const rRow2 = [12, 15];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelSheet();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(4, 10, 16, 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF222226))),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: _showCancelSheet,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            workout.day.name,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _elapsed,
                            style: TextStyle(
                                color: accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Navigation row ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF222226))),
                ),
                child: Row(
                  children: [
                    _NavBtn(
                      icon: Icons.chevron_left,
                      enabled: idx > 0,
                      onTap: () =>
                          ref.read(activeWorkoutProvider.notifier).prevExercise(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: workout.isLastExercise
                            ? const Text('Last exercise',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('NEXT',
                                      style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 9,
                                          letterSpacing: 1.2)),
                                  const SizedBox(height: 2),
                                  Text(
                                    idx + 2 < exercises.length
                                        ? '${exercises[idx + 1].name}  ·  ${exercises[idx + 2].name}'
                                        : exercises[idx + 1].name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    workout.isLastExercise
                        ? GestureDetector(
                            onTap: _showOptionsSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text('END',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 0.5)),
                            ),
                          )
                        : _NavBtn(
                            icon: Icons.chevron_right,
                            enabled: true,
                            onTap: () => ref
                                .read(activeWorkoutProvider.notifier)
                                .nextExercise(),
                          ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        exercise.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.usualSets} sets · ${exercise.usualReps} reps',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 10),

                      if (prSet != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0x22D4AF37), Color(0x0EFFE066)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFD4AF37)
                                    .withValues(alpha: 0.6),
                                width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: Color(0xFFD4AF37), size: 13),
                              const SizedBox(width: 5),
                              Text(
                                'PR  ${_fmtW(prSet.weight)}kg × ${prSet.reps}',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (sessionSets.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: sessionSets
                              .map((s) =>
                                  _Chip('${_fmtW(s.weight)}kg × ${s.reps}'))
                              .toList(),
                        ),

                      const SizedBox(height: 28),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: const _Label('WEIGHT (KG)'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final w in wRow1)
                            Expanded(
                              child: _GridBtn(
                                label: _fmtW(w),
                                selected: workout.selectedWeight == w,
                                onTap: () => ref
                                    .read(activeWorkoutProvider.notifier)
                                    .selectWeight(w),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final w in wRow2)
                            Expanded(
                              child: _GridBtn(
                                label: _fmtW(w),
                                selected: workout.selectedWeight == w,
                                onTap: () => ref
                                    .read(activeWorkoutProvider.notifier)
                                    .selectWeight(w),
                              ),
                            ),
                          if (prChallengeWeight != null)
                            Expanded(
                              child: _GridBtn(
                                label: _fmtW(prChallengeWeight),
                                selected: workout.selectedWeight ==
                                    prChallengeWeight,
                                special: true,
                                onTap: () => ref
                                    .read(activeWorkoutProvider.notifier)
                                    .selectWeight(prChallengeWeight),
                              ),
                            ),
                          Expanded(
                            flex: 2,
                            child: _GridBtn(
                              label: 'Custom',
                              selected: !weightOptions
                                      .contains(workout.selectedWeight) &&
                                  workout.selectedWeight != prChallengeWeight,
                              onTap: () =>
                                  _customWeightDialog(workout.selectedWeight),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: const _Label('REPS'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final r in rRow1)
                            Expanded(
                              child: _GridBtn(
                                label: '$r',
                                selected: workout.selectedReps == r,
                                onTap: () => ref
                                    .read(activeWorkoutProvider.notifier)
                                    .selectReps(r),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final r in rRow2)
                            Expanded(
                              child: _GridBtn(
                                label: '$r',
                                selected: workout.selectedReps == r,
                                onTap: () => ref
                                    .read(activeWorkoutProvider.notifier)
                                    .selectReps(r),
                              ),
                            ),
                          Expanded(
                            flex: 2,
                            child: _GridBtn(
                              label: 'Custom',
                              selected: !repOptions.contains(workout.selectedReps),
                              onTap: () => _customRepsDialog(workout.selectedReps),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      _ExerciseHistory(
                          exercise: exercise, sessionSets: sessionSets),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Rest timer banner ────────────────────────────────────────────
              if (_restSecondsLeft > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2E1C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF34C759), size: 18),
                      const SizedBox(width: 10),
                      const Text('Rest', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(
                        _restLabel,
                        style: const TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _skipRest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.3)),
                          ),
                          child: const Text('Skip',
                              style: TextStyle(
                                  color: Color(0xFF34C759),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── LOG SET button ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
                child: GestureDetector(
                  onTap: () {
                    ref.read(activeWorkoutProvider.notifier).logSet();
                    _startRestTimer();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'LOG SET  ·  ${_fmtW(workout.selectedWeight)}kg × ${workout.selectedReps}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Options sheet tile ─────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise history graph ─────────────────────────────────────────────────────

class _ExerciseHistory extends StatelessWidget {
  final ExerciseTemplate exercise;
  final List<SetEntry> sessionSets;
  const _ExerciseHistory({required this.exercise, required this.sessionSets});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final allSets = [...exercise.history, ...sessionSets]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (allSets.isEmpty) return const SizedBox();

    final byDay = <String, double>{};
    for (final s in allSets) {
      final key =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      if (!byDay.containsKey(key) || s.weight > byDay[key]!) {
        byDay[key] = s.weight;
      }
    }
    final sortedKeys = byDay.keys.toList()..sort();
    final spots = List.generate(
        sortedKeys.length, (i) => FlSpot(i.toDouble(), byDay[sortedKeys[i]]!));

    if (spots.length < 2) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minY: (spots.map((s) => s.y).reduce(min) - 5).clamp(0, double.infinity),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accent,
                    barWidth: 2,
                    dotData: FlDotData(show: spots.length <= 20),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

String _fmtW(double w) => w % 1 == 0 ? '${w.toInt()}' : '$w';

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5));
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0xFF242428), borderRadius: BorderRadius.circular(8)),
        child:
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)));
}

class _GridBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool special;
  final VoidCallback onTap;
  const _GridBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.special = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final BoxDecoration deco;
    final Color textColor;

    if (selected) {
      deco = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.8,
        ),
      );
      textColor = Colors.white;
    } else if (special) {
      deco = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x22D4AF37), Color(0x10FFE066)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
            width: 0.8),
      );
      textColor = const Color(0xFFD4AF37);
    } else {
      deco = BoxDecoration(
        color: const Color(0xFF242428),
        borderRadius: BorderRadius.circular(12),
      );
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: deco,
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF242428) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: enabled ? Colors.white : Colors.white12, size: 28),
      ),
    );
  }
}

// ── Rating Dialog ──────────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final String elapsed;
  final double? totalWeightKg;
  final int newPrCount;
  const _RatingDialog({
    required this.elapsed,
    this.totalWeightKg,
    required this.newPrCount,
  });
  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  String? _location;

  @override
  void initState() {
    super.initState();
    LocationService.fetchPlaceName()
        .then((v) { if (mounted) setState(() => _location = v); });
  }

  void _submit(String rating) =>
      Navigator.pop(context, (rating: rating, location: _location));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stats row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _StatChip(label: widget.elapsed, icon: Icons.timer_outlined),
                if (widget.totalWeightKg != null)
                  _StatChip(
                      label:
                          '${widget.totalWeightKg!.toStringAsFixed(0)}kg',
                      icon: Icons.fitness_center),
                if (widget.newPrCount > 0)
                  _StatChip(
                      label:
                          '${widget.newPrCount} PR${widget.newPrCount > 1 ? 's' : ''}',
                      icon: Icons.emoji_events_outlined,
                      color: const Color(0xFFFFD60A)),
              ],
            ),
            const SizedBox(height: 22),
            const Text('How was it?',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RatingBtn(
                    icon: Icons.sentiment_very_dissatisfied,
                    color: const Color(0xFFFF453A),
                    onTap: () => _submit('red')),
                _RatingBtn(
                    icon: Icons.sentiment_neutral,
                    color: const Color(0xFFFF9F0A),
                    onTap: () => _submit('yellow')),
                _RatingBtn(
                    icon: Icons.sentiment_very_satisfied,
                    color: const Color(0xFF34C759),
                    onTap: () => _submit('green')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _StatChip({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: color != null ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: color != null
            ? Border.all(color: color!.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RatingBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RatingBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}

class _InputDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final TextInputType keyboardType;
  const _InputDialog(
      {required this.title, required this.controller, required this.keyboardType});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      backgroundColor: const Color(0xFF242428),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: controller,
        keyboardType: keyboardType,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(filled: false),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
          child: Text('Set', style: TextStyle(color: accent)),
        ),
      ],
    );
  }
}
