import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/checklist/providers/checklist_provider.dart';
import '../services/notification_service.dart';

const _barHeight = 56.0;
const _barMargin = 14.0;
const _barHPad = 20.0;

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
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

    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Reserve only the margin + safe area — content extends behind the glass for blur
    final reservedBottom = _barMargin + bottomInset;

    return Scaffold(
      // Transparent so child screens provide the background; glass blurs real content
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
          // ── Checklist circle — hidden on calendar and body pages ──────────────
          if (currentIndex != 2 && currentIndex != 3)
            Positioned(
              left: _barHPad,
              bottom: _barMargin + bottomInset + _barHeight + 10,
              child: _GlassCircleBtn(
                icon: Icons.checklist_rounded,
                selected: currentIndex == 4,
                onTap: () => context.go('/checklist'),
              ),
            ),
          // ── Horizontal bar (5 icons) + edit circle ─────────────────────────────
          Positioned(
            left: _barHPad,
            right: _barHPad,
            bottom: _barMargin + bottomInset,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _GlassNavPill(
                  currentIndex: currentIndex,
                  onTap: (i) {
                    switch (i) {
                      case 0:
                        context.go('/gym');
                      case 1:
                        context.go('/cardio');
                      case 2:
                        context.go('/schedule');
                      case 3:
                        context.go('/body');
                      case 5:
                        context.go('/reading');
                    }
                  },
                ),
                const Spacer(),
                _EditCircle(
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
    final buttonAreaBottom = safeBottom + _barMargin + _barHeight;
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
            color: const Color(0xFF5B7FA8),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'reading',
          child: _MenuRow(
            icon: Icons.menu_book_outlined,
            label: 'Add New Book',
            color: const Color(0xFF9B7FD4),
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
        5, (i) => TimeOfDay(hour: (now.hour + i + 1) % 24, minute: 0));
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

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final hours = _nextHours;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 4,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: "Add to today's checklist...",
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 18),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B7FA8).withValues(alpha: 0.4),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...hours.map((t) {
                    final key = _hourKey(t);
                    final sel = _selectedTime == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF5B7FA8)
                                    .withValues(alpha: 0.18)
                                : const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF5B7FA8)
                                      .withValues(alpha: 0.7)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            _fmtHour(t),
                            style: TextStyle(
                              color: sel
                                  ? const Color(0xFF5B7FA8)
                                  : Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => setState(() {
                      _showCustom = !_showCustom;
                      if (!_showCustom) _customController.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_showCustom || _customTimeActive)
                            ? const Color(0xFF5B7FA8)
                                .withValues(alpha: 0.18)
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_showCustom || _customTimeActive)
                              ? const Color(0xFF5B7FA8)
                                  .withValues(alpha: 0.7)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        _customTimeActive && !_showCustom
                            ? _fmtTime(_selectedTime!)
                            : 'Custom',
                        style: TextStyle(
                          color: (_showCustom || _customTimeActive)
                              ? const Color(0xFF5B7FA8)
                              : Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                  GestureDetector(
                    onTap: _confirmCustom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B7FA8).withValues(alpha: 0.35),
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
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Glass Circle Button (checklist above bar) ──────────────────────────────────

class _GlassCircleBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _GlassCircleBtn(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF5B7FA8).withValues(alpha: 0.25)
                    : const Color(0xFF1C1C1E).withValues(alpha: 0.94),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF5B7FA8).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
              child: Icon(icon,
                  color: selected
                      ? const Color(0xFF5B7FA8)
                      : Colors.white,
                  size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Nav Pill (5 icons — gym, cardio, calendar, body, reading) ────────────

class _GlassNavPill extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassNavPill({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavIcon(
                  icon: Icons.fitness_center,
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavIcon(
                  icon: Icons.directions_run,
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavIcon(
                  icon: Icons.calendar_month,
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavIcon(
                  icon: Icons.monitor_weight_outlined,
                  selected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _NavIcon(
                  icon: Icons.menu_book_outlined,
                  selected: currentIndex == 5,
                  onTap: () => onTap(5),
                ),
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
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3A3A3C) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }
}

// ── Edit Circle Button ─────────────────────────────────────────────────────────

class _EditCircle extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _EditCircle({required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.94),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
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
