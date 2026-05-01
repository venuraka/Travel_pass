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

  /// Returns a stream of a specific passenger's location.
  /// Returns a stream of a specific passenger's location.
  Stream<Map<String, double>> getPassengerLocationStream(String driverId, String passengerId) {
    if (driverId.isEmpty || passengerId.isEmpty) return Stream.value({});
    return _db.ref('locations/$driverId/passengers/$passengerId').onValue.map((event) {
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

  /// Updates the final destination of the route for synchronization.
  Future<void> updateRouteDestination(String driverId, double lat, double lng, String name) async {
    if (driverId.isEmpty) return;
    try {
      await _db.ref('status/$driverId/destination').set({
        'lat': lat,
        'lng': lng,
        'name': name,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      if (kDebugMode) print('RTDB: Failed to update destination: $e');
    }
  }

  /// Returns a stream of the route's final destination.
  Stream<Map<String, dynamic>> getRouteDestinationStream(String driverId) {
    if (driverId.isEmpty) return Stream.value({});
    return _db.ref('status/$driverId/destination').onValue.map((event) {
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

  /// Updates the current journey target (next stop).
  Future<void> updateJourneyProgress(String driverId, int index, String targetName, double targetLat, double targetLng) async {
    if (driverId.isEmpty) return;
    try {
      await _db.ref('status/$driverId/progress').set({
        'index': index,
        'target_name': targetName,
        'target_lat': targetLat,
        'target_lng': targetLng,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      if (kDebugMode) print('RTDB: Failed to update progress: $e');
    }
  }

  /// Returns a stream of the journey's current progress.
  Stream<Map<String, dynamic>> getJourneyProgressStream(String driverId) {
    if (driverId.isEmpty) return Stream.value({});
    return _db.ref('status/$driverId/progress').onValue.map((event) {
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

  /// Returns a stream of the set of onboarded passenger IDs for a driver.
  Stream<Set<String>> getOnboardedPassengerIdsStream(String driverId) {
    if (driverId.isEmpty) return Stream.value({});
    return _db.ref('status/$driverId/passengers').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      
      Set<String> ids = {};
      data.forEach((key, value) {
        final pStatus = value as Map<dynamic, dynamic>?;
        if (pStatus != null && pStatus['onboarded'] == true) {
          ids.add(key.toString());
        }
      });
      return ids;
    });
  }
}

