import 'package:chaos_control/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Reminder {
  final String title;
  final String? description;
  final TimeOfDay time;

  // TODO: Add the description input window
  Reminder({required this.title, this.description, required this.time});

  Map<String, dynamic> toMap() => {
    "title": title,
    "description": description,
    "hour": time.hour,
    "minute": time.minute,
  };

  factory Reminder.fromMap(Map<dynamic, dynamic> map) => Reminder(
    title: map["title"],
    description: map["description"],
    time: TimeOfDay(hour: map["hour"], minute: map["minute"]),
  );
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

  final _remindersBox = HiveService.getRemindersBox();

  List<Reminder> _getRemindersForDay(DateTime day) {
    final dateKey = "${day.year}-${day.month}-${day.day}";
    final List<dynamic>? rawData = _remindersBox.get(dateKey);

    if (rawData == null) return [];

    return rawData.map((e) => Reminder.fromMap(e as Map)).toList();
  }

  void _addReminder() async {
    if (_selectedDay == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) return;

    final navigator = Navigator.of(context);

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
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final date = DateTime(
                    _selectedDay!.year,
                    _selectedDay!.month,
                    _selectedDay!.day,
                  );
                  final dateKey = "${date.year}-${date.month}-${date.day}";

                  final newReminder = Reminder(
                    title: controller.text,
                    time: pickedTime,
                  );

                  final currentReminders = _getRemindersForDay(date);
                  currentReminders.add(newReminder);

                  await _remindersBox.put(
                    dateKey,
                    currentReminders.map((r) => r.toMap()).toList(),
                  );

                  if (!mounted) return;
                  setState(() {});
                }
                navigator.pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRemindersForDay(
    DateTime day,
    List<Reminder> reminders,
  ) async {
    final dateKey = "${day.year}-${day.month}-${day.day}";

    await _remindersBox.put(dateKey, reminders.map((r) => r.toMap()).toList());
    if (mounted) setState(() {});
  }

  void _deleteReminder(int index) async {
    if (_selectedDay == null) return;

    final reminders = _getRemindersForDay(_selectedDay!);
    reminders.removeAt(index);
    await _saveRemindersForDay(_selectedDay!, reminders);
  }

  void _editReminder(int index, Reminder oldReminder) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: oldReminder.time,
    );

    if (pickedTime == null || !mounted) return;

    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: oldReminder.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Reminder"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && _selectedDay != null) {
                final reminders = _getRemindersForDay(_selectedDay!);

                reminders[index] = Reminder(
                  title: controller.text,
                  time: pickedTime,
                );
                await _saveRemindersForDay(_selectedDay!, reminders);
              }
              navigator.pop();
            },
            child: const Text("Update"),
          ),
        ],
      ),
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
            return _getRemindersForDay(day);
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
          child: ListView.builder(
            itemCount: _selectedDay != null
                ? _getRemindersForDay(_selectedDay!).length
                : 0,
            itemBuilder: (context, index) {
              final reminders = _getRemindersForDay(_selectedDay!);
              final reminder = reminders[index];

              return ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(reminder.title),
                subtitle: Text("Time: ${reminder.time.format(context)}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editReminder(index, reminder),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteReminder(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
