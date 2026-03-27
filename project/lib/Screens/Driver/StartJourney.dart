import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Components/Googlemaps.dart';
import '../Components/MapsBottomCard.dart';
import '../Components/PassengerGetInPopup.dart';
import '../../controllers/StartJourneyController.dart';
import '../../models/PassengerModel.dart';

class Startjourney extends StatefulWidget {
  const Startjourney({super.key});

  @override
  State<Startjourney> createState() => _StartjourneyState();
}

class _StartjourneyState extends State<Startjourney> {
  late StartJourneyController _controller;
  PassengerModel? _proximityPassenger;
  bool _isPopupShown = false;

  @override
  void initState() {
    super.initState();
    _controller = StartJourneyController(
      onLocationChanged: (position) {
        // Map will update automatically if myLocationEnabled is true
      },
      onProximityReached: (passenger) {
        if (!_isPopupShown) {
          setState(() {
            _proximityPassenger = passenger;
            _isPopupShown = true;
          });
          _showPassengerPopup(passenger);
        }
      },
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _controller.init(user.uid).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _showPassengerPopup(List<PassengerModel> proximalPassengers) {
    // Create a local copy to manage within the popup session
    List<PassengerModel> remainingPassengers = List.from(proximalPassengers);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return PassengerGetInPopup(
              passengers: remainingPassengers,
              onCorrect: (passenger) async {
                await _controller.markOnboarded(passenger.uid, true);
                setPopupState(() {
                  remainingPassengers.removeWhere((p) => p.uid == passenger.uid);
                });
                if (remainingPassengers.isEmpty) {
                  _isPopupShown = false;
                  Navigator.pop(context);
                  setState(() {
                    _controller.nextPassenger();
                  });
                }
              },
              onIncorrect: (passenger) async {
                await _controller.markOnboarded(passenger.uid, false);
                setPopupState(() {
                  remainingPassengers.removeWhere((p) => p.uid == passenger.uid);
                });
                if (remainingPassengers.isEmpty) {
                  _isPopupShown = false;
                  Navigator.pop(context);
                  setState(() {
                    _controller.nextPassenger();
                  });
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPassenger = _controller.currentPassenger;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map (Fills the entire screen)
          const GoogleMaps(),

          // 2. Next Passenger Card (Positioned at the bottom)
          if (currentPassenger != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: NextPassengerCard(
                passengerName: currentPassenger.name,
                location: currentPassenger.pickupLocation,
                eta: "Calculated from live data",
                onCallPressed: () {
                  print("Call pressed");
                },
                onPreviousPressed: () {
                  setState(() {
                    _controller.previousPassenger();
                  });
                },
                onNextPressed: () {
                  setState(() {
                    _controller.nextPassenger();
                  });
                },
              ),
            ),
          
          if (currentPassenger == null && _controller.passengers.isNotEmpty)
             const Align(
              alignment: Alignment.bottomCenter,
               child: Card(
                 color: Colors.black87,
                 child: Padding(
                   padding: EdgeInsets.all(20.0),
                   child: Text("All passengers reached", style: TextStyle(color: Colors.white)),
                 ),
               ),
             )
        ],
      ),
    );
  }
}