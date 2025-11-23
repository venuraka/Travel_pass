import 'package:flutter/material.dart';
import '../Components/AppBar.dart';
import '../Components/Cards.dart';
import 'RegisterPassenger.dart';

class NewPassengerScreen extends StatefulWidget {
  const NewPassengerScreen({super.key});

  @override
  State<NewPassengerScreen> createState() => _NewPassengerScreenState();
}

class _NewPassengerScreenState extends State<NewPassengerScreen> {
  // The theme color used throughout the app
  final Color appGreen = const Color(0xFF00C853);

  // Demo data to replicate the list entries in the image
  final List<Map<String, String>> newPassengers = List.generate(
    4,
        (index) => {
      "name": "Vethum Ranasinghe",
      "place": "Miriswatta",
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'New Passenger List',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              for (var passenger in newPassengers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _buildPassengerRow(
                    passenger["name"]!,
                    passenger["place"]!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerRow(String name, String place) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. MOVED: Phone icon is now the first child in the Row (Left side)
        Padding(
          padding: const EdgeInsets.only(right: 15), // Spacing between phone and card
          child: IconButton(
            onPressed: () {
              // TODO: Handle call action
            },
            icon: Icon(Icons.phone, color: appGreen),
            iconSize: 28,
          ),
        ),

        // 2. The Card takes up the remaining space
        Expanded(
          child: InfoCard(
            title: name,
            subtitle: place,
            showTag: false,
            // The check and cross buttons remain on the right side of the card content
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                  onPressed: () {
                    // Navigate to RegisterPassengerScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPassengerScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.check_circle_outline, color: appGreen, size: 28),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                  onPressed: () {
                    // TODO: Handle reject action
                  },
                  icon: const Icon(Icons.highlight_off, color: Colors.red, size: 28),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}