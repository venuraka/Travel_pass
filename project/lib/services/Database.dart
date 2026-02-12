// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/DriverModel.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveDriverData(DriverModel driver) async {
    try {
      await _db.collection('driver').doc(driver.uid).set(driver.toMap());
    } catch (e) {
      print("Error saving driver: $e");
      rethrow;
    }
  }
}
