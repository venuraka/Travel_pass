import 'package:flutter/material.dart';
import '../Components/AppBar.dart';
import '../Components/Cards.dart';

class TodaypassengersScreen extends StatefulWidget {
  const TodaypassengersScreen({super.key});

  @override
  State<TodaypassengersScreen> createState() => _TodaypassengersScreenState();
}

class _TodaypassengersScreenState extends State<TodaypassengersScreen> {
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

  @override
  Widget build(BuildContext context) {
    final Color appGreen = const Color(0xFF05A664);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Today Passengers',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const SizedBox(height: 20),

              // --- Section 2: Not Voted ---
              if (notVoted.isNotEmpty) ...[
                _buildSectionHeader("Not Voted", appGreen),

                for (int i = 0; i < notVoted.length; i++)
                  Dismissible(
                    key: Key("notvoted_$i"),
                    direction: DismissDirection.horizontal,
                    onDismissed: (direction) {
                      setState(() {
                        final person = notVoted.removeAt(i); // remove from not voted

                        if (direction == DismissDirection.startToEnd) {
                          todayPassengers.add(person);
                          print("Marked as Attended");
                        } else {
                          absent.add(person);
                          print("Marked as Absent");
                        }
                      });
                    },
                    background: Container(
                      color: const Color(0xFF05A664),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                    child: InfoCard(
                      title: notVoted[i]["name"],
                      subtitle: notVoted[i]["place"],
                      showTag: notVoted[i]["tag"],
                      trailing: _buildPhoneIcon(appGreen),
                    ),
                  ),

                const SizedBox(height: 30),
              ],


              // --- Section 1: Today’s Passengers ---
              _buildSectionHeader("Today's Passengers", appGreen),

              for (var passenger in todayPassengers)
                InfoCard(
                  title: passenger["name"],
                  subtitle: passenger["place"],
                  showTag: passenger["tag"],
                  trailing: _buildPhoneIcon(appGreen),
                ),

              const SizedBox(height: 10),

              // --- Section 3: Absent ---
              _buildSectionHeader("Absent Passengers", appGreen),

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

  // Helper widget for section titles
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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

  // Helper widget for the phone icon
  Widget _buildPhoneIcon(Color color) {
    return InkWell(
      onTap: () {
        print("Calling passenger...");
      },
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