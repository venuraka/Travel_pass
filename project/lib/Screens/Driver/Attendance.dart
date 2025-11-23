import 'package:flutter/material.dart';
import '../Components/Cards.dart';
import '../Components/Topic.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Color appGreen = const Color(0xFF05A664);

  // 1. Variable to store selected date
  DateTime _selectedDate = DateTime.now();

  // Temporary demo lists
  List<Map<String, dynamic>> todayPassengers = [
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": false},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
  ];

  List<Map<String, dynamic>> notVoted = [
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": false},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
  ];

  List<Map<String, dynamic>> absent = [
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": false},
  ];

  // 2. Function to show the Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: appGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Logic to filter passengers by date would go here
      });
    }
  }

  // Helper to format date string
  String get _dateString => "${_selectedDate.toLocal()}".split(' ')[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- HEADER ---
              PageHeader(
                title: "Attendance History",
                subtitle: Text(
                  _dateString,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.calendar_today_outlined, color: appGreen, size: 28),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              // --------------

              const SizedBox(height: 20),

              // --- Section 1: Not Voted (Renamed to Boarded based on your text) ---
              if (notVoted.isNotEmpty) ...[
                _buildSectionHeader("Passengers Boarded on $_dateString", appGreen),

                // REMOVED DISMISSIBLE WRAPPER HERE
                for (int i = 0; i < notVoted.length; i++)
                  InfoCard(
                    title: notVoted[i]["name"],
                    subtitle: notVoted[i]["place"],
                    showTag: notVoted[i]["tag"],
                    trailing: _buildPhoneIcon(appGreen),
                  ),

                const SizedBox(height: 30),
              ],

              // --- Section 2: Today’s Passengers (Renamed to Absent based on your text) ---
              _buildSectionHeader("Absent Passengers on $_dateString", appGreen),

              for (var passenger in todayPassengers)
                InfoCard(
                  title: passenger["name"],
                  subtitle: passenger["place"],
                  showTag: passenger["tag"],
                  trailing: _buildPhoneIcon(appGreen),
                ),

              const SizedBox(height: 10),

              // --- Section 3: Absent (Renamed to Not Voted based on your text) ---
              _buildSectionHeader("Not Voted Passengers on $_dateString", appGreen),

              for (var passenger in absent)
                InfoCard(
                  title: passenger["name"],
                  subtitle: passenger["place"],
                  showTag: passenger["tag"],
                  trailing: _buildPhoneIcon(appGreen),
                ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhoneIcon(Color color) {
    return InkWell(
      onTap: () {
        print("Calling passenger...");
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.phone,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}