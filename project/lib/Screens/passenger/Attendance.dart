import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../Components/AppBar.dart';




class PassengerAttendaceScreen extends StatefulWidget {
  const PassengerAttendaceScreen({super.key});

  @override
  State<PassengerAttendaceScreen> createState() => _PassengerAttendaceScreenState();
}

class _PassengerAttendaceScreenState extends State<PassengerAttendaceScreen> {
  // Use a map to store attendance status instead of a set of just selected dates.
  // Key: Normalized Date (DateTime.utc), Value: Attendance Status (e.g., 'Present', 'Absent')
  final Map<DateTime, String> _attendanceStatus = {
    // Example data: Mark a few dates as 'Present' (Green) and 'Absent' (Red)
    DateTime.utc(2025, 11, 10): 'Present',
    DateTime.utc(2025, 11, 12): 'Present',
    DateTime.utc(2025, 11, 15): 'Absent',
    DateTime.utc(2025, 11, 17): 'Present',
    DateTime.utc(2025, 11, 20): 'Absent',
  };

  // The focused day for the calendar's initial view
  DateTime _focusedDay = DateTime.now();
  // The selected day (optional, used for single-tap interaction)
  DateTime? _selectedDay;


  // Simplified day selection logic for an attendance view
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Normalize dates to midnight UTC for consistent comparison
    final normalizedSelectedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);

    setState(() {
      _selectedDay = normalizedSelectedDay;
      _focusedDay = focusedDay; // Update focused day

      // Optional: Show a detail about the selected day's attendance
      final status = _attendanceStatus[normalizedSelectedDay] ?? 'Not Recorded';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Date: ${normalizedSelectedDay.toIso8601String().split('T').first}, Status: $status")),
      );
    });
  }


  // Function to define the decoration/color for each day based on attendance status
  Decoration _getDayDecoration(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    final status = _attendanceStatus[normalizedDay];

    Color color;

    switch (status) {
      case 'Present':
      // Use the green color for 'Present'
        color = const Color(0xFF05A664);
        break;
      case 'Absent':
      // Use a contrasting color, e.g., red, for 'Absent'
        color = Colors.red;
        break;
      default:
      // Default to transparent if no status is recorded
        return const BoxDecoration(shape: BoxShape.circle);
    }

    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the CustomAppBar
      appBar: const CustomAppBar(
        title: 'Attendance Record',
      ),
      body: Column(
        children: [
          // Calendar takes the remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 16.0, right: 16.0),
              child: TableCalendar(
                // Use UTC dates for better calendar management
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,

                // --- Header Style (same as your poll screen) ---
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false, // hide 2-week toggle
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Color(0xFF121415),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  headerMargin: EdgeInsets.only(bottom: 30.0),
                ),

                // Define which day is currently 'selected' (if you want to track single taps)
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },

                // Use the simplified day selection function
                onDaySelected: _onDaySelected,

                // *** REMOVED onDayLongPressed: ***
                // The long-press navigation logic has been removed as requested.

                // --- Calendar Style adjusted for attendance status ---
                calendarStyle: CalendarStyle(
                  // Style for the day that is currently selected by tap
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF05A664), // Green for selected day (if using _selectedDay)
                    shape: BoxShape.circle,
                  ),
                  // Style for the 'Today' indicator
                  todayDecoration: const BoxDecoration(
                    color: Color(0xFF121415), // Dark circle for today
                    shape: BoxShape.circle,
                  ),

                  // Use the custom builder to apply attendance decorations
                  markerDecoration: const BoxDecoration(
                    color: Colors.transparent, // Hide default markers
                  ),

                  // Text styles remain the same
                  defaultTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  weekendTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  todayTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),

                // Custom Builder to draw the background/decoration based on status
                calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          decoration: _getDayDecoration(day), // Apply custom decoration
                          width: 40, // Match the size of the original selectedDecoration
                          height: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: _attendanceStatus[DateTime.utc(day.year, day.month, day.day)] != null
                                  ? Colors.white // White text on colored background
                                  : Colors.black, // Black text on default days
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    // Ensure 'Today' also respects the attendance status, or use a combination
                    todayBuilder: (context, day, focusedDay) {
                      final isAttendanceRecorded = _attendanceStatus[DateTime.utc(day.year, day.month, day.day)] != null;
                      return Center(
                        child: Container(
                          // If attendance is recorded, use that color; otherwise use the 'today' color
                          decoration: isAttendanceRecorded
                              ? _getDayDecoration(day)
                              : const BoxDecoration(
                            color: Color(0xFF121415), // Today's color
                            shape: BoxShape.circle,
                          ),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
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

          // --- Legend for Attendance Status ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Present', const Color(0xFF05A664)),
                _buildLegendItem('Absent', Colors.red),
                _buildLegendItem('Today', const Color(0xFF121415)),
              ],
            ),
          ),

          // --- 'Add Poll' button is removed and replaced with a descriptive text/empty space ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 30.0),
            child: Text(
              'Attendance data is loaded from the backend.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the legend items
  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}