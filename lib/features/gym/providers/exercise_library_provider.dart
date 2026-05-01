import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';

const _uuid = Uuid();

class ExerciseLibraryNotifier extends Notifier<List<LibraryExercise>> {
  Box get _box => Hive.box('gym');

  @override
  List<LibraryExercise> build() => _load();

  List<LibraryExercise> _load() {
    final raw = _box.get('library_exercises', defaultValue: []) as List;
    return raw.map((e) => LibraryExercise.fromMap(e as Map)).toList();
  }

  void _save() =>
      _box.put('library_exercises', state.map((e) => e.toMap()).toList());

  bool hasName(String name) =>
      state.any((e) => e.name.toLowerCase() == name.toLowerCase());

  void add(String name, {double defaultWeight = 20.0, int defaultReps = 8}) {
    if (hasName(name)) return;
    state = [
      ...state,
      LibraryExercise(
          id: _uuid.v4(),
          name: name,
          defaultWeight: defaultWeight,
          defaultReps: defaultReps),
    ];
    _save();
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  void updateDefaults(String id, double weight, int reps) {
    state = state
        .map((e) =>
            e.id == id ? e.copyWith(defaultWeight: weight, defaultReps: reps) : e)
        .toList();
    _save();
  }
}

final exerciseLibraryProvider =
    NotifierProvider<ExerciseLibraryNotifier, List<LibraryExercise>>(
        ExerciseLibraryNotifier.new);
