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
                await _controller.markAsAbsent(passenger.uid);
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
            bottomPadding: _controller.passengers.isNotEmpty ? 330 : 0,
            myLocationEnabled: false, // We use pooled location arrow instead
            showMyLocationButton: false, // Added to remove duplicate button
            onMapCreated: (mapController) {
              _controller.setMapController(mapController);
            },
          ),

          // 2. Navigation Control Buttons (Re-center and North/Compass)
          Positioned(
            bottom: _controller.passengers.isNotEmpty ? 280 : 100,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // North Button (shown if map is rotated or just for convenience)
                _buildNorthButton(),
                const SizedBox(height: 60),
                // Re-center button (shown when camera is not following)
                if (!_controller.isFollowingCamera)
                  _buildRecenterButton(),
              ],
            ),
          ),

          // 3. Next Passenger Card (Positioned at the bottom)
          if (_controller.passengers.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: NextPassengerCard(
                passengers: _controller.passengers,
                currentIndex: _controller.currentPassengerIndex,
                status: _controller.currentStatus,
                statusColor: _controller.statusColor, // Added
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

  /// Builds a circular "North" button to reset map orientation.
  Widget _buildNorthButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.resetMapRotation();
        });
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.explore,
          color: Color(0xFF1A73E8),
          size: 24,
        ),
      ),
    );
  }

  /// Builds a Google Maps-style "Re-center" button.
  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.reCenterCamera();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.navigation,
              color: const Color(0xFF1A73E8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Re-center',
              style: TextStyle(
                color: const Color(0xFF1A73E8),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}