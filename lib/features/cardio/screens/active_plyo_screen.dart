import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../models/plyo_models.dart';
import '../providers/active_plyo_provider.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/beep_service.dart';

class ActivePlyoScreen extends ConsumerStatefulWidget {
  const ActivePlyoScreen({super.key});

  @override
  ConsumerState<ActivePlyoScreen> createState() => _ActivePlyoScreenState();
}

class _ActivePlyoScreenState extends ConsumerState<ActivePlyoScreen> {
  late final Stopwatch _stopwatch;
  Timer? _ticker;
  String? _expandedId;

  // Interval timer
  bool _timerOpen = false;
  final _workCtrl = TextEditingController(text: '40');
  final _restCtrl = TextEditingController(text: '20');
  final _roundsCtrl = TextEditingController(text: '3');
  bool _timerRunning = false;
  bool _timerStarted = false;
  bool _isWorkPhase = true;
  int _currentRound = 1;
  int _totalRounds = 3;
  int _remainingSecs = 40;
  Timer? _intervalTicker;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _intervalTicker?.cancel();
    _workCtrl.dispose();
    _restCtrl.dispose();
    _roundsCtrl.dispose();
    super.dispose();
  }

  String get _elapsed {
    final e = _stopwatch.elapsed;
    final m = e.inMinutes.toString().padLeft(2, '0');
    final s = e.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Interval timer logic ───────────────────────────────────────────────────

  void _startInterval() {
    final work = int.tryParse(_workCtrl.text) ?? 40;
    _totalRounds = int.tryParse(_roundsCtrl.text) ?? 3;
    _intervalTicker?.cancel();
    if (_soundEnabled) BeepService.workBeep();
    setState(() {
      _timerRunning = true;
      _timerStarted = true;
      _isWorkPhase = true;
      _currentRound = 1;
      _remainingSecs = work;
    });
    _intervalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSecs > 0) {
          _remainingSecs--;
        } else {
          if (_isWorkPhase) {
            _isWorkPhase = false;
            _remainingSecs = int.tryParse(_restCtrl.text) ?? 20;
            if (_soundEnabled) BeepService.restBeep();
          } else {
            if (_currentRound >= _totalRounds) {
              _timerRunning = false;
              _timerStarted = false;
              _intervalTicker?.cancel();
              if (_soundEnabled) BeepService.restBeep();
            } else {
              _currentRound++;
              _isWorkPhase = true;
              _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
              if (_soundEnabled) BeepService.workBeep();
            }
          }
        }
      });
    });
  }

  void _pauseInterval() {
    _intervalTicker?.cancel();
    setState(() => _timerRunning = false);
  }

  void _resumeInterval() {
    _intervalTicker?.cancel();
    setState(() => _timerRunning = true);
    _intervalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSecs > 0) {
          _remainingSecs--;
        } else {
          if (_isWorkPhase) {
            _isWorkPhase = false;
            _remainingSecs = int.tryParse(_restCtrl.text) ?? 20;
            if (_soundEnabled) BeepService.restBeep();
          } else {
            if (_currentRound >= _totalRounds) {
              _timerRunning = false;
              _timerStarted = false;
              _intervalTicker?.cancel();
              if (_soundEnabled) BeepService.restBeep();
            } else {
              _currentRound++;
              _isWorkPhase = true;
              _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
              if (_soundEnabled) BeepService.workBeep();
            }
          }
        }
      });
    });
  }

  void _resetInterval() {
    _intervalTicker?.cancel();
    setState(() {
      _timerRunning = false;
      _timerStarted = false;
      _isWorkPhase = true;
      _currentRound = 1;
      _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
    });
  }

  // ── Rating dialog ──────────────────────────────────────────────────────────

  Future<({String? rating, String? location})?> _askRating() {
    final state = ref.read(activePlyoProvider);
    final sessionSets = state.sessionSets;
    final priorPrs = state.priorPrs;
    final workout = state.workout;

    int totalReps = 0;
    double totalWeight = 0;
    final newPrNames = <String>[];

    for (final ex in (workout?.exercises ?? <PlyoExercise>[])) {
      final sets = sessionSets[ex.id] ?? [];
      for (final s in sets) {
        totalReps += s.reps;
        if (s.weight != null) totalWeight += s.reps * s.weight!;
      }
      if (sets.isNotEmpty) {
        final sessionBest = sets.reduce((a, b) {
          final aScore = a.reps + (a.weight ?? 0) * 0.5;
          final bScore = b.reps + (b.weight ?? 0) * 0.5;
          return aScore >= bScore ? a : b;
        });
        final prior = priorPrs[ex.id];
        final priorScore =
            prior != null ? prior.reps + (prior.weight ?? 0) * 0.5 : 0.0;
        final sessionScore = sessionBest.reps + (sessionBest.weight ?? 0) * 0.5;
        if (sessionScore > priorScore) newPrNames.add(ex.name);
      }
    }

    return showDialog<({String? rating, String? location})>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PlyoRatingDialog(
        elapsed: _elapsed,
        totalReps: totalReps,
        totalWeightKg: totalWeight > 0 ? totalWeight : null,
        newPrs: newPrNames,
      ),
    );
  }

  // ── End sheet ──────────────────────────────────────────────────────────────

  void _showEndSheet() {
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
              _OptionTile(
                icon: Icons.check_circle_outline,
                label: 'End Workout',
                subtitle: 'Save and finish',
                color: Theme.of(context).colorScheme.primary,
                onTap: () async {
                  Navigator.of(dlgCtx).pop();
                  final nav = Navigator.of(context);
                  final res = await _askRating();
                  if (!mounted) return;
                  ref.read(activePlyoProvider.notifier).endWorkout(
                        rating: res?.rating,
                        location: res?.location,
                      );
                  nav.pop();
                },
              ),
              const Divider(color: Color(0xFF2C2C2E), height: 1),
              _OptionTile(
                icon: Icons.delete_outline,
                label: 'Abandon',
                subtitle: 'Discard and exit',
                color: const Color(0xFFFF453A),
                onTap: () {
                  Navigator.of(dlgCtx).pop();
                  ref.read(activePlyoProvider.notifier).abandon();
                  Navigator.of(context).pop();
                },
              ),
              const Divider(color: Color(0xFF2C2C2E), height: 1),
              TextButton(
                onPressed: () => Navigator.of(dlgCtx).pop(),
                child: const Text('Keep Going',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final state = ref.watch(activePlyoProvider);
    final workout = state.workout;
    if (workout == null) return const SizedBox.shrink();

    final exercises = workout.exercises;
    final screenH = MediaQuery.of(context).size.height;

    // First incomplete exercise
    String? currentExId;
    for (final ex in exercises) {
      final done =
          (state.sessionSets[ex.id]?.length ?? 0) >= ex.defaultSets;
      if (!done) {
        currentExId = ex.id;
        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PLYO',
                            style: TextStyle(
                                color: Colors.white30,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4)),
                        const SizedBox(height: 2),
                        Text(workout.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  _InfoChip(icon: Icons.timer_outlined, label: _elapsed),
                  const SizedBox(width: 6),
                  _InfoChip(
                      icon: Icons.fitness_center,
                      label: '${exercises.length}'),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: _showEndSheet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Exercise list (Expanded — shrinks when timer open) ────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: exercises.length,
                itemBuilder: (_, i) {
                  final ex = exercises[i];
                  final setsLogged =
                      state.sessionSets[ex.id]?.length ?? 0;
                  final isDone = setsLogged >= ex.defaultSets;
                  final isCurrent = ex.id == currentExId;
                  final isExpanded = _expandedId == ex.id;
                  return _ExerciseCell(
                    exercise: ex,
                    sessionSets: state.sessionSets[ex.id] ?? [],
                    setsLogged: setsLogged,
                    isDone: isDone,
                    isCurrent: isCurrent,
                    isExpanded: isExpanded,
                    onToggle: () => setState(() =>
                        _expandedId = isExpanded ? null : ex.id),
                    onLogSet: (reps, weight) => ref
                        .read(activePlyoProvider.notifier)
                        .logSet(ex.id, reps, weight: weight),
                    onRemoveSet: () => ref
                        .read(activePlyoProvider.notifier)
                        .removeLastSet(ex.id),
                    onBoxTap: (filled) {
                      if (filled) {
                        ref
                            .read(activePlyoProvider.notifier)
                            .removeLastSet(ex.id);
                      } else {
                        ref.read(activePlyoProvider.notifier).logSet(
                              ex.id,
                              ex.defaultReps,
                              weight: ex.defaultWeight,
                            );
                      }
                    },
                  );
                },
              ),
            ),

            // ── Interval timer panel (slides in from below exercises) ─────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _timerOpen ? screenH * 0.44 : 0,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              // OverflowBox lets the panel size to its natural height; the
              // AnimatedContainer clips the overflow so no assertion fires.
              child: OverflowBox(
                maxHeight: double.infinity,
                alignment: Alignment.topCenter,
                child: _IntervalTimerPanel(
                  workCtrl: _workCtrl,
                  restCtrl: _restCtrl,
                  roundsCtrl: _roundsCtrl,
                  isRunning: _timerRunning,
                  isStarted: _timerStarted,
                  isWorkPhase: _isWorkPhase,
                  currentRound: _currentRound,
                  totalRounds: _totalRounds,
                  remainingSecs: _remainingSecs,
                  soundEnabled: _soundEnabled,
                  onStart: _startInterval,
                  onPause: _pauseInterval,
                  onResume: _resumeInterval,
                  onReset: _resetInterval,
                  onToggleSound: () =>
                      setState(() => _soundEnabled = !_soundEnabled),
                ),
              ),
            ),

            // ── Interval timer toggle ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: GestureDetector(
                onTap: () => setState(() => _timerOpen = !_timerOpen),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _timerOpen
                        ? accent.withValues(alpha: 0.12)
                        : const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _timerOpen
                          ? accent.withValues(alpha: 0.4)
                          : const Color(0xFF2C2C2E),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 15,
                          color: _timerOpen
                              ? accent
                              : Colors.white38),
                      const SizedBox(width: 7),
                      Text('Interval Timer',
                          style: TextStyle(
                              color: _timerOpen
                                  ? accent
                                  : Colors.white38,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Icon(
                          _timerOpen
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 16,
                          color: _timerOpen
                              ? accent
                              : Colors.white38),
                    ],
                  ),
                ),
              ),
            ),

            // ── End Workout ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GestureDetector(
                onTap: () async {
                  final nav = Navigator.of(context);
                  final res = await _askRating();
                  if (!mounted) return;
                  ref.read(activePlyoProvider.notifier).endWorkout(
                        rating: res?.rating,
                        location: res?.location,
                      );
                  nav.pop();
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('End Workout',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Chip ──────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

// ── Exercise Cell ──────────────────────────────────────────────────────────────

class _ExerciseCell extends StatefulWidget {
  final PlyoExercise exercise;
  final List<PlyoSetEntry> sessionSets;
  final int setsLogged;
  final bool isDone;
  final bool isCurrent;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(int reps, double? weight) onLogSet;
  final VoidCallback onRemoveSet;
  final void Function(bool wasFilled) onBoxTap;

  const _ExerciseCell({
    required this.exercise,
    required this.sessionSets,
    required this.setsLogged,
    required this.isDone,
    required this.isCurrent,
    required this.isExpanded,
    required this.onToggle,
    required this.onLogSet,
    required this.onRemoveSet,
    required this.onBoxTap,
  });

  @override
  State<_ExerciseCell> createState() => _ExerciseCellState();
}

class _ExerciseCellState extends State<_ExerciseCell> {
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _repsCtrl =
        TextEditingController(text: '${widget.exercise.defaultReps}');
    _weightCtrl = TextEditingController(
        text: widget.exercise.defaultWeight != null
            ? '${widget.exercise.defaultWeight}'
            : '');
  }

  @override
  void didUpdateWidget(_ExerciseCell old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded && !old.isExpanded) {
      _initVideo();
    } else if (!widget.isExpanded && old.isExpanded) {
      _disposeVideo();
    }
  }

  void _initVideo() {
    final path = widget.exercise.videoPath;
    if (path == null) return;
    _videoCtrl = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _videoReady = true);
          _videoCtrl!.setLooping(true);
          _videoCtrl!.play();
        }
      });
  }

  void _disposeVideo() {
    _videoCtrl?.dispose();
    _videoCtrl = null;
    _videoReady = false;
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _logSet() {
    final reps =
        int.tryParse(_repsCtrl.text.trim()) ?? widget.exercise.defaultReps;
    final weight = double.tryParse(_weightCtrl.text.trim());
    widget.onLogSet(reps, weight);
    _repsCtrl.text = '${widget.exercise.defaultReps}';
    _weightCtrl.text = widget.exercise.defaultWeight != null
        ? '${widget.exercise.defaultWeight}'
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final ex = widget.exercise;
    final isDone = widget.isDone;
    final isCurrent = widget.isCurrent;
    final pr = ex.pr;

    final Color borderColor;
    final Color bgColor;
    if (isDone) {
      borderColor = Colors.white12;
      bgColor = const Color(0xFF111113);
    } else if (isCurrent) {
      borderColor = accent.withValues(alpha: 0.5);
      bgColor = const Color(0xFF131E2E);
    } else {
      borderColor = const Color(0xFF242426);
      bgColor = const Color(0xFF161618);
    }

    return Opacity(
      opacity: isDone ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              // Header row
              GestureDetector(
                onTap: widget.onToggle,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: [
                      // Status icon
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF34C759).withValues(alpha: 0.15)
                              : isCurrent
                                  ? accent.withValues(alpha: 0.2)
                                  : const Color(0xFF2C2C2E),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.fitness_center,
                          size: 13,
                          color: isDone
                              ? const Color(0xFF34C759)
                              : isCurrent
                                  ? accent
                                  : Colors.white24,
                        ),
                      ),
                      // Name + set boxes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex.name,
                                style: TextStyle(
                                    color: isDone
                                        ? Colors.white54
                                        : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 7),
                            // Set boxes
                            Row(
                              children: List.generate(ex.defaultSets, (i) {
                                final filled = i < widget.setsLogged;
                                return GestureDetector(
                                  onTap: () => widget.onBoxTap(filled),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 26,
                                    height: 26,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      color: filled
                                          ? accent
                                          : const Color(0xFF2A2A2C),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: filled
                                            ? accent
                                            : const Color(0xFF3A3A3C),
                                      ),
                                    ),
                                    child: filled
                                        ? const Icon(Icons.check,
                                            size: 13, color: Colors.white)
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        widget.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white24,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded content
              if (widget.isExpanded) ...[
                const Divider(height: 1, color: Color(0xFF242426)),

                // Video player
                if (ex.videoPath != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _videoReady && _videoCtrl != null
                            ? GestureDetector(
                                onTap: () => setState(() {
                                  _videoCtrl!.value.isPlaying
                                      ? _videoCtrl!.pause()
                                      : _videoCtrl!.play();
                                }),
                                child: VideoPlayer(_videoCtrl!),
                              )
                            : Container(
                                color: const Color(0xFF1C1C1E),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: accent,
                                      strokeWidth: 2),
                                ),
                              ),
                      ),
                    ),
                  ),

                // PR
                if (pr != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Container(
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
                                .withValues(alpha: 0.55),
                            width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Color(0xFFD4AF37), size: 13),
                          const SizedBox(width: 5),
                          Text(
                            'PR · ${pr.reps} reps${pr.weight != null ? ' @ ${pr.weight}kg' : ''}',
                            style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Custom log inputs
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SetField(
                            controller: _repsCtrl,
                            hint: 'Reps',
                            icon: Icons.repeat,
                            integer: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SetField(
                            controller: _weightCtrl,
                            hint: 'Weight kg',
                            icon: Icons.fitness_center,
                            integer: false),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _logSet,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      if (widget.sessionSets.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: widget.onRemoveSet,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.remove,
                                color: Colors.white38, size: 20),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Interval Timer Panel ───────────────────────────────────────────────────────

class _IntervalTimerPanel extends StatelessWidget {
  final TextEditingController workCtrl;
  final TextEditingController restCtrl;
  final TextEditingController roundsCtrl;
  final bool isRunning;
  final bool isStarted;
  final bool isWorkPhase;
  final int currentRound;
  final int totalRounds;
  final int remainingSecs;
  final bool soundEnabled;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onToggleSound;

  const _IntervalTimerPanel({
    required this.workCtrl,
    required this.restCtrl,
    required this.roundsCtrl,
    required this.isRunning,
    required this.isStarted,
    required this.isWorkPhase,
    required this.currentRound,
    required this.totalRounds,
    required this.remainingSecs,
    required this.soundEnabled,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final mins = (remainingSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (remainingSecs % 60).toString().padLeft(2, '0');
    final phaseColor =
        isWorkPhase ? accent : const Color(0xFF34C759);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        border: Border(top: BorderSide(color: Color(0xFF2C2C2E))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sound toggle row
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onToggleSound,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: soundEnabled
                      ? accent.withValues(alpha: 0.12)
                      : const Color(0xFF242428),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: soundEnabled
                        ? accent.withValues(alpha: 0.4)
                        : const Color(0xFF3A3A3C),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      size: 13,
                      color: soundEnabled
                          ? accent
                          : Colors.white30,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      soundEnabled ? 'Sound on' : 'Sound off',
                      style: TextStyle(
                          fontSize: 11,
                          color: soundEnabled
                              ? accent
                              : Colors.white30),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (!isStarted) ...[
            // Config row
            Row(
              children: [
                Expanded(
                    child: _TimerInput(
                        label: 'WORK (s)', controller: workCtrl)),
                const SizedBox(width: 10),
                Expanded(
                    child: _TimerInput(
                        label: 'REST (s)', controller: restCtrl)),
                const SizedBox(width: 10),
                Expanded(
                    child: _TimerInput(
                        label: 'ROUNDS', controller: roundsCtrl)),
              ],
            ),
            const SizedBox(height: 14),
            _TimerBtn(
              icon: Icons.play_arrow,
              color: accent,
              large: true,
              onTap: onStart,
            ),
          ] else ...[
            Text(isWorkPhase ? 'WORK' : 'REST',
                style: TextStyle(
                    color: phaseColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5)),
            const SizedBox(height: 2),
            Text('$mins:$secs',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()])),
            Text('Round $currentRound / $totalRounds',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimerBtn(
                    icon: Icons.refresh,
                    color: Colors.white38,
                    onTap: onReset),
                const SizedBox(width: 18),
                _TimerBtn(
                  icon: isRunning ? Icons.pause : Icons.play_arrow,
                  color: accent,
                  large: true,
                  onTap: isRunning ? onPause : onResume,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimerInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _TimerInput({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF242428),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _TimerBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool large;
  final VoidCallback onTap;
  const _TimerBtn(
      {required this.icon,
      required this.color,
      required this.onTap,
      this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 60.0 : 44.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: large ? 0.18 : 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: large ? 28 : 20),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool integer;
  const _SetField(
      {required this.controller,
      required this.hint,
      required this.icon,
      required this.integer});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: integer
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        prefixIcon: Icon(icon, size: 14, color: Colors.white30),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 30, minHeight: 44),
        filled: true,
        fillColor: const Color(0xFF242428),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title:
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: onTap,
    );
  }
}

// ── Rating Dialog ──────────────────────────────────────────────────────────────

class _PlyoRatingDialog extends StatefulWidget {
  final String elapsed;
  final int totalReps;
  final double? totalWeightKg;
  final List<String> newPrs;

  const _PlyoRatingDialog({
    required this.elapsed,
    required this.totalReps,
    this.totalWeightKg,
    required this.newPrs,
  });

  @override
  State<_PlyoRatingDialog> createState() => _PlyoRatingDialogState();
}

class _PlyoRatingDialogState extends State<_PlyoRatingDialog> {
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SummaryChip(
                    label: widget.elapsed, icon: Icons.timer_outlined),
                _SummaryChip(
                    label: '${widget.totalReps} reps', icon: Icons.repeat),
                if (widget.totalWeightKg != null)
                  _SummaryChip(
                      label:
                          '${widget.totalWeightKg!.toStringAsFixed(0)}kg',
                      icon: Icons.fitness_center),
              ],
            ),
            // PRs banner
            if (widget.newPrs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          const Color(0xFFFFD60A).withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        color: Color(0xFFFFD60A), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New PR${widget.newPrs.length > 1 ? 's' : ''}: ${widget.newPrs.join(', ')}',
                        style: const TextStyle(
                            color: Color(0xFFFFD60A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SummaryChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF242428),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
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
