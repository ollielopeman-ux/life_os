class ChecklistItem {
  final String id;
  final String title;
  final bool done;
  final DateTime date;
  final String? time;           // "HH:mm" 24h, e.g. "14:30"
  final bool calendarSynced;   // true once added to schedule

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.done,
    required this.date,
    this.time,
    this.calendarSynced = false,
  });

  // "2:30 PM" display string, null when no time set
  String? get formattedTime {
    if (time == null) return null;
    final parts = time!.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:$m $ampm';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'done': done,
        'date': date.toIso8601String(),
        'time': time,
        'calendarSynced': calendarSynced,
      };

  factory ChecklistItem.fromMap(Map map) => ChecklistItem(
        id: map['id'] as String,
        title: map['title'] as String,
        done: map['done'] as bool,
        date: DateTime.parse(map['date'] as String),
        time: map['time'] as String?,
        calendarSynced: (map['calendarSynced'] as bool?) ?? false,
      );

  ChecklistItem copyWith({bool? done, bool? calendarSynced}) =>
      ChecklistItem(
        id: id,
        title: title,
        done: done ?? this.done,
        date: date,
        time: time,
        calendarSynced: calendarSynced ?? this.calendarSynced,
      );
}
