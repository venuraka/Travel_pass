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
  LatLng? _passengerLocation; // Added
  LatLng? _pickupLocation; // Added
  List<LatLng> _walkingPath = []; // Added
  List<LatLng> _vehiclePath = []; // Added
  bool _isOnboarded = false;
  String _currentStatus = "Calculating...";
  String _nextStop = "Calculating..."; // Added
  int _onboardedCount = 0; // Added
  int _progressIndex = 0; // Added
  LatLng? _routeDestination; // Added


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
      onStatusChanged: (String status) {
        if (mounted) {
          setState(() {
            _currentStatus = status;
          });
        }
      },
      onNextStopChanged: (String nextStop) {
        if (mounted) {
          setState(() {
            _nextStop = nextStop;
          });
        }
      },
      onOnboardedCountChanged: (int count) {
        if (mounted) {
          setState(() {
            _onboardedCount = count;
          });
        }
      },
      onDestinationAcquired: (LatLng dest, String name) {
        if (mounted) {
          setState(() {
            _routeDestination = dest;
          });
        }
      },
      onProgressIndexChanged: (int index) {
        if (mounted) {
          setState(() {
            _progressIndex = index;
          });
        }
      },
      onPassengerLocationChanged: (LatLng loc) {
        if (mounted) {
          setState(() {
            _passengerLocation = loc;
          });
        }
      },
      onPickupLocationAcquired: (LatLng loc) {
        if (mounted) {
          setState(() {
            _pickupLocation = loc;
          });
        }
      },
      onWalkingPathChanged: (List<LatLng> path) {
        if (mounted) {
          setState(() {
            _walkingPath = path;
          });
        }
      },
      onVehiclePathChanged: (List<LatLng> path) {
        if (mounted) {
          setState(() {
            _vehiclePath = path;
            _fitBoundsOnce(); // Try to fit bounds when we have paths
          });
        }
      },
    );
    _controller.init(); // Use init instead of direct startTracking if we want to fetch pData first
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build Markers
    final Set<Marker> markers = {};
    if (_pooledLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pooled_vehicle'),
          position: _pooledLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Vehicle Location'),
        ),
      );
    }
    if (_passengerLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('passenger_location'),
          position: _passengerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }
    if (_pickupLocation != null && !_isOnboarded) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Pickup Point'),
        ),
      );
    }

    // Build Polylines
    final Set<Polyline> polylines = {};
    if (_walkingPath.isNotEmpty && !_isOnboarded) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('walking_route'),
          points: _walkingPath,
          color: Colors.orange,
          width: 5,
        ),
      );
    }
    if (_vehiclePath.isNotEmpty && !_isOnboarded) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('vehicle_route'),
          points: _vehiclePath,
          color: Colors.green.withOpacity(0.7),
          width: 5,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMaps(
            initialPosition: _pooledLocation,
            markers: markers,
            polylines: polylines,
            bottomPadding: 240, 
            onMapCreated: (c) {
              _mapController = c;
            },
          ),

          // Journey Info Card (Bottom Positioned)
          Align(
            alignment: Alignment.bottomCenter,
            child: JourneyInfoCard(
              busArrivalTime: _currentStatus,
              nextStop: _nextStop,
              attendanceCount: _onboardedCount,
              isOnboarded: _isOnboarded,
              progressIndex: _progressIndex, // Added
              onCallPressed: () {
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

  GoogleMapController? _mapController;
  bool _hasFittedBounds = false;

  void _fitBoundsOnce() {
    if (_hasFittedBounds || _mapController == null) return;

    List<LatLng> points = [];
    if (_pooledLocation != null) points.add(_pooledLocation!);
    if (_passengerLocation != null) points.add(_passengerLocation!);
    if (_pickupLocation != null) points.add(_pickupLocation!);

    if (points.length < 2) return;

    _hasFittedBounds = true;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // Padding
      ),
    );
  }
}

