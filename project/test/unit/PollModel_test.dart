import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/PollModel.dart';

void main() {
  group('PollModel Tests', () {
    final testDate = DateTime(2026, 5, 20);
    final mockTimestamp = Timestamp.fromDate(DateTime(2026, 5, 14));

    test('should construct correct PollModel properties', () {
      final poll = PollModel(
        id: 'poll1',
        driverId: 'driver55',
        vehiclePlate: 'WP BAA 8888',
        activeDates: [testDate],
        createdAt: mockTimestamp,
      );

      expect(poll.id, 'poll1');
      expect(poll.activeDates.length, 1);
      expect(poll.activeDates.first, testDate);
    });

    test('toMap() transforms DateTime objects into CloudFirestore Timestamps', () {
      final poll = PollModel(
        id: 'poll2',
        driverId: 'driver22',
        vehiclePlate: 'WP CBC 1111',
        activeDates: [testDate],
        createdAt: mockTimestamp,
      );

      final map = poll.toMap();

      expect(map['id'], 'poll2');
      expect(map['activeDates'], isA<List<Timestamp>>());
      expect(map['activeDates'][0], Timestamp.fromDate(testDate));
    });

    test('fromMap() parses firestore list of timestamps back to DateTime objects', () {
      final firestoreData = {
        'driverId': 'driver33',
        'vehiclePlate': 'ABC-1234',
        'activeDates': [Timestamp.fromDate(testDate)],
        'createdAt': mockTimestamp,
      };

      final model = PollModel.fromMap(firestoreData, 'remote_id');

      expect(model.id, 'remote_id');
      expect(model.activeDates, isA<List<DateTime>>());
      expect(model.activeDates[0], testDate);
      expect(model.createdAt, mockTimestamp);
    });
  });
}
