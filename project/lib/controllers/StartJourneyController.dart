import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/Database.dart';
import '../services/RealtimeDatabase.dart';
import '../models/PassengerModel.dart';

class StartJourneyController {
  final DatabaseService _dbService = DatabaseService();
  final RealtimeDatabaseService _rtDbService = RealtimeDatabaseService();
  
  static const _channel = MethodChannel('com.travelpass.app/phone');

  StreamSubscription<Position>? _positionSubscription;
  List<PassengerModel> _allPassengers = [];
  List<Map<String, dynamic>>? _driverRoute;
  int _currentPassengerIndex = 0;
  bool _isDisposed = false;
  String? _currentDriverId;

  // Real-time status for the card
  String _currentStatus = "Calculating...";
  Set<Marker> _markers = {};

  // State
  List<PassengerModel> get passengers => _allPassengers;
  int get currentPassengerIndex => _currentPassengerIndex;
  PassengerModel? get currentPassenger => 
      (_allPassengers.isNotEmpty && _currentPassengerIndex < _allPassengers.length)
      ? _allPassengers[_currentPassengerIndex] : null;

  String get currentStatus => _currentStatus;
  Set<Marker> get markers => _markers;

  final Function(Position) onLocationChanged;
  final Function(List<PassengerModel>) onProximityReached;

  StartJourneyController({
    required this.onLocationChanged,
    required this.onProximityReached,
  });

  Future<void> init(String driverId) async {
    _currentDriverId = driverId;
    
    // 1. Fetch driver data for route
    await _fetchDriverRoute(driverId);

    // 2. Fetch passengers for this driver
    _allPassengers = await _dbService.getPassengersByDriver(driverId);
    
    // Sort passengers based on the route order if possible, 
    // but for now we'll just use the list.
    
    // 3. Initial markers
    _updateMarkers();
    
    // 4. Start location tracking
    await _startLocationTracking(driverId);
  }

  Future<void> _fetchDriverRoute(String driverId) async {
    final driverData = await _dbService.getDriverData(driverId);
    if (driverData != null && driverData.route != null) {
      // route is List<Map<String, dynamic>>
      _driverRoute = driverData.route; // Store the route
    }
  }

  void _updateMarkers() async {
    final Set<Marker> newMarkers = {};
    if (_currentDriverId == null) return;

    final driverData = await _dbService.getDriverData(_currentDriverId!);
    if (driverData == null || driverData.route == null) return;

    for (var point in driverData.route!) {
      if (point['role'] == 'pickup') {
        newMarkers.add(
          Marker(
            markerId: MarkerId(point['name'] as String),
            position: LatLng(
              (point['lat'] as num).toDouble(),
              (point['lng'] as num).toDouble(),
            ),
            infoWindow: InfoWindow(title: point['name'] as String),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );
      }
    }
    _markers = newMarkers;
  }

  Future<void> _startLocationTracking(String driverId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      if (_isDisposed) return;
      
      onLocationChanged(position);
      
      // Update RTDB
      _rtDbService.updateDriverLocation(driverId, position.latitude, position.longitude);
      
      // Check proximity and update status
      _checkProximity(position);
    });
  }

  void _checkProximity(Position position) async {
    final targetPassenger = currentPassenger;
    if (targetPassenger == null || _currentDriverId == null) return;

    // 1. Resolve target passenger LatLng from driver's route
    final driverData = await _dbService.getDriverData(_currentDriverId!);
    if (driverData == null || driverData.route == null) return;

    LatLng? targetLatLng;
    for (var point in driverData.route!) {
      if (point['name'] == targetPassenger.pickupLocation) {
        targetLatLng = LatLng(
          (point['lat'] as num).toDouble(),
          (point['lng'] as num).toDouble(),
        );
        break;
      }
    }

    if (targetLatLng == null) {
      _currentStatus = "No location data";
      return;
    }

    // 2. Check distance to target
    double distance = Geolocator.distanceBetween(
      position.latitude, position.longitude,
      targetLatLng.latitude, targetLatLng.longitude
    );

    // Update Card Status
    if (distance < 50) { // 50 meters
      _currentStatus = "On Location";
      
      // 3. Find ALL passengers at this same location who are "Present"
      List<PassengerModel> proximalPassengers = [];
      
      for (var passenger in _allPassengers) {
        // Only check passengers who haven't been processed or are at the same spot
        if (passenger.pickupLocation == targetPassenger.pickupLocation) {
          final status = await _dbService.getTodayAttendanceStatus(passenger.uid);
          if (status == 'Present') {
            proximalPassengers.add(passenger);
          }
        }
      }

      if (proximalPassengers.isNotEmpty) {
        onProximityReached(proximalPassengers);
      }
    } else {
      // Simulating ETA based on ~40km/h (11m/s)
      int mins = (distance / 11 / 60).round();
      if (mins < 1) mins = 1;
      _currentStatus = "$mins min to pickup";
    }
  }

  Future<void> makeCall() async {
    final passenger = currentPassenger;
    if (passenger == null || passenger.phone.isEmpty) return;
    
    try {
      await _channel.invokeMethod('makeCall', {'phoneNumber': passenger.phone});
    } on PlatformException catch (e) {
      debugPrint("Failed to make call: ${e.message}");
    }
  }

  Future<void> markOnboarded(String passengerId, bool onboarded) async {
    if (_currentDriverId != null) {
      await _rtDbService.setOnboarded(_currentDriverId!, passengerId, onboarded);
    }
  }

  void nextPassenger() {
    if (_currentPassengerIndex < _allPassengers.length - 1) {
      _currentPassengerIndex++;
    }
  }

  void previousPassenger() {
    if (_currentPassengerIndex > 0) {
      _currentPassengerIndex--;
    }
  }

  void setPassengerIndex(int index) {
    if (index >= 0 && index < _allPassengers.length) {
      _currentPassengerIndex = index;
    }
  }

  void dispose() {
    _isDisposed = true;
    _positionSubscription?.cancel();
  }
}
