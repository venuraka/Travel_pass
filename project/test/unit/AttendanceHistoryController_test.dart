import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/controllers/AttendanceHistoryController.dart';
import 'package:project/services/Database.dart';
import 'package:project/models/PassengerModel.dart';
import 'package:project/models/AttendanceModel.dart';
import 'package:project/models/PollModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockDatabaseService extends Mock implements DatabaseService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockDatabaseService mockDb;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late AttendanceHistoryController controller;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    controller = AttendanceHistoryController(dbService: mockDb, auth: mockAuth);
  });

  group('AttendanceHistoryController Tests', () {
    const tUserId = 'p_123';
    const tDriverId = 'd_456';

    final tPassenger = PassengerModel(
      uid: tUserId, name: 'Saman', phone: '', otherPhone: '', email: '',
      pickupLocation: '', paymentType: '', driverId: tDriverId,
      vehiclePlate: '', address: '', createdAt: Timestamp.now(),
    );

    final tPoll = PollModel(
      id: 'poll_1',
      driverId: tDriverId,
      vehiclePlate: 'WP 1234',
      activeDates: [
        DateTime.utc(2026, 5, 10),
        DateTime.utc(2026, 5, 11),
        DateTime.utc(2026, 5, 12),
      ],
      createdAt: Timestamp.now(),
    );

    final tAttendance = AttendanceModel(
      id: tUserId,
      driverId: tDriverId,
      records: {
        '2026-05-10': 'Present',
        '2026-05-11': 'Absent',
      },
      lastUpdated: Timestamp.now(),
    );

    test('loadAttendanceHistory creates merged history map correctly', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tUserId);
      when(() => mockDb.getPassengerData(tUserId)).thenAnswer((_) async => tPassenger);
      when(() => mockDb.getPollsByDriver(tDriverId)).thenAnswer((_) async => [tPoll]);
      when(() => mockDb.getPassengerAttendance(tUserId)).thenAnswer((_) async => tAttendance);

      final result = await controller.loadAttendanceHistory();

      // We expect 3 dates from the poll. 
      // 10th -> Present, 11th -> Absent, 12th -> Not Marked
      expect(result.length, 3);
      
      final date10 = DateTime.utc(2026, 5, 10);
      final date11 = DateTime.utc(2026, 5, 11);
      final date12 = DateTime.utc(2026, 5, 12);

      expect(result[date10], 'Present');
      expect(result[date11], 'Absent');
      expect(result[date12], 'Not Marked');
    });

    test('loadAttendanceHistory throws exception if user not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => controller.loadAttendanceHistory(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User not logged in'))),
      );
    });

    test('loadAttendanceHistory throws exception if passenger profile missing', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(tUserId);
      when(() => mockDb.getPassengerData(tUserId)).thenAnswer((_) async => null);

      expect(
        () => controller.loadAttendanceHistory(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Passenger profile not found'))),
      );
    });
  });
}
