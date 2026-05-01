class BodyEntry {
  final String id;
  final DateTime date;
  final double? weight;
  final String? photoPath;
  final String? note;

  BodyEntry({
    required this.id,
    required this.date,
    this.weight,
    this.photoPath,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'photoPath': photoPath,
        'note': note,
      };

  factory BodyEntry.fromMap(Map<dynamic, dynamic> map) => BodyEntry(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
        photoPath: map['photoPath'] as String?,
        note: map['note'] as String?,
      );
}
