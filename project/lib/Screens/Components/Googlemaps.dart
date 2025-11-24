import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMaps extends StatelessWidget {
  const GoogleMaps({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GoogleMapsStateful();
  }
}

class _GoogleMapsStateful extends StatefulWidget {
  const _GoogleMapsStateful();

  @override
  State<_GoogleMapsStateful> createState() => _GoogleMapsStatefulState();
}

class _GoogleMapsStatefulState extends State<_GoogleMapsStateful> {
  GoogleMapController? controller;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            // 1. Google Map (Fills the entire screen)
            GoogleMap(
              onMapCreated: (c) => controller = c,
              initialCameraPosition: _initialPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

        // Back button (TOP LEFT)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 10),
            child: _circleButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),

        // Current location button (BOTTOM RIGHT)
        SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 12),
              child: _circleButton(
                icon: Icons.my_location,
                onTap: _goToMyLocation,
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  // Reusable circle button widget
  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onTap,
      ),
    );
  }

  // Move camera to user's live location
  Future<void> _goToMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if GPS is on
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }

    // Get current location
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    controller?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(pos.latitude, pos.longitude),
      ),
    );
  }
}