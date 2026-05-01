class Book {
  final String id;
  final String title;
  final String author;
  final String status; // 'want', 'reading', 'done'
  final String? coverUrl;
  final int? totalPages;
  final String? openLibraryKey;
  final String? description;
  final DateTime? startDate;
  final DateTime? completedDate;
  final int? currentPage;
  final double? rating;
  final String? notes;
  final DateTime addedAt;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    this.coverUrl,
    this.totalPages,
    this.openLibraryKey,
    this.description,
    this.startDate,
    this.completedDate,
    this.currentPage,
    this.rating,
    this.notes,
    required this.addedAt,
  });

  double? get progressPercent {
    if (currentPage == null || totalPages == null || totalPages! <= 0) return null;
    return (currentPage! / totalPages!).clamp(0.0, 1.0);
  }

  int get daysReading {
    if (startDate == null) return 1;
    return DateTime.now().difference(startDate!).inDays + 1;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'status': status,
        'coverUrl': coverUrl,
        'totalPages': totalPages,
        'openLibraryKey': openLibraryKey,
        'description': description,
        'startDate': startDate?.toIso8601String(),
        'completedDate': completedDate?.toIso8601String(),
        'currentPage': currentPage,
        'rating': rating,
        'notes': notes,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Book.fromMap(Map<dynamic, dynamic> map) => Book(
        id: map['id'] as String,
        title: map['title'] as String,
        author: map['author'] as String,
        status: (map['status'] as String?) ?? 'want',
        coverUrl: map['coverUrl'] as String?,
        totalPages: (map['totalPages'] as num?)?.toInt(),
        openLibraryKey: map['openLibraryKey'] as String?,
        description: map['description'] as String?,
        startDate: map['startDate'] != null
            ? DateTime.parse(map['startDate'] as String)
            : null,
        completedDate: map['completedDate'] != null
            ? DateTime.parse(map['completedDate'] as String)
            : null,
        currentPage: (map['currentPage'] as num?)?.toInt(),
        rating: (map['rating'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
        addedAt: DateTime.parse(map['addedAt'] as String),
      );

  Book copyWith({
    String? status,
    DateTime? startDate,
    DateTime? completedDate,
    int? currentPage,
  }) =>
      Book(
        id: id,
        title: title,
        author: author,
        status: status ?? this.status,
        coverUrl: coverUrl,
        totalPages: totalPages,
        openLibraryKey: openLibraryKey,
        description: description,
        startDate: startDate ?? this.startDate,
        completedDate: completedDate ?? this.completedDate,
        currentPage: currentPage ?? this.currentPage,
        rating: rating,
        notes: notes,
        addedAt: addedAt,
      );
}
