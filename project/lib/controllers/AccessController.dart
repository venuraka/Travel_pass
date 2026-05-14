import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AccessController {
  final FirebaseFirestore _db;

  AccessController({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  /// Checks if a passenger is registered.
  /// Returns true if registered, false otherwise.
  Future<bool> checkPassengerStatus(String uid) async {
    try {
      final doc = await _db.collection('passenger').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['registered'] == true;
      }
      return false; // User not found or not registered
    } catch (e) {
      debugPrint("Error checking passenger status: $e");
      return false; // Assume not registered on error to be safe
    }
  }

  /// Checks if a user is a driver.
  Future<bool> isDriver(String uid) async {
    try {
      final doc = await _db.collection('driver').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint("Error checking driver status: $e");
      return false;
    }
  }

  /// Checks if a driver is approved by admin.
  Future<bool> isDriverApproved(String uid) async {
    try {
      final doc = await _db.collection('driver').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['isVerified'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking driver approval status: $e");
      return false;
    }
  }
}
