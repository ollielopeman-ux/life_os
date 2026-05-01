import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/plyo_models.dart';
import '../../schedule/providers/schedule_provider.dart';

const _uuid = Uuid();

class PlyoNotifier extends Notifier<PlyoState> {
  Box get _box => Hive.box('plyo');

  @override
  PlyoState build() => PlyoState(workouts: _load());

  List<PlyoWorkout> _load() {
    final raw = _box.get('workouts', defaultValue: []) as List;
    return raw.map((e) => PlyoWorkout.fromMap(e as Map)).toList();
  }

  void _save() =>
      _box.put('workouts', state.workouts.map((w) => w.toMap()).toList());

  void addWorkout(String name) {
    final w = PlyoWorkout(id: _uuid.v4(), name: name);
    state = PlyoState(workouts: [...state.workouts, w]);
    _save();
  }

  void deleteWorkout(String id) {
    state = PlyoState(
        workouts: state.workouts.where((w) => w.id != id).toList());
    _save();
  }

  void addExercise(
    String workoutId,
    String name,
    int defaultReps, {
    int defaultSets = 3,
    double? defaultWeight,
    int? durationSeconds,
  }) {
    state = PlyoState(
      workouts: state.workouts
          .map((w) => w.id != workoutId
              ? w
              : w.copyWith(exercises: [
                  ...w.exercises,
                  PlyoExercise(
                    id: _uuid.v4(),
                    name: name,
                    defaultReps: defaultReps,
                    defaultSets: defaultSets,
                    defaultWeight: defaultWeight,
                    durationSeconds: durationSeconds,
                  ),
                ]))
          .toList(),
    );
    _save();
  }

  void removeExercise(String workoutId, String exerciseId) {
    state = PlyoState(
      workouts: state.workouts
          .map((w) => w.id != workoutId
              ? w
              : w.copyWith(
                  exercises:
                      w.exercises.where((e) => e.id != exerciseId).toList()))
          .toList(),
    );
    _save();
  }

  void updateExerciseVideo(
      String workoutId, String exerciseId, String? videoPath) {
    state = PlyoState(
      workouts: state.workouts
          .map((w) => w.id != workoutId
              ? w
              : w.copyWith(
                  exercises: w.exercises
                      .map((e) =>
                          e.id != exerciseId ? e : e.copyWith(videoPath: videoPath))
                      .toList()))
          .toList(),
    );
    _save();
  }

  void logPlyoSet(String workoutId, String exerciseId, int reps,
      {double? weight}) {
    final entry =
        PlyoSetEntry(reps: reps, weight: weight, date: DateTime.now());
    state = PlyoState(
      workouts: state.workouts
          .map((w) => w.id != workoutId
              ? w
              : w.copyWith(
                  exercises: w.exercises
                      .map((e) => e.id != exerciseId
                          ? e
                          : e.copyWith(history: [...e.history, entry]))
                      .toList()))
          .toList(),
    );
    _save();
  }

  void logWorkout(PlyoWorkout workout, {String? rating, String? location, int? durationMinutes}) {
    ref.read(scheduleProvider.notifier).addTask(
          '${workout.name} · Plyo',
          DateTime.now(),
          done: true,
          workoutData: {
            'plyo': true,
            'exercises': workout.exercises.length,
            'exerciseNames': workout.exercises.map((e) => e.name).toList(),
            'rating': rating,
            'location': location,
            'durationMinutes': durationMinutes,
          },
        );
  }
}

final plyoProvider =
    NotifierProvider<PlyoNotifier, PlyoState>(PlyoNotifier.new);
