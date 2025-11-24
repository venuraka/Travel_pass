// File: lib/next_passenger_card.dart
import 'package:flutter/material.dart';

// --- Color Definitions (Approximated from image) ---
const Color kCardBackgroundColor = Color(0xFF2B2B2B);
const Color kPrimaryTextColor = Color(0xFF4EE386);
const Color kSecondaryTextColor = Color(0xFFBDBDBD);

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
      // Use Column wrapped in a safe area for the main content to avoid overlap
      // with system bars if it were a fixed height, but here we only need the decoration.
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