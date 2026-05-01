import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/settings_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../gym/providers/gym_provider.dart';
import '../../gym/providers/active_workout_provider.dart';
import '../../cardio/providers/cardio_provider.dart';
import '../../cardio/providers/plyo_provider.dart';
import '../../cardio/providers/active_plyo_provider.dart';
import '../../reading/providers/reading_provider.dart';
import '../../body/providers/body_provider.dart';
import '../../checklist/providers/checklist_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    void update(AppSettings updated) => notifier.update(updated);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _AppearanceSection(
            isDark: s.isDarkMode,
            onToggle: (v) => update(s.copyWith(isDarkMode: v)),
          ),
          _NotifSection(
            icon: Icons.monitor_weight_outlined,
            title: 'Weight Log',
            subtitle: 'Morning reminder to log your weight',
            enabled: s.weightEnabled,
            hour: s.weightHour,
            minute: s.weightMinute,
            onToggle: (v) => update(s.copyWith(weightEnabled: v)),
            onTimePicked: (t) =>
                update(s.copyWith(weightHour: t.hour, weightMinute: t.minute)),
          ),
          _NotifSection(
            icon: Icons.fitness_center,
            title: 'Gym',
            subtitle: 'Workout or rest day motivation',
            enabled: s.gymEnabled,
            hour: s.gymHour,
            minute: s.gymMinute,
            onToggle: (v) => update(s.copyWith(gymEnabled: v)),
            onTimePicked: (t) =>
                update(s.copyWith(gymHour: t.hour, gymMinute: t.minute)),
            extras: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                _MessageField(
                  label: 'Custom workout message (optional)',
                  hint: 'e.g. "Get it done!"',
                  value: s.gymCustomMessage,
                  onChanged: (v) => update(s.copyWith(gymCustomMessage: v)),
                ),
                const SizedBox(height: 10),
                _MessageField(
                  label: 'Custom rest day message (optional)',
                  hint: 'e.g. "Recovery is progress"',
                  value: s.restCustomMessage,
                  onChanged: (v) => update(s.copyWith(restCustomMessage: v)),
                ),
              ],
            ),
          ),
          _NotifSection(
            icon: Icons.menu_book_outlined,
            title: 'Reading',
            subtitle: 'Evening nudge to read your book',
            enabled: s.readingEnabled,
            hour: s.readingHour,
            minute: s.readingMinute,
            onToggle: (v) => update(s.copyWith(readingEnabled: v)),
            onTimePicked: (t) =>
                update(s.copyWith(readingHour: t.hour, readingMinute: t.minute)),
          ),
          _NotifSection(
            icon: Icons.checklist_rounded,
            title: 'Checklist',
            subtitle: 'Mid-morning planning reminder',
            enabled: s.checklistEnabled,
            hour: s.checklistHour,
            minute: s.checklistMinute,
            onToggle: (v) => update(s.copyWith(checklistEnabled: v)),
            onTimePicked: (t) => update(
                s.copyWith(checklistHour: t.hour, checklistMinute: t.minute)),
          ),
          _NotifSection(
            icon: Icons.directions_run,
            title: 'Cardio',
            subtitle: 'Evening run reminder',
            enabled: s.cardioEnabled,
            hour: s.cardioHour,
            minute: s.cardioMinute,
            onToggle: (v) => update(s.copyWith(cardioEnabled: v)),
            onTimePicked: (t) =>
                update(s.copyWith(cardioHour: t.hour, cardioMinute: t.minute)),
          ),
          _ResetSection(),
        ],
      ),
    );
  }
}

// ── Appearance section ─────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onToggle;
  const _AppearanceSection({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD1D1D6);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF5B7FA8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: const Color(0xFF5B7FA8),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Switch app appearance',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF6E6E73),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: isDark, onChanged: onToggle),
        ],
      ),
    );
  }
}

// ── Notification section card ──────────────────────────────────────────────────

class _NotifSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onToggle;
  final ValueChanged<TimeOfDay> onTimePicked;
  final Widget? extras;

  const _NotifSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onToggle,
    required this.onTimePicked,
    this.extras,
  });

  String get _timeLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B7FA8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF5B7FA8), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: const Color(0xFF5B7FA8),
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF2C2C2E), height: 1),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: hour, minute: minute),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF5B7FA8),
                        surface: Color(0xFF1C1C1E),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) onTimePicked(picked);
              },
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  const Text('Time',
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const Spacer(),
                  Text(_timeLabel,
                      style: const TextStyle(
                          color: Color(0xFF5B7FA8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: Colors.white24, size: 18),
                ],
              ),
            ),
            ?extras,
          ],
        ],
      ),
    );
  }
}

// ── Reset section ─────────────────────────────────────────────────────────────

class _ResetSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A1A1A)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF453A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_forever_outlined,
                color: Color(0xFFFF453A), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset All Data',
                    style: TextStyle(
                        color: Color(0xFFFF453A),
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text('Permanently deletes everything',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showResetDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF453A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF453A).withValues(alpha: 0.4)),
              ),
              child: const Text('Reset',
                  style: TextStyle(
                      color: Color(0xFFFF453A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final valid = ctrl.text == 'RESET';
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF3A1A1A)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF453A), size: 22),
                      SizedBox(width: 10),
                      Text('Reset Everything',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This will permanently delete all workouts, logs, books, and settings. This cannot be undone.',
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('Type RESET to confirm',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 12, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'RESET',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 15),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2C),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (valid) _doReset(dlgCtx, context, ref);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(dlgCtx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: valid
                              ? () => _doReset(dlgCtx, context, ref)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: valid
                                  ? const Color(0xFFFF453A)
                                  : const Color(0xFFFF453A).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text('Reset',
                                  style: TextStyle(
                                      color: valid
                                          ? Colors.white
                                          : Colors.white24,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _doReset(
      BuildContext dlgCtx, BuildContext screenCtx, WidgetRef ref) async {
    Navigator.pop(dlgCtx);
    // Clear all Hive boxes
    await Future.wait([
      Hive.box('gym').clear(),
      Hive.box('reading').clear(),
      Hive.box('body').clear(),
      Hive.box('schedule').clear(),
      Hive.box('cardio').clear(),
      Hive.box('plyo').clear(),
      Hive.box('checklist').clear(),
      Hive.box('settings').clear(),
    ]);
    // Invalidate all providers so they rebuild from empty boxes
    ref.invalidate(scheduleProvider);
    ref.invalidate(gymProvider);
    ref.invalidate(activeWorkoutProvider);
    ref.invalidate(cardioProvider);
    ref.invalidate(plyoProvider);
    ref.invalidate(activePlyoProvider);
    ref.invalidate(booksProvider);
    ref.invalidate(bodyProvider);
    ref.invalidate(checklistProvider);
    ref.invalidate(settingsProvider);
  }
}

// ── Custom message text field ──────────────────────────────────────────────────

class _MessageField extends StatefulWidget {
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _MessageField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_MessageField> createState() => _MessageFieldState();
}

class _MessageFieldState extends State<_MessageField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF242428),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
