import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/gym_models.dart';
import '../providers/gym_provider.dart';

class PRScreen extends ConsumerWidget {
  const PRScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gym = ref.watch(gymProvider);
    final prs = _computePRs(gym);

    return Scaffold(
      appBar: AppBar(
          elevation: 0,
        title: const Text('Personal Records'),
      ),
      body: prs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 52, color: Colors.white12),
                  SizedBox(height: 16),
                  Text('No PRs yet',
                      style: TextStyle(color: Colors.white38, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Complete a workout to start tracking PRs',
                      style: TextStyle(color: Colors.white24, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prs.length,
              itemBuilder: (_, i) => _PRTile(entry: prs[i]),
            ),
    );
  }

  List<_PREntry> _computePRs(GymState gym) {
    final map = <String, _PREntry>{};
    for (final split in gym.splits) {
      for (final day in split.days) {
        for (final ex in day.exercises) {
          if (ex.history.isEmpty) continue;
          final best = ex.history.reduce(
              (a, b) => a.weight > b.weight || (a.weight == b.weight && a.reps > b.reps) ? a : b);
          final existing = map[ex.name];
          if (existing == null || best.weight > existing.pr.weight ||
              (best.weight == existing.pr.weight && best.reps > existing.pr.reps)) {
            map[ex.name] = _PREntry(name: ex.name, pr: best);
          }
        }
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}

class _PREntry {
  final String name;
  final SetEntry pr;
  const _PREntry({required this.name, required this.pr});
}

class _PRTile extends StatelessWidget {
  final _PREntry entry;
  const _PRTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final pr = entry.pr;
    final w = pr.weight % 1 == 0 ? '${pr.weight.toInt()}' : '${pr.weight}';
    final e1rm = pr.weight * (1 + pr.reps / 30);
    final e1rmStr = e1rm % 1 < 0.05 ? '${e1rm.round()}' : e1rm.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: Color(0xFFFFD700), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy').format(pr.date),
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${w}kg',
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text('× ${pr.reps} reps',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 2),
              Text('e1RM ${e1rmStr}kg',
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
