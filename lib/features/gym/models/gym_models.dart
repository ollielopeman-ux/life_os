class LibraryExercise {
  final String id;
  final String name;
  final double defaultWeight;
  final int defaultReps;

  LibraryExercise({
    required this.id,
    required this.name,
    this.defaultWeight = 20.0,
    this.defaultReps = 8,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'defaultWeight': defaultWeight,
        'defaultReps': defaultReps,
      };

  factory LibraryExercise.fromMap(Map map) => LibraryExercise(
        id: map['id'] as String,
        name: map['name'] as String,
        defaultWeight: (map['defaultWeight'] as num?)?.toDouble() ?? 20.0,
        defaultReps: (map['defaultReps'] as int?) ?? 8,
      );

  LibraryExercise copyWith({String? name, double? defaultWeight, int? defaultReps}) =>
      LibraryExercise(
        id: id,
        name: name ?? this.name,
        defaultWeight: defaultWeight ?? this.defaultWeight,
        defaultReps: defaultReps ?? this.defaultReps,
      );
}

class SetEntry {
  final double weight;
  final int reps;
  final DateTime date;

  SetEntry({required this.weight, required this.reps, required this.date});

  Map<String, dynamic> toMap() => {
        'weight': weight,
        'reps': reps,
        'date': date.toIso8601String(),
      };

  factory SetEntry.fromMap(Map map) => SetEntry(
        weight: (map['weight'] as num).toDouble(),
        reps: map['reps'] as int,
        date: DateTime.parse(map['date'] as String),
      );
}

class ExerciseTemplate {
  final String name;
  final double usualWeight;
  final int usualReps;
  final int usualSets;
  final List<SetEntry> history;

  ExerciseTemplate({
    required this.name,
    this.usualWeight = 20.0,
    this.usualReps = 8,
    this.usualSets = 3,
    List<SetEntry>? history,
  }) : history = history ?? [];

  Map<String, dynamic> toMap() => {
        'name': name,
        'usualWeight': usualWeight,
        'usualReps': usualReps,
        'usualSets': usualSets,
        'history': history.map((s) => s.toMap()).toList(),
      };

  factory ExerciseTemplate.fromMap(Map map) => ExerciseTemplate(
        name: map['name'] as String,
        usualWeight: (map['usualWeight'] as num?)?.toDouble() ?? 20.0,
        usualReps: (map['usualReps'] as int?) ?? 8,
        usualSets: (map['usualSets'] as int?) ?? 3,
        history:
            (map['history'] as List? ?? []).map((s) => SetEntry.fromMap(s as Map)).toList(),
      );

  ExerciseTemplate copyWith({double? usualWeight, int? usualReps, int? usualSets, List<SetEntry>? history}) =>
      ExerciseTemplate(
        name: name,
        usualWeight: usualWeight ?? this.usualWeight,
        usualReps: usualReps ?? this.usualReps,
        usualSets: usualSets ?? this.usualSets,
        history: history ?? this.history,
      );
}

class WorkoutDay {
  final String id;
  final String name;
  final bool isRestDay;
  // DateTime.weekday values: 1=Mon, 2=Tue, ..., 7=Sun
  final List<int> weekdays;
  final List<ExerciseTemplate> exercises;

  WorkoutDay({
    required this.id,
    required this.name,
    this.isRestDay = false,
    List<int>? weekdays,
    List<ExerciseTemplate>? exercises,
  })  : weekdays = weekdays ?? [],
        exercises = exercises ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isRestDay': isRestDay,
        'weekdays': weekdays,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  factory WorkoutDay.fromMap(Map map) => WorkoutDay(
        id: map['id'] as String,
        name: map['name'] as String,
        isRestDay: map['isRestDay'] as bool? ?? false,
        weekdays:
            (map['weekdays'] as List? ?? []).map((e) => e as int).toList(),
        exercises: (map['exercises'] as List? ?? [])
            .map((e) => ExerciseTemplate.fromMap(e as Map))
            .toList(),
      );

  WorkoutDay copyWith({
    String? name,
    bool? isRestDay,
    List<int>? weekdays,
    List<ExerciseTemplate>? exercises,
  }) =>
      WorkoutDay(
        id: id,
        name: name ?? this.name,
        isRestDay: isRestDay ?? this.isRestDay,
        weekdays: weekdays ?? this.weekdays,
        exercises: exercises ?? this.exercises,
      );
}

class GymSplit {
  final String id;
  final String name;
  final bool isPrimary;
  final List<WorkoutDay> days;

  GymSplit({required this.id, required this.name, this.isPrimary = false, List<WorkoutDay>? days})
      : days = days ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isPrimary': isPrimary,
        'days': days.map((d) => d.toMap()).toList(),
      };

  factory GymSplit.fromMap(Map map) => GymSplit(
        id: map['id'] as String,
        name: map['name'] as String,
        isPrimary: map['isPrimary'] as bool? ?? false,
        days:
            (map['days'] as List? ?? []).map((d) => WorkoutDay.fromMap(d as Map)).toList(),
      );

  GymSplit copyWith({String? name, bool? isPrimary, List<WorkoutDay>? days}) => GymSplit(
        id: id,
        name: name ?? this.name,
        isPrimary: isPrimary ?? this.isPrimary,
        days: days ?? this.days,
      );
}
