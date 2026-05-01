import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';

const _uuid = Uuid();

class GymState {
  final List<GymSplit> splits;
  final String? selectedSplitId;

  GymState({required this.splits, this.selectedSplitId});

  GymSplit? get selectedSplit {
    if (splits.isEmpty) return null;
    if (selectedSplitId != null) {
      final found = splits.where((s) => s.id == selectedSplitId).firstOrNull;
      if (found != null) return found;
    }
    return splits.firstWhere((s) => s.isPrimary, orElse: () => splits.first);
  }
}

class GymNotifier extends Notifier<GymState> {
  Box get _box => Hive.box('gym');

  @override
  GymState build() {
    _migrate();
    final splits = _load();
    final primary = splits.where((s) => s.isPrimary).firstOrNull ?? splits.firstOrNull;
    return GymState(splits: splits, selectedSplitId: primary?.id);
  }

  void _migrate() {
    final version = _box.get('schema_version', defaultValue: 1) as int;
    if (version < 2) {
      _box.delete('splits');
      _box.put('schema_version', 2);
    }
  }

  List<GymSplit> _load() {
    final raw = _box.get('splits', defaultValue: []) as List;
    return raw.map((e) => GymSplit.fromMap(e as Map)).toList();
  }

  void _save() => _box.put('splits', state.splits.map((s) => s.toMap()).toList());

  void selectSplit(String id) => state = GymState(splits: state.splits, selectedSplitId: id);

  void addSplit(String name) {
    final isFirst = state.splits.isEmpty;
    final s = GymSplit(id: _uuid.v4(), name: name, isPrimary: isFirst);
    state = GymState(splits: [...state.splits, s], selectedSplitId: state.selectedSplitId ?? s.id);
    _save();
  }

  void deleteSplit(String id) {
    final remaining = state.splits.where((s) => s.id != id).toList();
    state = GymState(splits: remaining, selectedSplitId: remaining.firstOrNull?.id);
    _save();
  }

  void setPrimary(String id) {
    state = GymState(
      splits: state.splits.map((s) => s.copyWith(isPrimary: s.id == id)).toList(),
      selectedSplitId: id,
    );
    _save();
  }

  void addDay(
    String splitId,
    String name, {
    bool isRestDay = false,
    List<int> weekdays = const [],
  }) {
    _updateSplit(splitId, (s) => s.copyWith(
          days: [
            ...s.days,
            WorkoutDay(id: _uuid.v4(), name: name, isRestDay: isRestDay, weekdays: weekdays),
          ],
        ));
  }

  void deleteDay(String splitId, String dayId) {
    _updateSplit(splitId, (s) => s.copyWith(
          days: s.days.where((d) => d.id != dayId).toList(),
        ));
  }

  void addExercise(String splitId, String dayId, String name, double usualWeight, int usualReps, {int usualSets = 3}) {
    _updateSplit(splitId, (s) => s.copyWith(
          days: s.days
              .map((d) => d.id != dayId
                  ? d
                  : d.copyWith(exercises: [
                      ...d.exercises,
                      ExerciseTemplate(name: name, usualWeight: usualWeight, usualReps: usualReps, usualSets: usualSets),
                    ]))
              .toList(),
        ));
  }

  void updateExercise(String splitId, String dayId, String name, double weight, int reps) {
    _updateSplit(splitId, (s) => s.copyWith(
          days: s.days
              .map((d) => d.id != dayId
                  ? d
                  : d.copyWith(
                      exercises: d.exercises
                          .map((e) => e.name != name
                              ? e
                              : e.copyWith(usualWeight: weight, usualReps: reps))
                          .toList()))
              .toList(),
        ));
  }

  void removeExercise(String splitId, String dayId, String name) {
    _updateSplit(splitId, (s) => s.copyWith(
          days: s.days
              .map((d) => d.id != dayId
                  ? d
                  : d.copyWith(exercises: d.exercises.where((e) => e.name != name).toList()))
              .toList(),
        ));
  }

  void logSet(String splitId, String dayId, String exerciseName, double weight, int reps) {
    final entry = SetEntry(weight: weight, reps: reps, date: DateTime.now());
    _updateSplit(splitId, (s) => s.copyWith(
          days: s.days
              .map((d) => d.id != dayId
                  ? d
                  : d.copyWith(
                      exercises: d.exercises
                          .map((e) => e.name != exerciseName
                              ? e
                              : e.copyWith(history: [...e.history, entry]))
                          .toList()))
              .toList(),
        ));
  }

  void _updateSplit(String splitId, GymSplit Function(GymSplit) fn) {
    state = GymState(
      splits: state.splits.map((s) => s.id == splitId ? fn(s) : s).toList(),
      selectedSplitId: state.selectedSplitId,
    );
    _save();
  }
}

final gymProvider = NotifierProvider<GymNotifier, GymState>(GymNotifier.new);
