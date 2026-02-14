import 'package:flutter/material.dart';
import '../models/PassengerModel.dart';
import '../services/Database.dart';

class RegisterPassengerController {
  final DatabaseService _dbService = DatabaseService();

  Future<void> registerPassenger({
    required PassengerModel passenger,
    required String name,
    required String paymentAmount,
    required String phone,
    required String paymentType,
    required String pickupLocation,
    required BuildContext context, // For SnackBar
  }) async {
    try {
      // Create updated passenger model
      PassengerModel updatedPassenger = PassengerModel(
        uid: passenger.uid,
        name: name,
        vehiclePlate: passenger.vehiclePlate,
        driverId: passenger.driverId,
        address: passenger.address,
        email: passenger.email,
        phone: phone,
        otherPhone: passenger.otherPhone,
        paymentType: paymentType, // Can be daily/monthly from UI
        pickupLocation: pickupLocation,
        role: passenger.role,
        registered: true, // Mark as registered
        createdAt: passenger.createdAt,
        paymentAmount: paymentAmount, // Save payment amount
      );

      // Save to database
      await _dbService.savePassengerData(updatedPassenger);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passenger registered successfully!'),
            backgroundColor: Color(0xFF05A664),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error registering passenger: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering passenger: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
}
