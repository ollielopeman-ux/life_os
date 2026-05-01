import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/checklist/providers/checklist_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../services/notification_service.dart';

const _barMargin = 14.0;
const _barHPad = 20.0;

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _showMore = false;

  @override
  void initState() {
    super.initState();
    NotificationService.pendingAction.addListener(_handleNotificationAction);
  }

  @override
  void dispose() {
    NotificationService.pendingAction.removeListener(_handleNotificationAction);
    super.dispose();
  }

  void _handleNotificationAction() {
    if (NotificationService.pendingAction.value == kPayloadChecklist &&
        mounted) {
      NotificationService.pendingAction.value = null;
      WidgetsBinding.instance
          .addPostFrameCallback((_) { if (mounted) _showQuickAdd(context); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final int currentIndex;
    if (location.startsWith('/gym')) {
      currentIndex = 0;
    } else if (location.startsWith('/cardio')) {
      currentIndex = 1;
    } else if (location.startsWith('/schedule')) {
      currentIndex = 2;
    } else if (location.startsWith('/body')) {
      currentIndex = 3;
    } else if (location.startsWith('/checklist')) {
      currentIndex = 4;
    } else if (location.startsWith('/reading')) {
      currentIndex = 5;
    } else {
      currentIndex = 4;
    }

    final navBarScale = ref.watch(settingsProvider.select((s) => s.navBarScale));
    final navBarBottom = ref.watch(settingsProvider.select((s) => s.navBarBottom));
    final navBarHPad = ref.watch(settingsProvider.select((s) => s.navBarHPad));
    final showLabels = ref.watch(settingsProvider.select((s) => s.showNavLabels));
    final barHeight = 64.0 * navBarScale;
    final pillHeight = showLabels ? barHeight + 18 : barHeight;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final reservedBottom = _barMargin + bottomInset;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(
                bottom: reservedBottom,
              ),
            ),
            child: widget.child,
          ),
          // Dismiss overlay when More popup is open
          if (_showMore)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showMore = false),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
          // More popup — right-anchored so Body sits above More, Reading above Calendar
          Positioned(
            right: navBarHPad + barHeight + 10,
            bottom: navBarBottom + bottomInset + pillHeight + 10,
            child: IgnorePointer(
              ignoring: !_showMore,
              child: AnimatedOpacity(
                opacity: _showMore ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: AnimatedSlide(
                  offset: _showMore ? Offset.zero : const Offset(0, 0.25),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _MorePopup(
                    currentIndex: currentIndex,
                    barHeight: barHeight,
                    showLabels: showLabels,
                    onReadingTap: () {
                      setState(() => _showMore = false);
                      final haptics = ref.read(settingsProvider).hapticsEnabled;
                      if (haptics) HapticFeedback.lightImpact();
                      context.go('/reading');
                    },
                    onBodyTap: () {
                      setState(() => _showMore = false);
                      final haptics = ref.read(settingsProvider).hapticsEnabled;
                      if (haptics) HapticFeedback.lightImpact();
                      context.go('/body');
                    },
                  ),
                ),
              ),
            ),
          ),
          // Nav bar + edit circle
          Positioned(
            left: navBarHPad,
            right: navBarHPad,
            bottom: navBarBottom + bottomInset,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _GlassNavPill(
                  currentIndex: currentIndex,
                  barHeight: barHeight,
                  showLabels: showLabels,
                  showMore: _showMore,
                  onMoreTap: () => setState(() => _showMore = !_showMore),
                  onTap: (i) {
                    setState(() => _showMore = false);
                    final haptics = ref.read(settingsProvider).hapticsEnabled;
                    if (haptics) HapticFeedback.lightImpact();
                    switch (i) {
                      case 0:
                        context.go('/gym');
                      case 1:
                        context.go('/cardio');
                      case 2:
                        context.go('/schedule');
                      case 4:
                        context.go('/checklist');
                    }
                  },
                ),
                const Spacer(),
                _EditCircle(
                  size: barHeight,
                  onTap: () => _showQuickAdd(context),
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    _showEditMenu(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMenu(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final buttonAreaBottom = safeBottom + _barMargin + 68.0;
    final router = GoRouter.of(context);

    showMenu<String>(
      context: context,
      color: const Color(0xFF2C2C2E),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(minWidth: 220),
      position: RelativeRect.fromLTRB(
        screen.width - _barHPad - 56,
        screen.height - buttonAreaBottom - 8,
        _barHPad,
        buttonAreaBottom + 8,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'body',
          child: _MenuRow(
            icon: Icons.monitor_weight_outlined,
            label: 'Log Weight & Photo',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'reading',
          child: _MenuRow(
            icon: Icons.menu_book_outlined,
            label: 'Add New Book',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ).then((value) {
      if (value == 'body') {
        NotificationService.pendingAction.value = kPayloadWeight;
        router.go('/body');
      }
      if (value == 'reading') {
        NotificationService.pendingAction.value = kPayloadAddBook;
        router.go('/reading');
      }
    });
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QuickAddSheet(),
    );
  }
}

// ── Quick Add Sheet ────────────────────────────────────────────────────────────

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet();

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _customController = TextEditingController();
  String? _selectedTime;
  bool _showCustom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _customController.dispose();
    super.dispose();
  }

  List<TimeOfDay> get _nextHours {
    final now = TimeOfDay.now();
    return List.generate(
        7, (i) => TimeOfDay(hour: (now.hour + i + 1) % 24, minute: 0));
  }

  String _hourKey(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:00';

  String _fmtHour(TimeOfDay t) {
    if (t.hour == 0) return '12 AM';
    if (t.hour == 12) return '12 PM';
    return t.hour < 12 ? '${t.hour} AM' : '${t.hour - 12} PM';
  }

  String _fmtTime(String t) {
    final p = t.split(':');
    final h = int.parse(p[0]);
    final m = p[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:$m $ampm';
  }

  String? _parseCustom(String input) {
    final s = input.trim().toLowerCase();
    final r1 = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$');
    final m1 = r1.firstMatch(s);
    if (m1 != null) {
      var h = int.parse(m1.group(1)!);
      final min = m1.group(2) != null ? int.parse(m1.group(2)!) : 0;
      if (m1.group(3) == 'pm' && h != 12) h += 12;
      if (m1.group(3) == 'am' && h == 12) h = 0;
      if (h >= 0 && h < 24 && min >= 0 && min < 60) {
        return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      }
    }
    final r2 = RegExp(r'^(\d{1,2}):(\d{2})$');
    final m2 = r2.firstMatch(s);
    if (m2 != null) {
      final h = int.parse(m2.group(1)!);
      final min = int.parse(m2.group(2)!);
      if (h >= 0 && h < 24 && min >= 0 && min < 60) {
        return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      }
    }
    return null;
  }

  void _confirmCustom() {
    final parsed = _parseCustom(_customController.text);
    if (parsed != null) {
      final hasText = _controller.text.trim().isNotEmpty;
      setState(() {
        _selectedTime = parsed;
        _showCustom = false;
        _customController.clear();
      });
      if (hasText) {
        _submit();
      } else {
        _focusNode.requestFocus();
      }
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    final now = DateTime.now();
    if (text.isNotEmpty) {
      ref.read(checklistProvider.notifier).addItem(
            text,
            DateTime(now.year, now.month, now.day),
            time: _selectedTime,
          );
    }
    Navigator.of(context).pop();
  }

  bool get _customTimeActive {
    if (_selectedTime == null) return false;
    return !_nextHours.map(_hourKey).contains(_selectedTime);
  }

  void _fillText(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
    setState(() {});
    _focusNode.requestFocus();
  }

  static const _quickItems = [
    ('Gym',      Icons.fitness_center,    Color(0xFF5B7FA8)),
    ('Cardio',   Icons.directions_run,    Color(0xFFE07B54)),
    ('Reading',  Icons.menu_book_rounded, Color(0xFF9B7FD4)),
    ('Journal',  Icons.edit_note_rounded, Colors.white54),
    ('Walk',     Icons.directions_walk,   Colors.white54),
    ('Meditate', Icons.self_improvement,  Colors.white54),
  ];

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final hours = _nextHours;
    final allItems = ref.watch(checklistProvider);
    final now = DateTime.now();
    final todayMid = DateTime(now.year, now.month, now.day);
    bool sameDay(DateTime d) =>
        d.year == todayMid.year && d.month == todayMid.month && d.day == todayMid.day;
    final todayTitles = allItems
        .where((i) => sameDay(i.date))
        .map((i) => i.title.toLowerCase())
        .toSet();
    final seenLower = <String>{};
    final recents = allItems
        .where((i) => !sameDay(i.date))
        .map((i) => i.title)
        .where((t) => !todayTitles.contains(t.toLowerCase()) && seenLower.add(t.toLowerCase()))
        .take(5)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: keyboardHeight + safeBottom + 12,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick add suggestions ────────────────────────────────────
            const Text('QUICK ADD',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickItems
                  .map((q) => _QuickChip(
                        label: q.$1,
                        icon: q.$2,
                        iconColor: q.$3,
                        onTap: () => _fillText(q.$1),
                      ))
                  .toList(),
            ),
            if (recents.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('RECENT',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: recents
                    .map((t) => _QuickChip(label: t, onTap: () => _fillText(t)))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFF2C2C2E)),
            const SizedBox(height: 12),
            // ── Text field ───────────────────────────────────────────────
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: "Add to today's checklist...",
                        hintStyle:
                            TextStyle(color: Colors.white38, fontSize: 16),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _submit,
                    child: Builder(builder: (ctx) {
                      final accent = Theme.of(ctx).colorScheme.primary;
                      return Container(
                        width: 48,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 22),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Row 1: first 5 upcoming hours
            Row(
              children: hours.sublist(0, 5).map((t) {
                final key = _hourKey(t);
                final sel = _selectedTime == key;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _TimeChip(
                      label: _fmtHour(t),
                      selected: sel,
                      onTap: () {
                        final hasText = _controller.text.trim().isNotEmpty;
                        if (!sel && hasText) {
                          setState(() => _selectedTime = key);
                          _submit();
                        } else {
                          setState(() {
                            _selectedTime = sel ? null : key;
                            _showCustom = false;
                          });
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            // Row 2: hours 6 & 7 + wide Custom chip
            Row(
              children: [
                ...hours.sublist(5, 7).map((t) {
                  final key = _hourKey(t);
                  final sel = _selectedTime == key;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _TimeChip(
                        label: _fmtHour(t),
                        selected: sel,
                        onTap: () {
                          final hasText = _controller.text.trim().isNotEmpty;
                          if (!sel && hasText) {
                            setState(() => _selectedTime = key);
                            _submit();
                          } else {
                            setState(() {
                              _selectedTime = sel ? null : key;
                              _showCustom = false;
                            });
                          }
                        },
                      ),
                    ),
                  );
                }),
                Expanded(
                  flex: 3,
                  child: _TimeChip(
                    label: _customTimeActive && !_showCustom
                        ? _fmtTime(_selectedTime!)
                        : 'Custom',
                    selected: _showCustom || _customTimeActive,
                    onTap: () => setState(() {
                      _showCustom = !_showCustom;
                      if (!_showCustom) _customController.clear();
                    }),
                  ),
                ),
              ],
            ),
            if (_showCustom) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: '3:30 PM  or  15:30',
                        hintStyle: TextStyle(
                            color: Colors.white24, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _confirmCustom(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(builder: (ctx) {
                    final accent = Theme.of(ctx).colorScheme.primary;
                    return GestureDetector(
                      onTap: _confirmCustom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.8,
                          ),
                        ),
                        child: const Text('Set',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Time Chip ─────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.7) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? accent : Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Quick chip (used in quick-add sheet) ──────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon!, size: 14, color: iconColor ?? Colors.white38),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Glass Nav Pill (4 icons + More) ───────────────────────────────────────────

class _GlassNavPill extends StatelessWidget {
  final int currentIndex;
  final double barHeight;
  final bool showLabels;
  final bool showMore;
  final ValueChanged<int> onTap;
  final VoidCallback onMoreTap;

  const _GlassNavPill({
    required this.currentIndex,
    required this.barHeight,
    required this.showLabels,
    required this.showMore,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final pillHeight = showLabels ? barHeight + 18 : barHeight;
    return Container(
      height: pillHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavIcon(icon: Icons.format_list_bulleted_rounded, label: 'Tasks', selected: !showMore && currentIndex == 4, barHeight: barHeight, showLabel: showLabels, onTap: () => onTap(4)),
                _NavIcon(icon: Icons.fitness_center, label: 'Gym', selected: !showMore && currentIndex == 0, barHeight: barHeight, showLabel: showLabels, onTap: () => onTap(0)),
                _NavIcon(icon: Icons.directions_run, label: 'Cardio', selected: !showMore && currentIndex == 1, barHeight: barHeight, showLabel: showLabels, onTap: () => onTap(1)),
                _NavIcon(icon: Icons.calendar_month, label: 'Log', selected: !showMore && currentIndex == 2, barHeight: barHeight, showLabel: showLabels, onTap: () => onTap(2)),
                _NavIcon(icon: Icons.more_horiz, label: 'More', selected: showMore || (!showMore && (currentIndex == 3 || currentIndex == 5)), barHeight: barHeight, showLabel: showLabels, onTap: onMoreTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── More Popup ────────────────────────────────────────────────────────────────

class _MorePopup extends StatelessWidget {
  final int currentIndex;
  final double barHeight;
  final bool showLabels;
  final VoidCallback onReadingTap;
  final VoidCallback onBodyTap;

  const _MorePopup({
    required this.currentIndex,
    required this.barHeight,
    required this.showLabels,
    required this.onReadingTap,
    required this.onBodyTap,
  });

  @override
  Widget build(BuildContext context) {
    final pillHeight = showLabels ? barHeight + 18 : barHeight;
    return Container(
      height: pillHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavIcon(icon: Icons.menu_book_outlined, label: 'Reading', selected: currentIndex == 5, barHeight: barHeight, showLabel: showLabels, onTap: onReadingTap),
                _NavIcon(icon: Icons.monitor_weight_outlined, label: 'Body', selected: currentIndex == 3, barHeight: barHeight, showLabel: showLabels, onTap: onBodyTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final double barHeight;
  final bool showLabel;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.barHeight,
    required this.showLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final iconSize = (barHeight * 0.37).clamp(20.0, 32.0);
    final w = barHeight * 0.72;
    final itemHeight = showLabel ? barHeight + 10 : barHeight - 8;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: w,
        height: itemHeight,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(barHeight / 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? accent : Colors.white54, size: iconSize),
            if (showLabel) ...[
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? accent : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Edit Circle Button ─────────────────────────────────────────────────────────

class _EditCircle extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _EditCircle({required this.size, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Long-press Menu Row ────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuRow(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
