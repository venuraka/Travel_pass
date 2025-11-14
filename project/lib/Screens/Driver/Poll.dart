import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class PollScreen extends StatefulWidget {
  const PollScreen({super.key});

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  final Set<DateTime> _selectedDates = {}; // stores selected dates

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      if (_selectedDates.contains(day)) {
        _selectedDates.remove(day); // deselect if already selected
      } else {
        _selectedDates.add(day); // select new date
      }
    });
  }

  void _saveDates() {
    // You can save this list to database or shared preferences
    print("Selected Dates: $_selectedDates");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dates saved!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make a Poll',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: const Color(0xFF05A664),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return _selectedDates.contains(day);
            },
            onDaySelected: _onDaySelected,
            calendarStyle: const CalendarStyle(
              isTodayHighlighted: true,
              selectedDecoration: BoxDecoration(
                color: Color(0xFF05A664),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveDates,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05A664),
            ),
            child: const Text("Save Selected Dates"),
          ),
        ],
      ),
    );
  }
}