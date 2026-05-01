import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_models.dart';
import '../providers/gym_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../../settings/screens/settings_screen.dart';

class EditSplitScreen extends ConsumerStatefulWidget {
  const EditSplitScreen({super.key});

  @override
  ConsumerState<EditSplitScreen> createState() => _EditSplitScreenState();
}

class _EditSplitScreenState extends ConsumerState<EditSplitScreen>
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

  void _addSplitDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _TextDialog(
        title: 'New Split',
        hint: 'e.g. Push Pull Legs',
        controller: ctrl,
        onConfirm: () {
          if (ctrl.text.trim().isNotEmpty) {
            ref.read(gymProvider.notifier).addSplit(ctrl.text.trim());
          }
        },
      ),
    );
  }

  void _addExerciseDialog() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLibraryExerciseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isSplitsTab = _tabs.index == 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Edit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: isSplitsTab ? _addSplitDialog : _addExerciseDialog,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
      ),
      body: Column(
        children: [
          // Clean segmented tab selector — no AppBar bottom box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _TabPill(
                    label: 'Splits',
                    selected: _tabs.index == 0,
                    onTap: () => _tabs.animateTo(0),
                    accent: accent,
                  ),
                  _TabPill(
                    label: 'Exercises',
                    selected: _tabs.index == 1,
                    onTap: () => _tabs.animateTo(1),
                    accent: accent,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SplitsTab(),
                _ExercisesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF48484A) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Splits Tab ─────────────────────────────────────────────────────────────────

class _SplitsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(gymProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: gym.splits
          .map((split) => _SplitSection(
                split: split,
                isSelected: split.id == gym.selectedSplitId,
              ))
          .toList(),
    );
  }
}

class _SplitSection extends ConsumerWidget {
  final GymSplit split;
  final bool isSelected;
  const _SplitSection({required this.split, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final notifier = ref.read(gymProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: accent.withValues(alpha: 0.35))
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
                        Text('PRIMARY',
                            style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                letterSpacing: 1.4)),
                    ],
                  ),
                ),
                if (!split.isPrimary)
                  TextButton(
                    onPressed: () => notifier.setPrimary(split.id),
                    child:
                        const Text('Set Primary', style: TextStyle(fontSize: 12)),
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
          ...split.days.map((day) => _DaySection(splitId: split.id, day: day)),
          InkWell(
            onTap: () => _addDaySheet(context, ref, split.id),
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

  void _addDaySheet(BuildContext context, WidgetRef ref, String splitId) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDaySheet(splitId: splitId),
    );
  }
}

class _DaySection extends ConsumerWidget {
  final String splitId;
  final WorkoutDay day;
  const _DaySection({required this.splitId, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gymProvider.notifier);

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
                onPressed: () => _exercisePickerSheet(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.white24),
                visualDensity: VisualDensity.compact,
                onPressed: () => notifier.deleteDay(splitId, day.id),
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
                        Text(
                          '${_fmtW(ex.usualWeight)}kg  ×  ${ex.usualReps} reps',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: Colors.white38),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _EditExerciseInDaySheet(
                        splitId: splitId,
                        dayId: day.id,
                        exercise: ex,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, size: 16, color: Colors.white24),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        notifier.removeExercise(splitId, day.id, ex.name),
                  ),
                ],
              ),
            )),
        const Divider(
            height: 1, indent: 16, endIndent: 16, color: Color(0xFF2C2C2E)),
      ],
    );
  }

  void _exercisePickerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExercisePickerSheet(splitId: splitId, dayId: day.id),
    );
  }
}

// ── Exercise Picker Sheet ──────────────────────────────────────────────────────

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final String splitId;
  final String dayId;
  const _ExercisePickerSheet({required this.splitId, required this.dayId});

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final library = ref.watch(exerciseLibraryProvider);
    final gym = ref.watch(gymProvider);
    // Names already in this day
    final split = gym.splits.firstWhere((s) => s.id == widget.splitId,
        orElse: () => gym.splits.first);
    final day = split.days.firstWhere((d) => d.id == widget.dayId,
        orElse: () => split.days.first);
    final existing = {for (final e in day.exercises) e.name};

    final filtered = library
        .where((e) =>
            _query.isEmpty ||
            e.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final showCreateNew =
        _query.isNotEmpty && !library.any((e) => e.name.toLowerCase() == _query.toLowerCase());

    return Container(
      padding:
          EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Search or add exercise…',
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF242428),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (showCreateNew)
                  _PickerTile(
                    name: _query,
                    subtitle: 'Add to library & day',
                    icon: Icons.add_circle_outline,
                    iconColor: accent,
                    onTap: () {
                      ref.read(exerciseLibraryProvider.notifier).add(_query);
                      final ex = ref
                          .read(exerciseLibraryProvider)
                          .firstWhere((e) => e.name.toLowerCase() == _query.toLowerCase());
                      ref.read(gymProvider.notifier).addExercise(
                          widget.splitId, widget.dayId, ex.name, ex.defaultWeight, ex.defaultReps);
                      Navigator.pop(context);
                    },
                  ),
                ...filtered.map((ex) {
                  final alreadyAdded = existing.contains(ex.name);
                  return _PickerTile(
                    name: ex.name,
                    subtitle: '${_fmtW(ex.defaultWeight)}kg × ${ex.defaultReps} reps',
                    icon: alreadyAdded
                        ? Icons.check_circle_outline
                        : Icons.fitness_center,
                    iconColor:
                        alreadyAdded ? Colors.white24 : Colors.white54,
                    onTap: alreadyAdded
                        ? null
                        : () {
                            ref.read(gymProvider.notifier).addExercise(
                                widget.splitId, widget.dayId, ex.name,
                                ex.defaultWeight, ex.defaultReps);
                            Navigator.pop(context);
                          },
                  );
                }),
                if (filtered.isEmpty && !showCreateNew)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No exercises in library yet.\nType a name to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13)),
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

class _PickerTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  const _PickerTile({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: onTap == null ? Colors.white38 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercises Tab ──────────────────────────────────────────────────────────────

class _ExercisesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(exerciseLibraryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: library
          .map((ex) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2C2C2E)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(ex.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    '${_fmtW(ex.defaultWeight)}kg × ${ex.defaultReps} reps',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: Colors.white38),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _EditDefaultsSheet(exercise: ex),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.white24),
                        onPressed: () =>
                            ref.read(exerciseLibraryProvider.notifier).delete(ex.id),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _AddLibraryExerciseSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddLibraryExerciseSheet> createState() =>
      _AddLibraryExerciseSheetState();
}

class _AddLibraryExerciseSheetState
    extends ConsumerState<_AddLibraryExerciseSheet> {
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(text: '20');
  final _repsCtrl = TextEditingController(text: '8');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final weight = double.tryParse(_weightCtrl.text) ?? 20.0;
    final reps = int.tryParse(_repsCtrl.text) ?? 8;
    ref.read(exerciseLibraryProvider.notifier).add(name, defaultWeight: weight, defaultReps: reps);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Exercise', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Exercise name'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Default weight (kg)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _repsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Default reps'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submit, child: const Text('Add Exercise')),
          ),
        ],
      ),
    );
  }
}

class _EditDefaultsSheet extends ConsumerStatefulWidget {
  final LibraryExercise exercise;
  const _EditDefaultsSheet({required this.exercise});

  @override
  ConsumerState<_EditDefaultsSheet> createState() => _EditDefaultsSheetState();
}

class _EditDefaultsSheetState extends ConsumerState<_EditDefaultsSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
        text: _fmtW(widget.exercise.defaultWeight));
    _repsCtrl =
        TextEditingController(text: '${widget.exercise.defaultReps}');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.exercise.name,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Default weight (kg)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _repsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Default reps'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final w = double.tryParse(_weightCtrl.text) ??
                    widget.exercise.defaultWeight;
                final r = int.tryParse(_repsCtrl.text) ??
                    widget.exercise.defaultReps;
                ref
                    .read(exerciseLibraryProvider.notifier)
                    .updateDefaults(widget.exercise.id, w, r);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Day Sheet ──────────────────────────────────────────────────────────────

class _AddDaySheet extends ConsumerStatefulWidget {
  final String splitId;
  const _AddDaySheet({required this.splitId});

  @override
  ConsumerState<_AddDaySheet> createState() => _AddDaySheetState();
}

class _AddDaySheetState extends ConsumerState<_AddDaySheet> {
  final _nameCtrl = TextEditingController();
  bool _isRest = false;
  final Set<int> _weekdays = {};

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNumbers = [1, 2, 3, 4, 5, 6, 7];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final rawName = _nameCtrl.text.trim();
    final name = _isRest ? (rawName.isEmpty ? 'Rest' : rawName) : rawName;
    if (name.isEmpty) return;
    ref.read(gymProvider.notifier).addDay(
          widget.splitId,
          name,
          isRestDay: _isRest,
          weekdays: _weekdays.toList()..sort(),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding:
          EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
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
            decoration: InputDecoration(
              hintText: _isRest ? 'Name (optional)' : 'e.g. Push, Pull, Legs',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                  child: Text('Rest Day',
                      style: TextStyle(color: Colors.white70, fontSize: 15))),
              Switch(
                value: _isRest,
                onChanged: (v) => setState(() => _isRest = v),
                activeThumbColor: accent,
                activeTrackColor: accent.withValues(alpha: 0.3),
              ),
            ],
          ),
          if (!_isRest) ...[
            const SizedBox(height: 12),
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
                    onTap: () =>
                        setState(() => sel ? _weekdays.remove(n) : _weekdays.add(n)),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: sel
                            ? accent
                            : const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
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

// ── Edit Exercise In Day Sheet ─────────────────────────────────────────────────

class _EditExerciseInDaySheet extends ConsumerStatefulWidget {
  final String splitId;
  final String dayId;
  final ExerciseTemplate exercise;
  const _EditExerciseInDaySheet({
    required this.splitId,
    required this.dayId,
    required this.exercise,
  });

  @override
  ConsumerState<_EditExerciseInDaySheet> createState() =>
      _EditExerciseInDaySheetState();
}

class _EditExerciseInDaySheetState
    extends ConsumerState<_EditExerciseInDaySheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl =
        TextEditingController(text: _fmtW(widget.exercise.usualWeight));
    _repsCtrl = TextEditingController(text: '${widget.exercise.usualReps}');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.exercise.name,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Edit weight & reps for this split day',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Weight (kg)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _repsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Reps'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final w = double.tryParse(_weightCtrl.text) ??
                    widget.exercise.usualWeight;
                final r = int.tryParse(_repsCtrl.text) ??
                    widget.exercise.usualReps;
                ref.read(gymProvider.notifier).updateExercise(
                    widget.splitId, widget.dayId, widget.exercise.name, w, r);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtW(double w) => w % 1 == 0 ? '${w.toInt()}' : '$w';

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
    final accent = Theme.of(context).colorScheme.primary;
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
          child: Text('Add',
              style: TextStyle(color: accent)),
        ),
      ],
    );
  }
}
