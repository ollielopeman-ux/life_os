import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/body_entry.dart';

const _uuid = Uuid();

class BodyNotifier extends Notifier<List<BodyEntry>> {
  Box get _box => Hive.box('body');

  @override
  List<BodyEntry> build() => _load();

  List<BodyEntry> _load() {
    final raw = _box.get('entries', defaultValue: []) as List;
    return (raw.map((e) => BodyEntry.fromMap(e as Map)).toList()
          ..sort((a, b) => b.date.compareTo(a.date)))
        .toList();
  }

  void _save() {
    final sorted = [...state]..sort((a, b) => b.date.compareTo(a.date));
    _box.put('entries', sorted.map((e) => e.toMap()).toList());
  }

  void addEntry({double? weight, String? photoPath, String? note}) {
    state = [
      BodyEntry(
        id: _uuid.v4(),
        date: DateTime.now(),
        weight: weight,
        photoPath: photoPath,
        note: note,
      ),
      ...state,
    ];
    _save();
  }

  void deleteEntry(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }
}

final bodyProvider = NotifierProvider<BodyNotifier, List<BodyEntry>>(BodyNotifier.new);
