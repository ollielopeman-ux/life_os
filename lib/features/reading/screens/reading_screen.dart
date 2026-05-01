import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../providers/reading_provider.dart';
import '../../../shared/services/notification_service.dart';

// ── Search result data class ───────────────────────────────────────────────────

class _SearchResult {
  final String title;
  final String author;
  final String? coverUrl;
  final int? totalPages;
  final String openLibraryKey;
  final String? description;

  const _SearchResult({
    required this.title,
    required this.author,
    this.coverUrl,
    this.totalPages,
    required this.openLibraryKey,
    this.description,
  });

  static String? _cover(dynamic coverId) {
    if (coverId == null) return null;
    return 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
  }

  factory _SearchResult.fromJson(Map<String, dynamic> json) {
    String? description;
    final fs = json['first_sentence'];
    if (fs is String) {
      description = fs;
    } else if (fs is Map) {
      description = fs['value'] as String?;
    }
    return _SearchResult(
      title: (json['title'] as String?) ?? 'Unknown Title',
      author: ((json['author_name'] as List?)?.firstOrNull as String?) ??
          'Unknown Author',
      coverUrl: _cover(json['cover_i']),
      totalPages: (json['number_of_pages_median'] as num?)?.toInt(),
      openLibraryKey: (json['key'] as String?) ?? '',
      description: description,
    );
  }
}

// ── Main screen ────────────────────────────────────────────────────────────────

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() { if (mounted) setState(() {}); });
    NotificationService.pendingAction.addListener(_handleNotificationAction);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotificationAction());
  }

  @override
  void dispose() {
    NotificationService.pendingAction.removeListener(_handleNotificationAction);
    _tabs.dispose();
    super.dispose();
  }

  void _handleNotificationAction() {
    if (NotificationService.pendingAction.value == kPayloadAddBook && mounted) {
      NotificationService.pendingAction.value = null;
      _showSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);
    final want = books.where((b) => b.status == 'want').toList();
    final reading = books.where((b) => b.status == 'reading').toList();
    final done = books.where((b) => b.status == 'done').toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Center(
                child: Text('READING',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 0.5),
                ),
                child: Row(
                  children: [
                    _TabBtn(
                      label: 'WANT',
                      count: want.length,
                      selected: _tabs.index == 0,
                      onTap: () => _tabs.animateTo(0),
                    ),
                    _TabBtn(
                      label: 'READING',
                      count: reading.length,
                      selected: _tabs.index == 1,
                      onTap: () => _tabs.animateTo(1),
                    ),
                    _TabBtn(
                      label: 'DONE',
                      count: done.length,
                      selected: _tabs.index == 2,
                      onTap: () => _tabs.animateTo(2),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _WantTab(books: want, onAddBook: _showSearch),
                  _ReadingTab(books: reading),
                  _DoneTab(books: done),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SearchSheet(),
    );
  }
}

// ── Want tab ───────────────────────────────────────────────────────────────────

class _WantTab extends StatelessWidget {
  final List<Book> books;
  final VoidCallback onAddBook;
  const _WantTab({required this.books, required this.onAddBook});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return GestureDetector(
        onTap: onAddBook,
        behavior: HitTestBehavior.opaque,
        child: const _EmptyState(
          icon: Icons.bookmark_border,
          message: 'Your reading list is empty',
          sub: 'Tap anywhere to add a book',
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.58,
      ),
      itemCount: books.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return GestureDetector(
            onTap: onAddBook,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C2C2E)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white24, size: 30),
                  SizedBox(height: 4),
                  Text('Add',
                      style: TextStyle(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ),
          );
        }
        return _WantBookCard(book: books[i - 1]);
      },
    );
  }
}

class _WantBookCard extends StatelessWidget {
  final Book book;
  const _WantBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _WantDetailSheet(book: book),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _CoverImage(url: book.coverUrl, title: book.title),
            ),
          ),
          const SizedBox(height: 6),
          Text(book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          Text(book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Reading tab ────────────────────────────────────────────────────────────────

class _ReadingTab extends StatelessWidget {
  final List<Book> books;
  const _ReadingTab({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const _EmptyState(
        icon: Icons.menu_book_outlined,
        message: 'Not reading anything yet',
        sub: 'Move a book from Want to start tracking',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: books.length,
      itemBuilder: (_, i) => _ReadingBookCard(book: books[i]),
    );
  }
}

class _ReadingBookCard extends StatelessWidget {
  final Book book;
  const _ReadingBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final progress = book.progressPercent;
    final days = book.daysReading;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReadingDetailSheet(book: book),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF5B7FA8).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                  width: 56,
                  height: 80,
                  child:
                      _CoverImage(url: book.coverUrl, title: book.title)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.schedule_outlined,
                        label: days == 1
                            ? 'Started today'
                            : '$days days',
                      ),
                      if (progress != null) ...[
                        const SizedBox(width: 8),
                        Text('${(progress * 100).toInt()}%',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFF2C2C2E),
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF5B7FA8)),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Done tab ───────────────────────────────────────────────────────────────────

class _DoneTab extends StatelessWidget {
  final List<Book> books;
  const _DoneTab({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        message: 'No finished books yet',
        sub: 'Books you complete will appear here',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: books.length,
      itemBuilder: (_, i) => _DoneBookCard(book: books[i]),
    );
  }
}

class _DoneBookCard extends StatelessWidget {
  final Book book;
  const _DoneBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final blurb = book.notes?.isNotEmpty == true
        ? book.notes!
        : book.description;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DoneDetailSheet(book: book),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                  width: 56,
                  height: 80,
                  child:
                      _CoverImage(url: book.coverUrl, title: book.title)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                  if (book.rating != null) ...[
                    const SizedBox(height: 6),
                    _StarDisplay(rating: book.rating!),
                  ],
                  if (blurb != null && blurb.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      blurb.length > 80
                          ? '${blurb.substring(0, 80)}…'
                          : blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontStyle: book.notes?.isNotEmpty == true
                              ? FontStyle.italic
                              : FontStyle.normal),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Want detail sheet ──────────────────────────────────────────────────────────

class _WantDetailSheet extends ConsumerWidget {
  final Book book;
  const _WantDetailSheet({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                    width: 80,
                    height: 112,
                    child:
                        _CoverImage(url: book.coverUrl, title: book.title)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(book.author,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 14)),
                    if (book.totalPages != null) ...[
                      const SizedBox(height: 6),
                      Text('${book.totalPages} pages',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (book.description != null &&
              book.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              book.description!.length > 220
                  ? '${book.description!.substring(0, 220)}…'
                  : book.description!,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13, height: 1.5),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(booksProvider.notifier).startReading(book.id);
                Navigator.pop(context);
              },
              child: const Text('Start Reading'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                ref.read(booksProvider.notifier).deleteBook(book.id);
                Navigator.pop(context);
              },
              child: const Text('Remove',
                  style: TextStyle(color: Colors.white38)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reading detail sheet ───────────────────────────────────────────────────────

class _ReadingDetailSheet extends ConsumerStatefulWidget {
  final Book book;
  const _ReadingDetailSheet({required this.book});

  @override
  ConsumerState<_ReadingDetailSheet> createState() =>
      _ReadingDetailSheetState();
}

class _ReadingDetailSheetState
    extends ConsumerState<_ReadingDetailSheet> {
  late final TextEditingController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = TextEditingController(
        text: widget.book.currentPage?.toString() ?? '');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(String val) {
    final page = int.tryParse(val);
    if (page != null && page >= 0) {
      ref.read(booksProvider.notifier).updatePage(widget.book.id, page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(booksProvider).firstWhere(
          (b) => b.id == widget.book.id,
          orElse: () => widget.book,
        );
    final progress = book.progressPercent;
    final days = book.daysReading;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DragHandle(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      width: 90,
                      height: 128,
                      child: _CoverImage(
                          url: book.coverUrl, title: book.title)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(book.author,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 12),
                      _InfoChip(
                        icon: Icons.schedule_outlined,
                        label: days == 1
                            ? 'Started today'
                            : 'Reading for $days days',
                      ),
                      if (book.startDate != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Since ${DateFormat('d MMM yyyy').format(book.startDate!)}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            const Text('PROGRESS',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1.4)),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _pageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Current page',
                      suffixText: book.totalPages != null
                          ? '/ ${book.totalPages}'
                          : null,
                    ),
                    onChanged: _onPageChanged,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                        color: Color(0xFF5B7FA8),
                        fontSize: 28,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),

            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF2C2C2E),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF5B7FA8)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              if (book.currentPage != null && book.totalPages != null)
                Text(
                  '${book.totalPages! - book.currentPage!} pages remaining',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      _MarkDoneSheet(bookId: widget.book.id),
                ),
                child: const Text('Mark as Done'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  ref
                      .read(booksProvider.notifier)
                      .deleteBook(book.id);
                  Navigator.pop(context);
                },
                child: const Text('Remove',
                    style: TextStyle(color: Colors.white38)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mark done sheet ────────────────────────────────────────────────────────────

class _MarkDoneSheet extends ConsumerStatefulWidget {
  final String bookId;
  const _MarkDoneSheet({required this.bookId});

  @override
  ConsumerState<_MarkDoneSheet> createState() => _MarkDoneSheetState();
}

class _MarkDoneSheetState extends ConsumerState<_MarkDoneSheet> {
  double _rating = 0;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final nav = Navigator.of(context);
    ref.read(booksProvider.notifier).markDone(
          widget.bookId,
          rating: _rating > 0 ? _rating : null,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
    nav.pop(); // _MarkDoneSheet
    nav.pop(); // _ReadingDetailSheet
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),
          const Text('Finished!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('How was it?',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 24),

          const Text('YOUR RATING',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () =>
                    setState(() => _rating = (i + 1).toDouble()),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < _rating
                        ? const Color(0xFFFFD700)
                        : Colors.white24,
                    size: 38,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          const Text('NOTES  (optional)',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.4)),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'Your thoughts on the book…'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}

// ── Done detail sheet ──────────────────────────────────────────────────────────

class _DoneDetailSheet extends ConsumerWidget {
  final Book book;
  const _DoneDetailSheet({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int? readDays;
    if (book.startDate != null && book.completedDate != null) {
      readDays =
          book.completedDate!.difference(book.startDate!).inDays + 1;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          children: [
            _DragHandle(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      width: 90,
                      height: 128,
                      child: _CoverImage(
                          url: book.coverUrl, title: book.title)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(book.author,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14)),
                      if (book.rating != null) ...[
                        const SizedBox(height: 10),
                        _StarDisplay(rating: book.rating!),
                      ],
                      const SizedBox(height: 8),
                      if (readDays != null)
                        Text(
                          'Read in $readDays ${readDays == 1 ? 'day' : 'days'}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      if (book.completedDate != null)
                        Text(
                          'Finished ${DateFormat('d MMM yyyy').format(book.completedDate!)}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (book.notes != null && book.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('YOUR NOTES',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1.4)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF242428),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(book.notes!,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                        fontStyle: FontStyle.italic)),
              ),
            ],
            if (book.description != null &&
                book.description!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('ABOUT',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1.4)),
              const SizedBox(height: 8),
              Text(book.description!,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.6)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove from library'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white38,
                  side: const BorderSide(color: Color(0xFF3A3A3C)),
                ),
                onPressed: () {
                  ref.read(booksProvider.notifier).deleteBook(book.id);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search sheet ───────────────────────────────────────────────────────────────

class _SearchSheet extends ConsumerStatefulWidget {
  const _SearchSheet();

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<_SearchSheet> {
  final _ctrl = TextEditingController();
  List<_SearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(
        const Duration(milliseconds: 600), () => _search(query.trim()));
  }

  Future<void> _search(String query) async {
    try {
      final uri = Uri.parse(
        'https://openlibrary.org/search.json'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&limit=10'
        '&fields=title,author_name,cover_i,number_of_pages_median,key,first_sentence',
      );
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final req = await client.getUrl(uri);
        final res = await req.close();
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final docs = (json['docs'] as List?) ?? [];
        if (mounted) {
          setState(() {
            _results = docs
                .map((d) =>
                    _SearchResult.fromJson(d as Map<String, dynamic>))
                .toList();
            _loading = false;
            _searched = true;
          });
        }
      } finally {
        client.close();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _searched = true;
        });
      }
    }
  }

  void _addFromResult(_SearchResult r) {
    ref.read(booksProvider.notifier).addBook(
          title: r.title,
          author: r.author,
          coverUrl: r.coverUrl,
          totalPages: r.totalPages,
          openLibraryKey: r.openLibraryKey,
          description: r.description,
        );
    Navigator.pop(context);
  }

  void _addManually() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    ref
        .read(booksProvider.notifier)
        .addBook(title: t, author: 'Unknown Author');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _DragHandle(),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Search by title or author…',
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF242428),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF5B7FA8)),
                        ),
                      )
                    : null,
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_results.isNotEmpty) {
      return ListView.separated(
        itemCount: _results.length,
        separatorBuilder: (ctx, i) =>
            const Divider(height: 1, color: Color(0xFF2C2C2E)),
        itemBuilder: (_, i) => _SearchResultTile(
          result: _results[i],
          onTap: () => _addFromResult(_results[i]),
        ),
      );
    }
    if (_searched && !_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No results found',
                style:
                    TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 16),
            if (_ctrl.text.trim().isNotEmpty)
              OutlinedButton(
                onPressed: _addManually,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60),
                child: Text('Add "${_ctrl.text.trim()}" manually'),
              ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search, size: 48, color: Colors.white12),
          SizedBox(height: 12),
          Text('Search for a book to add it',
              style:
                  TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final _SearchResult result;
  final VoidCallback onTap;
  const _SearchResultTile(
      {required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                  width: 40,
                  height: 58,
                  child: _CoverImage(
                      url: result.coverUrl, title: result.title)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(result.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            if (result.totalPages != null) ...[
              const SizedBox(width: 8),
              Text('${result.totalPages}p',
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 11)),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.add, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Tab Button ─────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn(
      {required this.label,
      required this.count,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3A3A3C) : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Center(
            child: Text(
              count > 0 ? '$label  $count' : label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  final String? url;
  final String title;
  const _CoverImage({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _CoverPlaceholder(title: title);
        },
        errorBuilder: (ctx, err, stack) => _CoverPlaceholder(title: title),
      );
    }
    return _CoverPlaceholder(title: title);
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final String title;
  const _CoverPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C2C2E),
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 22,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  final double rating;
  const _StarDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          5,
          (i) => Icon(
                i < rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: i < rating
                    ? const Color(0xFFFFD700)
                    : Colors.white24,
                size: 16,
              )),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF5B7FA8).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: const Color(0xFF5B7FA8).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF5B7FA8)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF5B7FA8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Colors.white12),
          const SizedBox(height: 16),
          Text(message,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 8),
          Text(sub,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }
}
