// lib/services/database_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/DriverModel.dart';
import '../models/PassengerModel.dart';
import '../models/PollModel.dart';
import '../models/UpdateModel.dart';
import '../models/AttendanceModel.dart'; // Added // Added
import '../models/RedemptionModel.dart'; // New Import

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

  /// Fetches a list of matching vehicle plates for autocomplete.
  Future<List<String>> searchVehiclePlates(String query) async {
    try {
      final querySnapshot = await _db.collection('driver').get();
      final loweredQuery = query.toLowerCase();
      
      final results = querySnapshot.docs
          .map((doc) => doc.data()['vehiclePlate'] as String? ?? '')
          .where((plate) => plate.toLowerCase().contains(loweredQuery))
          .take(10)
          .toList();
          
      return results;
    } catch (e) {
      debugPrint("Error searching vehicle plates: $e");
      return [];
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
          route: (data['route'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList(),
          isJourneyStarted: data['isJourneyStarted'] ?? false,
          balance: (data['balance'] ?? 0.0).toDouble(),
          badgePreference: data['badgePreference'] ?? 'Both',
          monthlyPaymentAmount: data['monthlyPaymentAmount'],
          dailyPaymentAmount: data['dailyPaymentAmount'],
          paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
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

  /// Fetches passengers where registered == false for a specific vehicle plate.
  Future<List<PassengerModel>> getUnregisteredPassengers(
    String vehiclePlate,
  ) async {
    try {
      final querySnapshot = await _db
          .collection('passenger')
          .where('vehiclePlate', isEqualTo: vehiclePlate)
          .where('registered', isEqualTo: false)
          .get();

      return querySnapshot.docs
          .map((doc) => PassengerModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches passengers where registered == true for a specific vehicle plate.
  Future<List<PassengerModel>> getRegisteredPassengers(
    String vehiclePlate,
  ) async {
    try {
      final querySnapshot = await _db
          .collection('passenger')
          .where('vehiclePlate', isEqualTo: vehiclePlate)
          .where('registered', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PassengerModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint("Error fetching registered passengers: $e");
      rethrow;
    }
  }

  /// Fetches all passengers assigned to a specific driver.
  Future<List<PassengerModel>> getPassengersByDriver(String driverId) async {
    try {
      final querySnapshot = await _db
          .collection('passenger')
          .where('driverId', isEqualTo: driverId)
          .get();

      return querySnapshot.docs
          .map((doc) => PassengerModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint("Error fetching passengers by driver: $e");
      rethrow;
    }
  }

  // --- Updates Methods ---

  /// Saves a new update/announcement to Firestore.
  Future<void> saveUpdate(UpdateModel update) async {
    try {
      await _db.collection('updates').doc(update.id).set(update.toMap());
    } catch (e) {
      debugPrint("Error saving update: $e");
      rethrow;
    }
  }

  /// Streams updates for a specific driver, ordered by timestamp descending.
  Stream<List<UpdateModel>> getUpdates(String driverId) {
    return _db
        .collection('updates')
        .where('driverId', isEqualTo: driverId)
        // .orderBy('timestamp', descending: true) // Removed to avoid Index requirement
        .snapshots()
        .map((snapshot) {
          debugPrint(
            "Fetched ${snapshot.docs.length} updates for driver: $driverId",
          );
          final updates = snapshot.docs
              .map((doc) => UpdateModel.fromMap(doc.data(), doc.id))
              .toList();

          // Sort client-side
          updates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return updates;
        });
  }

  // --- Settings Methods ---

  Future<void> updateDriverSettings(
    String uid,
    DateTime? paymentDate,
    String? monthlyAmount,
    String? dailyAmount,
    String? badgePreference,
  ) async {
    try {
      await _db.collection('driver').doc(uid).update({
        if (paymentDate != null) 'paymentDate': Timestamp.fromDate(paymentDate),
        if (monthlyAmount != null) 'monthlyPaymentAmount': monthlyAmount,
        if (dailyAmount != null) 'dailyPaymentAmount': dailyAmount,
        if (badgePreference != null) 'badgePreference': badgePreference,
      });
    } catch (e) {
      debugPrint("Error updating driver settings: $e");
      rethrow;
    }
  }

  Future<void> adjustPassengerPaymentAmounts(
    String driverId,
    int delta,
    String paymentType,
  ) async {
    try {
      final querySnapshot = await _db
          .collection('passenger')
          .where('driverId', isEqualTo: driverId)
          .where('paymentType', isEqualTo: paymentType)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final currentStr = data['paymentAmount'] as String? ?? '0';
        final currentVal = int.tryParse(currentStr) ?? 0;
        final newVal = currentVal + delta;

        batch.update(doc.reference, {'paymentAmount': newVal.toString()});
      }

      await batch.commit();
      debugPrint(
        "Adjusted payment amount by $delta for ${querySnapshot.docs.length} $paymentType passengers.",
      );
    } catch (e) {
      debugPrint("Error batch adjusting $paymentType passengers: $e");
      rethrow;
    }
  }

  // --- Attendance Methods ---

  /// Updates the attendance record for a passenger for a specific date.
  /// Uses a single document per passenger (doc ID = passengerId).
  Future<void> updateAttendance(
    String passengerId,
    String driverId,
    DateTime date,
    String status,
  ) async {
    try {
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final docRef = _db.collection('attendance').doc(passengerId);

      // Use set with merge to create if not exists, or update if exists
      // We update the specific key in the 'records' map
      await docRef.set({
        'id': passengerId,
        'driverId': driverId,
        'lastUpdated': Timestamp.now(),
        // Map syntax for updating a specific key in a nested map field (dot notation)
        // Note: In standard set(merge: true), dot notation for keys works if the parent exists.
        // However, safely we can just merge the map.
        'records': {dateKey: status},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating attendance: $e");
      rethrow;
    }
  }

  /// Removes the attendance record for a passenger for a specific date (Undo).
  Future<void> removeAttendanceRecord(
    String passengerId,
    DateTime date,
  ) async {
    try {
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final docRef = _db.collection('attendance').doc(passengerId);
      await docRef.update({
        'records.$dateKey': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint("Error removing attendance: $e");
    }
  }

  /// Fetches the single attendance document for a passenger.
  Future<AttendanceModel?> getPassengerAttendance(String passengerId) async {
    try {
      final doc = await _db.collection('attendance').doc(passengerId).get();
      if (doc.exists && doc.data() != null) {
        return AttendanceModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
      rethrow;
    }
  }

  /// Updates passenger phone and pickup location.
  Future<void> updatePassengerDetails({
    required String uid,
    required String phone,
    required String pickupLocation,
  }) async {
    try {
      await _db.collection('passenger').doc(uid).update({
        'phone': phone,
        'pickupLocation': pickupLocation,
      });
    } catch (e) {
      debugPrint("Error updating passenger details: $e");
      rethrow;
    }
  }

  /// Updates the journey starting status for a driver.
  Future<void> updateJourneyStatus(String driverId, bool isStarted) async {
    try {
      await _db.collection('driver').doc(driverId).update({
        'isJourneyStarted': isStarted,
      });
    } catch (e) {
      debugPrint("Error updating journey status: $e");
      rethrow;
    }
  }

  /// Returns a stream of the journey status for a specific driver.
  Stream<bool> getJourneyStatusStream(String driverId) {
    return _db.collection('driver').doc(driverId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data()!['isJourneyStarted'] ?? false;
      }
      return false;
    });
  }

  /// Returns a stream of whether there is an active poll for today for a driver.
  Stream<bool> getTodayPollStatusStream(String driverId) {
    return _db.collection('polls')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final today = DateTime.utc(now.year, now.month, now.day);

      for (var doc in snapshot.docs) {
        final poll = PollModel.fromMap(doc.data(), doc.id);
        if (poll.activeDates.any((d) =>
        d.year == today.year &&
            d.month == today.month &&
            d.day == today.day)) {
          return true;
        }
      }
      return false;
    });
  }

  /// Returns the attendance status for a passenger for today.
  Future<String> getTodayAttendanceStatus(String passengerId) async {
    try {
      final doc = await _db.collection('attendance').doc(passengerId).get();
      if (doc.exists && doc.data() != null) {
        final records = doc.data()!['records'] as Map<String, dynamic>? ?? {};
        final now = DateTime.now();
        final dateKey =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        return records[dateKey] ?? 'Not Marked';
      }
      return 'Not Marked';
    } catch (e) {
      debugPrint("Error fetching today's attendance status: $e");
      return 'Error';
    }
  }

  /// Returns a stream of the count of passengers marked 'Present' for today for a specific driver.
  Stream<int> getTodayPassengerCountStream(String driverId) {
    return _db.collection('attendance')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final dateKey =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      int count = 0;
      for (var doc in snapshot.docs) {
        final records = doc.data()['records'] as Map<String, dynamic>? ?? {};
        if (records[dateKey] == 'Present') {
          count++;
        }
      }
      return count;
    });
  }

  /// Returns a stream of the newest updates for a specific driver.
  Stream<List<UpdateModel>> getUpdatesStream(String driverId) {
    return _db.collection('updates')
        .where('driverId', isEqualTo: driverId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UpdateModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Returns a stream of the count of pending passengers for a specific driver.
  Stream<int> getPendingPassengersCountStream(String driverId) {
    return _db.collection('passenger')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Returns a stream of polls created by a driver.
  Stream<List<PollModel>> getPollsByDriverStream(String driverId) {
    return _db.collection('polls')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PollModel.fromMap(doc.data(), doc.id)).toList());
  }

  /// Returns a stream of an attendance document.
  Stream<AttendanceModel?> getPassengerAttendanceStream(String passengerId) {
    return _db.collection('attendance').doc(passengerId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AttendanceModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Returns a stream of a driver's balance.
  Stream<double> getDriverBalanceStream(String driverId) {
    return _db.collection('driver').doc(driverId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['balance'] ?? 0.0).toDouble();
      }
      return 0.0;
    });
  }

  /// Returns a stream of redemption history for a driver.
  Stream<List<RedemptionModel>> getRedemptionsStream(String driverId) {
    return _db
        .collection('redemptions')
        .where('driverId', isEqualTo: driverId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RedemptionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Creates a payment request in a new collection.
  Future<void> requestPayment(String driverId, double amount) async {
    try {
      await _db.collection('paymentRequests').add({
        'driverId': driverId,
        'amount': amount,
        'requestedAt': Timestamp.now(),
        'status': 'Pending',
      });
    } catch (e) {
      debugPrint("Error requesting payment: $e");
      rethrow;
    }
  }
}
