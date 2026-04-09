import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerModel {
  final String uid;
  final String name;
  final String vehiclePlate;
  final String driverId;
  final String address;
  final String email;
  final String phone;
  final String otherPhone;
  final String paymentType;
  final String pickupLocation;
  final String role;
  final bool registered;
  final Timestamp createdAt;
  final String paymentAmount; // Added field
  final String? fcmToken; // Added for push notifications

  PassengerModel({
    required this.uid,
    required this.name,
    required this.vehiclePlate,
    required this.driverId,
    required this.address,
    required this.email,
    required this.phone,
    required this.otherPhone,
    required this.paymentType,
    required this.pickupLocation,
    this.role = 'passenger',
    this.registered = false,
    required this.createdAt,
    this.paymentAmount = '', // Default empty
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'vehiclePlate': vehiclePlate,
      'driverId': driverId,
      'address': address,
      'email': email,
      'phone': phone,
      'otherPhone': otherPhone,
      'paymentType': paymentType,
      'pickupLocation': pickupLocation,
      'role': role,
      'registered': registered,
      'createdAt': createdAt,
      'paymentAmount': paymentAmount, // Added
      'fcmToken': fcmToken,
    };
  }

  factory PassengerModel.fromMap(Map<String, dynamic> map) {
    return PassengerModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      vehiclePlate: map['vehiclePlate'] ?? '',
      driverId: map['driverId'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      otherPhone: map['otherPhone'] ?? '',
      paymentType: map['paymentType'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      role: map['role'] ?? 'passenger',
      registered: map['registered'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      paymentAmount: map['paymentAmount'] ?? '', // Added
      fcmToken: map['fcmToken'],
    );
  }
}
