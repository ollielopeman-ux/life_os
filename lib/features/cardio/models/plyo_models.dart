class PlyoSetEntry {
  final int reps;
  final double? weight;
  final DateTime date;

  PlyoSetEntry({required this.reps, this.weight, required this.date});

  Map<String, dynamic> toMap() => {
        'reps': reps,
        'weight': weight,
        'date': date.millisecondsSinceEpoch,
      };

  factory PlyoSetEntry.fromMap(Map map) => PlyoSetEntry(
        reps: (map['reps'] as num).toInt(),
        weight: (map['weight'] as num?)?.toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      );
}

class PlyoExercise {
  final String id;
  final String name;
  final int defaultReps;
  final int defaultSets;
  final double? defaultWeight;
  final int? durationSeconds;
  final String? videoPath;
  final List<PlyoSetEntry> history;

  PlyoExercise({
    required this.id,
    required this.name,
    this.defaultReps = 10,
    this.defaultSets = 3,
    this.defaultWeight,
    this.durationSeconds,
    this.videoPath,
    List<PlyoSetEntry>? history,
  }) : history = history ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'defaultReps': defaultReps,
        'defaultSets': defaultSets,
        'defaultWeight': defaultWeight,
        'durationSeconds': durationSeconds,
        'videoPath': videoPath,
        'history': history.map((e) => e.toMap()).toList(),
      };

  factory PlyoExercise.fromMap(Map map) => PlyoExercise(
        id: map['id'] as String,
        name: map['name'] as String,
        defaultReps: map['defaultReps'] as int? ?? 10,
        defaultSets: map['defaultSets'] as int? ?? 3,
        defaultWeight: (map['defaultWeight'] as num?)?.toDouble(),
        durationSeconds: map['durationSeconds'] as int?,
        videoPath: map['videoPath'] as String?,
        history: (map['history'] as List? ?? [])
            .map((e) => PlyoSetEntry.fromMap(e as Map))
            .toList(),
      );

  PlyoExercise copyWith({
    String? name,
    int? defaultReps,
    int? defaultSets,
    double? defaultWeight,
    int? durationSeconds,
    String? videoPath,
    List<PlyoSetEntry>? history,
  }) =>
      PlyoExercise(
        id: id,
        name: name ?? this.name,
        defaultReps: defaultReps ?? this.defaultReps,
        defaultSets: defaultSets ?? this.defaultSets,
        defaultWeight: defaultWeight ?? this.defaultWeight,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        videoPath: videoPath ?? this.videoPath,
        history: history ?? this.history,
      );

  PlyoSetEntry? get pr {
    if (history.isEmpty) return null;
    return history.reduce((a, b) {
      final aScore = a.reps + (a.weight ?? 0) * 0.5;
      final bScore = b.reps + (b.weight ?? 0) * 0.5;
      return aScore >= bScore ? a : b;
    });
  }
}

class PlyoWorkout {
  final String id;
  final String name;
  final List<PlyoExercise> exercises;

  PlyoWorkout({
    required this.id,
    required this.name,
    List<PlyoExercise>? exercises,
  }) : exercises = exercises ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  factory PlyoWorkout.fromMap(Map map) => PlyoWorkout(
        id: map['id'] as String,
        name: map['name'] as String,
        exercises: (map['exercises'] as List? ?? [])
            .map((e) => PlyoExercise.fromMap(e as Map))
            .toList(),
      );

  PlyoWorkout copyWith({String? name, List<PlyoExercise>? exercises}) =>
      PlyoWorkout(
        id: id,
        name: name ?? this.name,
        exercises: exercises ?? this.exercises,
      );
}

class PlyoState {
  final List<PlyoWorkout> workouts;
  const PlyoState({required this.workouts});
}
