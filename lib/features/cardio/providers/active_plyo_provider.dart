import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plyo_models.dart';
import './plyo_provider.dart';
import '../../schedule/providers/schedule_provider.dart';

class ActivePlyoState {
  final PlyoWorkout? workout;
  final Map<String, List<PlyoSetEntry>> sessionSets;
  final Map<String, PlyoSetEntry?> priorPrs;
  final bool active;
  final DateTime? startedAt;

  const ActivePlyoState({
    this.workout,
    this.sessionSets = const {},
    this.priorPrs = const {},
    this.active = false,
    this.startedAt,
  });
}

class ActivePlyoNotifier extends Notifier<ActivePlyoState> {
  @override
  ActivePlyoState build() => const ActivePlyoState();

  void startWorkout(PlyoWorkout workout) {
    final priorPrs = {for (final ex in workout.exercises) ex.id: ex.pr};
    state = ActivePlyoState(
      workout: workout,
      sessionSets: {},
      priorPrs: priorPrs,
      active: true,
      startedAt: DateTime.now(),
    );
  }

  void logSet(String exerciseId, int reps, {double? weight}) {
    final entry = PlyoSetEntry(reps: reps, weight: weight, date: DateTime.now());
    final updated = Map<String, List<PlyoSetEntry>>.from(state.sessionSets);
    updated[exerciseId] = [...(updated[exerciseId] ?? []), entry];
    state = ActivePlyoState(
      workout: state.workout,
      sessionSets: updated,
      priorPrs: state.priorPrs,
      active: state.active,
      startedAt: state.startedAt,
    );
    if (state.workout != null) {
      ref.read(plyoProvider.notifier).logPlyoSet(
            state.workout!.id,
            exerciseId,
            reps,
            weight: weight,
          );
    }
  }

  void removeLastSet(String exerciseId) {
    final updated = Map<String, List<PlyoSetEntry>>.from(state.sessionSets);
    final sets = List<PlyoSetEntry>.from(updated[exerciseId] ?? []);
    if (sets.isNotEmpty) sets.removeLast();
    if (sets.isEmpty) {
      updated.remove(exerciseId);
    } else {
      updated[exerciseId] = sets;
    }
    state = ActivePlyoState(
      workout: state.workout,
      sessionSets: updated,
      priorPrs: state.priorPrs,
      active: state.active,
      startedAt: state.startedAt,
    );
  }

  void endWorkout({String? rating, String? location}) {
    final w = state.workout;
    if (w == null) return;
    final elapsed = state.startedAt != null
        ? DateTime.now().difference(state.startedAt!).inMinutes
        : null;
    ref.read(scheduleProvider.notifier).addTask(
          '${w.name} · Plyo',
          DateTime.now(),
          done: true,
          workoutData: {
            'plyo': true,
            'exercises': w.exercises.length,
            'exerciseNames': w.exercises.map((e) => e.name).toList(),
            'rating': rating,
            'location': location,
            'durationMinutes': elapsed,
          },
        );
    state = const ActivePlyoState();
  }

  void abandon() {
    state = const ActivePlyoState();
  }
}

final activePlyoProvider =
    NotifierProvider<ActivePlyoNotifier, ActivePlyoState>(
        ActivePlyoNotifier.new);
