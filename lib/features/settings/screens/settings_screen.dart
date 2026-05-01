import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_theme.dart' show parseAccent;
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
import '../../gym/providers/exercise_library_provider.dart';
import '../../../shared/services/backup_service.dart';

// ── Accent palette ─────────────────────────────────────────────────────────────
const _accentOptions = [
  ('Steel Blue',  '5B7FA8'),
  ('Purple',      'BF5AF2'),
  ('Emerald',     '34C759'),
  ('Amber',       'FF9F0A'),
  ('Coral',       'FF6B6B'),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    void update(AppSettings v) => notifier.update(v);
    final accent = parseAccent(s.accentColor);

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF161618),
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: Colors.white54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
        children: [

          // ── NOTIFICATIONS ────────────────────────────────────────────────────
          _SectionHeader('NOTIFICATIONS'),
          _NotificationsCard(
            accent: accent,
            weightEnabled: s.weightEnabled,
            weightHour: s.weightHour,
            weightMinute: s.weightMinute,
            gymEnabled: s.gymEnabled,
            gymHour: s.gymHour,
            gymMinute: s.gymMinute,
            gymCustomMessage: s.gymCustomMessage,
            restCustomMessage: s.restCustomMessage,
            readingEnabled: s.readingEnabled,
            readingHour: s.readingHour,
            readingMinute: s.readingMinute,
            checklistEnabled: s.checklistEnabled,
            checklistHour: s.checklistHour,
            checklistMinute: s.checklistMinute,
            cardioEnabled: s.cardioEnabled,
            cardioHour: s.cardioHour,
            cardioMinute: s.cardioMinute,
            onWeightToggle: (v) => update(s.copyWith(weightEnabled: v)),
            onWeightTime: (t) => update(s.copyWith(weightHour: t.hour, weightMinute: t.minute)),
            onGymToggle: (v) => update(s.copyWith(gymEnabled: v)),
            onGymTime: (t) => update(s.copyWith(gymHour: t.hour, gymMinute: t.minute)),
            onGymMsg: (v) => update(s.copyWith(gymCustomMessage: v)),
            onRestMsg: (v) => update(s.copyWith(restCustomMessage: v)),
            onReadingToggle: (v) => update(s.copyWith(readingEnabled: v)),
            onReadingTime: (t) => update(s.copyWith(readingHour: t.hour, readingMinute: t.minute)),
            onChecklistToggle: (v) => update(s.copyWith(checklistEnabled: v)),
            onChecklistTime: (t) => update(s.copyWith(checklistHour: t.hour, checklistMinute: t.minute)),
            onCardioToggle: (v) => update(s.copyWith(cardioEnabled: v)),
            onCardioTime: (t) => update(s.copyWith(cardioHour: t.hour, cardioMinute: t.minute)),
          ),

          // ── APPEARANCE ───────────────────────────────────────────────────────
          _SectionHeader('APPEARANCE'),
          _Card(children: [
            _ToggleRow(
              icon: s.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              label: s.isDarkMode ? 'Dark mode' : 'Light mode',
              value: s.isDarkMode,
              accent: accent,
              onChanged: (v) => update(s.copyWith(isDarkMode: v)),
            ),
            _Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Accent colour',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _accentOptions.map((opt) {
                      final hex = opt.$2;
                      final color = parseAccent(hex);
                      final selected = s.accentColor == hex;
                      return GestureDetector(
                        onTap: () => update(s.copyWith(accentColor: hex)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _accentOptions.map((opt) => SizedBox(
                      width: 46,
                      child: Text(opt.$1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white24, fontSize: 9)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ]),

          // ── DISPLAY ──────────────────────────────────────────────────────────
          _SectionHeader('DISPLAY'),
          _Card(children: [
            _SliderRow(
              icon: Icons.text_fields_rounded,
              label: 'Text size',
              value: s.uiScale,
              min: 0.8, max: 1.3,
              displayText: '${(s.uiScale * 100).round()}%',
              accent: accent,
              onChanged: (v) => update(s.copyWith(uiScale: v)),
            ),
            _Divider(),
            _SliderRow(
              icon: Icons.crop_free_rounded,
              label: 'Nav bar size',
              value: s.navBarScale,
              min: 0.7, max: 1.4,
              displayText: '${(s.navBarScale * 100).round()}%',
              accent: accent,
              onChanged: (v) => update(s.copyWith(navBarScale: v)),
            ),
            _Divider(),
            _SliderRow(
              icon: Icons.vertical_align_bottom_rounded,
              label: 'Nav bar height from bottom',
              value: s.navBarBottom,
              min: 0, max: 60, step: 1,
              displayText: '${s.navBarBottom.round()}px',
              accent: accent,
              onChanged: (v) => update(s.copyWith(navBarBottom: v)),
            ),
            _Divider(),
            _SliderRow(
              icon: Icons.swap_horiz_rounded,
              label: 'Nav bar side padding',
              value: s.navBarHPad,
              min: 0, max: 60, step: 1,
              displayText: '${s.navBarHPad.round()}px',
              accent: accent,
              onChanged: (v) => update(s.copyWith(navBarHPad: v)),
            ),
            _Divider(),
            _ToggleRow(
              icon: Icons.label_outline_rounded,
              label: 'Nav bar labels',
              sub: 'Show text under each icon',
              value: s.showNavLabels,
              accent: accent,
              onChanged: (v) => update(s.copyWith(showNavLabels: v)),
            ),
            _Divider(),
            _SliderRow(
              icon: Icons.vertical_align_top_rounded,
              label: 'Page top padding',
              value: s.pageTopPad,
              min: 0, max: 40, step: 1,
              displayText: '${s.pageTopPad.round()}px',
              accent: accent,
              onChanged: (v) => update(s.copyWith(pageTopPad: v)),
            ),
          ]),

          // ── WORKOUT ──────────────────────────────────────────────────────────
          _SectionHeader('WORKOUT'),
          _Card(children: [
            _RowHeader(icon: Icons.fitness_center, label: 'Default weight step'),
            const SizedBox(height: 10),
            _SegmentedRow(
              options: const ['1.25', '2.5', '5', '10'],
              labels: const ['1.25 kg', '2.5 kg', '5 kg', '10 kg'],
              selected: s.weightStep.toString().replaceAll('.0', ''),
              accent: accent,
              onSelect: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) update(s.copyWith(weightStep: parsed));
              },
            ),
            const SizedBox(height: 4),
            _Divider(),
            _SliderRow(
              icon: Icons.timer_outlined,
              label: 'Rest timer between sets',
              value: s.restTimerSeconds.toDouble(),
              min: 0, max: 300, step: 5,
              displayText: s.restTimerSeconds == 0 ? 'Off' : '${s.restTimerSeconds}s',
              accent: accent,
              onChanged: (v) => update(s.copyWith(restTimerSeconds: v.round())),
            ),
          ]),

          // ── GOALS ────────────────────────────────────────────────────────────
          _SectionHeader('GOALS'),
          _GoalsCard(
            accent: accent,
            targetWeightKg: s.targetWeightKg,
            readingGoal: s.readingGoal,
            weightUnit: s.weightUnit,
            onTargetWeight: (v) => update(v == null
                ? s.copyWith(clearTargetWeight: true)
                : s.copyWith(targetWeightKg: v)),
            onReadingGoal: (v) => update(s.copyWith(readingGoal: v)),
          ),

          // ── BEHAVIOUR ────────────────────────────────────────────────────────
          _SectionHeader('BEHAVIOUR'),
          _Card(children: [
            _ToggleRow(
              icon: Icons.vibration_rounded,
              label: 'Haptic feedback',
              sub: 'Vibration on taps and swipes',
              value: s.hapticsEnabled,
              accent: accent,
              onChanged: (v) => update(s.copyWith(hapticsEnabled: v)),
            ),
            _Divider(),
            _RowHeader(icon: Icons.monitor_weight_outlined, label: 'Weight unit'),
            const SizedBox(height: 10),
            _SegmentedRow(
              options: const ['kg', 'lbs'],
              labels: const ['Kilograms (kg)', 'Pounds (lbs)'],
              selected: s.weightUnit,
              accent: accent,
              onSelect: (v) => update(s.copyWith(weightUnit: v)),
            ),
            const SizedBox(height: 4),
            _Divider(),
            _RowHeader(icon: Icons.calendar_today_outlined, label: 'Week starts on'),
            const SizedBox(height: 10),
            _SegmentedRow(
              options: const ['mon', 'sun'],
              labels: const ['Monday', 'Sunday'],
              selected: s.weekStartsMonday ? 'mon' : 'sun',
              accent: accent,
              onSelect: (v) => update(s.copyWith(weekStartsMonday: v == 'mon')),
            ),
            const SizedBox(height: 4),
          ]),

          // ── DATA ─────────────────────────────────────────────────────────────
          _SectionHeader('DATA'),
          _BackupCard(),
          const SizedBox(height: 10),
          _ResetCard(),
        ],
      ),
    );
  }
}

// ── Layout helpers ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: Color(0xFF2C2C2E)),
      );
}

class _RowHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RowHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]);
}

// ── Reusable row widgets ────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (sub != null)
              Text(sub!,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: accent,
          activeThumbColor: Colors.white,
          inactiveThumbColor: Colors.white38,
          inactiveTrackColor: const Color(0xFF3A3A3C),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ]);
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String displayText;
  final Color accent;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 0.05,
    required this.displayText,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final divisions = ((max - min) / step).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Text(displayText,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: accent,
          inactiveTrackColor: const Color(0xFF3A3A3C),
          thumbColor: Colors.white,
          overlayColor: accent.withValues(alpha: 0.18),
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        ),
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ),
    ]);
  }
}

class _SegmentedRow extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final Color accent;
  final ValueChanged<String> onSelect;
  const _SegmentedRow({
    required this.options,
    required this.labels,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(options.length, (i) {
          final isSelected = options[i] == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? accent.withValues(alpha: 0.15) : const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? accent.withValues(alpha: 0.6) : Colors.transparent,
                  ),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? accent : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      );
}

// ── Notifications Card ─────────────────────────────────────────────────────────

class _NotificationsCard extends StatefulWidget {
  final Color accent;
  final bool weightEnabled;
  final int weightHour, weightMinute;
  final bool gymEnabled;
  final int gymHour, gymMinute;
  final String gymCustomMessage, restCustomMessage;
  final bool readingEnabled;
  final int readingHour, readingMinute;
  final bool checklistEnabled;
  final int checklistHour, checklistMinute;
  final bool cardioEnabled;
  final int cardioHour, cardioMinute;
  final ValueChanged<bool> onWeightToggle;
  final ValueChanged<TimeOfDay> onWeightTime;
  final ValueChanged<bool> onGymToggle;
  final ValueChanged<TimeOfDay> onGymTime;
  final ValueChanged<String> onGymMsg;
  final ValueChanged<String> onRestMsg;
  final ValueChanged<bool> onReadingToggle;
  final ValueChanged<TimeOfDay> onReadingTime;
  final ValueChanged<bool> onChecklistToggle;
  final ValueChanged<TimeOfDay> onChecklistTime;
  final ValueChanged<bool> onCardioToggle;
  final ValueChanged<TimeOfDay> onCardioTime;

  const _NotificationsCard({
    required this.accent,
    required this.weightEnabled, required this.weightHour, required this.weightMinute,
    required this.gymEnabled, required this.gymHour, required this.gymMinute,
    required this.gymCustomMessage, required this.restCustomMessage,
    required this.readingEnabled, required this.readingHour, required this.readingMinute,
    required this.checklistEnabled, required this.checklistHour, required this.checklistMinute,
    required this.cardioEnabled, required this.cardioHour, required this.cardioMinute,
    required this.onWeightToggle, required this.onWeightTime,
    required this.onGymToggle, required this.onGymTime,
    required this.onGymMsg, required this.onRestMsg,
    required this.onReadingToggle, required this.onReadingTime,
    required this.onChecklistToggle, required this.onChecklistTime,
    required this.onCardioToggle, required this.onCardioTime,
  });

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<_NotificationsCard> {
  String? _expanded;

  static String _fmtTime(int h, int m) {
    final hd = h % 12 == 0 ? 12 : h % 12;
    final ms = m.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'AM' : 'PM';
    return '$hd:$ms $ampm';
  }

  Future<void> _pickTime(
      BuildContext ctx, int hour, int minute, ValueChanged<TimeOfDay> cb) async {
    final picked = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: widget.accent,
            surface: const Color(0xFF1C1C1E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) cb(picked);
  }

  Widget _buildRow({
    required String key,
    required IconData icon,
    required String title,
    required bool enabled,
    required int hour,
    required int minute,
    required ValueChanged<bool> onToggle,
    required ValueChanged<TimeOfDay> onTimePicked,
    bool isLast = false,
    Widget? extras,
  }) {
    final isOpen = _expanded == key;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () => setState(() => _expanded = isOpen ? null : key),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: widget.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            if (enabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_fmtTime(hour, minute),
                    style: TextStyle(
                        color: widget.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 8),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeTrackColor: widget.accent,
              activeThumbColor: Colors.white,
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: const Color(0xFF3A3A3C),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
        ),
      ),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState:
            isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: const SizedBox.shrink(),
        secondChild: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _pickTime(context, hour, minute, onTimePicked),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242428),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(children: [
                    Icon(Icons.access_time_rounded,
                        color: widget.accent, size: 15),
                    const SizedBox(width: 10),
                    const Text('Notification time',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                    const Spacer(),
                    Text(_fmtTime(hour, minute),
                        style: TextStyle(
                            color: widget.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: Colors.white24, size: 16),
                  ]),
                ),
              ),
              if (extras != null) ...[const SizedBox(height: 8), extras],
            ],
          ),
        ),
      ),
      if (!isLast) const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: Color(0xFF2C2C2E)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(children: [
        _buildRow(
          key: 'weight',
          icon: Icons.monitor_weight_outlined,
          title: 'Weight Log',
          enabled: widget.weightEnabled,
          hour: widget.weightHour,
          minute: widget.weightMinute,
          onToggle: widget.onWeightToggle,
          onTimePicked: widget.onWeightTime,
        ),
        _buildRow(
          key: 'gym',
          icon: Icons.fitness_center,
          title: 'Gym',
          enabled: widget.gymEnabled,
          hour: widget.gymHour,
          minute: widget.gymMinute,
          onToggle: widget.onGymToggle,
          onTimePicked: widget.onGymTime,
          extras: Column(children: [
            _MsgField(
              label: 'Workout message',
              hint: 'e.g. "Get it done!"',
              value: widget.gymCustomMessage,
              onChanged: widget.onGymMsg,
            ),
            const SizedBox(height: 8),
            _MsgField(
              label: 'Rest day message',
              hint: 'e.g. "Recovery is progress"',
              value: widget.restCustomMessage,
              onChanged: widget.onRestMsg,
            ),
          ]),
        ),
        _buildRow(
          key: 'reading',
          icon: Icons.menu_book_outlined,
          title: 'Reading',
          enabled: widget.readingEnabled,
          hour: widget.readingHour,
          minute: widget.readingMinute,
          onToggle: widget.onReadingToggle,
          onTimePicked: widget.onReadingTime,
        ),
        _buildRow(
          key: 'checklist',
          icon: Icons.checklist_rounded,
          title: 'Checklist',
          enabled: widget.checklistEnabled,
          hour: widget.checklistHour,
          minute: widget.checklistMinute,
          onToggle: widget.onChecklistToggle,
          onTimePicked: widget.onChecklistTime,
        ),
        _buildRow(
          key: 'cardio',
          icon: Icons.directions_run,
          title: 'Cardio',
          enabled: widget.cardioEnabled,
          hour: widget.cardioHour,
          minute: widget.cardioMinute,
          onToggle: widget.onCardioToggle,
          onTimePicked: widget.onCardioTime,
          isLast: true,
        ),
      ]),
    );
  }
}

// ── Goals Card ─────────────────────────────────────────────────────────────────

class _GoalsCard extends StatefulWidget {
  final Color accent;
  final double? targetWeightKg;
  final int readingGoal;
  final String weightUnit;
  final ValueChanged<double?> onTargetWeight;
  final ValueChanged<int> onReadingGoal;

  const _GoalsCard({
    required this.accent,
    required this.targetWeightKg,
    required this.readingGoal,
    required this.weightUnit,
    required this.onTargetWeight,
    required this.onReadingGoal,
  });

  @override
  State<_GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends State<_GoalsCard> {
  late final TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.targetWeightKg != null
          ? _fmtKg(widget.targetWeightKg!, widget.weightUnit)
          : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  String _fmtKg(double kg, String unit) {
    final v = unit == 'lbs' ? kg * 2.20462 : kg;
    return v.toStringAsFixed(1);
  }

  void _onWeightSubmit(String val) {
    final parsed = double.tryParse(val.trim());
    if (parsed == null || parsed <= 0) {
      widget.onTargetWeight(null);
      _weightCtrl.clear();
    } else {
      final kg = widget.weightUnit == 'lbs' ? parsed / 2.20462 : parsed;
      widget.onTargetWeight(kg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalLabel = widget.readingGoal == 0
        ? 'Off'
        : '${widget.readingGoal} books / yr';

    return _Card(children: [
      // Target weight
      Row(children: [
        Icon(Icons.flag_outlined, size: 16, color: Colors.white38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Target weight (${widget.weightUnit})',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Text('Shown on body screen',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
        SizedBox(
          width: 88,
          child: TextField(
            controller: _weightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: widget.accent,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '—',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: widget.targetWeightKg != null
                  ? GestureDetector(
                      onTap: () {
                        _weightCtrl.clear();
                        widget.onTargetWeight(null);
                      },
                      child: const Icon(Icons.close, size: 13, color: Colors.white38),
                    )
                  : null,
            ),
            onSubmitted: _onWeightSubmit,
            onEditingComplete: () => _onWeightSubmit(_weightCtrl.text),
          ),
        ),
      ]),
      _Divider(),
      // Reading goal
      _SliderRow(
        icon: Icons.auto_stories_outlined,
        label: 'Annual reading goal',
        value: widget.readingGoal.toDouble(),
        min: 0, max: 52, step: 1,
        displayText: goalLabel,
        accent: widget.accent,
        onChanged: (v) => widget.onReadingGoal(v.round()),
      ),
    ]);
  }
}

// ── Reset Card ─────────────────────────────────────────────────────────────────

class _BackupCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(children: [
      _buildRow(
        context: context,
        icon: Icons.upload_file_outlined,
        color: const Color(0xFF0A84FF),
        title: 'Export Data',
        subtitle: 'Save a JSON backup of everything',
        buttonLabel: 'Export',
        onTap: () => _doExport(context),
      ),
      _Divider(),
      _buildRow(
        context: context,
        icon: Icons.download_outlined,
        color: const Color(0xFFFF9F0A),
        title: 'Import Data',
        subtitle: 'Restore from a previous backup',
        buttonLabel: 'Import',
        onTap: () => _doImport(context, ref),
      ),
    ]);
  }

  Widget _buildRow({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(buttonLabel,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Future<void> _doExport(BuildContext context) async {
    try {
      await BackupService.export();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _doImport(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3A2A1A)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9F0A), size: 20),
              SizedBox(width: 10),
              Text('Import Backup', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            const Text(
              'This will overwrite all current data with the contents of the backup file.',
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Cancel', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF9F0A).withValues(alpha: 0.4)),
                    ),
                    child: const Text('Restore', textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFFF9F0A), fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      final ok = await BackupService.import();
      if (!ok) return;
      ref.invalidate(gymProvider);
      ref.invalidate(exerciseLibraryProvider);
      ref.invalidate(booksProvider);
      ref.invalidate(bodyProvider);
      ref.invalidate(scheduleProvider);
      ref.invalidate(cardioProvider);
      ref.invalidate(plyoProvider);
      ref.invalidate(checklistProvider);
      ref.invalidate(settingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data restored successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }
}

class _ResetCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showResetDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A1A1A)),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF453A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.delete_forever_outlined,
                color: Color(0xFFFF453A), size: 17),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reset All Data',
                  style: TextStyle(
                      color: Color(0xFFFF453A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text('Permanently deletes everything',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFF453A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFF453A).withValues(alpha: 0.35)),
            ),
            child: const Text('Reset',
                style: TextStyle(
                    color: Color(0xFFFF453A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
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
                  const Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFF453A), size: 20),
                    SizedBox(width: 10),
                    Text('Reset Everything',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    'Permanently deletes all workouts, logs, books, and settings. This cannot be undone.',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('Type RESET to confirm',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'RESET',
                      hintStyle: const TextStyle(
                          color: Colors.white24, fontSize: 15),
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
                  Row(children: [
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
                                : const Color(0xFFFF453A)
                                    .withValues(alpha: 0.2),
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
                  ]),
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

// ── Message field ──────────────────────────────────────────────────────────────

class _MsgField extends StatefulWidget {
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  const _MsgField({
      required this.label,
      required this.hint,
      required this.value,
      required this.onChanged});

  @override
  State<_MsgField> createState() => _MsgFieldState();
}

class _MsgFieldState extends State<_MsgField> {
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 5),
          TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle:
                  const TextStyle(color: Colors.white24, fontSize: 13),
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
