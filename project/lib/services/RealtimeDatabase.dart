import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Updates the driver's location in the realtime database.
  Future<void> updateDriverLocation(String driverId, double lat, double lng) async {
    try {
      await _db.ref('locations/$driverId/driver').set({
        'lat': lat,
        'lng': lng,
        'timestamp': ServerValue.timestamp,
      });
      
      // Also update the pool
      await _updatePooledLocation(driverId);
    } catch (e) {
      debugPrint("Error updating driver location: $e");
    }
  }

  /// Updates a passenger's location in the realtime database if they are onboard.
  Future<void> updatePassengerLocation(String driverId, String passengerId, double lat, double lng) async {
    try {
      await _db.ref('locations/$driverId/passengers/$passengerId').set({
        'lat': lat,
        'lng': lng,
        'timestamp': ServerValue.timestamp,
      });
      
      // Also update the pool
      await _updatePooledLocation(driverId);
    } catch (e) {
      debugPrint("Error updating passenger location: $e");
    }
  }

  /// Sets whether a passenger is onboarded.
  Future<void> setOnboarded(String driverId, String passengerId, bool onboarded) async {
    try {
      await _db.ref('status/$driverId/passengers/$passengerId/onboarded').set(onboarded);
    } catch (e) {
      debugPrint("Error setting onboarded status: $e");
    }
  }

  /// Returns a stream of whether a passenger is onboarded.
  Stream<bool> getOnboardedStream(String driverId, String passengerId) {
    return _db.ref('status/$driverId/passengers/$passengerId/onboarded').onValue.map((event) {
      return (event.snapshot.value as bool?) ?? false;
    });
  }

  /// Calculates and updates the pooled location based on all active locations.
  Future<void> _updatePooledLocation(String driverId) async {
    try {
      final snapshot = await _db.ref('locations/$driverId').get();
      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      double totalLat = 0;
      double totalLng = 0;
      int count = 0;

      // Extract driver location
      if (data.containsKey('driver')) {
        final driverLoc = data['driver'] as Map<dynamic, dynamic>;
        totalLat += (driverLoc['lat'] as num).toDouble();
        totalLng += (driverLoc['lng'] as num).toDouble();
        count++;
      }

      // Extract passenger locations
      if (data.containsKey('passengers')) {
        final passengers = data['passengers'] as Map<dynamic, dynamic>;
        passengers.forEach((key, value) {
          final pLoc = value as Map<dynamic, dynamic>;
          totalLat += (pLoc['lat'] as num).toDouble();
          totalLng += (pLoc['lng'] as num).toDouble();
          count++;
        });
      }

      if (count > 0) {
        final pooledLat = totalLat / count;
        final pooledLng = totalLng / count;

        await _db.ref('locations/$driverId/pooled').set({
          'lat': pooledLat,
          'lng': pooledLng,
          'accuracy_weight': count,
          'timestamp': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint("Error updating pooled location: $e");
    }
  }

  /// Returns a stream of the pooled location for a specific driver.
  Stream<Map<String, double>> getPooledLocationStream(String driverId) {
    return _db.ref('locations/$driverId/pooled').onValue.map((event) {
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
}
