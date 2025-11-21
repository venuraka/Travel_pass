import 'package:flutter/material.dart';
import '../Components/Cards.dart';


class TodaypassengersScreen extends StatelessWidget {
  const TodaypassengersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the green color used throughout the app
    final Color appGreen = const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white, // Or slightly grey if needed
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // --- Header Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_circle_left_outlined, color: appGreen, size: 30),
                      onPressed: () {
                        // Handle back navigation
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Today Passenger Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Section 1: Today's Passengers ---
              _buildSectionHeader("Today's Passengers", appGreen),

              InfoCard(
                title: "Vethum Ranasinghe",
                subtitle: "Miriswatta",
                showTag: true,
                trailing: _buildPhoneIcon(appGreen),
              ),
              InfoCard(
                title: "Vethum Ranasinghe",
                subtitle: "Miriswatta",
                showTag: false,
                trailing: _buildPhoneIcon(appGreen),
              ),
              InfoCard(
                title: "Vethum Ranasinghe",
                subtitle: "Miriswatta",
                showTag: true,
                trailing: _buildPhoneIcon(appGreen),
              ),

              const SizedBox(height: 10),

              // --- Section 2: Absent Passengers ---
              _buildSectionHeader("Absent Passengers", appGreen),

              InfoCard(
                title: "Vethum Ranasinghe",
                subtitle: "Miriswatta",
                showTag: true,
                trailing: _buildPhoneIcon(appGreen),
              ),
              InfoCard(
                title: "Vethum Ranasinghe",
                subtitle: "Miriswatta",
                showTag: true,
                trailing: _buildPhoneIcon(appGreen),
              ),
              InfoCard(
                title: "Vethum Ranasinghe",
                subtitle: "Miriswatta",
                showTag: false,
                trailing: _buildPhoneIcon(appGreen),
              ),

              const SizedBox(height: 10),

              // --- Section 3: Not voted ---
              _buildSectionHeader("Not voted", appGreen),

              InfoCard(
                title: "Vethum Ranasinghe",
                subtitle: "Miriswatta",
                showTag: true,
                trailing: _buildPhoneIcon(appGreen),
              ),

              const SizedBox(height: 30), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the Green Section Titles
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

  // Helper widget for the Phone Icon
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