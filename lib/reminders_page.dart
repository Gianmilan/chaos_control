import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));

    return TableCalendar(
      focusedDay: now,
      firstDay: firstDayOfWeek,
      lastDay: lastDayOfWeek,
      headerStyle: const HeaderStyle(formatButtonVisible: false),
    );
  }
}
