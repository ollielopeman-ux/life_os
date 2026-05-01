const kCardioTypes = [
  'Running',
  'Cycling',
  'Swimming',
  'Rowing',
  'Walking',
  'HIIT',
  'Other',
];

const kCardioIntensities = ['Easy', 'Moderate', 'Hard', 'Race Pace'];

class CardioSession {
  final String id;
  final String name;
  final String type; // from kCardioTypes
  final int? durationMinutes;
  final double? distanceKm;
  final String intensity; // from kCardioIntensities
  final List<int> weekdays; // 1=Mon, 7=Sun

  CardioSession({
    required this.id,
    required this.name,
    this.type = 'Running',
    this.durationMinutes,
    this.distanceKm,
    this.intensity = 'Moderate',
    List<int>? weekdays,
  }) : weekdays = weekdays ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'durationMinutes': durationMinutes,
        'distanceKm': distanceKm,
        'intensity': intensity,
        'weekdays': weekdays,
      };

  factory CardioSession.fromMap(Map map) => CardioSession(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as String? ?? 'Running',
        durationMinutes: map['durationMinutes'] as int?,
        distanceKm: (map['distanceKm'] as num?)?.toDouble(),
        intensity: map['intensity'] as String? ?? 'Moderate',
        weekdays:
            (map['weekdays'] as List? ?? []).map((e) => e as int).toList(),
      );

  CardioSession copyWith({
    String? name,
    String? type,
    int? durationMinutes,
    double? distanceKm,
    String? intensity,
    List<int>? weekdays,
  }) =>
      CardioSession(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        distanceKm: distanceKm ?? this.distanceKm,
        intensity: intensity ?? this.intensity,
        weekdays: weekdays ?? this.weekdays,
      );
}

class CardioSplit {
  final String id;
  final String name;
  final bool isPrimary;
  final List<CardioSession> sessions;

  CardioSplit({
    required this.id,
    required this.name,
    this.isPrimary = false,
    List<CardioSession>? sessions,
  }) : sessions = sessions ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isPrimary': isPrimary,
        'sessions': sessions.map((s) => s.toMap()).toList(),
      };

  factory CardioSplit.fromMap(Map map) => CardioSplit(
        id: map['id'] as String,
        name: map['name'] as String,
        isPrimary: map['isPrimary'] as bool? ?? false,
        sessions: (map['sessions'] as List? ?? [])
            .map((s) => CardioSession.fromMap(s as Map))
            .toList(),
      );

  CardioSplit copyWith({
    String? name,
    bool? isPrimary,
    List<CardioSession>? sessions,
  }) =>
      CardioSplit(
        id: id,
        name: name ?? this.name,
        isPrimary: isPrimary ?? this.isPrimary,
        sessions: sessions ?? this.sessions,
      );
}

class CardioState {
  final List<CardioSplit> splits;
  final String? selectedSplitId;

  CardioState({required this.splits, this.selectedSplitId});

  CardioSplit? get selectedSplit {
    if (splits.isEmpty) return null;
    if (selectedSplitId != null) {
      final found = splits.where((s) => s.id == selectedSplitId).firstOrNull;
      if (found != null) return found;
    }
    return splits.firstWhere((s) => s.isPrimary, orElse: () => splits.first);
  }
}
