import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/controllers/TodayPassengersController.dart';
import 'package:project/services/Database.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:project/models/PollModel.dart';
import 'package:project/models/AttendanceModel.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockDatabaseService mockDb;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late TodayPassengersController controller;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    controller = TodayPassengersController(dbService: mockDb, auth: mockAuth);
  });

  group('TodayPassengersController Tests', () {
    const tDriverId = 'driver_today';

    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final activePoll = PollModel(
      id: 'poll1', driverId: tDriverId, vehiclePlate: 'WP XXX 9999',
      activeDates: [DateTime(today.year, today.month, today.day)],
      createdAt: Timestamp.now(),
    );

    PassengerModel makePassenger(String uid) => PassengerModel(
      uid: uid, name: uid, vehiclePlate: 'WP XXX 9999', driverId: tDriverId,
      address: '', email: '', phone: '', otherPhone: '', paymentType: 'Daily',
      pickupLocation: 'Fort', createdAt: Timestamp.now(),
    );

    test('returns noPoll:true when no active poll exists today', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);
      when(() => mockDb.getPollsByDriver(tDriverId)).thenAnswer((_) async => []);

      final result = await controller.loadTodayData();

      expect(result['noPoll'], true);
    });

    test('returns error map when user is not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await controller.loadTodayData();

      expect(result['error'], 'Driver not logged in');
    });

    test('correctly groups Present/Absent/notVoted passengers', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);
      when(() => mockDb.getPollsByDriver(tDriverId)).thenAnswer((_) async => [activePoll]);
      when(() => mockDb.getPassengersByDriver(tDriverId)).thenAnswer((_) async => [
        makePassenger('p_present'),
        makePassenger('p_absent'),
        makePassenger('p_pending'),
      ]);

      when(() => mockDb.getPassengerAttendance('p_present')).thenAnswer((_) async =>
        AttendanceModel(id: 'p_present', driverId: tDriverId, records: {todayKey: 'Present'}, lastUpdated: Timestamp.now()));
      when(() => mockDb.getPassengerAttendance('p_absent')).thenAnswer((_) async =>
        AttendanceModel(id: 'p_absent', driverId: tDriverId, records: {todayKey: 'Absent'}, lastUpdated: Timestamp.now()));
      when(() => mockDb.getPassengerAttendance('p_pending')).thenAnswer((_) async => null);

      final result = await controller.loadTodayData();

      expect((result['boarded'] as List).length, 1);
      expect((result['absent'] as List).length, 1);
      expect((result['notVoted'] as List).length, 1);
    });

    test('markAttendance maps Boarded to Present in DB call', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);
      when(() => mockDb.updateAttendance(any(), any(), any(), any())).thenAnswer((_) async => {});

      await controller.markAttendance('p1', 'Boarded');

      verify(() => mockDb.updateAttendance('p1', tDriverId, any(), 'Present')).called(1);
    });
  });
}
