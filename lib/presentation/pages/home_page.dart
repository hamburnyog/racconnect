import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime now = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: Theme.of(context).primaryColor,
            child: ListTile(
              title: Text(
                'No event for today',
                // @TODO: Count holiday for the selected day
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Today is ${DateFormat.yMMMMd().format(now)}',
                style: TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDay = now;
                    _focusedDay = now;
                  });
                },
                icon: Icon(Icons.calendar_today, color: Colors.white),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                // holidayPredicate: ,
                // rowHeight: 80,
                availableGestures: AvailableGestures.none,
                firstDay: now.subtract(const Duration(days: 365)),
                lastDay: now.add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
