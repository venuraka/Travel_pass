import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Components/Googlemaps.dart';
import '../Components/MapsBottomCard.dart';
import '../../controllers/TrackVehicleController.dart';

// --- Color Definitions (Approximated from image) ---
const Color kCardBackgroundColor = Color(0xFF121415);
const Color kPrimaryTextColor = Color(0xFF05A664);
const Color kSecondaryTextColor = Color(0xFFF8F9FC);

class TrackVehicle extends StatefulWidget {
  final String driverId;
  final String passengerId;

  const TrackVehicle({
    super.key,
    required this.driverId,
    required this.passengerId,
  });

  @override
  State<TrackVehicle> createState() => _TrackVehicleState();
}

class _TrackVehicleState extends State<TrackVehicle> {
  late TrackVehicleController _controller;
  LatLng? _pooledLocation;
  bool _isOnboarded = false;

  @override
  void initState() {
    super.initState();
    _controller = TrackVehicleController(
      onPooledLocationChanged: (LatLng location) {
        if (mounted) {
          setState(() {
            _pooledLocation = location;
          });
        }
      },
      onOnboardingStatusChanged: (bool status) {
        if (mounted) {
          setState(() {
            _isOnboarded = status;
          });
        }
      },
    );
    _controller.startTracking(widget.driverId, widget.passengerId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMaps(
            initialPosition: _pooledLocation,
            markers: _pooledLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('pooled_vehicle'),
                      position: _pooledLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                      infoWindow: const InfoWindow(title: "Vehicle Location"),
                    )
                  }
                : {},
          ),

          // Journey Info Card (Bottom Positioned)
          Align(
            alignment: Alignment.bottomCenter,
            child: JourneyInfoCard(
              busArrivalTime: _isOnboarded ? "Onboarded" : "Calculating...",
              nextStop: _isOnboarded ? "Sharing your location" : "Waiting for pick up",
              attendanceCount: _isOnboarded ? 1 : 0, // Placeholder
              onCallPressed: () {
                print("Call pressed");
              },
            ),
          ),
          
          // Onboarding Status Overlay (Optional)
          if (_isOnboarded)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "ONBOARDED - SHARING",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
