import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/Database.dart';
import '../models/PassengerModel.dart';

class PassengerEditDetailsController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<PassengerModel?> loadPassengerDetails() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('passenger')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return PassengerModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("Error loading passenger details: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> updateDetails(
    String phone,
    String pickupLocation,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'error': 'User not logged in'};

      if (phone.isEmpty || pickupLocation.isEmpty) {
        return {'error': 'Please fill all fields'};
      }

      await _dbService.updatePassengerDetails(
        uid: user.uid,
        phone: phone,
        pickupLocation: pickupLocation,
      );

      return {'success': true};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
