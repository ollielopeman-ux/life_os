import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/services/beep_service.dart';

class IntervalTimerScreen extends StatefulWidget {
  const IntervalTimerScreen({super.key});

  @override
  State<IntervalTimerScreen> createState() => _IntervalTimerScreenState();
}

class _IntervalTimerScreenState extends State<IntervalTimerScreen> {
  final _workCtrl = TextEditingController(text: '40');
  final _restCtrl = TextEditingController(text: '20');
  final _roundsCtrl = TextEditingController(text: '3');

  bool _timerRunning = false;
  bool _timerStarted = false;
  bool _isWorkPhase = true;
  int _currentRound = 1;
  int _totalRounds = 3;
  int _remainingSecs = 40;
  Timer? _intervalTicker;
  bool _soundEnabled = true;

  @override
  void dispose() {
    _intervalTicker?.cancel();
    _workCtrl.dispose();
    _restCtrl.dispose();
    _roundsCtrl.dispose();
    super.dispose();
  }

  void _start() {
    final work = int.tryParse(_workCtrl.text) ?? 40;
    _totalRounds = int.tryParse(_roundsCtrl.text) ?? 3;
    _intervalTicker?.cancel();
    if (_soundEnabled) BeepService.workBeep();
    setState(() {
      _timerRunning = true;
      _timerStarted = true;
      _isWorkPhase = true;
      _currentRound = 1;
      _remainingSecs = work;
    });
    _intervalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSecs > 0) {
          _remainingSecs--;
        } else {
          if (_isWorkPhase) {
            _isWorkPhase = false;
            _remainingSecs = int.tryParse(_restCtrl.text) ?? 20;
            if (_soundEnabled) BeepService.restBeep();
          } else {
            if (_currentRound >= _totalRounds) {
              _timerRunning = false;
              _timerStarted = false;
              _intervalTicker?.cancel();
              if (_soundEnabled) BeepService.restBeep();
            } else {
              _currentRound++;
              _isWorkPhase = true;
              _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
              if (_soundEnabled) BeepService.workBeep();
            }
          }
        }
      });
    });
  }

  void _pause() {
    _intervalTicker?.cancel();
    setState(() => _timerRunning = false);
  }

  void _resume() {
    _intervalTicker?.cancel();
    setState(() => _timerRunning = true);
    _intervalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSecs > 0) {
          _remainingSecs--;
        } else {
          if (_isWorkPhase) {
            _isWorkPhase = false;
            _remainingSecs = int.tryParse(_restCtrl.text) ?? 20;
            if (_soundEnabled) BeepService.restBeep();
          } else {
            if (_currentRound >= _totalRounds) {
              _timerRunning = false;
              _timerStarted = false;
              _intervalTicker?.cancel();
              if (_soundEnabled) BeepService.restBeep();
            } else {
              _currentRound++;
              _isWorkPhase = true;
              _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
              if (_soundEnabled) BeepService.workBeep();
            }
          }
        }
      });
    });
  }

  void _reset() {
    _intervalTicker?.cancel();
    setState(() {
      _timerRunning = false;
      _timerStarted = false;
      _isWorkPhase = true;
      _currentRound = 1;
      _remainingSecs = int.tryParse(_workCtrl.text) ?? 40;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mins = (_remainingSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSecs % 60).toString().padLeft(2, '0');
    final phaseColor =
        _isWorkPhase ? const Color(0xFF5B7FA8) : const Color(0xFF34C759);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      'Interval Timer',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  // Sound toggle
                  GestureDetector(
                    onTap: () => setState(() => _soundEnabled = !_soundEnabled),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _soundEnabled
                            ? const Color(0xFF5B7FA8).withValues(alpha: 0.12)
                            : const Color(0xFF242428),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _soundEnabled
                              ? const Color(0xFF5B7FA8).withValues(alpha: 0.4)
                              : const Color(0xFF3A3A3C),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _soundEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            size: 15,
                            color: _soundEnabled
                                ? const Color(0xFF5B7FA8)
                                : Colors.white30,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _soundEnabled ? 'Sound on' : 'Sound off',
                            style: TextStyle(
                                fontSize: 12,
                                color: _soundEnabled
                                    ? const Color(0xFF5B7FA8)
                                    : Colors.white30),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (!_timerStarted) ...[
              // Config section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _ConfigRow(
                      label: 'WORK',
                      unit: 'seconds',
                      controller: _workCtrl,
                      color: const Color(0xFF5B7FA8),
                    ),
                    const SizedBox(height: 16),
                    _ConfigRow(
                      label: 'REST',
                      unit: 'seconds',
                      controller: _restCtrl,
                      color: const Color(0xFF34C759),
                    ),
                    const SizedBox(height: 16),
                    _ConfigRow(
                      label: 'ROUNDS',
                      unit: 'rounds',
                      controller: _roundsCtrl,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 48),
                    // Start button
                    GestureDetector(
                      onTap: _start,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF5B7FA8).withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF5B7FA8)
                                  .withValues(alpha: 0.6),
                              width: 2),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Color(0xFF5B7FA8), size: 44),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Running display
              Column(
                children: [
                  Text(
                    _isWorkPhase ? 'WORK' : 'REST',
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
                    'Round $_currentRound / $_totalRounds',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalRounds, (i) {
                      final done = i < _currentRound - 1;
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
                      // Reset
                      GestureDetector(
                        onTap: _reset,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.white38, size: 24),
                        ),
                      ),
                      const SizedBox(width: 28),
                      // Play/pause
                      GestureDetector(
                        onTap: _timerRunning ? _pause : _resume,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: phaseColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: phaseColor.withValues(alpha: 0.6),
                                width: 2),
                          ),
                          child: Icon(
                            _timerRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
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
          child: Text(
            label,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1C1C1E),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            unit,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
