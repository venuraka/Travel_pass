import 'package:firebase_database/firebase_database.dart';
import '../models/PassengerModel.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _db;

  RealtimeDatabaseService({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  /// Updates the driver's current location in the Realtime Database.
  Future<void> updateDriverLocation(String driverId, double lat, double lng) async {
    if (driverId.isEmpty) return;
    await _db.ref('status/$driverId/location').set({
      'lat': lat,
      'lng': lng,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Sets the onboarded status for a specific passenger under a driver.
  Future<void> setOnboarded(String driverId, String passengerId, bool status) async {
    if (driverId.isEmpty || passengerId.isEmpty) return;
    await _db.ref('status/$driverId/passengers/$passengerId').set({
      'onboarded': status,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Updates the current target/next stop info for sharing with passengers.
  Future<void> updateNextStop(String driverId, int index, String targetName, double targetLat, double targetLng) async {
    if (driverId.isEmpty) return;
    await _db.ref('status/$driverId/next_stop').set({
      'index': index,
      'target_name': targetName,
      'target_lat': targetLat,
      'target_lng': targetLng,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Updates journey progress (alias for updateNextStop used by controllers)
  Future<void> updateJourneyProgress(String driverId, int index, String targetName, double targetLat, double targetLng) async {
    await updateNextStop(driverId, index, targetName, targetLat, targetLng);
  }

  /// Updates the final destination of the route in the Realtime Database.
  Future<void> updateRouteDestination(String driverId, double lat, double lng, String name) async {
    if (driverId.isEmpty) return;
    await _db.ref('status/$driverId/route_destination').set({
      'lat': lat,
      'lng': lng,
      'name': name,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Returns a stream of the driver's current location.
  Stream<Map<String, double>> getDriverLocationStream(String driverId) {
    if (driverId.isEmpty) return Stream.value({});
    return _db.ref('status/$driverId/location').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return {
          'lat': (data['lat'] as num).toDouble(),
          'lng': (data['lng'] as num).toDouble(),
        };
      }
      return {};
    });
  }

  /// Returns a stream of the driver's pooled location (high accuracy).
  Stream<Map<String, double>> getPooledLocationStream(String driverId) {
    return getDriverLocationStream(driverId);
  }

  /// Returns a stream of the driver's current target/next stop info.
  Stream<Map<String, dynamic>> getNextStopStream(String driverId) {
    if (driverId.isEmpty) return Stream.value({});
    return _db.ref('status/$driverId/next_stop').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return {
          'index': (data['index'] as num).toInt(),
          'target_name': data['target_name'] as String,
          'target_lat': (data['target_lat'] as num).toDouble(),
          'target_lng': (data['target_lng'] as num).toDouble(),
        };
      }
      return {};
    });
  }

  /// Returns a stream of journey progress (alias for getNextStopStream)
  Stream<Map<String, dynamic>> getJourneyProgressStream(String driverId) {
    return getNextStopStream(driverId);
  }

  /// Returns a stream of the final route destination.
  Stream<Map<String, dynamic>> getRouteDestinationStream(String driverId) {
    if (driverId.isEmpty) return Stream.value({});
    return _db.ref('status/$driverId/route_destination').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return {
          'lat': (data['lat'] as num).toDouble(),
          'lng': (data['lng'] as num).toDouble(),
          'name': data['name'] as String,
        };
      }
      return {};
    });
  }

  /// Returns a stream of the total count of onboarded passengers for a driver.
  Stream<int> getOnboardedCountStream(String driverId) {
    if (driverId.isEmpty) return Stream.value(0);
    return _db.ref('status/$driverId/passengers').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return 0;
      
      int count = 0;
      data.forEach((key, value) {
        final pStatus = value as Map<dynamic, dynamic>;
        if (pStatus['onboarded'] == true) {
          count++;
        }
      });
      return count;
    });
  }

  /// Returns a stream of the total count of 'handled' passengers (onboarded OR absent) for a driver.
  Stream<int> getHandledCountStream(String driverId) {
    if (driverId.isEmpty) return Stream.value(0);
    return _db.ref('status/$driverId/passengers').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return 0;
      return data.length; // Number of keys in the passengers map
    });
  }

  /// Returns a stream of the set of handled passenger IDs for a driver.
  Stream<Set<String>> getOnboardedPassengerIdsStream(String driverId) {
    if (driverId.isEmpty) return Stream.value({});
    return _db.ref('status/$driverId/passengers').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      
      Set<String> ids = {};
      data.forEach((key, value) {
        ids.add(key.toString());
      });
      return ids;
    });
  }

  /// Returns a one-time fetch of the set of handled passenger IDs for a driver.
  Future<Set<String>> getOnboardedPassengerIds(String driverId) async {
    if (driverId.isEmpty) return {};
    final snapshot = await _db.ref('status/$driverId/passengers').get();
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return {};
    
    Set<String> ids = {};
    data.forEach((key, value) {
      ids.add(key.toString());
    });
    return ids;
  }

  /// Returns a stream of the onboarding status for a specific passenger.
  Stream<bool> getOnboardedStream(String driverId, String passengerId) {
    if (driverId.isEmpty || passengerId.isEmpty) return Stream.value(false);
    return _db.ref('status/$driverId/passengers/$passengerId/onboarded').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Returns a stream of a passenger's shared location.
  Stream<Map<String, double>> getPassengerLocationStream(String driverId, String passengerId) {
    if (driverId.isEmpty || passengerId.isEmpty) return Stream.value({});
    return _db.ref('status/$driverId/passenger_locations/$passengerId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        return {
          'lat': (data['lat'] as num).toDouble(),
          'lng': (data['lng'] as num).toDouble(),
        };
      }
      return {};
    });
  }

  /// Updates a passenger's shared location in RTDB.
  Future<void> updatePassengerLocation(String driverId, String passengerId, double lat, double lng) async {
    if (driverId.isEmpty || passengerId.isEmpty) return;
    await _db.ref('status/$driverId/passenger_locations/$passengerId').set({
      'lat': lat,
      'lng': lng,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Clears all onboarded/handled passenger state for a driver.
  Future<void> clearOnboardedPassengers(String driverId) async {
    if (driverId.isEmpty) return;
    await _db.ref('status/$driverId/passengers').remove();
    await _db.ref('status/$driverId/passenger_locations').remove();
  }

  /// Dummy method for testing connection (restored for compatibility)
  Future<void> testConnection() async {
    return;
  }
}
