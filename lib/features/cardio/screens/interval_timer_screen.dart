import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/services/beep_service.dart';

class IntervalTimerScreen extends StatefulWidget {
  const IntervalTimerScreen({super.key});

  @override
  State<IntervalTimerScreen> createState() => _IntervalTimerScreenState();
}

class _IntervalTimerScreenState extends State<IntervalTimerScreen> {
  // Simple mode
  final _workCtrl   = TextEditingController(text: '40');
  final _restCtrl   = TextEditingController(text: '20');
  final _roundsCtrl = TextEditingController(text: '3');

  // Advanced mode
  bool _advancedMode = false;
  final List<Map<String, dynamic>> _advancedSteps = [
    {'name': 'Work', 'secs': 30},
    {'name': 'Rest', 'secs': 10},
  ];
  int _advancedCurrentStep = 0;

  Box get _box => Hive.box('interval_presets');

  List<Map<String, dynamic>> get _presets {
    final raw = _box.get('presets');
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  void _loadPreset(Map<String, dynamic> p) {
    if (p['type'] == 'advanced') {
      final steps = (p['steps'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      setState(() {
        _advancedMode = true;
        _advancedSteps
          ..clear()
          ..addAll(steps);
        _roundsCtrl.text = '${p['rounds'] ?? 1}';
      });
    } else {
      _workCtrl.text   = '${p['work']}';
      _restCtrl.text   = '${p['rest']}';
      _roundsCtrl.text = '${p['rounds']}';
      setState(() {
        _advancedMode   = false;
        _remainingSecs  = p['work'] as int;
      });
    }
  }

  Future<void> _savePreset() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    final current = _presets;
    if (_advancedMode) {
      current.add({
        'name'  : name.trim(),
        'type'  : 'advanced',
        'steps' : _advancedSteps.map((s) => Map<String, dynamic>.from(s)).toList(),
        'rounds': int.tryParse(_roundsCtrl.text) ?? 1,
      });
    } else {
      current.add({
        'name'  : name.trim(),
        'work'  : int.tryParse(_workCtrl.text)   ?? 40,
        'rest'  : int.tryParse(_restCtrl.text)   ?? 20,
        'rounds': int.tryParse(_roundsCtrl.text) ?? 3,
      });
    }
    await _box.put('presets', current);
    setState(() {});
  }

  Future<void> _deletePreset(int index) async {
    final current = _presets..removeAt(index);
    await _box.put('presets', current);
    setState(() {});
  }

  Future<void> _confirmDelete(BuildContext ctx, int index, String name) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dlg) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "$name"?',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('This preset will be removed.',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlg, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dlg, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF453A), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) _deletePreset(index);
  }

  // ── Timer state ──────────────────────────────────────────────────────────────
  bool   _timerRunning  = false;
  bool   _timerStarted  = false;
  bool   _isWorkPhase   = true;
  int    _currentRound  = 1;
  int    _totalRounds   = 3;
  int    _remainingSecs = 40;
  Timer? _intervalTicker;
  bool   _soundEnabled  = true;

  @override
  void dispose() {
    _intervalTicker?.cancel();
    _workCtrl.dispose();
    _restCtrl.dispose();
    _roundsCtrl.dispose();
    super.dispose();
  }

  void _setupTicker() {
    _intervalTicker?.cancel();
    _intervalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSecs > 0) {
          _remainingSecs--;
        } else if (_advancedMode) {
          _tickAdvanced();
        } else {
          _tickSimple();
        }
      });
    });
  }

  void _tickSimple() {
    if (_isWorkPhase) {
      _isWorkPhase   = false;
      _remainingSecs = int.tryParse(_restCtrl.text) ?? 20;
      if (_soundEnabled) BeepService.restBeep();
    } else {
      if (_currentRound >= _totalRounds) {
        _timerRunning  = false;
        _timerStarted  = false;
        _intervalTicker?.cancel();
        if (_soundEnabled) BeepService.restBeep();
      } else {
        _currentRound++;
        _isWorkPhase   = true;
        _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
        if (_soundEnabled) BeepService.workBeep();
      }
    }
  }

  void _tickAdvanced() {
    final next = _advancedCurrentStep + 1;
    if (next < _advancedSteps.length) {
      _advancedCurrentStep = next;
      _remainingSecs = _advancedSteps[next]['secs'] as int;
      if (_soundEnabled) BeepService.workBeep();
    } else if (_currentRound < _totalRounds) {
      _currentRound++;
      _advancedCurrentStep = 0;
      _remainingSecs = _advancedSteps[0]['secs'] as int;
      if (_soundEnabled) BeepService.workBeep();
    } else {
      _timerRunning  = false;
      _timerStarted  = false;
      _intervalTicker?.cancel();
      if (_soundEnabled) BeepService.restBeep();
    }
  }

  void _start() {
    if (_advancedMode) {
      if (_advancedSteps.isEmpty) return;
      _totalRounds = int.tryParse(_roundsCtrl.text) ?? 1;
      if (_soundEnabled) BeepService.workBeep();
      setState(() {
        _timerRunning        = true;
        _timerStarted        = true;
        _currentRound        = 1;
        _advancedCurrentStep = 0;
        _remainingSecs       = _advancedSteps[0]['secs'] as int;
      });
    } else {
      _totalRounds = int.tryParse(_roundsCtrl.text) ?? 3;
      if (_soundEnabled) BeepService.workBeep();
      setState(() {
        _timerRunning  = true;
        _timerStarted  = true;
        _isWorkPhase   = true;
        _currentRound  = 1;
        _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
      });
    }
    _setupTicker();
  }

  void _pause()  { _intervalTicker?.cancel(); setState(() => _timerRunning = false); }
  void _resume() { setState(() => _timerRunning = true); _setupTicker(); }

  void _reset() {
    _intervalTicker?.cancel();
    if (_advancedMode) {
      setState(() {
        _timerRunning        = false;
        _timerStarted        = false;
        _advancedCurrentStep = 0;
        _currentRound        = 1;
        _remainingSecs       = _advancedSteps.isEmpty ? 0 : _advancedSteps[0]['secs'] as int;
      });
    } else {
      setState(() {
        _timerRunning  = false;
        _timerStarted  = false;
        _isWorkPhase   = true;
        _currentRound  = 1;
        _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    Color phaseColor;
    if (_advancedMode && _timerStarted && _advancedSteps.isNotEmpty) {
      final stepName = (_advancedSteps[_advancedCurrentStep]['name'] as String).toLowerCase();
      phaseColor = stepName.contains('rest') ? const Color(0xFF34C759) : accent;
    } else {
      phaseColor = _isWorkPhase ? accent : const Color(0xFF34C759);
    }

    final mins = (_remainingSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSecs % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'INTERVAL TIMER',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5),
                    ),
                  ),
                  // Advanced toggle
                  _HeaderChip(
                    icon: Icons.tune_rounded,
                    label: 'Advanced',
                    active: _advancedMode,
                    accent: accent,
                    onTap: _timerStarted ? null : () => setState(() => _advancedMode = !_advancedMode),
                  ),
                  const SizedBox(width: 8),
                  // Sound toggle (icon-only)
                  GestureDetector(
                    onTap: () => setState(() => _soundEnabled = !_soundEnabled),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _soundEnabled
                            ? accent.withValues(alpha: 0.12)
                            : const Color(0xFF242428),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _soundEnabled
                              ? accent.withValues(alpha: 0.4)
                              : const Color(0xFF3A3A3C),
                        ),
                      ),
                      child: Icon(
                        _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        size: 16,
                        color: _soundEnabled ? accent : Colors.white30,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Config or running ─────────────────────────────────────────────
            if (!_timerStarted) ...[
              // Presets row
              if (_presets.isNotEmpty) ...[
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = _presets[i];
                      final isAdv = p['type'] == 'advanced';
                      return GestureDetector(
                        onTap: () => _loadPreset(p),
                        onLongPress: () => _confirmDelete(context, i, p['name'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: accent.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdv) ...[
                                Icon(Icons.tune_rounded, color: accent, size: 11),
                                const SizedBox(width: 4),
                              ],
                              Text(p['name'] as String,
                                  style: TextStyle(
                                      color: accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Text(
                                isAdv
                                    ? '${(p['steps'] as List).length} steps'
                                    : '${p['work']}/${p['rest']}×${p['rounds']}',
                                style: const TextStyle(color: Colors.white24, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Input fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_advancedMode) ...[
                      _ConfigRow(label: 'WORK',   unit: 'seconds', controller: _workCtrl,   color: accent),
                      const SizedBox(height: 16),
                      _ConfigRow(label: 'REST',   unit: 'seconds', controller: _restCtrl,   color: const Color(0xFF34C759)),
                      const SizedBox(height: 16),
                      _ConfigRow(label: 'ROUNDS', unit: 'rounds',  controller: _roundsCtrl, color: Colors.white54),
                    ] else ...[
                      // Step list
                      ..._advancedSteps.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AdvancedStepRow(
                              key: ValueKey(e.key),
                              index: e.key,
                              name: e.value['name'] as String,
                              secs: e.value['secs'] as int,
                              onDelete: () => setState(() => _advancedSteps.removeAt(e.key)),
                              onChanged: (n, s) => _advancedSteps[e.key] = {'name': n, 'secs': s},
                            ),
                          )),
                      // Add step
                      GestureDetector(
                        onTap: () => setState(() => _advancedSteps.add({'name': 'Work', 'secs': 30})),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, color: accent, size: 16),
                              const SizedBox(width: 6),
                              Text('Add Step',
                                  style: TextStyle(
                                      color: accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ConfigRow(label: 'ROUNDS', unit: 'rounds', controller: _roundsCtrl, color: Colors.white54),
                    ],
                    const SizedBox(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _savePreset,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bookmark_add_outlined, color: Colors.white38, size: 16),
                                SizedBox(width: 6),
                                Text('Save',
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                        GestureDetector(
                          onTap: _start,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: accent.withValues(alpha: 0.6), width: 2),
                            ),
                            child: Icon(Icons.play_arrow_rounded, color: accent, size: 44),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── Running display ─────────────────────────────────────────────
              Column(
                children: [
                  Text(
                    _advancedMode
                        ? (_advancedSteps[_advancedCurrentStep]['name'] as String).toUpperCase()
                        : (_isWorkPhase ? 'WORK' : 'REST'),
                    style: TextStyle(
                        color: phaseColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$mins:$secs',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 88,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _advancedMode
                        ? 'Step ${_advancedCurrentStep + 1}/${_advancedSteps.length} · Round $_currentRound/$_totalRounds'
                        : 'Round $_currentRound / $_totalRounds',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _advancedMode
                        ? List.generate(_advancedSteps.length, (i) {
                            final done    = i < _advancedCurrentStep;
                            final current = i == _advancedCurrentStep;
                            return Container(
                              width: current ? 18 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: done
                                    ? phaseColor.withValues(alpha: 0.4)
                                    : current
                                        ? phaseColor
                                        : Colors.white12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          })
                        : List.generate(_totalRounds, (i) {
                            final done    = i < _currentRound - 1;
                            final current = i == _currentRound - 1;
                            return Container(
                              width: current ? 18 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: done
                                    ? phaseColor.withValues(alpha: 0.6)
                                    : current
                                        ? phaseColor
                                        : Colors.white12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _reset,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 24),
                        ),
                      ),
                      const SizedBox(width: 28),
                      GestureDetector(
                        onTap: _timerRunning ? _pause : _resume,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: phaseColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: phaseColor.withValues(alpha: 0.6), width: 2),
                          ),
                          child: Icon(
                            _timerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: phaseColor,
                            size: 38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ── Header chip ────────────────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback? onTap;

  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = active && !disabled ? accent : Colors.white30;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active && !disabled
                ? accent.withValues(alpha: 0.12)
                : const Color(0xFF242428),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active && !disabled
                  ? accent.withValues(alpha: 0.4)
                  : const Color(0xFF3A3A3C),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Advanced step row ──────────────────────────────────────────────────────────

class _AdvancedStepRow extends StatefulWidget {
  final int index;
  final String name;
  final int secs;
  final VoidCallback onDelete;
  final void Function(String name, int secs) onChanged;

  const _AdvancedStepRow({
    super.key,
    required this.index,
    required this.name,
    required this.secs,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_AdvancedStepRow> createState() => _AdvancedStepRowState();
}

class _AdvancedStepRowState extends State<_AdvancedStepRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _secsCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _secsCtrl = TextEditingController(text: '${widget.secs}');
    _nameCtrl.addListener(_notify);
    _secsCtrl.addListener(_notify);
  }

  void _notify() =>
      widget.onChanged(_nameCtrl.text, int.tryParse(_secsCtrl.text) ?? widget.secs);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _secsCtrl.dispose();
    super.dispose();
  }

  static InputDecoration _fieldDeco({String? suffix}) => InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '${widget.index + 1}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _fieldDeco(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: TextField(
            controller: _secsCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _fieldDeco(suffix: 's'),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: widget.onDelete,
          child: const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
        ),
      ],
    );
  }
}

// ── Name dialog ────────────────────────────────────────────────────────────────

class _NameDialog extends StatefulWidget {
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: const Text('Save Preset',
          style: TextStyle(color: Colors.white, fontSize: 16)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'e.g. Tabata',
          hintStyle: TextStyle(color: Colors.white24),
          filled: true,
          fillColor: Color(0xFF2C2C2E),
          border: OutlineInputBorder(borderSide: BorderSide.none),
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: Text('Save', style: TextStyle(color: accent)),
        ),
      ],
    );
  }
}

// ── Config row ─────────────────────────────────────────────────────────────────

class _ConfigRow extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final Color color;

  const _ConfigRow({
    required this.label,
    required this.unit,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1C1C1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(unit,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
      ],
    );
  }
}
