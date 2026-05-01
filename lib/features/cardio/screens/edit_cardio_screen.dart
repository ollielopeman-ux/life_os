import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cardio_models.dart';
import '../models/plyo_models.dart';
import '../providers/cardio_provider.dart';
import '../providers/plyo_provider.dart';

class EditCardioScreen extends ConsumerStatefulWidget {
  const EditCardioScreen({super.key});

  @override
  ConsumerState<EditCardioScreen> createState() => _EditCardioScreenState();
}

class _EditCardioScreenState extends ConsumerState<EditCardioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _addCardioPlanDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _TextDialog(
        title: 'New Cardio Plan',
        hint: 'e.g. 5K Training, Base Building',
        controller: ctrl,
        onConfirm: () {
          if (ctrl.text.trim().isNotEmpty) {
            ref.read(cardioProvider.notifier).addSplit(ctrl.text.trim());
          }
        },
      ),
    );
  }

  void _addPlyoPlanDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _TextDialog(
        title: 'New Plyo Plan',
        hint: 'e.g. Lower Body, Full Body',
        controller: ctrl,
        onConfirm: () {
          if (ctrl.text.trim().isNotEmpty) {
            ref.read(plyoProvider.notifier).addPlan(ctrl.text.trim());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCardioTab = _tabs.index == 0;

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161618),
        elevation: 0,
        title: const Text('Edit'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF5B7FA8),
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: const Color(0xFF5B7FA8),
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'CARDIO'), Tab(text: 'PLYO')],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: isCardioTab ? _addCardioPlanDialog : _addPlyoPlanDialog,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6E96C0), Color(0xFF3C618A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7FA8).withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CardioTab(),
          _PlyoTab(),
        ],
      ),
    );
  }
}

// ── Cardio Tab ─────────────────────────────────────────────────────────────────

class _CardioTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardio = ref.watch(cardioProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: cardio.splits
          .map((split) => _CardioSplitSection(
                split: split,
                isSelected: split.id == cardio.selectedSplitId,
              ))
          .toList(),
    );
  }
}

class _CardioSplitSection extends ConsumerWidget {
  final CardioSplit split;
  final bool isSelected;
  const _CardioSplitSection({required this.split, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cardioProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(
                color: const Color(0xFF5B7FA8).withValues(alpha: 0.35))
            : Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(split.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (split.isPrimary)
                        const Text('PRIMARY',
                            style: TextStyle(
                                color: Color(0xFF5B7FA8),
                                fontSize: 10,
                                letterSpacing: 1.4)),
                    ],
                  ),
                ),
                if (!split.isPrimary)
                  TextButton(
                    onPressed: () => notifier.setPrimary(split.id),
                    child: const Text('Set Primary',
                        style: TextStyle(fontSize: 12)),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.white24),
                  onPressed: () => notifier.deleteSplit(split.id),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C2C2E)),
          ...split.sessions.map((s) => _CardioSessionRow(split: split, session: s)),
          InkWell(
            onTap: () => _addSessionSheet(context, ref, split.id),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white38),
                  SizedBox(width: 6),
                  Text('Add Session',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addSessionSheet(BuildContext context, WidgetRef ref, String splitId) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSessionSheet(splitId: splitId),
    );
  }
}

class _CardioSessionRow extends ConsumerWidget {
  final CardioSplit split;
  final CardioSession session;
  const _CardioSessionRow({required this.split, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = [
      session.type,
      if (session.distanceKm != null) '${session.distanceKm}km',
      if (session.durationMinutes != null) '${session.durationMinutes}min',
      session.intensity,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Text(_typeEmoji(session.type), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(detail,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.white24),
            visualDensity: VisualDensity.compact,
            onPressed: () => ref
                .read(cardioProvider.notifier)
                .deleteSession(split.id, session.id),
          ),
        ],
      ),
    );
  }
}

// ── Plyo Tab ───────────────────────────────────────────────────────────────────

class _PlyoTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plyo = ref.watch(plyoProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: plyo.plans
          .map((plan) => _PlyoPlanSection(
                plan: plan,
                isSelected: plan.id == plyo.selectedPlanId,
              ))
          .toList(),
    );
  }
}

class _PlyoPlanSection extends ConsumerWidget {
  final PlyoPlan plan;
  final bool isSelected;
  const _PlyoPlanSection({required this.plan, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(plyoProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(
                color: const Color(0xFF5B7FA8).withValues(alpha: 0.35))
            : Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (plan.isPrimary)
                        const Text('PRIMARY',
                            style: TextStyle(
                                color: Color(0xFF5B7FA8),
                                fontSize: 10,
                                letterSpacing: 1.4)),
                    ],
                  ),
                ),
                if (!plan.isPrimary)
                  TextButton(
                    onPressed: () => notifier.setPrimary(plan.id),
                    child: const Text('Set Primary',
                        style: TextStyle(fontSize: 12)),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.white24),
                  onPressed: () => notifier.deletePlan(plan.id),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C2C2E)),
          ...plan.days.map((day) => _PlyoDaySection(planId: plan.id, day: day)),
          InkWell(
            onTap: () => _addDaySheet(context, ref, plan.id),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white38),
                  SizedBox(width: 6),
                  Text('Add Day',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addDaySheet(BuildContext context, WidgetRef ref, String planId) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlyoDaySheet(planId: planId),
    );
  }
}

class _PlyoDaySection extends ConsumerWidget {
  final String planId;
  final PlyoDay day;
  const _PlyoDaySection({required this.planId, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(plyoProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.white38),
              const SizedBox(width: 8),
              Expanded(
                child: Text(day.name,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: Colors.white38),
                visualDensity: VisualDensity.compact,
                onPressed: () => _addExerciseDialog(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.white24),
                visualDensity: VisualDensity.compact,
                onPressed: () => notifier.deleteDay(planId, day.id),
              ),
            ],
          ),
        ),
        ...day.exercises.map((ex) => Padding(
              padding: const EdgeInsets.fromLTRB(38, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        Text('${ex.defaultReps} reps',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: Colors.white24),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        notifier.removeExercise(planId, day.id, ex.id),
                  ),
                ],
              ),
            )),
        const Divider(
            height: 1, indent: 16, endIndent: 16, color: Color(0xFF2C2C2E)),
      ],
    );
  }

  void _addExerciseDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final repsCtrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF242428),
        title: const Text('Add Exercise',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: Colors.white),
              decoration:
                  const InputDecoration(hintText: 'e.g. Box Jumps, Burpees'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Default reps'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final reps = int.tryParse(repsCtrl.text) ?? 10;
              ref
                  .read(plyoProvider.notifier)
                  .addExercise(planId, day.id, name, reps);
              Navigator.pop(context);
            },
            child: const Text('Add',
                style: TextStyle(color: Color(0xFF5B7FA8))),
          ),
        ],
      ),
    );
  }
}

// ── Add Session Sheet (Cardio) ─────────────────────────────────────────────────

class _AddSessionSheet extends ConsumerStatefulWidget {
  final String splitId;
  const _AddSessionSheet({required this.splitId});

  @override
  ConsumerState<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends ConsumerState<_AddSessionSheet> {
  final _nameCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String _type = kCardioTypes[0];
  String _intensity = kCardioIntensities[1];
  final Set<int> _weekdays = {};

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNumbers = [1, 2, 3, 4, 5, 6, 7];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _distanceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(cardioProvider.notifier).addSession(
          widget.splitId,
          name,
          _type,
          _intensity,
          durationMinutes: int.tryParse(_durationCtrl.text),
          distanceKm: double.tryParse(_distanceCtrl.text),
          weekdays: _weekdays.toList()..sort(),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Session', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  hintText: 'Session name (e.g. Easy Run)'),
            ),
            const SizedBox(height: 16),
            const Text('TYPE',
                style: TextStyle(
                    color: Colors.white38, fontSize: 10, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kCardioTypes.map((t) {
                  final sel = t == _type;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF5B7FA8)
                            : const Color(0xFF242428),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: 'Duration (min)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _distanceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(hintText: 'Distance (km)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('INTENSITY',
                style: TextStyle(
                    color: Colors.white38, fontSize: 10, letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Row(
              children: kCardioIntensities.map((level) {
                final sel = level == _intensity;
                final color = _intensityColor(level);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _intensity = level),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? color.withValues(alpha: 0.2)
                            : const Color(0xFF242428),
                        borderRadius: BorderRadius.circular(10),
                        border: sel
                            ? Border.all(color: color.withValues(alpha: 0.5))
                            : null,
                      ),
                      child: Text(level,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: sel ? color : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('LINK TO DAYS OF WEEK',
                style: TextStyle(
                    color: Colors.white38, fontSize: 10, letterSpacing: 1.4)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) {
                final n = _dayNumbers[i];
                final sel = _weekdays.contains(n);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(
                        () => sel ? _weekdays.remove(n) : _weekdays.add(n)),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF5B7FA8)
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(_dayLabels[i],
                            style: TextStyle(
                                color: sel ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _submit, child: const Text('Add Session')),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Plyo Day Sheet ─────────────────────────────────────────────────────────

class _AddPlyoDaySheet extends ConsumerStatefulWidget {
  final String planId;
  const _AddPlyoDaySheet({required this.planId});

  @override
  ConsumerState<_AddPlyoDaySheet> createState() => _AddPlyoDaySheetState();
}

class _AddPlyoDaySheetState extends ConsumerState<_AddPlyoDaySheet> {
  final _nameCtrl = TextEditingController();
  final Set<int> _weekdays = {};

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNumbers = [1, 2, 3, 4, 5, 6, 7];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(plyoProvider.notifier).addDay(
          widget.planId,
          name,
          weekdays: _weekdays.toList()..sort(),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Day', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(hintText: 'e.g. Lower Body, Full Body'),
          ),
          const SizedBox(height: 16),
          const Text('LINK TO DAYS OF WEEK',
              style: TextStyle(
                  color: Colors.white38, fontSize: 10, letterSpacing: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              final n = _dayNumbers[i];
              final sel = _weekdays.contains(n);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(
                      () => sel ? _weekdays.remove(n) : _weekdays.add(n)),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF5B7FA8)
                          : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(_dayLabels[i],
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submit, child: const Text('Add Day')),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _typeEmoji(String type) => switch (type) {
      'Running' => '🏃',
      'Cycling' => '🚴',
      'Swimming' => '🏊',
      'Rowing' => '🚣',
      'Walking' => '🚶',
      'HIIT' => '⚡',
      _ => '💪',
    };

Color _intensityColor(String i) => switch (i) {
      'Easy' => const Color(0xFF4CAF50),
      'Moderate' => const Color(0xFFFF9800),
      'Hard' => const Color(0xFFFF5252),
      'Race Pace' => const Color(0xFFE040FB),
      _ => Colors.white38,
    };

class _TextDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onConfirm;
  const _TextDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242428),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (_) {
          onConfirm();
          Navigator.pop(context);
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('Add', style: TextStyle(color: Color(0xFF5B7FA8))),
        ),
      ],
    );
  }
}
