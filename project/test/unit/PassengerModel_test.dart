import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/PassengerModel.dart';

void main() {
  group('PassengerModel Tests', () {
    final mockTimestamp = Timestamp.fromDate(DateTime(2026, 5, 14));

    test('should construct correctly and parse default values', () {
      final passenger = PassengerModel(
        uid: 'pass123',
        name: 'Venuraka',
        vehiclePlate: 'WP AAA 1234',
        driverId: 'driver99',
        address: '123 Main St',
        email: 'test@email.com',
        phone: '0771234567',
        otherPhone: '0777654321',
        paymentType: 'monthly',
        pickupLocation: 'City Square',
        createdAt: mockTimestamp,
      );

      expect(passenger.uid, 'pass123');
      expect(passenger.role, 'passenger'); // Default value assertion
      expect(passenger.registered, false); // Default value assertion
      expect(passenger.balance, 0.0); // Default value assertion
    });

    test('toMap() returns expected map structure', () {
      final passenger = PassengerModel(
        uid: 'p456',
        name: 'Nuwan',
        vehiclePlate: 'WP CAR 4321',
        driverId: 'driver101',
        address: 'Colombo Rd',
        email: 'nuwan@email.com',
        phone: '0712223333',
        otherPhone: '',
        paymentType: 'daily',
        pickupLocation: 'Galle Face',
        createdAt: mockTimestamp,
        balance: 150.50,
        lastChargedMonth: '2026-05',
      );

      final map = passenger.toMap();

      expect(map['uid'], 'p456');
      expect(map['name'], 'Nuwan');
      expect(map['balance'], 150.50);
      expect(map['lastChargedMonth'], '2026-05');
      expect(map['role'], 'passenger');
    });

    test('fromMap() should recreate PassengerModel accurately', () {
      final data = {
        'uid': 'p789',
        'name': 'Kusal',
        'vehiclePlate': 'WP XYZ 9999',
        'driverId': 'driver77',
        'address': 'Highlevel Rd',
        'email': 'kusal@email.com',
        'phone': '0756665555',
        'otherPhone': 'none',
        'paymentType': 'free',
        'pickupLocation': 'Nugegoda',
        'role': 'vip',
        'registered': true,
        'createdAt': mockTimestamp,
        'balance': 50.0,
        'lastChargedMonth': '2026-04',
      };

      final model = PassengerModel.fromMap(data);

      expect(model.uid, 'p789');
      expect(model.name, 'Kusal');
      expect(model.role, 'vip');
      expect(model.registered, true);
      expect(model.balance, 50.0);
    });
  });
}
