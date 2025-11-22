import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../Components/AppBar.dart';
import 'PassengerSummery.dart';

class PollScreen extends StatefulWidget {
  const PollScreen({super.key});

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  final Set<DateTime> _selectedDates = {}; // stores selected dates

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      // Normalize dates to midnight UTC for consistent comparison, as TableCalendar does.
      final normalizedDay = DateTime.utc(day.year, day.month, day.day);

      if (_selectedDates.contains(normalizedDay)) {
        _selectedDates.remove(normalizedDay); // deselect if already selected
      } else {
        _selectedDates.add(normalizedDay); // select new date
      }
    });
  }

  void _saveDates() {
    print("Selected Dates: $_selectedDates");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Poll added successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Start a Poll',
      ),
      body: Column(
        children: [
          // Calendar takes remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 16.0, right: 16.0),
              child: TableCalendar(
                // Use UTC dates for better calendar management
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,

                // --- Updated Header Style to match image colors/font ---
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false, // hide 2-week toggle
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Color(0xFF121415), // Green month name
                    fontSize: 20, // Slightly larger font
                    fontWeight: FontWeight.bold,
                  ),
                  headerMargin: EdgeInsets.only(bottom: 30.0), // Add margin below the month
                ),

                // Ensure selection predicate uses normalized dates
                selectedDayPredicate: (day) {
                  return _selectedDates.contains(
                      DateTime.utc(day.year, day.month, day.day));
                },
              onDaySelected: _onDaySelected,
              onDayLongPressed: (selectedDay, focusedDay) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PassengersummeryScreen(selectedDay: selectedDay),
                  ),
                );
              },

                // --- Calendar Style adjusted for green dates ---
                calendarStyle: const CalendarStyle(
                  // Style for selected days (green circle)
                  cellMargin: EdgeInsets.all(4.0), // Add margin around each cell
                  // increase the size of the calendar days
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF05A664),
                    shape: BoxShape.circle,
                  ),
                  // Style for the 'Today' indicator (dark circle in original)
                  todayDecoration: BoxDecoration(
                    color: Color(0xFF121415),
                    shape: BoxShape.circle,
                  ),
                  // Style for the main day numbers (green text as in image)
                  defaultTextStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  weekendTextStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  selectedTextStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  todayTextStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  // Highlight day names and numbers in green
                  rowDecoration: BoxDecoration(),
                ),

                // --- Customize Day of Week labels (M T W T F S S) ---
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: Color(0xFF05A664), fontWeight: FontWeight.bold),
                  weekendStyle: TextStyle(
                      color: Color(0xFF05A664), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // --- Button modified for Pill Shape ---
          Padding(
            // Increased vertical padding at the bottom to match image spacing
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 30.0),
            child: SizedBox(
              width: double.infinity, // full width
              height: 60,
              child: ElevatedButton(
                onPressed: _saveDates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05A664),
                  elevation: 0, // Removes shadow
                  // *** KEY CHANGE: Large border radius for the pill shape ***
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  "Add Poll",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600, // Slightly bolder text
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}