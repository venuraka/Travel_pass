import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class GoogleMaps extends StatelessWidget {
  final LatLng? initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool showMyLocationButton;
  final double bottomPadding; // Added
  final Function(GoogleMapController)? onMapCreated;
  final bool myLocationEnabled;

  const GoogleMaps({
    super.key,
    this.initialPosition,
    this.markers = const {},
    this.polylines = const {},
    this.showMyLocationButton = true,
    this.bottomPadding = 0, // Default 0
    this.onMapCreated,
    this.myLocationEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return _GoogleMapsStateful(
      initialPosition: initialPosition,
      markers: markers,
      polylines: polylines,
      showMyLocationButton: showMyLocationButton,
      bottomPadding: bottomPadding,
      onMapCreated: onMapCreated,
      myLocationEnabled: myLocationEnabled,
    );
  }
}

class _GoogleMapsStateful extends StatefulWidget {
  final LatLng? initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool showMyLocationButton;
  final double bottomPadding;
  final Function(GoogleMapController)? onMapCreated;
  final bool myLocationEnabled;

  const _GoogleMapsStateful({
    this.initialPosition,
    this.markers = const {},
    this.polylines = const {},
    this.showMyLocationButton = true,
    required this.bottomPadding,
    this.onMapCreated,
    this.myLocationEnabled = true,
  });

  @override
  State<_GoogleMapsStateful> createState() => _GoogleMapsStatefulState();
}

class _GoogleMapsStatefulState extends State<_GoogleMapsStateful> {
  GoogleMapController? controller;

  late final CameraPosition _initialPosition = CameraPosition(
    target: widget.initialPosition ?? const LatLng(6.9271, 79.8612),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
            // 1. Google Map (Fills the entire screen)
            GoogleMap(
              onMapCreated: (c) {
                controller = c;
                widget.onMapCreated?.call(c);
              },
              initialCameraPosition: _initialPosition,
              myLocationEnabled: widget.myLocationEnabled,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: widget.markers,
              polylines: widget.polylines,
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
              padding: EdgeInsets.only(
                right: 16, 
                bottom: 16 + widget.bottomPadding, // Use padding to avoid UI elements
              ),
              child: _circleButton(
                icon: Icons.my_location,
                onTap: _goToMyLocation,
              ),
            ),
          ),
        ),
      ],
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

  // Move camera to user's live location or a specific target
  Future<void> _goToMyLocation() async {
    // 1. Check if we have a Pooled Location marker already on the map
    // This is mathematically more accurate (averaged from multiple devices)
    final pooledMarker = widget.markers.cast<Marker?>().firstWhere(
      (m) => m?.markerId.value == 'pooled_location',
      orElse: () => null,
    );

    if (pooledMarker != null) {
      controller?.animateCamera(
        CameraUpdate.newLatLngZoom(pooledMarker.position, 17),
      );
      return;
    }

    // 2. Fallback to standard GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16),
    );
  }
}