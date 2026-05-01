import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/body_provider.dart';
import '../models/body_entry.dart';
import '../../../shared/services/notification_service.dart';
import '../../settings/providers/settings_provider.dart';

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
    final accent = Theme.of(context).colorScheme.primary;
    final entries = ref.watch(bodyProvider);

    // Map date-key → entries for that day (for calendar dots)
    final entryMap = <String, List<BodyEntry>>{};
    for (final e in entries) {
      entryMap.putIfAbsent(_dateKey(e.date), () => []).add(e);
    }

    final weightEntries = entries.where((e) => e.weight != null).toList();
    final weightUnit = ref.watch(settingsProvider.select((s) => s.weightUnit));
    final pageTopPad = ref.watch(settingsProvider.select((s) => s.pageTopPad));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, pageTopPad, 20, 0),
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
                      _KpiRow(entries: weightEntries, unit: weightUnit),
                      const SizedBox(height: 10),
                      _GoalWeightBanner(
                          entries: weightEntries, unit: weightUnit),
                      const SizedBox(height: 6),
                      if (weightEntries.length >= 2)
                        _WeightChart(entries: weightEntries, unit: weightUnit),
                      const SizedBox(height: 16),
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
                              color: accent.withValues(alpha: 0.4),
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
  final String unit;
  const _KpiRow({required this.entries, required this.unit});

  @override
  Widget build(BuildContext context) {
    double conv(double kg) => unit == 'lbs' ? kg * 2.20462 : kg;
    String fmt(double kg) => conv(kg).toStringAsFixed(1);

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
        trend7 = conv(current) - conv(older.weight!);
      }
    }

    // Streak: consecutive days with any log (deduplicated by day)
    int streak = 0;
    if (entries.isNotEmpty) {
      final uniqueDays = entries.map((e) => _dayOnly(e.date)).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
      var expected = _dayOnly(DateTime.now());
      for (final d in uniqueDays) {
        if (d == expected) {
          streak++;
          expected = expected.subtract(const Duration(days: 1));
        } else if (d.isBefore(expected)) {
          break;
        }
      }
    }

    return Row(
      children: [
        Expanded(
            child: _KpiCard(
                label: 'CURRENT',
                value: current != null ? '${fmt(current)} $unit' : '—')),
        const SizedBox(width: 10),
        Expanded(
            child: _KpiCard(
                label: '7-DAY',
                value: trend7 == null
                    ? '—'
                    : '${trend7 >= 0 ? '+' : ''}${trend7.toStringAsFixed(1)} $unit',
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

// ── Goal Weight Banner ─────────────────────────────────────────────────────────

class _GoalWeightBanner extends ConsumerWidget {
  final List<BodyEntry> entries;
  final String unit;
  const _GoalWeightBanner({required this.entries, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final targetKg = ref.watch(settingsProvider.select((s) => s.targetWeightKg));
    if (targetKg == null || entries.isEmpty) return const SizedBox.shrink();

    double conv(double kg) => unit == 'lbs' ? kg * 2.20462 : kg;
    String fmt(double kg) => conv(kg).toStringAsFixed(1);

    final currentKg = entries.first.weight!;
    final startKg = entries.last.weight!;
    final target = conv(targetKg);
    final current = conv(currentKg);
    final start = conv(startKg);

    final totalChange = (target - start).abs();
    final progress = totalChange == 0
        ? 1.0
        : ((current - start) / (target - start)).clamp(0.0, 1.0);
    final remaining = (target - current).abs();
    final done = progress >= 1.0;
    final label = done
        ? 'Goal reached!'
        : '${fmt(remaining)} $unit to go';
    final color = done ? const Color(0xFF34C759) : accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_outline : Icons.flag_outlined,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Goal  ${fmt(targetKg)} $unit',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF2C2C2E),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weight Sparkline ───────────────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<BodyEntry> entries; // weight-only, newest first
  final String unit;
  const _WeightChart({required this.entries, required this.unit});

  @override
  Widget build(BuildContext context) {
    double conv(double kg) => unit == 'lbs' ? kg * 2.20462 : kg;

    // Take up to 30 most-recent entries, reverse to chronological
    final pts = entries.take(30).toList().reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < pts.length; i++) {
      spots.add(FlSpot(i.toDouble(), conv(pts[i].weight!)));
    }
    final weights = pts.map((e) => conv(e.weight!));
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final pad = (maxW - minW) < 1.0 ? 1.0 : (maxW - minW) * 0.2;
    final first = conv(pts.first.weight!);
    final last = conv(pts.last.weight!);
    final trending = last - first;
    final lineColor = trending <= 0
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF6B6B);

    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('TREND',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${trending >= 0 ? '+' : ''}${trending.toStringAsFixed(1)} $unit',
                style: TextStyle(
                    color: lineColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                minY: minW - pad,
                maxY: maxW + pad,
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) {
                        final isLast = idx == spots.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 4 : 2,
                          color: lineColor,
                          strokeWidth: isLast ? 2 : 0,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.18),
                          lineColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final accent = Theme.of(context).colorScheme.primary;
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
                              color: accent,
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
                              : accent),
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
            children: [
              _Dot(color: accent),
              const SizedBox(width: 6),
              const Text('Weight',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 20),
              const _Dot(color: Colors.white54),
              const SizedBox(width: 6),
              const Text('Photo',
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
            Builder(builder: (ctx) {
              final unit = ref.watch(settingsProvider.select((s) => s.weightUnit));
              final display = unit == 'lbs'
                  ? '${(weightEntry.weight! * 2.20462).toStringAsFixed(1)} lbs'
                  : '${weightEntry.weight!.toStringAsFixed(1)} kg';
              return _DetailRow(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Weight',
                  value: display);
            }),
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
    final accent = Theme.of(context).colorScheme.primary;
    final entries = ref.watch(bodyProvider);
    final lastWeight =
        entries.where((e) => e.weight != null).firstOrNull?.weight;
    final unit = ref.watch(settingsProvider.select((s) => s.weightUnit));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Container(
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
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17),
                    decoration: InputDecoration(
                      hintText: 'Weight ($unit)',
                      filled: true,
                      fillColor: const Color(0xFF242428),
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
                          ? accent
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
                            ? accent
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
                  backgroundColor: accent,
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
      );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtWeight(double w) =>
    w % 1 == 0 ? w.toInt().toString() : w.toString();

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
