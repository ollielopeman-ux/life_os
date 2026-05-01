import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekStrip extends StatelessWidget {
  final DateTime weekStart; // always a Monday
  final Map<String, Color> completedDates; // 'yyyy-MM-dd' → rating colour
  final ValueChanged<DateTime> onWeekChanged;

  const WeekStrip({
    super.key,
    required this.weekStart,
    required this.completedDates,
    required this.onWeekChanged,
  });

  static DateTime mondayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

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
          color: const Color(0xFF1A1A1C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF242426)),
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
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3)),
                ),
                _NavArrow(
                  icon: Icons.chevron_right,
                  onTap: () =>
                      onWeekChanged(weekStart.add(const Duration(days: 7))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Day cells
            Row(
              children: days.map((day) {
                final key = _dateKey(day);
                final dotColor = completedDates[key];
                final isToday = day == today;
                final isPast = day.isBefore(today);

                return Expanded(
                  child: _DayCell(
                    day: day,
                    dotColor: dotColor,
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
        child: Icon(icon, color: Colors.white24, size: 20),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Color? dotColor;
  final bool isToday;
  final bool isPast;
  const _DayCell({
    required this.day,
    required this.dotColor,
    required this.isToday,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final letter = DateFormat('E').format(day)[0];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day letter
        Text(
          letter,
          style: TextStyle(
            color: isToday ? accent : Colors.white24,
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        // Date number — pill for today
        Container(
          width: 34,
          height: 34,
          decoration: isToday
              ? BoxDecoration(
                  color: const Color(0xFF1A2C47),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.55),
                    width: 1,
                  ),
                )
              : null,
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isToday
                    ? Colors.white
                    : isPast
                        ? Colors.white54
                        : Colors.white24,
                fontSize: isToday ? 17 : 15,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Completed dot
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: dotColor ?? Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
