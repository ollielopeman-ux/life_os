import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/body_provider.dart';
import '../models/body_entry.dart';
import '../../../shared/services/notification_service.dart';

class BodyScreen extends ConsumerStatefulWidget {
  const BodyScreen({super.key});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  DateTime _calMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    NotificationService.pendingAction.addListener(_handleNotificationAction);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _handleNotificationAction());
  }

  @override
  void dispose() {
    NotificationService.pendingAction.removeListener(_handleNotificationAction);
    super.dispose();
  }

  void _handleNotificationAction() {
    if (NotificationService.pendingAction.value == kPayloadWeight && mounted) {
      NotificationService.pendingAction.value = null;
      _showAddSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(bodyProvider);

    // Map date-key → entries for that day (for calendar dots)
    final entryMap = <String, List<BodyEntry>>{};
    for (final e in entries) {
      entryMap.putIfAbsent(_dateKey(e.date), () => []).add(e);
    }

    final weightEntries = entries.where((e) => e.weight != null).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Center(
                child: Text('WEIGHT',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    children: [
                      _KpiRow(entries: weightEntries),
                      const SizedBox(height: 24),
                      _CalendarCard(
                        month: _calMonth,
                        entryMap: entryMap,
                        onMonthChanged: (m) => setState(() => _calMonth = m),
                        onDayTap: (date) {
                          final key = _dateKey(date);
                          final day = entryMap[key];
                          if (day != null && day.isNotEmpty) {
                            _showDayDetail(context, date, day);
                          }
                        },
                      ),
                    ],
                  ),

                  // Floating log button above the nav bar
                  Positioned(
                    bottom: 80,
                    left: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => _showAddSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B7FA8).withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: Colors.white, size: 22),
                            SizedBox(width: 10),
                            Text('Log Today',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddEntrySheet(),
    );
  }

  void _showDayDetail(
      BuildContext context, DateTime date, List<BodyEntry> entries) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(date: date, entries: entries),
    );
  }
}

// ── KPI Row ────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final List<BodyEntry> entries; // weight-only, newest first
  const _KpiRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final current = entries.isNotEmpty ? entries.first.weight : null;

    // 7-day trend: current vs last entry that is >= 7 days ago
    double? trend7;
    if (current != null && entries.length >= 2) {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final older = entries.firstWhere(
        (e) => e.date.isBefore(cutoff),
        orElse: () => entries.last,
      );
      if (older != entries.first) {
        trend7 = current - older.weight!;
      }
    }

    // Streak: consecutive days with any log
    int streak = 0;
    if (entries.isNotEmpty) {
      var day = _dayOnly(DateTime.now());
      for (final e in entries) {
        final eDay = _dayOnly(e.date);
        if (eDay == day || eDay == day.subtract(const Duration(days: 1))) {
          streak++;
          day = eDay;
        } else {
          break;
        }
      }
    }

    return Row(
      children: [
        Expanded(
            child: _KpiCard(
                label: 'CURRENT',
                value: current != null ? '${current.toStringAsFixed(1)} kg' : '—')),
        const SizedBox(width: 10),
        Expanded(
            child: _KpiCard(
                label: '7-DAY',
                value: trend7 == null
                    ? '—'
                    : '${trend7 >= 0 ? '+' : ''}${trend7.toStringAsFixed(1)} kg',
                valueColor: trend7 == null
                    ? null
                    : trend7 < 0
                        ? const Color(0xFF4CAF50)
                        : trend7 > 0
                            ? const Color(0xFFFF6B6B)
                            : null)),
        const SizedBox(width: 10),
        Expanded(
            child: _KpiCard(
                label: 'STREAK',
                value: streak == 0 ? '—' : '$streak ${streak == 1 ? 'day' : 'days'}')),
      ],
    );
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _KpiCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 9, letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Calendar ───────────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  final DateTime month;
  final Map<String, List<BodyEntry>> entryMap;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDayTap;
  const _CalendarCard({
    required this.month,
    required this.entryMap,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // offset so week starts on Monday (weekday 1 → 0 offset)
    final startOffset = firstDay.weekday - 1;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: Colors.white38, size: 22),
                visualDensity: VisualDensity.compact,
                onPressed: () => onMonthChanged(
                    DateTime(month.year, month.month - 1)),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: Colors.white38, size: 22),
                visualDensity: VisualDensity.compact,
                onPressed: () => onMonthChanged(
                    DateTime(month.year, month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekday headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
              return Expanded(
                child: Text(d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Day grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.85,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startOffset) return const SizedBox();
              final day = i - startOffset + 1;
              final date = DateTime(month.year, month.month, day);
              final key = _dateKey(date);
              final dayEntries = entryMap[key];
              final hasWeight =
                  dayEntries?.any((e) => e.weight != null) ?? false;
              final hasPhoto =
                  dayEntries?.any((e) => e.photoPath != null) ?? false;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isFuture = date.isAfter(today);

              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () => onDayTap(date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: isToday
                          ? BoxDecoration(
                              color: const Color(0xFF5B7FA8),
                              borderRadius: BorderRadius.circular(10),
                            )
                          : null,
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isFuture
                                ? Colors.white12
                                : isToday
                                    ? Colors.white
                                    : dayEntries != null
                                        ? Colors.white
                                        : Colors.white38,
                            fontWeight: isToday || dayEntries != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasWeight)
                          _Dot(color: isToday
                              ? Colors.white54
                              : const Color(0xFF5B7FA8)),
                        if (hasWeight && hasPhoto)
                          const SizedBox(width: 3),
                        if (hasPhoto)
                          const _Dot(color: Colors.white54),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Legend
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFF2C2C2E)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _Dot(color: Color(0xFF5B7FA8)),
              SizedBox(width: 6),
              Text('Weight',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              SizedBox(width: 20),
              _Dot(color: Colors.white54),
              SizedBox(width: 6),
              Text('Photo',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Day Detail Sheet ───────────────────────────────────────────────────────────

class _DayDetailSheet extends ConsumerWidget {
  final DateTime date;
  final List<BodyEntry> entries;
  const _DayDetailSheet({required this.date, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoEntry = entries.firstWhere(
      (e) => e.photoPath != null,
      orElse: () => entries.first,
    );
    final weightEntry = entries.firstWhere(
      (e) => e.weight != null,
      orElse: () => entries.first,
    );
    final hasPhoto = photoEntry.photoPath != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Date
          Text(DateFormat('EEEE, d MMMM yyyy').format(date),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 16),

          // Weight
          if (weightEntry.weight != null) ...[
            _DetailRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: '${weightEntry.weight!.toStringAsFixed(1)} kg'),
            const SizedBox(height: 10),
          ],

          // Note
          if (weightEntry.note != null && weightEntry.note!.isNotEmpty) ...[
            _DetailRow(
                icon: Icons.notes_outlined,
                label: 'Note',
                value: weightEntry.note!),
            const SizedBox(height: 10),
          ],

          // Photo
          if (hasPhoto) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(photoEntry.photoPath!),
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Delete button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete entry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white38,
                side: const BorderSide(color: Color(0xFF3A3A3C)),
              ),
              onPressed: () {
                for (final e in entries) {
                  ref.read(bodyProvider.notifier).deleteEntry(e.id);
                }
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Text('$label  ',
            style: const TextStyle(color: Colors.white38, fontSize: 14)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Add Entry Sheet ────────────────────────────────────────────────────────────

class _AddEntrySheet extends ConsumerStatefulWidget {
  const _AddEntrySheet();

  @override
  ConsumerState<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<_AddEntrySheet> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  String? _photoPath;

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file != null) setState(() => _photoPath = file.path);
  }

  void _submit() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null && _photoPath == null &&
        _noteController.text.trim().isEmpty) { return; }
    ref.read(bodyProvider.notifier).addEntry(
          weight: weight,
          photoPath: _photoPath,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(bodyProvider);
    final lastWeight =
        entries.where((e) => e.weight != null).firstOrNull?.weight;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 32),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Log Progress',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Weight field + last weight chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17),
                    decoration: const InputDecoration(
                      hintText: 'Weight (kg)',
                      filled: true,
                      fillColor: Color(0xFF242428),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (lastWeight != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() =>
                        _weightController.text =
                            _fmtWeight(lastWeight)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242428),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF3A3A3C)),
                      ),
                      child: Column(
                        children: [
                          const Text('Last',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10)),
                          Text(
                            lastWeight.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Note field
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Note (optional)',
                filled: true,
                fillColor: Color(0xFF242428),
              ),
            ),
            const SizedBox(height: 16),

            // Photo preview
            if (_photoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(_photoPath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
            ],

            // Camera button (big, iOS-style)
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF242428),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF3A3A3C)),
                ),
                child: Column(
                  children: [
                    Icon(
                      _photoPath != null
                          ? Icons.check_circle_outline
                          : Icons.camera_alt_rounded,
                      color: _photoPath != null
                          ? const Color(0xFF5B7FA8)
                          : Colors.white54,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _photoPath != null
                          ? 'Photo taken — tap to retake'
                          : 'Take Photo',
                      style: TextStyle(
                        color: _photoPath != null
                            ? const Color(0xFF5B7FA8)
                            : Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7FA8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtWeight(double w) =>
    w % 1 == 0 ? w.toInt().toString() : w.toString();

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
