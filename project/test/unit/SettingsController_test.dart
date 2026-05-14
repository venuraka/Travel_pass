import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/controllers/SettingsController.dart';
import 'package:project/services/Database.dart';
import 'package:project/services/NotificationService.dart';
import 'package:project/models/DriverModel.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockNotificationService extends Mock implements PushNotificationService {}
class MockUser extends Mock implements User {}

void main() {
  late MockDatabaseService mockDb;
  late MockFirebaseAuth mockAuth;
  late MockNotificationService mockNotification;
  late MockUser mockUser;
  late SettingsController controller;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAuth = MockFirebaseAuth();
    mockNotification = MockNotificationService();
    mockUser = MockUser();
    controller = SettingsController(
      dbService: mockDb,
      auth: mockAuth,
      notificationService: mockNotification,
    );
  });

  group('SettingsController Tests', () {
    const tUserId = 'driver123';
    
    final tDriverOld = DriverModel(
      uid: tUserId, name: 'Saman', email: '', phone: '', vehiclePlate: '',
      monthlyPaymentAmount: '3000',
      dailyPaymentAmount: '100',
      badgePreference: 'Both',
    );

    final tDriverNew = DriverModel(
      uid: tUserId, name: 'Saman', email: '', phone: '', vehiclePlate: '',
      monthlyPaymentAmount: '3500',
      dailyPaymentAmount: '120',
      badgePreference: 'Both',
    );

    final tMonthlyPassenger = PassengerModel(
      uid: 'p_monthly', name: 'Nimal', phone: '', otherPhone: '', email: '',
      pickupLocation: '', paymentType: 'Monthly', driverId: tUserId,
      vehiclePlate: '', address: '', createdAt: Timestamp.now(),
    );

    final tDailyPassenger = PassengerModel(
      uid: 'p_daily', name: 'Kamal', phone: '', otherPhone: '', email: '',
      pickupLocation: '', paymentType: 'Daily', driverId: tUserId,
      vehiclePlate: '', address: '', createdAt: Timestamp.now(),
    );

    test('getSettings fetches from database', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tUserId);
      when(() => mockDb.getDriverData(tUserId)).thenAnswer((_) async => tDriverOld);

      final result = await controller.getSettings();
      expect(result?.monthlyPaymentAmount, '3000');
    });

    test('saveSettings updates amounts and notifies passengers when delta != 0', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tUserId);
      when(() => mockDb.getDriverData(tUserId)).thenAnswer((_) async => tDriverOld);
      
      when(() => mockDb.updateDriverSettings(tUserId, null, '3500', '120', 'Both'))
          .thenAnswer((_) async => {});

      when(() => mockDb.adjustPassengerPaymentAmounts(tUserId, 500, 'Monthly'))
          .thenAnswer((_) async => {});
          
      when(() => mockDb.adjustPassengerPaymentAmounts(tUserId, 20, 'Daily'))
          .thenAnswer((_) async => {});

      when(() => mockDb.getPassengersByDriver(tUserId))
          .thenAnswer((_) async => [tMonthlyPassenger, tDailyPassenger]);

      when(() => mockNotification.sendNotificationToPassengers(
            passengerIds: any(named: 'passengerIds'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => true);

      await controller.saveSettings(
        paymentDate: null,
        monthlyAmount: '3500',
        dailyAmount: '120',
        badgePreference: 'Both',
      );

      verify(() => mockDb.updateDriverSettings(tUserId, null, '3500', '120', 'Both')).called(1);
      verify(() => mockDb.adjustPassengerPaymentAmounts(tUserId, 500, 'Monthly')).called(1);
      verify(() => mockDb.adjustPassengerPaymentAmounts(tUserId, 20, 'Daily')).called(1);
      
      // Should send 2 notification batches: 1 for monthly, 1 for daily
      verify(() => mockNotification.sendNotificationToPassengers(
            passengerIds: ['p_monthly'],
            title: 'Monthly Fare Updated 💳',
            body: any(named: 'body'),
            data: any(named: 'data'),
          )).called(1);
          
      verify(() => mockNotification.sendNotificationToPassengers(
            passengerIds: ['p_daily'],
            title: 'Daily Fare Updated 💳',
            body: any(named: 'body'),
            data: any(named: 'data'),
          )).called(1);
    });

    test('saveSettings only updates driver doc if delta == 0', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tUserId);
      when(() => mockDb.getDriverData(tUserId)).thenAnswer((_) async => tDriverOld);
      
      when(() => mockDb.updateDriverSettings(tUserId, null, '3000', '100', 'Both'))
          .thenAnswer((_) async => {});

      await controller.saveSettings(
        paymentDate: null,
        monthlyAmount: '3000',
        dailyAmount: '100',
        badgePreference: 'Both',
      );

      verify(() => mockDb.updateDriverSettings(tUserId, null, '3000', '100', 'Both')).called(1);
      
      verifyNever(() => mockDb.adjustPassengerPaymentAmounts(any(), any(), any()));
      verifyNever(() => mockNotification.sendNotificationToPassengers(
          passengerIds: any(named: 'passengerIds'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
      ));
    });
  });
}
