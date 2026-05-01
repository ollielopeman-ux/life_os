import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/cardio_models.dart';
import '../../schedule/providers/schedule_provider.dart';

const _uuid = Uuid();

class CardioNotifier extends Notifier<CardioState> {
  Box get _box => Hive.box('cardio');

  @override
  CardioState build() {
    final splits = _load();
    final primary =
        splits.where((s) => s.isPrimary).firstOrNull ?? splits.firstOrNull;
    return CardioState(splits: splits, selectedSplitId: primary?.id);
  }

  List<CardioSplit> _load() {
    final raw = _box.get('splits', defaultValue: []) as List;
    return raw.map((e) => CardioSplit.fromMap(e as Map)).toList();
  }

  void _save() =>
      _box.put('splits', state.splits.map((s) => s.toMap()).toList());

  void selectSplit(String id) =>
      state = CardioState(splits: state.splits, selectedSplitId: id);

  void addSplit(String name) {
    final isFirst = state.splits.isEmpty;
    final s = CardioSplit(id: _uuid.v4(), name: name, isPrimary: isFirst);
    state = CardioState(
        splits: [...state.splits, s],
        selectedSplitId: state.selectedSplitId ?? s.id);
    _save();
  }

  void deleteSplit(String id) {
    final remaining = state.splits.where((s) => s.id != id).toList();
    state =
        CardioState(splits: remaining, selectedSplitId: remaining.firstOrNull?.id);
    _save();
  }

  void setPrimary(String id) {
    state = CardioState(
      splits:
          state.splits.map((s) => s.copyWith(isPrimary: s.id == id)).toList(),
      selectedSplitId: id,
    );
    _save();
  }

  void addSession(
    String splitId,
    String name,
    String type,
    String intensity, {
    int? durationMinutes,
    double? distanceKm,
    List<int> weekdays = const [],
  }) {
    _updateSplit(
        splitId,
        (s) => s.copyWith(sessions: [
              ...s.sessions,
              CardioSession(
                id: _uuid.v4(),
                name: name,
                type: type,
                intensity: intensity,
                durationMinutes: durationMinutes,
                distanceKm: distanceKm,
                weekdays: weekdays,
              ),
            ]));
  }

  void deleteSession(String splitId, String sessionId) {
    _updateSplit(splitId,
        (s) => s.copyWith(sessions: s.sessions.where((ss) => ss.id != sessionId).toList()));
  }

  void logSession(String splitId, CardioSession session) {
    final detail = [
      session.type,
      if (session.distanceKm != null) '${session.distanceKm}km',
      if (session.durationMinutes != null) '${session.durationMinutes}min',
      session.intensity,
    ].join(' · ');

    ref.read(scheduleProvider.notifier).addTask(
          '${session.name} · Cardio',
          DateTime.now(),
          done: true,
          workoutData: {
            'sets': <String, dynamic>{},
            'prs': <String>[],
            'cardio': true,
            'detail': detail,
          },
        );
  }

  void _updateSplit(String splitId, CardioSplit Function(CardioSplit) fn) {
    state = CardioState(
      splits: state.splits
          .map((s) => s.id == splitId ? fn(s) : s)
          .toList(),
      selectedSplitId: state.selectedSplitId,
    );
    _save();
  }
}

final cardioProvider =
    NotifierProvider<CardioNotifier, CardioState>(CardioNotifier.new);
