import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../../schedule/providers/schedule_provider.dart';

const _uuid = Uuid();

class BooksNotifier extends Notifier<List<Book>> {
  Box get _box => Hive.box('reading');

  @override
  List<Book> build() => _load();

  List<Book> _load() {
    final raw = _box.get('books', defaultValue: []) as List;
    return raw.map((e) => Book.fromMap(e as Map)).toList();
  }

  void _save() => _box.put('books', state.map((b) => b.toMap()).toList());

  void addBook({
    required String title,
    required String author,
    String? coverUrl,
    int? totalPages,
    String? openLibraryKey,
    String? description,
  }) {
    state = [
      ...state,
      Book(
        id: _uuid.v4(),
        title: title,
        author: author,
        status: 'want',
        coverUrl: coverUrl,
        totalPages: totalPages,
        openLibraryKey: openLibraryKey,
        description: description,
        addedAt: DateTime.now(),
      ),
    ];
    _save();
  }

  void startReading(String id) {
    state = state
        .map((b) => b.id == id
            ? b.copyWith(status: 'reading', startDate: DateTime.now())
            : b)
        .toList();
    _save();
    final book = state.firstWhere((b) => b.id == id);
    ref.read(scheduleProvider.notifier).addTask(
          'Started: ${book.title}',
          DateTime.now(),
          done: true,
        );
  }

  void updatePage(String id, int page) {
    state = state
        .map((b) => b.id == id ? b.copyWith(currentPage: page) : b)
        .toList();
    _save();
  }

  void markDone(String id, {double? rating, String? notes}) {
    state = state.map((b) {
      if (b.id != id) return b;
      return Book(
        id: b.id,
        title: b.title,
        author: b.author,
        status: 'done',
        coverUrl: b.coverUrl,
        totalPages: b.totalPages,
        openLibraryKey: b.openLibraryKey,
        description: b.description,
        startDate: b.startDate,
        completedDate: DateTime.now(),
        currentPage: b.currentPage,
        rating: rating,
        notes: notes?.isEmpty == true ? null : notes,
        addedAt: b.addedAt,
      );
    }).toList();
    _save();
    final book = state.firstWhere((b) => b.id == id);
    ref.read(scheduleProvider.notifier).addTask(
          'Finished: ${book.title}',
          DateTime.now(),
          done: true,
        );
  }

  void deleteBook(String id) {
    state = state.where((b) => b.id != id).toList();
    _save();
  }
}

final booksProvider =
    NotifierProvider<BooksNotifier, List<Book>>(BooksNotifier.new);
