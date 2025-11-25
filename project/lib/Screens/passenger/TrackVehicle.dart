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

class NextPassengerCard extends StatelessWidget {
  final String passengerName;
  final String location;
  final String eta;
  // Define callback functions for interactions
  final VoidCallback? onCallPressed;
  final VoidCallback? onPreviousPressed;
  final VoidCallback? onNextPressed;

  const NextPassengerCard({
    super.key,
    required this.passengerName,
    required this.location,
    required this.eta,
    this.onCallPressed,
    this.onPreviousPressed,
    this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // --- Title: Next Passenger ---
          const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Text(
              'Next Passenger',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),

          // --- Passenger Info Row with Arrows ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Left Arrow Button
              IconButton(
                onPressed: onPreviousPressed,
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: kPrimaryTextColor,
                  size: 24,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                constraints: const BoxConstraints(),
              ),

              // Centered Passenger Details
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(passengerName, style: const TextStyle(color: kPrimaryTextColor, fontSize: 18.0, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4.0),
                    Text(location, style: const TextStyle(color: kPrimaryTextColor, fontSize: 18.0, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8.0),
                    const Text('On Location', style: TextStyle(color: kPrimaryTextColor, fontSize: 16.0, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8.0),
                    Text(eta, style: const TextStyle(color: kSecondaryTextColor, fontSize: 16.0)),
                  ],
                ),
              ),

              // Right Arrow Button
              IconButton(
                onPressed: onNextPressed,
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: kPrimaryTextColor,
                  size: 24,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // --- Divider Space ---
          const SizedBox(height: 30.0),

          // --- Bottom Action: Hold To Get a Call ---
          GestureDetector(
            onTap: onCallPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(
                  Icons.call,
                  color: kPrimaryTextColor,
                  size: 18,
                ),
                SizedBox(width: 8.0),
                Text(
                  'Hold To Get a Call...',
                  style: TextStyle(
                    color: kSecondaryTextColor,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW: Journey Info Card ---
class JourneyInfoCard extends StatelessWidget {
  final String busArrivalTime;
  final String nextStop;
  final int attendanceCount;
  final VoidCallback? onCallPressed;

  const JourneyInfoCard({
    super.key,
    required this.busArrivalTime,
    required this.nextStop,
    required this.attendanceCount,
    this.onCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // --- Swipe Up Instruction ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Icon(
                Icons.keyboard_arrow_up,
                color: kSecondaryTextColor,
                size: 18,
              ),
              SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  'Swipe Up If you have come to Pickup spot',
                  style: TextStyle(
                    color: kSecondaryTextColor,
                    fontSize: 13.0,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6.0),
              Icon(
                Icons.keyboard_arrow_up,
                color: kSecondaryTextColor,
                size: 18,
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // --- Bus Will Come on ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Bus Will Come on',
                style: TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                busArrivalTime,
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // --- Next Stop ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Next Stop',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                nextStop,
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // --- Attendance Count ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Attendance Count',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                '$attendanceCount',
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // --- Hold To Get a Call ---
          GestureDetector(
            onTap: onCallPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(
                  Icons.phone_callback,
                  color: kPrimaryTextColor,
                  size: 18,
                ),
                SizedBox(width: 8.0),
                Text(
                  'Hold To Get a Call...',
                  style: TextStyle(
                    color: kPrimaryTextColor,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}