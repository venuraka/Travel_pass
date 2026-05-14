import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:project/controllers/UpdatesController.dart';
import 'package:project/services/Database.dart';
import 'package:project/services/NotificationService.dart';
import 'package:project/models/UpdateModel.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockPushNotificationService extends Mock implements PushNotificationService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUuid extends Mock implements Uuid {}
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late MockDatabaseService mockDb;
  late MockPushNotificationService mockNotify;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockUuid mockUuid;
  late MockBuildContext mockContext;
  late UpdatesController controller;

  setUpAll(() {
    // Register standard fallback values for custom data classes passed into mocks
    registerFallbackValue(
      UpdateModel(id: '', driverId: '', content: '', timestamp: DateTime.now())
    );
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockNotify = MockPushNotificationService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockUuid = MockUuid();
    mockContext = MockBuildContext();

    controller = UpdatesController(
      dbService: mockDb,
      notificationService: mockNotify,
      auth: mockAuth,
      uuid: mockUuid,
    );
  });

  group('UpdatesController Tests', () {
    const tDriverId = 'driver_777';

    test('getUpdates returns empty stream if user is logged out', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      final resultStream = controller.getUpdates();

      expect(resultStream, emits([]));
    });

    test('getUpdates calls database service for current driver UID', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);
      when(() => mockDb.getUpdates(tDriverId)).thenAnswer((_) => Stream.value([]));

      final _ = controller.getUpdates();

      verify(() => mockDb.getUpdates(tDriverId)).called(1);
    });

    test('sendUpdate saves to database and fires push notification successfully', () async {
      const tUpdateId = 'uuid-1111-2222';
      const tContent = 'Important broadcast: Delay on main route';

      // Setup mocks
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);
      when(() => mockUuid.v4()).thenReturn(tUpdateId);

      // Mock asynchronous responses
      when(() => mockDb.saveUpdate(any())).thenAnswer((_) async => {});
      when(() => mockNotify.sendPushNotification(
        driverId: any(named: 'driverId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      )).thenAnswer((_) async => {});

      // Run the action
      await controller.sendUpdate(tContent, mockContext);

      // Assert DB write occurred with EXACT properties
      verify(() => mockDb.saveUpdate(any(
        that: predicate((dynamic update) {
          return update is UpdateModel &&
              update.id == tUpdateId &&
              update.driverId == tDriverId &&
              update.content == tContent &&
              update.role == 'admin';
        }),
      ))).called(1);

      // Assert Push Notification was dispatched to current driver route
      verify(() => mockNotify.sendPushNotification(
        driverId: tDriverId,
        title: 'New Update from Driver',
        body: tContent,
        data: {"type": "update", "screen": "updates", "driverId": tDriverId},
      )).called(1);
    });
  });
}
