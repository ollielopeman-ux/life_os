class Task {
  final String id;
  final String title;
  final bool done;
  final DateTime date;
  final String? time;
  // Non-null for workout tasks. Keys = exercise names, values = list of {weight, reps}.
  final Map<String, dynamic>? workoutData;

  Task({
    required this.id,
    required this.title,
    required this.done,
    required this.date,
    this.time,
    this.workoutData,
  });

  // Only true for gym sessions (title ends with '· Gym')
  bool get isWorkout => workoutData != null && title.endsWith('· Gym');

  // Parsed helpers (safe casts after Hive round-trip)
  Map<String, List<Map<String, dynamic>>> get workoutSets {
    final raw = workoutData?['sets'];
    if (raw == null) return {};
    final m = (raw as Map).cast<String, dynamic>();
    return m.map((k, v) =>
        MapEntry(k, (v as List).map((s) => Map<String, dynamic>.from(s as Map)).toList()));
  }

  List<String> get workoutPRs {
    final raw = workoutData?['prs'];
    if (raw == null) return [];
    return (raw as List).map((e) => e as String).toList();
  }

  // Shared across gym / cardio / plyo
  String? get sessionRating => workoutData?['rating'] as String?;
  String? get sessionLocation => workoutData?['location'] as String?;
  int? get sessionDuration => (workoutData?['durationMinutes'] as num?)?.toInt();

  // Gym-only
  List<String> get missedExercises {
    final raw = workoutData?['missedExercises'];
    if (raw == null) return [];
    return (raw as List).map((e) => e as String).toList();
  }

  // Cardio-only
  double? get cardioDistanceKm => (workoutData?['distanceKm'] as num?)?.toDouble();
  String? get cardioIntensity => workoutData?['intensity'] as String?;
  String? get cardioType => workoutData?['sessionType'] as String?;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'done': done,
        'date': date.toIso8601String(),
        'time': time,
        if (workoutData != null) 'workoutData': workoutData,
      };

  factory Task.fromMap(Map<dynamic, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        done: map['done'] as bool,
        date: DateTime.parse(map['date'] as String),
        time: map['time'] as String?,
        workoutData: map['workoutData'] != null
            ? Map<String, dynamic>.from(map['workoutData'] as Map)
            : null,
      );

  Task copyWith({bool? done}) => Task(
        id: id,
        title: title,
        done: done ?? this.done,
        date: date,
        time: time,
        workoutData: workoutData,
      );
}
