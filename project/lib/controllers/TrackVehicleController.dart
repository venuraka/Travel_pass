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
  final Function(String) onNextStopChanged; // Added
  final Function(int) onOnboardedCountChanged; // Added
  final Function(LatLng, String) onDestinationAcquired; // Added
  final Function(int) onProgressIndexChanged; // Added

  TrackVehicleController({
    required this.onPooledLocationChanged,
    required this.onOnboardingStatusChanged,
    required this.onStatusChanged,
    required this.onNextStopChanged,
    required this.onOnboardedCountChanged,
    required this.onDestinationAcquired,
    required this.onProgressIndexChanged, // Added
  });


  Future<void> init() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _passengerId = user.uid;

    // 1. Fetch passenger data
    final pData = await _dbService.getPassengerData(_passengerId!);
    if (pData != null) {
       _driverId = pData.driverId;
       if (_driverId != null) {
         startTracking(_driverId!, _passengerId!);
       }
    }
  }
  
  StreamSubscription? _progressSubscription;
  StreamSubscription? _destSubscription;
  StreamSubscription? _attendanceSubscription;
  LatLng? _currentVehicleLoc;
  LatLng? _currentPassengerLoc;
  LatLng? _routeDestination;
  LatLng? _nextStopLoc;
  bool _isOnboarded = false;

  void startTracking(String driverId, String passengerId) {
    _driverId = driverId;
    _passengerId = passengerId;

    // 1. Listen to pooled location
    _rtDbService.getPooledLocationStream(driverId).listen((loc) async {
      if (_isDisposed) return;
      if (loc.containsKey('lat') && loc.containsKey('lng')) {
        _currentVehicleLoc = LatLng(loc['lat']!, loc['lng']!);
        onPooledLocationChanged(_currentVehicleLoc!);
        _calculateStatus();
      }
    });

    // 2. Listen to onboarding status
    _onboardedSubscription = _rtDbService.getOnboardedStream(driverId, passengerId).listen((isOnboarded) {
      if (_isDisposed) return;
      _isOnboarded = isOnboarded;
      onOnboardingStatusChanged(isOnboarded);
      _calculateStatus();
    });

    // 3. Listen to Journey Progress (Next Stop)
    _progressSubscription = _rtDbService.getJourneyProgressStream(driverId).listen((data) {
      if (_isDisposed || data.isEmpty) return;
      onNextStopChanged(data['target_name']);
      onProgressIndexChanged(data['index']); // Added
      _nextStopLoc = LatLng(data['target_lat'], data['target_lng']);
      _calculateStatus();
    });

    // 4. Listen to Route Destination
    _destSubscription = _rtDbService.getRouteDestinationStream(driverId).listen((data) async {
      if (_isDisposed) return;
      if (data.isNotEmpty) {
        _routeDestination = LatLng(data['lat'], data['lng']);
        onDestinationAcquired(_routeDestination!, data['name']);
        _calculateStatus();
      } else {
        // Fallback to Firestore if RTDB is empty
        final driverData = await _dbService.getDriverData(driverId);
        if (driverData != null && driverData.route != null && driverData.route!.isNotEmpty) {
          final last = driverData.route!.last;
          _routeDestination = LatLng((last['lat'] as num).toDouble(), (last['lng'] as num).toDouble());
          onDestinationAcquired(_routeDestination!, last['name'] ?? 'Destination');
          _calculateStatus();
        }
      }
    });

    // 5. Listen to Onboarded Count
    _attendanceSubscription = _rtDbService.getOnboardedCountStream(driverId).listen((count) {
       if (_isDisposed) return;
       onOnboardedCountChanged(count);
    });

    // 6. Start location sharing immediately
    _startLocationSharing();
  }

  Future<void> _calculateStatus() async {
    if (_isDisposed || _driverId == null || _passengerId == null || _currentVehicleLoc == null) return;

    if (_isOnboarded) {
      // Logic for Onboarded Passenger -> Show Drop-off ETA
      if (_routeDestination != null) {
        double dist = Geolocator.distanceBetween(
          _currentVehicleLoc!.latitude, _currentVehicleLoc!.longitude,
          _routeDestination!.latitude, _routeDestination!.longitude
        );
        int mins = (dist / 11 / 60).round();
        if (mins < 1) mins = 1;
        onStatusChanged("Drop-off in $mins min");
      } else {
        onStatusChanged("You are onboarded");
      }
      return;
    }

    // Logic for Waiting Passenger
    // 1. Get Passenger Data for pickup point if nextStopLoc is not their pickup
    final passengerData = await _dbService.getPassengerData(_passengerId!);
    if (passengerData == null) return;
    
    final pickupName = passengerData.pickupLocation;
    LatLng? myPickupLoc;
    
    // Find my pickup coords from driver route
    final driverData = await _dbService.getDriverData(_driverId!);
    if (driverData != null && driverData.route != null) {
      for (var point in driverData.route!) {
        if (point['name'] == pickupName) {
          myPickupLoc = LatLng((point['lat'] as num).toDouble(), (point['lng'] as num).toDouble());
          break;
        }
      }
    }

    if (myPickupLoc == null) return;

    // Distance vehicle to pickup
    double busDist = Geolocator.distanceBetween(
      _currentVehicleLoc!.latitude, _currentVehicleLoc!.longitude,
      myPickupLoc.latitude, myPickupLoc.longitude
    );

    // If passenger is moving, calculate their ETA to pickup
    if (_currentPassengerLoc != null) {
      double pDist = Geolocator.distanceBetween(
        _currentPassengerLoc!.latitude, _currentPassengerLoc!.longitude,
        myPickupLoc.latitude, myPickupLoc.longitude
      );

      if (pDist > 50) {
        // Orange Status: Passenger moving to spot
        int pMins = (pDist / 1.4 / 60).round();
        if (pMins < 1) pMins = 1;
        onStatusChanged("SPOT: $pMins min"); // Use a short code or "Wait" as per previous optimization
        // Actually, user said: "if he is comming to pickup point there should be display estimated time to pickup point"
        // I'll use "Wait: $pMins min" or "$pMins min wait" to keep it short.
        onStatusChanged("$pMins min wait"); 
        return;
      }
    }

    // Green Status: Bus moving to pickup
    int busMins = (busDist / 11 / 60).round();
    if (busMins < 1) busMins = 1;
    onStatusChanged("$busMins min pickup");
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
        _currentPassengerLoc = LatLng(position.latitude, position.longitude);
        _rtDbService.updatePassengerLocation(_driverId!, _passengerId!, position.latitude, position.longitude);
        _calculateStatus();
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
    _progressSubscription?.cancel();
    _destSubscription?.cancel();
    _attendanceSubscription?.cancel();
    _stopLocationSharing();
  }
}
