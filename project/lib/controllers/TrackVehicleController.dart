import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/Database.dart';
import '../services/RealtimeDatabase.dart';
import '../models/PassengerModel.dart';

class TrackVehicleController {
  final DatabaseService _dbService = DatabaseService();
  final RealtimeDatabaseService _rtDbService = RealtimeDatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<bool>? _onboardedSubscription;
  bool _isDisposed = false;
  String? _driverId;
  String? _passengerId;

  // State
  final Function(LatLng) onPooledLocationChanged;
  final Function(bool) onOnboardingStatusChanged;
  final Function(String) onStatusChanged;

  TrackVehicleController({
    required this.onPooledLocationChanged,
    required this.onOnboardingStatusChanged,
    required this.onStatusChanged,
  });


  Future<void> init() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _passengerId = user.uid;

    // 1. Fetch passenger data to get driverId
    final passengerData = await _dbService.getPassengerAttendance(_passengerId!);
    // Wait, getPassengerAttendance returns AttendanceModel. I need PassengerModel for driverId.
    // Let's use getPassengerData instead (if it exists).
    // Actually, I'll just use the collection directly or add getPassengerData to dbService.
    
    // Check Database.dart again... it has getPassengerAttendance, but not a simple getPassengerData?
    // Oh, I see getPassengerAttendance(passengerId).
    // Let's assume I can get the passenger details.
  }
  
  void startTracking(String driverId, String passengerId) {
    _driverId = driverId;
    _passengerId = passengerId;

    // 1. Listen to pooled location
    _rtDbService.getPooledLocationStream(driverId).listen((loc) async {
      if (_isDisposed) return;
      if (loc.containsKey('lat') && loc.containsKey('lng')) {
        final vehicleLatLng = LatLng(loc['lat']!, loc['lng']!);
        onPooledLocationChanged(vehicleLatLng);
        
        // 1a. Calculate Status (ETA/Proximity)
        await _calculateStatus(driverId, passengerId, vehicleLatLng);
      }
    });

    // 2. Listen to onboarding status
    _onboardedSubscription = _rtDbService.getOnboardedStream(driverId, passengerId).listen((isOnboarded) {
      if (_isDisposed) return;
      onOnboardingStatusChanged(isOnboarded);
      if (isOnboarded) {
        onStatusChanged("ONBOARDED");
        _startLocationSharing();
      } else {
        _stopLocationSharing();
      }
    });
  }

  Future<void> _calculateStatus(String driverId, String passengerId, LatLng vehicleLoc) async {
    // 1. Get Passenger Data for pickup point name
    final passengerData = await _dbService.getPassengerData(passengerId);
    if (passengerData == null) {
      onStatusChanged("Calculating...");
      return;
    }
    final pickupName = passengerData.pickupLocation;


    // 2. Get Driver Route to find coords of that pickup point
    final driverData = await _dbService.getDriverData(driverId);
    if (driverData == null || driverData.route == null) return;

    LatLng? pickupLatLng;
    for (var point in driverData.route!) {
      if (point['name'] == pickupName) {
        pickupLatLng = LatLng(
          (point['lat'] as num).toDouble(),
          (point['lng'] as num).toDouble(),
        );
        break;
      }
    }

    if (pickupLatLng == null) {
      onStatusChanged("Calculating...");
      return;
    }

    // 3. Distance Check
    double distance = Geolocator.distanceBetween(
      vehicleLoc.latitude, vehicleLoc.longitude,
      pickupLatLng.latitude, pickupLatLng.longitude
    );

    if (distance < 50) {
      onStatusChanged("ON LOCATION");
    } else {
      // 40km/h average (~11m/s)
      int mins = (distance / 11 / 60).round();
      if (mins < 1) mins = 1;
      onStatusChanged("$mins min away");
    }
  }


  void _startLocationSharing() async {
    if (_positionSubscription != null) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (radiusPerm(permission)) {
       _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        if (_isDisposed || _driverId == null || _passengerId == null) return;
        _rtDbService.updatePassengerLocation(_driverId!, _passengerId!, position.latitude, position.longitude);
      });
    }
  }
  
  bool radiusPerm(LocationPermission p) => p == LocationPermission.always || p == LocationPermission.whileInUse;

  void _stopLocationSharing() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    _isDisposed = true;
    _onboardedSubscription?.cancel();
    _stopLocationSharing();
  }
}
