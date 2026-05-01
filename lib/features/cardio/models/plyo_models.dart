class PlyoExercise {
  final String id;
  final String name;
  final int defaultReps;

  PlyoExercise({required this.id, required this.name, this.defaultReps = 10});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'defaultReps': defaultReps,
      };

  factory PlyoExercise.fromMap(Map map) => PlyoExercise(
        id: map['id'] as String,
        name: map['name'] as String,
        defaultReps: map['defaultReps'] as int? ?? 10,
      );

  PlyoExercise copyWith({String? name, int? defaultReps}) => PlyoExercise(
        id: id,
        name: name ?? this.name,
        defaultReps: defaultReps ?? this.defaultReps,
      );
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
