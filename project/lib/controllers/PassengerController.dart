import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/PassengerModel.dart';
import '../models/DriverModel.dart';
import '../services/Database.dart';

class PassengerController {
  final DatabaseService _dbService;
  final FirebaseAuth _auth;

  PassengerController({DatabaseService? dbService, FirebaseAuth? auth})
      : _dbService = dbService ?? DatabaseService(),
        _auth = auth ?? FirebaseAuth.instance;

  Future<List<PassengerModel>> getRegisteredPassengers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // 1. Get driver details to get vehiclePlate
      final DriverModel? driver = await _dbService.getDriverData(user.uid);

      if (driver == null || driver.vehiclePlate.isEmpty) {
        debugPrint("Driver not found or vehicle plate missing");
        return [];
      }

      // 2. Fetch passengers with registered == true for this vehicle
      return await _dbService.getRegisteredPassengers(driver.vehiclePlate);
    } catch (e) {
      debugPrint("Error fetching registered passengers in controller: $e");
      rethrow;
    }
  }

  Future<List<String>> getPickupLocations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final DriverModel? driver = await _dbService.getDriverData(user.uid);
      if (driver == null || driver.route == null) return [];

      return driver.route!.map((point) => point['name'] as String).toList();
    } catch (e) {
      debugPrint("Error fetching pickup locations: $e");
      return [];
    }
  }
}
