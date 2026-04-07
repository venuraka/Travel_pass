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
  List<PassengerModel>? _proximalPassengers;
  bool _isPopupShown = false;

  @override
  void initState() {
    super.initState();
    _controller = StartJourneyController(
      onLocationChanged: (position) {
        if (mounted) setState(() {});
      },
      onProximityReached: (passengers) {
        if (!_isPopupShown) {
          setState(() {
            _proximalPassengers = passengers;
            _isPopupShown = true;
          });
          _showPassengerPopup(passengers);
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
              onCallPressed: (phone) {
                _controller.makeCall(phone);
              },
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
          GoogleMaps(
            markers: _controller.markers,
            polylines: _controller.polylines,
            bottomPadding: _controller.passengers.isNotEmpty ? 280 : 0, // Push button up if card is visible
          ),

          // 2. Next Passenger Card (Positioned at the bottom)
          if (_controller.passengers.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: NextPassengerCard(
                passengers: _controller.passengers,
                currentIndex: _controller.currentPassengerIndex,
                status: _controller.currentStatus,
                onCallPressed: (phone) {
                  _controller.makeCall(phone);
                },
                onPageChanged: (index) {
                  setState(() {
                    _controller.setPassengerIndex(index);
                  });
                },
                isAtFinalDestination: _controller.isAtFinalDestination, // Added
                onFinishJourney: () async {
                  await _controller.finishJourney();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),


        ],
      ),
    );
  }
}