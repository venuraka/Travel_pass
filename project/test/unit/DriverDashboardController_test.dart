import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/controllers/DriverDashboardController.dart';
import 'package:project/services/Database.dart';
import 'package:project/services/WeatherService.dart';
import 'package:project/services/NotificationService.dart';
import 'package:project/services/RealtimeDatabase.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:project/models/PollModel.dart';
import 'package:project/models/AttendanceModel.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockWeatherService extends Mock implements WeatherService {}
class MockPushNotificationService extends Mock implements PushNotificationService {}
class MockRealtimeDatabaseService extends Mock implements RealtimeDatabaseService {}

void main() {
  late MockDatabaseService mockDb;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockWeatherService mockWeather;
  late MockPushNotificationService mockNotify;
  late MockRealtimeDatabaseService mockRtDb;
  late DriverDashboardController controller;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockWeather = MockWeatherService();
    mockNotify = MockPushNotificationService();
    mockRtDb = MockRealtimeDatabaseService();

    controller = DriverDashboardController(
      dbService: mockDb,
      auth: mockAuth,
      weatherService: mockWeather,
      notificationService: mockNotify,
      rtDbService: mockRtDb,
    );
  });

  group('DriverDashboardController Tests', () {
    const tDriverId = 'driver_dash_001';

    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    test('getDriverId returns current user UID', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);

      expect(controller.getDriverId(), tDriverId);
    });

    test('getDriverId returns null when not logged in', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(controller.getDriverId(), isNull);
    });

    test('getTodayPassengerCount returns 0 when no active poll today', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);
      when(() => mockDb.getPollsByDriver(tDriverId)).thenAnswer((_) async => []);

      final count = await controller.getTodayPassengerCount();

      expect(count, 0);
    });

    test('getTodayPassengerCount counts only Present passengers', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);

      final activePoll = PollModel(
        id: 'p1', driverId: tDriverId, vehiclePlate: 'WP XYZ 1111',
        activeDates: [DateTime(today.year, today.month, today.day)],
        createdAt: Timestamp.now(),
      );

      PassengerModel makeP(String uid) => PassengerModel(
        uid: uid, name: uid, vehiclePlate: 'WP XYZ 1111', driverId: tDriverId,
        address: '', email: '', phone: '', otherPhone: '', paymentType: 'Daily',
        pickupLocation: 'Fort', createdAt: Timestamp.now(),
      );

      when(() => mockDb.getPollsByDriver(tDriverId)).thenAnswer((_) async => [activePoll]);
      when(() => mockDb.getPassengersByDriver(tDriverId)).thenAnswer((_) async => [makeP('p1'), makeP('p2')]);

      when(() => mockDb.getPassengerAttendance('p1')).thenAnswer((_) async =>
        AttendanceModel(id: 'p1', driverId: tDriverId, records: {todayKey: 'Present'}, lastUpdated: Timestamp.now()));
      when(() => mockDb.getPassengerAttendance('p2')).thenAnswer((_) async =>
        AttendanceModel(id: 'p2', driverId: tDriverId, records: {todayKey: 'Absent'}, lastUpdated: Timestamp.now()));

      final count = await controller.getTodayPassengerCount();

      expect(count, 1); // Only p1 is Present
    });

    test('hasActivePollToday returns false when user is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await controller.hasActivePollToday();

      expect(result, false);
    });

    test('hasActivePollToday returns true when a poll date matches today', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);

      final poll = PollModel(
        id: 'p1', driverId: tDriverId, vehiclePlate: 'WP XYZ 1111',
        activeDates: [DateTime(today.year, today.month, today.day)],
        createdAt: Timestamp.now(),
      );

      when(() => mockDb.getPollsByDriver(tDriverId)).thenAnswer((_) async => [poll]);

      final result = await controller.hasActivePollToday();

      expect(result, true);
    });

    test('getTodayPassengerCountStream returns empty stream when user is null', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      final stream = controller.getTodayPassengerCountStream();

      expect(stream, emits(0));
    });
  });
}
