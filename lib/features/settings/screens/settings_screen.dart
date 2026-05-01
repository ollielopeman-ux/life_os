import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    void update(AppSettings updated) => notifier.update(updated);

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161618),
        elevation: 0,
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
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
