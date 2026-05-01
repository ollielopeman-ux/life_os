import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/checklist_item.dart';
import '../../schedule/providers/schedule_provider.dart';

const _uuid = Uuid();

class ChecklistNotifier extends Notifier<List<ChecklistItem>> {
  Box get _box => Hive.box('checklist');

  @override
  List<ChecklistItem> build() => _load();

  List<ChecklistItem> _load() {
    final raw = _box.get('items', defaultValue: []) as List;
    return raw.map((e) => ChecklistItem.fromMap(e as Map)).toList();
  }

  void _save() =>
      _box.put('items', state.map((i) => i.toMap()).toList());

  void addItem(String title, DateTime date, {String? time}) {
    state = [
      ...state,
      ChecklistItem(
        id: _uuid.v4(),
        title: title,
        done: false,
        date: date,
        time: time,
      ),
    ];
    _save();
  }

  void toggleItem(String id) {
    final item = state.firstWhere((i) => i.id == id);
    final newDone = !item.done;

    ChecklistItem updated;
    if (newDone && !item.calendarSynced) {
      updated = item.copyWith(done: true, calendarSynced: true);
      ref.read(scheduleProvider.notifier).addTask(
            item.title,
            item.date,
            time: item.time,
            done: true,
          );
    } else {
      updated = item.copyWith(done: newDone);
    }

    state = state.map((i) => i.id == id ? updated : i).toList();
    _save();
  }

  void deleteItem(String id) {
    state = state.where((i) => i.id != id).toList();
    _save();
  }
}

final checklistProvider =
    NotifierProvider<ChecklistNotifier, List<ChecklistItem>>(
        ChecklistNotifier.new);
