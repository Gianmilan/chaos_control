import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Reminder {
  final String title;
  final String? description;
  final TimeOfDay time;

  // TODO: Add the description input window
  Reminder({required this.title, this.description, required this.time});
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late final DateTime _kFirstDay = DateTime(_focusedDay.year, 1, 1);
  late final DateTime _kLastDay = DateTime((_focusedDay.year + 1), 12, 31);
  final Map<DateTime, List<Reminder>> _reminders = {};

  void _addReminder() async {
    if (_selectedDay == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text("Add reminder title"),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    final date = DateTime(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day,
                    );

                    final newReminder = Reminder(
                      title: controller.text,
                      time: pickedTime,
                    );

                    if (_reminders[date] != null) {
                      _reminders[date]!.add(newReminder);
                    } else {
                      _reminders[date] = [newReminder];
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          focusedDay: _focusedDay,
          firstDay: _kFirstDay,
          lastDay: _kLastDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) {
            final date = DateTime(day.year, day.month, day.day);

            return _reminders[date] ?? [];
          },
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _selectedDay != null ? _addReminder : null,
          icon: const Icon(Icons.add),
          label: const Text("Add Reminder for Selected Day"),
        ),
        Expanded(
          child: ListView(
            children:
                (_reminders[DateTime(
                          _selectedDay?.year ?? 0,
                          _selectedDay?.month ?? 0,
                          _selectedDay?.day ?? 0,
                        )] ??
                        [])
                    .map(
                      (reminder) => ListTile(
                        leading: const Icon(Icons.alarm),
                        title: Text(reminder.title),
                        subtitle: Text(
                          "Time: ${reminder.time.format(context)}",
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }
}
