import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/controllers/PassengerEditDetailsController.dart';
import 'package:project/services/Database.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockDatabaseService mockDb;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late PassengerEditDetailsController controller;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    controller = PassengerEditDetailsController(dbService: mockDb, auth: mockAuth);
  });

  group('PassengerEditDetailsController Tests', () {
    const tUserId = 'user123';
    final tPassenger = PassengerModel(
      uid: tUserId,
      name: 'John Doe',
      phone: '0712345678',
      otherPhone: '',
      email: 'john@test.com',
      pickupLocation: 'Colombo',
      paymentType: 'Monthly',
      driverId: 'driver123',
      vehiclePlate: 'WP 1234',
      address: '123 Main St',
      createdAt: Timestamp.now(),
    );

    test('loadPassengerDetails returns passenger model if user is logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tUserId);
      when(() => mockDb.getPassengerData(tUserId)).thenAnswer((_) async => tPassenger);

      final result = await controller.loadPassengerDetails();

      expect(result, isNotNull);
      expect(result?.name, 'John Doe');
      expect(result?.phone, '0712345678');
      verify(() => mockDb.getPassengerData(tUserId)).called(1);
    });

    test('loadPassengerDetails returns null if user is not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await controller.loadPassengerDetails();

      expect(result, isNull);
      verifyNever(() => mockDb.getPassengerData(any()));
    });

    test('updateDetails succeeds when fields are valid', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tUserId);
      when(() => mockDb.updatePassengerDetails(
            uid: tUserId,
            phone: '0777123456',
            pickupLocation: 'Kandy',
          )).thenAnswer((_) async => {});

      final result = await controller.updateDetails('0777123456', 'Kandy');

      expect(result, {'success': true});
      verify(() => mockDb.updatePassengerDetails(
            uid: tUserId,
            phone: '0777123456',
            pickupLocation: 'Kandy',
          )).called(1);
    });

    test('updateDetails returns error if fields are empty', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result = await controller.updateDetails('', '');

      expect(result, {'error': 'Please fill all fields'});
      verifyNever(() => mockDb.updatePassengerDetails(
            uid: any(named: 'uid'),
            phone: any(named: 'phone'),
            pickupLocation: any(named: 'pickupLocation'),
          ));
    });

    test('updateDetails returns error if user is not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await controller.updateDetails('0777123456', 'Kandy');

      expect(result, {'error': 'User not logged in'});
    });
  });
}
