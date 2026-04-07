import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isAtFinalDestination = false;
  Timer? _autoFinishTimer; // Added for auto-termination

  // Real-time status for the card
  String _currentStatus = "Calculating...";
  Set<Marker> _markers = {};


  // State
  List<PassengerModel> get passengers => _allPassengers;
  int get currentPassengerIndex => _currentPassengerIndex;
  PassengerModel? get currentPassenger => 
      (_allPassengers.isNotEmpty && _currentPassengerIndex < _allPassengers.length)
      ? _allPassengers[_currentPassengerIndex] : null;

  bool get isAtFinalDestination => _isAtFinalDestination;
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
    
    // 3. Initial markers
    _updateMarkers();
    
    // 4. Start location tracking
    await _startLocationTracking(driverId);
  }

  Future<void> _fetchDriverRoute(String driverId) async {
    final driverData = await _dbService.getDriverData(driverId);
    if (driverData != null && driverData.route != null) {
      _driverRoute = driverData.route;
    }
  }

  void _updateMarkers() async {
    final Set<Marker> newMarkers = {};
    if (_currentDriverId == null) return;

    final driverData = await _dbService.getDriverData(_currentDriverId!);
    if (driverData == null || driverData.route == null) return;

    for (var point in driverData.route!) {
      final role = point['role'] ?? 'pickup';
      final color = role == 'pickup' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed;
      
      newMarkers.add(
        Marker(
          markerId: MarkerId(point['name'] as String),
          position: LatLng(
            (point['lat'] as num).toDouble(),
            (point['lng'] as num).toDouble(),
          ),
          infoWindow: InfoWindow(title: point['name'] as String),
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
        ),
      );
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
        distanceFilter: 5,
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
    
    // 1. If currently picking up passengers
    if (targetPassenger != null && _currentDriverId != null) {
      await _checkPassengerProximity(position, targetPassenger);
    } 
    // 2. If all passengers are picked up, or no passengers exist, check for final destination
    else if (_currentDriverId != null && _driverRoute != null && _driverRoute!.isNotEmpty) {
      await _checkDestinationProximity(position);
    }
  }

  Future<void> _checkPassengerProximity(Position position, PassengerModel targetPassenger) async {
    LatLng? targetLatLng;
    for (var point in _driverRoute!) {
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

    double distance = Geolocator.distanceBetween(
      position.latitude, position.longitude,
      targetLatLng.latitude, targetLatLng.longitude
    );

    if (distance < 50) {
      _currentStatus = "On Location";
      List<PassengerModel> proximalPassengers = [];
      for (var passenger in _allPassengers) {
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
      int mins = (distance / 11 / 60).round();
      if (mins < 1) mins = 1;
      _currentStatus = "$mins min to pickup";
    }
  }

  Future<void> _checkDestinationProximity(Position position) async {
    // Find the LAST destination in the route
    Map<String, dynamic>? finalDest;
    for (var i = _driverRoute!.length - 1; i >= 0; i--) {
      if (_driverRoute![i]['role'] == 'destination') {
        finalDest = _driverRoute![i];
        break;
      }
    }

    if (finalDest == null) {
      _isAtFinalDestination = true; // Fallback if no destination defined
      _currentStatus = "Trip Complete";
      return;
    }

    LatLng targetLatLng = LatLng(
      (finalDest['lat'] as num).toDouble(),
      (finalDest['lng'] as num).toDouble(),
    );

    double distance = Geolocator.distanceBetween(
      position.latitude, position.longitude,
      targetLatLng.latitude, targetLatLng.longitude
    );

    if (distance < 50) {
      if (!_isAtFinalDestination) {
        _isAtFinalDestination = true;
        _startAutoFinishTimer(); // Trigger auto-finish
      }
      _currentStatus = "At Destination";
    } else {
      _isAtFinalDestination = false;
      _autoFinishTimer?.cancel(); // Cancel if they move away before it finishes
      int mins = (distance / 11 / 60).round();
      if (mins < 1) mins = 1;
      _currentStatus = "$mins min to final destination";
    }
  }

  void _startAutoFinishTimer() {
    _autoFinishTimer?.cancel();
    _autoFinishTimer = Timer(const Duration(minutes: 2), () {
      if (!_isDisposed && _isAtFinalDestination) {
        debugPrint("Auto-finishing journey after destination wait...");
        finishJourney();
      }
    });
  }


  Future<void> makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> markOnboarded(String passengerId, bool onboarded) async {
    if (_currentDriverId != null) {
      await _rtDbService.setOnboarded(_currentDriverId!, passengerId, onboarded);
    }
  }

  void nextPassenger() {
    if (_currentPassengerIndex < _allPassengers.length) {
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

  Future<void> finishJourney() async {
    _autoFinishTimer?.cancel(); // Cancel any pending auto-finish
    if (_currentDriverId != null) {
      await _dbService.updateJourneyStatus(_currentDriverId!, false);
      // Optional: Cleanup RTDB locations on finish
      await _rtDbService.updateDriverLocation(_currentDriverId!, 0, 0); 
      dispose();
    }
  }

  void dispose() {
    _isDisposed = true;
    _positionSubscription?.cancel();
    _autoFinishTimer?.cancel();
  }
}



