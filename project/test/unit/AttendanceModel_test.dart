import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/AttendanceModel.dart';

void main() {
  group('AttendanceModel Tests', () {
    final mockTimestamp = Timestamp.fromDate(DateTime(2026, 5, 14));

    test('should construct with accurate variables', () {
      final attendance = AttendanceModel(
        id: 'pass_a',
        driverId: 'driver_x',
        records: {'2026-05-14': 'Present'},
        lastUpdated: mockTimestamp,
      );

      expect(attendance.id, 'pass_a');
      expect(attendance.driverId, 'driver_x');
      expect(attendance.records['2026-05-14'], 'Present');
    });

    test('toMap() should convert properly', () {
      final attendance = AttendanceModel(
        id: 'pass_b',
        driverId: 'driver_y',
        records: {'2026-05-14': 'Absent', '2026-05-13': 'Present'},
        lastUpdated: mockTimestamp,
      );

      final map = attendance.toMap();

      expect(map['id'], 'pass_b');
      expect(map['driverId'], 'driver_y');
      expect(map['records'], isA<Map<String, String>>());
      expect(map['records']['2026-05-14'], 'Absent');
    });

    test('fromMap() reconstructs properly using string dynamic map and docId', () {
      final data = {
        'driverId': 'driver_z',
        'records': {'2026-05-01': 'Present'},
        'lastUpdated': mockTimestamp,
      };

      final model = AttendanceModel.fromMap(data, 'custom_doc_id');

      expect(model.id, 'custom_doc_id');
      expect(model.driverId, 'driver_z');
      expect(model.records['2026-05-01'], 'Present');
      expect(model.lastUpdated, mockTimestamp);
    });
  });
}
