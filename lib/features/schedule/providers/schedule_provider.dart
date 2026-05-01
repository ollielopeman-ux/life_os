import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

const _uuid = Uuid();

class ScheduleNotifier extends Notifier<List<Task>> {
  Box get _box => Hive.box('schedule');

  @override
  List<Task> build() => _load();

  List<Task> _load() {
    final raw = _box.get('tasks', defaultValue: []) as List;
    return raw.map((e) => Task.fromMap(e as Map)).toList();
  }

  void _save() => _box.put('tasks', state.map((t) => t.toMap()).toList());

  void addTask(String title, DateTime date,
      {String? time, bool done = false, Map<String, dynamic>? workoutData}) {
    state = [
      ...state,
      Task(
          id: _uuid.v4(),
          title: title,
          done: done,
          date: date,
          time: time,
          workoutData: workoutData),
    ];
    _save();
  }

  void toggleDone(String id) {
    state = state.map((t) => t.id == id ? t.copyWith(done: !t.done) : t).toList();
    _save();
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
    _save();
  }

  List<Task> forDate(DateTime date) => state
      .where((t) => t.date.year == date.year && t.date.month == date.month && t.date.day == date.day)
      .toList();
}

final scheduleProvider = NotifierProvider<ScheduleNotifier, List<Task>>(ScheduleNotifier.new);
