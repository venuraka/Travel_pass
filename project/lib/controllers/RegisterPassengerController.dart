import 'package:flutter/material.dart';
import '../models/PassengerModel.dart';
import '../services/Database.dart';
import '../services/NotificationService.dart';

class RegisterPassengerController {
  final DatabaseService _dbService = DatabaseService();
  final PushNotificationService _notificationService = PushNotificationService();

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

      // Notify Passenger that they have been approved/registered
      try {
        await _notificationService.sendNotificationToPassengers(
          passengerIds: [updatedPassenger.uid],
          title: 'Registration Approved 🎉',
          body: 'You have been registered by your driver. You can use the app from now on.',
          data: {
            'type': 'registration_approved',
          },
        );
      } catch (e) {
        debugPrint('⚠️ Could not notify passenger of registration approval: $e');
      }

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

  Future<void> updatePassenger({
    required PassengerModel passenger,
    required String name,
    required String paymentAmount,
    required String phone,
    required String paymentType,
    required String pickupLocation,
    required BuildContext context,
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
        paymentType: paymentType,
        pickupLocation: pickupLocation,
        role: passenger.role,
        registered: true,
        createdAt: passenger.createdAt,
        paymentAmount: paymentAmount,
      );

      // Save to database
      await _dbService.savePassengerData(updatedPassenger);

      // Notify Passenger if critical details changed
      List<String> changes = [];
      if (passenger.paymentAmount != paymentAmount) changes.add('fare (Rs $paymentAmount)');
      if (passenger.phone != phone) changes.add('phone number');
      if (passenger.pickupLocation != pickupLocation) changes.add('pickup location ($pickupLocation)');

      if (changes.isNotEmpty) {
        try {
          String body = 'Your driver has updated your ${changes.join(', ')}.';
          await _notificationService.sendNotificationToPassengers(
            passengerIds: [updatedPassenger.uid],
            title: 'Profile Updated 📝',
            body: body,
            data: {
              'type': 'profile_update',
              'updatedFields': changes.join(','),
            },
          );
        } catch (e) {
          debugPrint('⚠️ Could not notify passenger of profile update: $e');
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passenger updated successfully!'),
            backgroundColor: Color(0xFF05A664),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating passenger: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating passenger: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
}
