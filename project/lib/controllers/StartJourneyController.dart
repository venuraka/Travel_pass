import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/Database.dart';
import '../services/RealtimeDatabase.dart';
import '../services/PlaceService.dart';
import '../models/PassengerModel.dart';
import '../config/AppConfig.dart';

class StartJourneyController {
  final DatabaseService _dbService = DatabaseService();
  final RealtimeDatabaseService _rtDbService = RealtimeDatabaseService();
  late final PlaceService _placeService = PlaceService(AppConfig.googleMapsApiKey);
  
  static const _channel = MethodChannel('com.travelpass.app/phone');

  StreamSubscription<Position>? _positionSubscription;
  List<PassengerModel> _allPassengers = [];
  List<Map<String, dynamic>>? _driverRoute;
  int _currentPassengerIndex = 0;
  bool _isDisposed = false;
  String? _currentDriverId;
  bool _isAtFinalDestination = false;
  Timer? _autoFinishTimer;
  StreamSubscription? _pooledSubscription;

  // Real-time status for the card
  String _currentStatus = "Calculating...";
  Set<Marker> _markers = {};
  Set<Marker> _staticMarkers = {}; // Cached route markers
  Set<Polyline> _polylines = {};

  // Navigation arrow fields
  GoogleMapController? _mapController;
  double _heading = 0;
  BitmapDescriptor? _navigationArrowIcon;
  bool _isFollowingCamera = true;
  LatLng? _lastPooledPosition;

  // State
  List<PassengerModel> get passengers => _allPassengers;
  int get currentPassengerIndex => _currentPassengerIndex;
  PassengerModel? get currentPassenger => 
      (_allPassengers.isNotEmpty && _currentPassengerIndex < _allPassengers.length)
      ? _allPassengers[_currentPassengerIndex] : null;

  bool get isAtFinalDestination => _isAtFinalDestination;
  String get currentStatus => _currentStatus;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  bool get isFollowingCamera => _isFollowingCamera;

  final Function(Position) onLocationChanged;
  final Function(List<PassengerModel>) onProximityReached;

  StartJourneyController({
    required this.onLocationChanged,
    required this.onProximityReached,
  });

  /// Sets the Google Map controller for camera animations.
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    // If we already have a pooled position, center the camera immediately
    if (_lastPooledPosition != null) {
      _animateCameraToPosition(_lastPooledPosition!);
    }
  }

  /// Resumes camera following and re-centers on pooled location.
  void reCenterCamera() {
    _isFollowingCamera = true;
    if (_lastPooledPosition != null) {
      _animateCameraToPosition(_lastPooledPosition!);
    }
  }

  /// Pauses camera following (e.g., when user pans manually).
  void pauseCameraFollow() {
    _isFollowingCamera = false;
  }

  /// Resets the map's rotation and tilt to North-up and flat.
  void resetMapRotation() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _lastPooledPosition ?? const LatLng(0, 0),
          zoom: 17,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );
  }

  Future<void> init(String driverId) async {
    _currentDriverId = driverId;
    
    // 0. Create the navigation arrow icon
    await _createNavigationArrowIcon();

    // 1. Fetch driver data for route
    await _fetchDriverRoute(driverId);

    // 2. Fetch passengers for this driver
    _allPassengers = await _dbService.getPassengersByDriver(driverId);
    
    // 3. Initial markers
    _updateMarkers();
    
    // 4. Start location tracking
    await _startLocationTracking(driverId);

    // 5. Build initial polylines
    await _updatePolylines();

    // 6. Subscribe to Pooled Location for higher accuracy
    _startPooledSubscription(driverId);
  }

  /// Creates a custom blue navigation arrow icon (like Google Maps navigation).
  Future<void> _createNavigationArrowIcon() async {
    try {
      const double size = 140;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final center = ui.Offset(size / 2, size / 2);

      // Draw outer glow/shadow
      final glowPaint = ui.Paint()
        ..color = const ui.Color(0x304285F4)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
      canvas.drawCircle(center, size / 2.4, glowPaint);

      // Draw white circle background
      final whitePaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(center, size / 3.2, whitePaint);

      // Draw blue navigation arrow (chevron/triangle)
      final arrowPaint = ui.Paint()
        ..color = const ui.Color(0xFF4285F4)
        ..style = ui.PaintingStyle.fill;

      final arrow = ui.Path();
      // Top tip
      arrow.moveTo(size / 2, size / 2 - size / 4.2);
      // Bottom right
      arrow.lineTo(size / 2 + size / 5.2, size / 2 + size / 5);
      // Center notch
      arrow.lineTo(size / 2, size / 2 + size / 9);
      // Bottom left
      arrow.lineTo(size / 2 - size / 5.2, size / 2 + size / 5);
      arrow.close();

      canvas.drawPath(arrow, arrowPaint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        _navigationArrowIcon = BitmapDescriptor.bytes(
          byteData.buffer.asUint8List(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create navigation arrow icon: $e');
      }
    }
  }

  Future<void> _fetchDriverRoute(String driverId) async {
    // Perform a one-time connection and rules test
    await _rtDbService.testConnection();
    
    // Fetch driver data to get vehicle info
    final driverData = await _dbService.getDriverData(driverId);
    if (driverData != null && driverData.route != null) {
      _driverRoute = driverData.route;
      _updatePolylines(); // Refresh line when data arrives
    }
  }

  Future<void> _updatePolylines() async {
    if (_driverRoute == null || _driverRoute!.isEmpty) return;

    try {
      // Use driver's current position as starting point if available, else first route point
      LatLng origin = (_lastPooledPosition != null) 
          ? _lastPooledPosition! 
          : LatLng((_driverRoute![0]['lat'] as num).toDouble(), (_driverRoute![0]['lng'] as num).toDouble());

      LatLng destination = LatLng(
        (_driverRoute!.last['lat'] as num).toDouble(),
        (_driverRoute!.last['lng'] as num).toDouble(),
      );

      // Intermediate waypoints
      List<LatLng> waypoints = [];
      if (_driverRoute!.length > 2) {
        waypoints = _driverRoute!
            .sublist(1, _driverRoute!.length - 1)
            .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
            .toList();
      }

      final List<LatLng> roadPoints = await _placeService.getDirections(origin, destination, waypoints);

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: roadPoints,
          color: const ui.Color(0xFF4285F4), // Google Maps blue for route
          width: 6,
          geodesic: true,
        ),
      };
      
      onLocationChanged(Position(
        latitude: origin.latitude,
        longitude: origin.longitude,
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: _heading, speed: 0, speedAccuracy: 0,
        altitudeAccuracy: 0, headingAccuracy: 0,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch road directions: $e');
      }
      // Fallback to straight lines if Directions API fails
      final List<LatLng> straightPoints = _driverRoute!
          .map((p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ))
          .toList();

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: straightPoints,
          color: const ui.Color(0xFF4285F4).withOpacity(0.5),
          width: 6,
          geodesic: true,
        ),
      };
    }
  }

  void _startPooledSubscription(String driverId) {
    _pooledSubscription = _rtDbService.getPooledLocationStream(driverId).listen((data) {
      if (_isDisposed || data.isEmpty) return;

      final lat = data['lat']!;
      final lng = data['lng']!;
      final pooledLatLng = LatLng(lat, lng);

      // Store the latest pooled position
      _lastPooledPosition = pooledLatLng;

      // Add/Update the navigation arrow marker
      _updateMarkersWithPooled(pooledLatLng);

      // Animate camera to follow
      if (_isFollowingCamera) {
        _animateCameraToPosition(pooledLatLng);
      }
    });
  }

  /// Animates the camera to center on the given position with a navigation-like view.
  void _animateCameraToPosition(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 17,
          bearing: _heading,
          tilt: 45, // Tilted view like navigation mode
        ),
      ),
    );
  }

  void _updateMarkersWithPooled(LatLng pooledPosition) {
    if (_isDisposed) return;

    // Calculate bearing between previous and current pooled position for arrow rotation
    if (_lastPooledPosition != null) {
      double calculatedBearing = Geolocator.bearingBetween(
        _lastPooledPosition!.latitude,
        _lastPooledPosition!.longitude,
        pooledPosition.latitude,
        pooledPosition.longitude,
      );
      
      double distance = Geolocator.distanceBetween(
        _lastPooledPosition!.latitude,
        _lastPooledPosition!.longitude,
        pooledPosition.latitude,
        pooledPosition.longitude,
      );

      if (distance > 0.5) { // Small threshold to avoid twitching
        _heading = calculatedBearing;
      }
    }

    _lastPooledPosition = pooledPosition;
    
    // Combine static markers with the dynamic pooled location arrow
    final updatedMarkers = Set<Marker>.from(_staticMarkers);
    
    updatedMarkers.add(
      Marker(
        markerId: const MarkerId('pooled_location'),
        position: pooledPosition,
        icon: _navigationArrowIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: _heading,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 100,
      ),
    );

    _markers = updatedMarkers;
    
    // Notify UI
    onLocationChanged(Position(
      latitude: pooledPosition.latitude,
      longitude: pooledPosition.longitude,
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, heading: _heading, speed: 0, speedAccuracy: 0,
      altitudeAccuracy: 0, headingAccuracy: 0,
    ));

    // Follow camera if enabled
    if (_isFollowingCamera) {
      _animateCameraToPosition(pooledPosition);
    }
  }

  Future<void> _updateMarkers() async {
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
    _staticMarkers = newMarkers;
    
    // If we already have a pooled location, merge it too
    if (_lastPooledPosition != null) {
      _updateMarkersWithPooled(_lastPooledPosition!);
    } else {
      _markers = _staticMarkers;
    }
  }

  Future<void> _startLocationTracking(String driverId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (kDebugMode) {
        print('Geolocator: Location service is NOT enabled');
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('Geolocator: Permission denied');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) {
        print('Geolocator: Permission denied forever');
      }
      return;
    }

    // Get an initial position immediately (one-shot) and write to RTDB
    // This ensures data gets to RTDB even if the stream below fails
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _heading = initialPosition.heading;
      _rtDbService.updateDriverLocation(driverId, initialPosition.latitude, initialPosition.longitude);
      onLocationChanged(initialPosition);
      if (kDebugMode) {
        print('Geolocator: Initial position acquired: ${initialPosition.latitude}, ${initialPosition.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Geolocator: Failed to get initial position: $e');
      }
    }

    // Now start continuous tracking
    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: false, // Use FusedLocationProvider (more reliable)
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Travel Pass is tracking your location to inform passengers.",
          notificationTitle: "Journey in Progress",
          enableWakeLock: false, // Avoid SecurityException on some devices
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    if (kDebugMode) {
      print('Geolocator: Starting continuous location stream for driver: $driverId');
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_isDisposed) return;

      // Capture heading for the navigation arrow rotation
      _heading = position.heading;
      
      onLocationChanged(position);
      
      // Update RTDB
      _rtDbService.updateDriverLocation(driverId, position.latitude, position.longitude);
      
      // Check proximity and update status
      _checkProximity(position);

      if (kDebugMode) {
        print('Geolocator: Position update -> ${position.latitude}, ${position.longitude}');
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('Geolocator: Stream error: $error');
      }
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

  Future<void> markAsAbsent(String passengerId) async {
    if (_currentDriverId != null) {
      // 1. Update RTDB status
      await _rtDbService.setOnboarded(_currentDriverId!, passengerId, false);
      
      // 2. Update Firestore Attendance record to 'Absent'
      await _dbService.updateAttendance(
        passengerId, 
        _currentDriverId!, 
        DateTime.now(), 
        'Absent'
      );
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
    _pooledSubscription?.cancel(); // Cancel pooled too
    _autoFinishTimer?.cancel();
  }
}
