import 'package:flutter/cupertino.dart';

import '../core/app_icons.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/ph_time.dart';

/// Month grid for picking a due date (built from plain widgets).
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.firstDate,
  });

  final DateTime selected;

  /// Earliest day that can be picked; earlier days are greyed out.
  final DateTime? firstDate;
  final ValueChanged<DateTime> onSelected;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdayLetters = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  /// Can the user go back a month without leaving the allowed range?
  bool get _canGoBack {
    final first = widget.firstDate;
    if (first == null) return true;
    return DateTime(_month.year, _month.month).isAfter(DateTime(first.year, first.month));
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = _month.weekday % 7; // Sunday = 0
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final today = phToday();
    final secondary = AppColors.secondaryText(context);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              _NavButton(
                icon: AppIcons.chevronLeft,
                onTap: _canGoBack ? () => _shift(-1) : null,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              _NavButton(icon: AppIcons.chevronRight, onTap: () => _shift(1)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final letter in _weekdayLetters)
                Expanded(
                  child: Text(
                    letter,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var row = 0; row < cellCount ~/ 7; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(child: _cell(row * 7 + col - leading + 1, daysInMonth, today)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(int day, int daysInMonth, DateTime today) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 40);

    final date = DateTime(_month.year, _month.month, day);
    final isSelected = isSameDay(date, widget.selected);
    final isToday = isSameDay(date, today);
    final first = widget.firstDate;
    final disabled = first != null && date.isBefore(dateOnly(first));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : () => widget.onSelected(date),
      child: SizedBox(
        height: 40,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected ? AppColors.orangeGradient : null,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.orange, width: 1.5)
                  : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? CupertinoColors.white
                    : (disabled ? AppColors.secondaryText(context).withValues(alpha: 0.35) : null),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? AppColors.secondaryText(context).withValues(alpha: 0.35)
              : AppColors.orange,
        ),
      ),
    );
  }
}
