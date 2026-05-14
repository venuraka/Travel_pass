import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/controllers/PassengerController.dart';
import 'package:project/services/Database.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:project/models/DriverModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockDatabaseService mockDb;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late PassengerController controller;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    controller = PassengerController(dbService: mockDb, auth: mockAuth);
  });

  group('PassengerController Tests', () {
    const tDriverId = 'driver_abc';
    const tPlate = 'WP CAB 1234';

    final tDriver = DriverModel(
      uid: tDriverId, name: 'Kamal', email: 'k@test.com',
      phone: '', vehiclePlate: tPlate,
      vehicleType: 'Bus', vehicleModel: 'Ashok',
      isVerified: true,
    );

    final tPassenger = PassengerModel(
      uid: 'p1', name: 'Nimal', vehiclePlate: tPlate, driverId: tDriverId,
      address: '', email: '', phone: '', otherPhone: '',
      paymentType: 'Monthly', pickupLocation: 'Fort',
      createdAt: Timestamp.now(),
    );

    test('getRegisteredPassengers fetches by driver vehicle plate', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);
      when(() => mockDb.getDriverData(tDriverId)).thenAnswer((_) async => tDriver);
      when(() => mockDb.getRegisteredPassengers(tPlate)).thenAnswer((_) async => [tPassenger]);

      final result = await controller.getRegisteredPassengers();

      expect(result.length, 1);
      expect(result.first.vehiclePlate, tPlate);
      verify(() => mockDb.getRegisteredPassengers(tPlate)).called(1);
    });

    test('getRegisteredPassengers returns empty if driver not found', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);
      when(() => mockDb.getDriverData(tDriverId)).thenAnswer((_) async => null);

      final result = await controller.getRegisteredPassengers();

      expect(result, isEmpty);
    });

    test('getPickupLocations extracts all route name strings', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);

      final driverWithRoute = DriverModel(
        uid: tDriverId, name: 'Kamal', email: 'k@test.com',
        phone: '', vehiclePlate: tPlate,
        vehicleType: 'Bus', vehicleModel: 'Ashok',
        isVerified: true,
        route: [
          {'name': 'Colombo Fort', 'lat': 6.93, 'lng': 79.85},
          {'name': 'Maradana', 'lat': 6.92, 'lng': 79.86},
        ],
      );

      when(() => mockDb.getDriverData(tDriverId)).thenAnswer((_) async => driverWithRoute);

      final locations = await controller.getPickupLocations();

      expect(locations.length, 2);
      expect(locations.first, 'Colombo Fort');
      expect(locations.last, 'Maradana');
    });
  });
}
