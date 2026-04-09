import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String uid;
  final String name;
  final String vehiclePlate;
  final String phone;
  final String email;
  final String? vehicleModel;
  final int? seatCount;
  final String? vehicleType;
  final List<Map<String, dynamic>>? route;
  final DateTime? paymentDate;
  final String? monthlyPaymentAmount;
  final String? dailyPaymentAmount;
  final bool isJourneyStarted;
  final double balance;
  final String badgePreference; // Added: 'Daily', 'Monthly', or 'Both'
  final String? fcmToken; // Added for push notifications

  DriverModel({
    required this.uid,
    required this.name,
    required this.vehiclePlate,
    required this.phone,
    required this.email,
    this.vehicleModel,
    this.seatCount,
    this.vehicleType,
    this.route,
    this.paymentDate,
    this.monthlyPaymentAmount,
    this.dailyPaymentAmount,
    this.isJourneyStarted = false,
    this.balance = 0.0,
    this.badgePreference = 'Both', // Default to 'Both'
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'vehiclePlate': vehiclePlate,
      'phone': phone,
      'email': email,
      'vehicleModel': vehicleModel,
      'seatCount': seatCount,
      'vehicleType': vehicleType,
      'role': 'driver',
      'route': route,
      'paymentDate': paymentDate != null
          ? Timestamp.fromDate(paymentDate!)
          : null,
      'monthlyPaymentAmount': monthlyPaymentAmount,
      'dailyPaymentAmount': dailyPaymentAmount,
      'isJourneyStarted': isJourneyStarted,
      'balance': balance,
      'badgePreference': badgePreference,
      'fcmToken': fcmToken,
    };
  }
}
