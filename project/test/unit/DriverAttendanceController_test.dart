import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/controllers/DriverAttendanceController.dart';
import 'package:project/services/Database.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:project/models/AttendanceModel.dart';
import 'package:project/models/PollModel.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockDatabaseService mockDb;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late DriverAttendanceController controller;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    controller = DriverAttendanceController(dbService: mockDb, auth: mockAuth);
  });

  group('DriverAttendanceController Tests', () {
    const tDriverId = 'driver_456';
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final todayKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    test('returns error map if user is not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await controller.loadAttendanceData(null);

      expect(result, isMap);
      expect(result['error'], 'Driver not logged in');
    });

    test('processes, sorts, groups dates, and segments passengers into correct states', () async {
      // 1. Setup Current User
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tDriverId);

      // 2. Setup Mock Polls for date detection
      final poll = PollModel(
        id: 'poll_abc',
        driverId: tDriverId,
        vehiclePlate: 'WP CAT 9876',
        activeDates: [
          today.subtract(const Duration(days: 2)), // Past Date
          today,                                   // Today (Target)
          today.add(const Duration(days: 2)),      // Future Date
        ],
        createdAt: Timestamp.now(),
      );
      when(() => mockDb.getPollsByDriver(tDriverId))
          .thenAnswer((_) async => [poll]);

      // 3. Setup Mock Passengers
      final passBoarded = PassengerModel(
        uid: 'p_present', name: 'Kamal', vehiclePlate: 'WP CAT 9876', driverId: tDriverId,
        address: '', email: '', phone: '', otherPhone: '', paymentType: '', pickupLocation: '',
        createdAt: Timestamp.now(),
      );
      final passAbsent = PassengerModel(
        uid: 'p_absent', name: 'Nimal', vehiclePlate: 'WP CAT 9876', driverId: tDriverId,
        address: '', email: '', phone: '', otherPhone: '', paymentType: '', pickupLocation: '',
        createdAt: Timestamp.now(),
      );
      final passPending = PassengerModel(
        uid: 'p_pending', name: 'Sunil', vehiclePlate: 'WP CAT 9876', driverId: tDriverId,
        address: '', email: '', phone: '', otherPhone: '', paymentType: '', pickupLocation: '',
        createdAt: Timestamp.now(),
      );

      when(() => mockDb.getPassengersByDriver(tDriverId))
          .thenAnswer((_) async => [passBoarded, passAbsent, passPending]);

      // 4. Setup Mock Attendances
      // Boarded: Has attendance record with today marked 'Present'
      final attendPresent = AttendanceModel(
        id: 'p_present', driverId: tDriverId, 
        records: {todayKey: 'Present'}, lastUpdated: Timestamp.now(),
      );
      // Absent: Has attendance record with today marked 'Absent'
      final attendAbsent = AttendanceModel(
        id: 'p_absent', driverId: tDriverId, 
        records: {todayKey: 'Absent'}, lastUpdated: Timestamp.now(),
      );

      when(() => mockDb.getPassengerAttendance('p_present')).thenAnswer((_) async => attendPresent);
      when(() => mockDb.getPassengerAttendance('p_absent')).thenAnswer((_) async => attendAbsent);
      when(() => mockDb.getPassengerAttendance('p_pending')).thenAnswer((_) async => null);

      // 5. Run Method
      final data = await controller.loadAttendanceData(null);

      // 6. Run Assertions
      expect(data['error'], isNull);
      expect(data['targetDate'], today);
      expect(data['isPollActive'], true);

      // Ensure dates are aggregated and sorted correctly
      final List<DateTime> allDates = data['allDates'];
      expect(allDates.length, 3);
      expect(allDates.first.isBefore(allDates.last), true);

      // Validate list grouping assignments
      final List<PassengerModel> boardedList = data['boarded'];
      final List<PassengerModel> absentList = data['absent'];
      final List<PassengerModel> pendingList = data['notVoted'];

      expect(boardedList.length, 1);
      expect(boardedList.first.uid, 'p_present');

      expect(absentList.length, 1);
      expect(absentList.first.uid, 'p_absent');

      expect(pendingList.length, 1);
      expect(pendingList.first.uid, 'p_pending');
    });
  });
}
