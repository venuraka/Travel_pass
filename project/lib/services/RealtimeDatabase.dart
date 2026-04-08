import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class RealtimeDatabaseService {
  // Must use instanceFor with explicit URL — this RTDB is in asia-southeast1, not the default US region
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://travelpass-40736-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  /// Performs a one-time connection test to the database.
  Future<void> testConnection() async {
    try {
      // A simple read to the root or a 'status' node to check connectivity
      await _db.ref('.info/connected').get();
    } catch (e) {
      if (kDebugMode) {
        print('RTDB Connection Test Failed: $e');
      }
    }
  }

  /// Updates the driver's location in the realtime database.
  Future<void> updateDriverLocation(String driverId, double lat, double lng) async {
    if (driverId.isEmpty) return;
    try {
      final ref = _db.ref('locations/$driverId/driver');
      
      // Use set() with a completion handler for more native error info
      await ref.set({
        'lat': lat,
        'lng': lng,
        'timestamp': ServerValue.timestamp,
      });
      
      // Also update the pool
      await _updatePooledLocation(driverId);
      if (kDebugMode) {
        print('RTDB: Driver location updated for $driverId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RTDB: Failed to update driver location: $e');
      }
    }
  }


  /// Updates a passenger's location in the realtime database if they are onboard.
  Future<void> updatePassengerLocation(String driverId, String passengerId, double lat, double lng) async {
    if (driverId.isEmpty || passengerId.isEmpty) return;
    try {
      await _db.ref('locations/$driverId/passengers/$passengerId').set({
        'lat': lat,
        'lng': lng,
        'timestamp': ServerValue.timestamp,
      });
      
      // Also update the pool
      await _updatePooledLocation(driverId);
    } catch (e) {
      if (kDebugMode) {
        print('RTDB: Failed to update passenger location: $e');
      }
    }
  }

  /// Sets whether a passenger is onboarded.
  Future<void> setOnboarded(String driverId, String passengerId, bool onboarded) async {
    if (driverId.isEmpty || passengerId.isEmpty) return;
    try {
      await _db.ref('status/$driverId/passengers/$passengerId/onboarded').set(onboarded);
      // If removed from onboarding, cleanup their location from the pool
      if (!onboarded) {
        await _db.ref('locations/$driverId/passengers/$passengerId').remove();
        await _updatePooledLocation(driverId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('RTDB: Failed to set onboarded status: $e');
      }
    }
  }

  /// Returns a stream of whether a passenger is onboarded.
  Stream<bool> getOnboardedStream(String driverId, String passengerId) {
    if (driverId.isEmpty || passengerId.isEmpty) return Stream.value(false);
    return _db.ref('status/$driverId/passengers/$passengerId/onboarded').onValue.map((event) {
      return (event.snapshot.value as bool?) ?? false;
    });
  }

  /// Calculates and updates the pooled location based on all active locations.
  /// Uses a mean/weighted average of the driver and all onboarded passengers.
  Future<void> _updatePooledLocation(String driverId) async {
    try {
      final snapshot = await _db.ref('locations/$driverId').get();
      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      double totalLat = 0;
      double totalLng = 0;
      int count = 0;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      const int staleThreshold = 60000; // 60 seconds

      // 1. Extract and Validate Driver Location
      if (data.containsKey('driver')) {
        final driverLoc = data['driver'] as Map<dynamic, dynamic>;
        final ts = (driverLoc['timestamp'] as num?)?.toInt() ?? 0;
        
        // Only include if not stale or if it's the only point
        if (now - ts < staleThreshold) {
          totalLat += (driverLoc['lat'] as num).toDouble();
          totalLng += (driverLoc['lng'] as num).toDouble();
          count++;
        }
      }

      // 2. Extract and Validate Onboarded Passenger Locations
      if (data.containsKey('passengers')) {
        final passengers = data['passengers'] as Map<dynamic, dynamic>;
        passengers.forEach((key, value) {
          final pLoc = value as Map<dynamic, dynamic>;
          final ts = (pLoc['timestamp'] as num?)?.toInt() ?? 0;
          
          if (now - ts < staleThreshold) {
            totalLat += (pLoc['lat'] as num).toDouble();
            totalLng += (pLoc['lng'] as num).toDouble();
            count++;
          }
        });
      }

      // 3. Update the Pooled Node
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
      if (kDebugMode) {
        print('RTDB: Failed to update pooled location: $e');
      }
    }
  }

  /// Returns a stream of the pooled location for a specific driver.
  Stream<Map<String, double>> getPooledLocationStream(String driverId) {
    if (driverId.isEmpty) return Stream.value({});
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

