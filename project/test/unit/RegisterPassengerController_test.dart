import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project/controllers/RegisterPassengerController.dart';
import 'package:project/services/Database.dart';
import 'package:project/services/NotificationService.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockNotificationService extends Mock implements PushNotificationService {}
class MockBuildContext extends Mock implements BuildContext {
  @override
  bool get mounted => false; // Skip scaffold messenger logic
}

class FakePassengerModel extends Fake implements PassengerModel {}

void main() {
  late MockDatabaseService mockDb;
  late MockNotificationService mockNotification;
  late MockBuildContext mockContext;
  late RegisterPassengerController controller;

  setUpAll(() {
    registerFallbackValue(FakePassengerModel());
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockNotification = MockNotificationService();
    mockContext = MockBuildContext();
    controller = RegisterPassengerController(
      dbService: mockDb,
      notificationService: mockNotification,
    );
  });

  group('RegisterPassengerController Tests', () {
    final tPassenger = PassengerModel(
      uid: 'p_123', name: 'Old Name', phone: '111', otherPhone: '', email: '',
      pickupLocation: 'Old Place', paymentType: 'Daily', driverId: 'd_123',
      vehiclePlate: 'WP 1234', address: '', createdAt: Timestamp.now(),
      paymentAmount: '100',
    );

    test('registerPassenger saves updated model and notifies passenger', () async {
      when(() => mockDb.savePassengerData(any())).thenAnswer((_) async {});
      when(() => mockNotification.sendNotificationToPassengers(
            passengerIds: any(named: 'passengerIds'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => true);

      await controller.registerPassenger(
        passenger: tPassenger,
        name: 'New Name',
        paymentAmount: '3000',
        phone: '222',
        paymentType: 'Monthly',
        pickupLocation: 'New Place',
        context: mockContext,
      );

      verify(() => mockDb.savePassengerData(any())).called(1);
      verify(() => mockNotification.sendNotificationToPassengers(
            passengerIds: ['p_123'],
            title: 'Registration Approved 🎉',
            body: any(named: 'body'),
            data: any(named: 'data'),
          )).called(1);
    });

    test('updatePassenger detects changes and notifies passenger', () async {
      when(() => mockDb.savePassengerData(any())).thenAnswer((_) async {});
      when(() => mockNotification.sendNotificationToPassengers(
            passengerIds: any(named: 'passengerIds'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => true);

      // Call update changing phone and pickup
      await controller.updatePassenger(
        passenger: tPassenger,
        name: 'Old Name',
        paymentAmount: '100',
        phone: '222', // Changed
        paymentType: 'Daily',
        pickupLocation: 'New Place', // Changed
        context: mockContext,
      );

      verify(() => mockDb.savePassengerData(any())).called(1);
      verify(() => mockNotification.sendNotificationToPassengers(
            passengerIds: ['p_123'],
            title: 'Profile Updated 📝',
            body: any(named: 'body', that: contains('phone number')),
            data: any(named: 'data'),
          )).called(1);
    });

    test('updatePassenger does not send notification if critical details are unchanged', () async {
      when(() => mockDb.savePassengerData(any())).thenAnswer((_) async {});

      // Call update without changing critical tracking fields
      await controller.updatePassenger(
        passenger: tPassenger,
        name: 'Just A Name Change',
        paymentAmount: '100',
        phone: '111',
        paymentType: 'Daily',
        pickupLocation: 'Old Place',
        context: mockContext,
      );

      verify(() => mockDb.savePassengerData(any())).called(1);
      // Verify notification was NOT sent
      verifyNever(() => mockNotification.sendNotificationToPassengers(
            passengerIds: any(named: 'passengerIds'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ));
    });
  });
}
