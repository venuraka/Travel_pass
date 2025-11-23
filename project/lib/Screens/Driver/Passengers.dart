import 'package:flutter/material.dart';
import '../Components/Cards.dart';
import '../Components/Topic.dart';
import 'NewPassenger.dart';
import 'EditPassenger.dart'; // Import the EditPassenger screen

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final Color appGreen = const Color(0xFF00C853);
  int _selectedIndex = 0;

  // Demo data to replicate the list in the image
  final List<Map<String, String>> passengers = List.generate(
    7,
    (index) => {
      "name": "Vethum Ranasinghe",
      "place": "Miriswatta",
      "price": "Rs 1000",
    },
  );

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Handle navigation to other screens here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header using the PageHeader component ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: PageHeader(
                title: "Passenger Details",
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.person_add_alt_1,
                      color: appGreen,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => NewPassengerScreen()));
                    },
                  ),
                ],
              ),
            ),

            // --- Scrollable List of InfoCards ---
            Expanded(
              child: ListView.builder(
                // Add padding around the list itself
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: passengers.length,
                itemBuilder: (context, index) {
                  final passenger = passengers[index];
                  return Padding(
                    // Add space between cards
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InfoCard(
                      title: passenger["name"]!,
                      // Combine place and price with a line break for the subtitle
                      subtitle:
                          "${passenger["place"]!}\n${passenger["price"]!}",
                      showTag: false, // No tag needed as per the image
                      trailing: IconButton(
                        icon: Icon(Icons.more_vert, color: appGreen),
                        onPressed: () {
                          // Navigate to EditPassenger screen on tap
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditPassengerScreen()),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
