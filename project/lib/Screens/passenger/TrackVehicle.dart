import 'package:flutter/material.dart';
import '../Components/Googlemaps.dart';
import '../Components/MapsBottomCard.dart';

// --- Color Definitions (Approximated from image) ---
const Color kCardBackgroundColor = Color(0xFF121415);
const Color kPrimaryTextColor = Color(0xFF05A664);
const Color kSecondaryTextColor = Color(0xFFF8F9FC);

// --- TrackVehicle Screen ---
class TrackVehicle extends StatelessWidget {
  const TrackVehicle({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map (Fills the entire screen)
          const GoogleMaps(),

          // Journey Info Card (Bottom Positioned)
          Align(
            alignment: Alignment.bottomCenter,
            child: JourneyInfoCard(
              busArrivalTime: "20 min",
              nextStop: "Kadawatha",
              attendanceCount: 17,
              onCallPressed: () {
                print("Call pressed");
              },
            ),
          ),
        ],
      ),
    );
  }
}
