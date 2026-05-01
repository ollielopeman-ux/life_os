import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_models.dart';
import 'gym_provider.dart';
import '../../schedule/providers/schedule_provider.dart';

class ActiveWorkoutState {
  final String splitId;
  final WorkoutDay day;
  final int currentIndex;
  final Map<String, List<SetEntry>> sessionSets;
  final double selectedWeight;
  final int selectedReps;
  final bool isAdHoc;

  ActiveWorkoutState({
    required this.splitId,
    required this.day,
    required this.currentIndex,
    required this.sessionSets,
    required this.selectedWeight,
    required this.selectedReps,
    this.isAdHoc = false,
  });

  ExerciseTemplate get currentExercise => day.exercises[currentIndex];
  bool get isLastExercise => currentIndex >= day.exercises.length - 1;
  List<SetEntry> setsFor(String name) => sessionSets[name] ?? [];
}

class ActiveWorkoutNotifier extends Notifier<ActiveWorkoutState?> {
  @override
  ActiveWorkoutState? build() => null;

  void startWorkout(String splitId, WorkoutDay day) {
    if (day.exercises.isEmpty) return;
    final first = day.exercises[0];
    state = ActiveWorkoutState(
      splitId: splitId,
      day: day,
      currentIndex: 0,
      sessionSets: {},
      selectedWeight: first.usualWeight,
      selectedReps: first.usualReps,
    );
  }

  void startAdHocWorkout(List<ExerciseTemplate> exercises) {
    if (exercises.isEmpty) return;
    final day = WorkoutDay(
      id: '__adhoc__',
      name: 'Quick Session',
      isRestDay: false,
      weekdays: [],
      exercises: exercises,
    );
    state = ActiveWorkoutState(
      splitId: '__adhoc__',
      day: day,
      currentIndex: 0,
      sessionSets: {},
      selectedWeight: exercises[0].usualWeight,
      selectedReps: exercises[0].usualReps,
      isAdHoc: true,
    );
  }

  void selectWeight(double w) {
    if (state == null) return;
    state = _copy(selectedWeight: w);
  }

  void selectReps(int r) {
    if (state == null) return;
    state = _copy(selectedReps: r);
  }

  void logSet() {
    if (state == null) return;
    final s = state!;
    final name = s.currentExercise.name;
    final updated = Map<String, List<SetEntry>>.from(s.sessionSets);
    updated[name] = [
      ...(updated[name] ?? []),
      SetEntry(weight: s.selectedWeight, reps: s.selectedReps, date: DateTime.now()),
    ];
    state = _copy(sessionSets: updated);
  }

  void nextExercise() {
    if (state == null || state!.isLastExercise) return;
    final idx = state!.currentIndex + 1;
    final ex = state!.day.exercises[idx];
    state = _copy(currentIndex: idx, selectedWeight: ex.usualWeight, selectedReps: ex.usualReps);
  }

  void prevExercise() {
    if (state == null || state!.currentIndex == 0) return;
    final idx = state!.currentIndex - 1;
    final ex = state!.day.exercises[idx];
    state = _copy(currentIndex: idx, selectedWeight: ex.usualWeight, selectedReps: ex.usualReps);
  }

  void endWorkout({String? rating, String? location, int? durationMinutes}) {
    if (state == null) return;
    final w = state!;
    final gymState = ref.read(gymProvider);

    // Compute PRs before writing new history
    final prsBroken = <String>[];
    for (final entry in w.sessionSets.entries) {
      if (entry.value.isEmpty) continue;
      final sessionMax =
          entry.value.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
      double? allTimePR;
      for (final split in gymState.splits) {
        for (final day in split.days) {
          for (final ex in day.exercises) {
            if (ex.name == entry.key && ex.history.isNotEmpty) {
              final best =
                  ex.history.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
              if (allTimePR == null || best > allTimePR) allTimePR = best;
            }
          }
        }
      }
      if (allTimePR == null || sessionMax > allTimePR) {
        prsBroken.add(entry.key);
      }
    }

    // Persist sets to exercise history (skip for ad-hoc: no real split/day)
    if (!w.isAdHoc) {
      for (final entry in w.sessionSets.entries) {
        for (final set in entry.value) {
          ref.read(gymProvider.notifier).logSet(
              w.splitId, w.day.id, entry.key, set.weight, set.reps);
        }
      }
    }

    // Compute missed exercises (in plan but zero sets logged)
    final loggedNames = w.sessionSets.keys.toSet();
    final allNames = w.day.exercises.map((e) => e.name).toSet();
    final missed = allNames.difference(loggedNames).toList();

    // Build workout summary for schedule
    final setsMap = w.sessionSets.map((name, sets) =>
        MapEntry(name, sets.map((s) => {'weight': s.weight, 'reps': s.reps}).toList()));

    ref.read(scheduleProvider.notifier).addTask(
      '${w.day.name} · Gym',
      DateTime.now(),
      done: true,
      workoutData: {
        'sets': setsMap,
        'prs': prsBroken,
        'rating': rating,
        'location': location,
        'durationMinutes': durationMinutes,
        'missedExercises': missed,
      },
    );

    state = null;
  }

  void abandon() => state = null;

  ActiveWorkoutState _copy({
    int? currentIndex,
    Map<String, List<SetEntry>>? sessionSets,
    double? selectedWeight,
    int? selectedReps,
  }) {
    final s = state!;
    return ActiveWorkoutState(
      splitId: s.splitId,
      day: s.day,
      currentIndex: currentIndex ?? s.currentIndex,
      sessionSets: sessionSets ?? s.sessionSets,
      selectedWeight: selectedWeight ?? s.selectedWeight,
      selectedReps: selectedReps ?? s.selectedReps,
    );
  }
}

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>(ActiveWorkoutNotifier.new);
