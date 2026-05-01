import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cardio_models.dart';
import '../models/plyo_models.dart' show PlyoWorkout;
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

  void _addPlyoWorkoutDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _TextDialog(
        title: 'New Plyo Workout',
        hint: 'e.g. Jump Day, Full Body Plyo',
        controller: ctrl,
        onConfirm: () {
          if (ctrl.text.trim().isNotEmpty) {
            ref.read(plyoProvider.notifier).addWorkout(ctrl.text.trim());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCardioTab = _tabs.index == 0;

    return Scaffold(
      appBar: AppBar(
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
        onTap: isCardioTab ? _addCardioPlanDialog : _addPlyoWorkoutDialog,
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
    if (plyo.workouts.isEmpty) {
      return const Center(
        child: Text(
          'No plyo workouts yet\nTap + to add one',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.6),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children:
          plyo.workouts.map((w) => _PlyoWorkoutSection(workout: w)).toList(),
    );
  }
}

class _PlyoWorkoutSection extends ConsumerWidget {
  final PlyoWorkout workout;
  const _PlyoWorkoutSection({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(plyoProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(workout.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.white24),
                  onPressed: () => notifier.deleteWorkout(workout.id),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C2C2E)),
          ...workout.exercises.map((ex) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
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
                          notifier.removeExercise(workout.id, ex.id),
                    ),
                  ],
                ),
              )),
          InkWell(
            onTap: () => _showAddExerciseSheet(context, ref),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white38),
                  SizedBox(width: 6),
                  Text('Add Exercise',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlyoExerciseSheet(workoutId: workout.id),
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

// ── Add Plyo Exercise Sheet ────────────────────────────────────────────────────

class _AddPlyoExerciseSheet extends ConsumerStatefulWidget {
  final String workoutId;
  const _AddPlyoExerciseSheet({required this.workoutId});

  @override
  ConsumerState<_AddPlyoExerciseSheet> createState() =>
      _AddPlyoExerciseSheetState();
}

class _AddPlyoExerciseSheetState extends ConsumerState<_AddPlyoExerciseSheet> {
  final _nameCtrl = TextEditingController();
  final _repsCtrl = TextEditingController(text: '10');
  final _setsCtrl = TextEditingController(text: '3');
  final _weightCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  String? _videoPath;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _repsCtrl.dispose();
    _setsCtrl.dispose();
    _weightCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() => _videoPath = file.path);
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(plyoProvider.notifier).addExercise(
          widget.workoutId,
          name,
          int.tryParse(_repsCtrl.text) ?? 10,
          defaultSets: int.tryParse(_setsCtrl.text) ?? 3,
          defaultWeight: double.tryParse(_weightCtrl.text),
          durationSeconds: int.tryParse(_durationCtrl.text),
        );
    if (_videoPath != null) {
      final workouts = ref.read(plyoProvider).workouts;
      final workout = workouts.firstWhere((w) => w.id == widget.workoutId);
      final ex = workout.exercises.last;
      ref
          .read(plyoProvider.notifier)
          .updateExerciseVideo(widget.workoutId, ex.id, _videoPath);
    }
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
            Text('Add Exercise', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  hintText: 'Exercise name (e.g. Box Jumps)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Default reps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _setsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Sets'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(hintText: 'Weight kg (opt)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(hintText: 'Duration seconds (opt)'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _videoPath != null
                      ? const Color(0xFF5B7FA8).withValues(alpha: 0.12)
                      : const Color(0xFF242428),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _videoPath != null
                        ? const Color(0xFF5B7FA8).withValues(alpha: 0.5)
                        : const Color(0xFF3C3C3E),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _videoPath != null
                          ? Icons.videocam
                          : Icons.videocam_outlined,
                      color: _videoPath != null
                          ? const Color(0xFF5B7FA8)
                          : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _videoPath != null
                            ? _videoPath!.split('/').last
                            : 'Attach video clip (optional)',
                        style: TextStyle(
                          color: _videoPath != null
                              ? Colors.white70
                              : Colors.white38,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_videoPath != null)
                      GestureDetector(
                        onTap: () => setState(() => _videoPath = null),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white38),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _submit, child: const Text('Add Exercise')),
            ),
          ],
        ),
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
