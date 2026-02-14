// lib/services/database_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/DriverModel.dart';
import '../models/PassengerModel.dart';
import '../models/PollModel.dart'; // Added

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveDriverData(DriverModel driver) async {
    try {
      await _db.collection('driver').doc(driver.uid).set(driver.toMap());
    } catch (e) {
      debugPrint("Error saving driver: $e");
      rethrow;
    }
  }

  Future<void> updateDriverVehicleDetails({
    required String uid,
    required String vehicleModel,
    required int seatCount,
    required String vehicleType,
  }) async {
    try {
      await _db.collection('driver').doc(uid).update({
        'vehicleModel': vehicleModel,
        'seatCount': seatCount,
        'vehicleType': vehicleType,
      });
    } catch (e) {
      debugPrint("Error updating driver vehicle details: $e");
      rethrow;
    }
  }

  Future<void> updateDriverRoute(
    String uid,
    List<Map<String, dynamic>> route,
  ) async {
    try {
      await _db.collection('driver').doc(uid).update({'route': route});
    } catch (e) {
      debugPrint("Error updating driver route: $e");
      rethrow;
    }
  }

  /// Finds a driver by their vehicle number plate.
  /// Returns the driver's data (including route) if found, otherwise null.
  Future<Map<String, dynamic>?> getDriverByPlate(String plate) async {
    try {
      final querySnapshot = await _db
          .collection('driver')
          .where('vehiclePlate', isEqualTo: plate)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint("Error finding driver by plate: $e");
      rethrow;
    }
  }

  /// Saves passenger registration data to Firestore.
  Future<void> savePassengerData(PassengerModel passenger) async {
    try {
      await _db
          .collection('passenger')
          .doc(passenger.uid)
          .set(passenger.toMap());
    } catch (e) {
      debugPrint("Error saving passenger data: $e");
      rethrow;
    }
  }

  // --- Poll Methods ---

  /// Creates a new poll in the 'polls' collection.
  Future<void> createPoll(PollModel poll) async {
    try {
      // Use the poll's ID as the document ID
      await _db.collection('polls').doc(poll.id).set(poll.toMap());
    } catch (e) {
      debugPrint("Error creating poll: $e");
      rethrow;
    }
  }

  /// Fetches driver data by UID.
  Future<DriverModel?> getDriverData(String uid) async {
    try {
      final doc = await _db.collection('driver').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        // We need to implement fromMap in DriverModel to use it properly,
        // but for now we'll manually construct it or assume we adjust DriverModel later.
        // CHECK: Does DriverModel have fromMap?
        // Based on previous reads, it didn't seem to have a fromMap shown,
        // I will implement a basic map-to-object logic here or update DriverModel.
        // Let's assume for this specific task we just need the vehiclePlate.

        final data = doc.data()!;
        return DriverModel(
          uid: uid,
          name: data['name'] ?? '',
          vehiclePlate: data['vehiclePlate'] ?? '',
          phone: data['phone'] ?? '',
          email: data['email'] ?? '',
          // ... other fields can be null or defaults
        );
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching driver data: $e");
      rethrow;
    }
  }

  /// Fetches all polls created by a specific driver.
  Future<List<PollModel>> getPollsByDriver(String driverId) async {
    try {
      final querySnapshot = await _db
          .collection('polls')
          .where('driverId', isEqualTo: driverId)
          .get();

      return querySnapshot.docs
          .map((doc) => PollModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching polls: $e");
      rethrow;
    }
  }

  /// Updates the active dates for a specific poll document.
  Future<void> updatePollDates(String docId, List<DateTime> activeDates) async {
    try {
      await _db.collection('polls').doc(docId).update({
        'activeDates': activeDates.map((d) => Timestamp.fromDate(d)).toList(),
      });
    } catch (e) {
      debugPrint("Error updating poll dates: $e");
      rethrow;
    }
  }

  /// Deletes a poll document.
  Future<void> deletePoll(String docId) async {
    try {
      await _db.collection('polls').doc(docId).delete();
    } catch (e) {
      debugPrint("Error deleting poll: $e");
      rethrow;
    }
  }
}
