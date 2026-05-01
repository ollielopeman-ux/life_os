import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekStrip extends StatelessWidget {
  final DateTime weekStart; // always a Monday
  final Set<String> completedDates; // 'yyyy-MM-dd' keys
  final ValueChanged<DateTime> onWeekChanged;

  const WeekStrip({
    super.key,
    required this.weekStart,
    required this.completedDates,
    required this.onWeekChanged,
  });

  static DateTime mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final sameMonth = weekStart.month == weekEnd.month;
    final label = sameMonth
        ? '${weekStart.day} – ${DateFormat('d MMM').format(weekEnd)}'
        : '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM').format(weekEnd)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C2E)),
        ),
        child: Column(
          children: [
            // Nav row
            Row(
              children: [
                _NavArrow(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      onWeekChanged(weekStart.subtract(const Duration(days: 7))),
                ),
                Expanded(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
                _NavArrow(
                  icon: Icons.chevron_right,
                  onTap: () =>
                      onWeekChanged(weekStart.add(const Duration(days: 7))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Day cells
            Row(
              children: days.map((day) {
                final key = _dateKey(day);
                final isCompleted = completedDates.contains(key);
                final isToday = day == today;
                final isPast = day.isBefore(today);

                return Expanded(
                  child: _DayCell(
                    day: day,
                    isCompleted: isCompleted,
                    isToday: isToday,
                    isPast: isPast,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, color: Colors.white38, size: 20),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isCompleted;
  final bool isToday;
  final bool isPast;
  const _DayCell({
    required this.day,
    required this.isCompleted,
    required this.isToday,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('E').format(day)[0];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: isToday ? Colors.white54 : Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF5B7FA8)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isCompleted
                ? Border.all(
                    color: const Color(0xFF5B7FA8).withValues(alpha: 0.5),
                    width: 1.5)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isToday
                          ? Colors.white
                          : isPast
                              ? Colors.white38
                              : Colors.white24,
                      fontSize: 12,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
