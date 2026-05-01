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

  void addExercise(String workoutId, String name, int defaultReps) {
    state = PlyoState(
      workouts: state.workouts
          .map((w) => w.id != workoutId
              ? w
              : w.copyWith(exercises: [
                  ...w.exercises,
                  PlyoExercise(
                      id: _uuid.v4(), name: name, defaultReps: defaultReps),
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

  void logWorkout(PlyoWorkout workout) {
    ref.read(scheduleProvider.notifier).addTask(
          '${workout.name} · Plyo',
          DateTime.now(),
          done: true,
          workoutData: {'plyo': true, 'exercises': workout.exercises.length},
        );
  }
}

final plyoProvider =
    NotifierProvider<PlyoNotifier, PlyoState>(PlyoNotifier.new);
