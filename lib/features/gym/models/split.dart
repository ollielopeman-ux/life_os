class Exercise {
  final String name;
  final List<SetEntry> sets;

  Exercise({required this.name, List<SetEntry>? sets}) : sets = sets ?? [];

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets.map((s) => s.toMap()).toList(),
      };

  factory Exercise.fromMap(Map<dynamic, dynamic> map) => Exercise(
        name: map['name'] as String,
        sets: (map['sets'] as List? ?? [])
            .map((s) => SetEntry.fromMap(s as Map))
            .toList(),
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

  factory SetEntry.fromMap(Map<dynamic, dynamic> map) => SetEntry(
        weight: (map['weight'] as num).toDouble(),
        reps: map['reps'] as int,
        date: DateTime.parse(map['date'] as String),
      );
}

class Split {
  final String id;
  final String name;
  final List<Exercise> exercises;

  Split({required this.id, required this.name, List<Exercise>? exercises})
      : exercises = exercises ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  factory Split.fromMap(Map<dynamic, dynamic> map) => Split(
        id: map['id'] as String,
        name: map['name'] as String,
        exercises: (map['exercises'] as List? ?? [])
            .map((e) => Exercise.fromMap(e as Map))
            .toList(),
      );

  Split copyWith({String? name, List<Exercise>? exercises}) => Split(
        id: id,
        name: name ?? this.name,
        exercises: exercises ?? this.exercises,
      );
}
