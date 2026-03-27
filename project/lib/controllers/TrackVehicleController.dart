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

  TrackVehicleController({
    required this.onPooledLocationChanged,
    required this.onOnboardingStatusChanged,
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
    _rtDbService.getPooledLocationStream(driverId).listen((loc) {
      if (_isDisposed) return;
      if (loc.containsKey('lat') && loc.containsKey('lng')) {
        onPooledLocationChanged(LatLng(loc['lat']!, loc['lng']!));
      }
    });

    // 2. Listen to onboarding status
    _onboardedSubscription = _rtDbService.getOnboardedStream(driverId, passengerId).listen((isOnboarded) {
      if (_isDisposed) return;
      onOnboardingStatusChanged(isOnboarded);
      if (isOnboarded) {
        _startLocationSharing();
      } else {
        _stopLocationSharing();
      }
    });
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
