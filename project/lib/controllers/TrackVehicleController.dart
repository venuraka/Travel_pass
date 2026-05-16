import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/Database.dart';
import '../services/RealtimeDatabase.dart';
import '../services/PlaceService.dart'; // Added
import '../config/AppConfig.dart'; // Added
import '../models/PassengerModel.dart';
import '../models/DriverModel.dart';
import '../services/NotificationService.dart'; // Added

class TrackVehicleController {
  final DatabaseService _dbService = DatabaseService();
  final RealtimeDatabaseService _rtDbService = RealtimeDatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PushNotificationService _notificationService = PushNotificationService(); // Added

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
  final Function(LatLng) onPassengerLocationChanged; // Added
  final Function(LatLng) onPickupLocationAcquired; // Added
  final Function(List<LatLng>) onWalkingPathChanged; // Added
  final Function(List<LatLng>) onVehiclePathChanged; // Added
  final Function(int) onVehicleETAChanged; // Added
  final Function(int) onPassengerETAChanged; // Added
  final Function(bool) onHasNextPickupChanged; // Added
  final Function(List<Map<String, dynamic>>) onFullRouteAcquired; // Added
  final Function(int) onRouteIndexChanged; // Added
  final VoidCallback onJourneyEnded; // Added

  TrackVehicleController({
    required this.onPooledLocationChanged,
    required this.onOnboardingStatusChanged,
    required this.onStatusChanged,
    required this.onNextStopChanged,
    required this.onOnboardedCountChanged,
    required this.onDestinationAcquired,
    required this.onProgressIndexChanged, // Added
    required this.onPassengerLocationChanged,
    required this.onPickupLocationAcquired,
    required this.onWalkingPathChanged,
    required this.onVehiclePathChanged,
    required this.onVehicleETAChanged,
    required this.onPassengerETAChanged,
    required this.onHasNextPickupChanged,
    required this.onFullRouteAcquired,
    required this.onRouteIndexChanged,
    required this.onJourneyEnded,
  });


  Future<void> init() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _passengerId = user.uid;

    _placeService = PlaceService(AppConfig.googleMapsApiKey); // Added

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
  StreamSubscription? _journeyStatusSubscription; // Added
  LatLng? _currentVehicleLoc; // Restored
  LatLng? _currentPassengerLoc; // Restored
  LatLng? _routeDestination;
  LatLng? _nextStopLoc;
  LatLng? _myPickupLoc;
  bool _isOnboarded = false;
  bool _notifiedDropOff = false; // Added
  PlaceService? _placeService;
  List<Map<String, dynamic>>? _driverRoute; // Added
  
  LatLng? _lastPathFetchPassengerPos;
  LatLng? _lastPathFetchPickupPos;
  LatLng? _lastVehiclePathFetchVehiclePos;
  LatLng? _lastVehiclePathFetchPickupPos;

  void startTracking(String driverId, String passengerId) async { // Added async
    _driverId = driverId;
    _passengerId = passengerId;

    // Fetch driver route from Firestore once
    final driverData = await _dbService.getDriverData(driverId);
    if (driverData != null) {
      _driverRoute = driverData.route;
      if (_driverRoute != null) {
        onFullRouteAcquired(_driverRoute!);
      }
    }

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
      
      _currentProgressIndex = data['index'];
      _nextStopLoc = LatLng(data['target_lat'], data['target_lng']);
      
      // Robust lookup from Firestore route
      String finalName = data['target_name'];
      if (_driverRoute != null) {
        for (var point in _driverRoute!) {
          double dist = Geolocator.distanceBetween(
            _nextStopLoc!.latitude, _nextStopLoc!.longitude,
            (point['lat'] as num).toDouble(), (point['lng'] as num).toDouble()
          );
          if (dist < 10) { // Matching coordinate
            finalName = point['name'] as String;
            break;
          }
        }
      }
      
      onNextStopChanged(finalName);
      onProgressIndexChanged(_currentProgressIndex); 
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

    // 6. Listen to Journey Status to detect end
    _journeyStatusSubscription = _dbService.getJourneyStatusStream(driverId).listen((isStarted) {
      if (_isDisposed) return;
      if (!isStarted) {
        onJourneyEnded();
      }
    });

    // 7. Start location sharing immediately
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
        onVehicleETAChanged(mins);
        onStatusChanged("Drop-off in $mins min");

        // Also check if more pickups remain even when onboarded
        final driverData = await _dbService.getDriverData(_driverId!);
        if (driverData != null) {
          _checkHasNextPickup(driverData);
        }
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
    
    // Find my pickup coords from driver route
    final driverData = await _dbService.getDriverData(_driverId!);
    if (driverData != null && driverData.route != null) {
      for (var point in driverData.route!) {
        if (point['name'] == pickupName) {
          _myPickupLoc = LatLng((point['lat'] as num).toDouble(), (point['lng'] as num).toDouble());
          onPickupLocationAcquired(_myPickupLoc!); // Notify UI
          break;
        }
      }
    }

    if (_myPickupLoc == null) return;

    // Distance vehicle to pickup
    double busDist = Geolocator.distanceBetween(
      _currentVehicleLoc!.latitude, _currentVehicleLoc!.longitude,
      _myPickupLoc!.latitude, _myPickupLoc!.longitude
    );

    // If passenger is moving, calculate their ETA to pickup
    if (_currentPassengerLoc != null) {
      onPassengerLocationChanged(_currentPassengerLoc!); // Notify UI
      
      double pDist = Geolocator.distanceBetween(
        _currentPassengerLoc!.latitude, _currentPassengerLoc!.longitude,
        _myPickupLoc!.latitude, _myPickupLoc!.longitude
      );

      if (pDist > 50) {
         _calculateWalkingPath(_currentPassengerLoc!, _myPickupLoc!); // Calculate path

        // Orange Status: Passenger moving to spot
        int pMins = (pDist / 1.4 / 60).round();
        if (pMins < 1) pMins = 1;
        onPassengerETAChanged(pMins);
        
        // Green Status: Bus moving to pickup (calculate even if passenger is moving)
        int busMins = (busDist / 11 / 60).round();
        if (busMins < 1) busMins = 1;
        onVehicleETAChanged(busMins);

        onStatusChanged("$pMins min wait"); 
        return;
      } else {
        onPassengerETAChanged(0);
        onWalkingPathChanged([]); // Clear path if close
      }
    }

    // Green Status: Bus moving to pickup
    int busMins = (busDist / 11 / 60).round();
    if (busMins < 1) busMins = 1;
    onVehicleETAChanged(busMins);

    // Calculate vehicle path to pickup
    _calculateVehiclePath(_currentVehicleLoc!, _myPickupLoc!);

    // Check if more pickups remain
    _checkHasNextPickup(driverData);

    onStatusChanged("$busMins min pickup");

    // ✅ SMART NOTIFICATION: 10 min to drop-off
    if (_isOnboarded && !_notifiedDropOff && _routeDestination != null && _currentVehicleLoc != null) {
      final double distToDest = Geolocator.distanceBetween(
        _currentVehicleLoc!.latitude, _currentVehicleLoc!.longitude,
        _routeDestination!.latitude, _routeDestination!.longitude
      );
      
      // Fast estimate (11m/s)
      final int dropOffMins = (distToDest / 11 / 60).round();
      
      if (dropOffMins <= 10 && dropOffMins > 0) {
        _notifiedDropOff = true;
        _notificationService.sendNotificationToPassengers(
          passengerIds: [_passengerId!], 
          title: "Almost There!", 
          body: "You are 10 minutes away from your destination. Tap here to settle your payment.",
          data: {'screen': 'payment'}
        );
      }
    }
  }

  void _checkHasNextPickup(DriverModel? driverData) {
    if (driverData == null || driverData.route == null || _isDisposed || _nextStopLoc == null) return;
    
    final route = driverData.route!;
    
    // 1. Find our current stop index in the route
    int currentStopIndexInRoute = -1;
    for (int i = 0; i < route.length; i++) {
       double dist = Geolocator.distanceBetween(
         _nextStopLoc!.latitude, _nextStopLoc!.longitude,
         (route[i]['lat'] as num).toDouble(), (route[i]['lng'] as num).toDouble()
       );
       if (dist < 10) {
         currentStopIndexInRoute = i;
         break;
       }
    }

    // 2. Check if any stop AFTER current one is a pickup
    bool morePickups = false;
    if (currentStopIndexInRoute != -1) {
      for (int i = currentStopIndexInRoute + 1; i < route.length; i++) {
        if (route[i]['role'] == 'pickup') {
          morePickups = true;
          break;
        }
      }
    }

    onHasNextPickupChanged(morePickups);
    onRouteIndexChanged(currentStopIndexInRoute);
  }

  int _currentProgressIndex = 0;

  bool _isFetchingPath = false;
  Future<void> _calculateWalkingPath(LatLng passengerLoc, LatLng pickupLoc) async {
    if (_isFetchingPath || _placeService == null) return;

    // Throttle: only re-fetch if they moved > 20 meters
    if (_lastPathFetchPassengerPos != null && _lastPathFetchPickupPos != null) {
      double dP = Geolocator.distanceBetween(
        passengerLoc.latitude, passengerLoc.longitude,
        _lastPathFetchPassengerPos!.latitude, _lastPathFetchPassengerPos!.longitude
      );
      double dPick = Geolocator.distanceBetween(
        pickupLoc.latitude, pickupLoc.longitude,
        _lastPathFetchPickupPos!.latitude, _lastPathFetchPickupPos!.longitude
      );
      if (dP < 20 && dPick < 10) return;
    }

    _isFetchingPath = true;
    try {
      final path = await _placeService!.getDirections(passengerLoc, pickupLoc, [], mode: 'walking');
      onWalkingPathChanged(path);
      _lastPathFetchPassengerPos = passengerLoc;
      _lastPathFetchPickupPos = pickupLoc;
    } catch (e) {
      if (kDebugMode) print('TrackVehicleController: Failed to fetch walking path: $e');
    } finally {
      _isFetchingPath = false;
    }
  }

  bool _isFetchingVehiclePath = false;
  Future<void> _calculateVehiclePath(LatLng vehicleLoc, LatLng pickupLoc) async {
    if (_isFetchingVehiclePath || _placeService == null) return;

    // Throttle: only re-fetch if they moved > 50 meters
    if (_lastVehiclePathFetchVehiclePos != null && _lastVehiclePathFetchPickupPos != null) {
      double dV = Geolocator.distanceBetween(
        vehicleLoc.latitude, vehicleLoc.longitude,
        _lastVehiclePathFetchVehiclePos!.latitude, _lastVehiclePathFetchVehiclePos!.longitude
      );
      double dPick = Geolocator.distanceBetween(
        pickupLoc.latitude, pickupLoc.longitude,
        _lastVehiclePathFetchPickupPos!.latitude, _lastVehiclePathFetchPickupPos!.longitude
      );
      if (dV < 50 && dPick < 10) return;
    }

    _isFetchingVehiclePath = true;
    try {
      final path = await _placeService!.getDirections(vehicleLoc, pickupLoc, [], mode: 'driving');
      onVehiclePathChanged(path);
      _lastVehiclePathFetchVehiclePos = vehicleLoc;
      _lastVehiclePathFetchPickupPos = pickupLoc;
    } catch (e) {
      if (kDebugMode) print('TrackVehicleController: Failed to fetch vehicle path: $e');
    } finally {
      _isFetchingVehiclePath = false;
    }
  }


  void _startLocationSharing() async {
    if (_positionSubscription != null) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
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
    _journeyStatusSubscription?.cancel();
    _stopLocationSharing();
  }
}
