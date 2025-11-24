import 'package:flutter/material.dart';
import '../Components/Googlemaps.dart';
import '../Components/MapsBottomCard.dart';


class Startjourney extends StatelessWidget {
  const Startjourney({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // 👈 CHANGE 1: Use Stack instead of Column
        children: [
          // 1. Google Map (Fills the entire screen)
          const GoogleMaps(), // 👈 CHANGE 2: No need for Expanded in Stack

          // 2. Next Passenger Card (Positioned at the bottom)
          Align(
            alignment: Alignment.bottomCenter, // 👈 Ensures the card is at the bottom
            child: NextPassengerCard(
              passengerName: "John Doe",
              location: "Gampaha Town",
              eta: "Arriving in 5 mins",
              onCallPressed: () {
                print("Call pressed");
              },
              onPreviousPressed: () {
                print("Previous pressed");
              },
              onNextPressed: () {
                print("Next pressed");
              },
            ),
          ),
        ],
      ),
    );
  }
}