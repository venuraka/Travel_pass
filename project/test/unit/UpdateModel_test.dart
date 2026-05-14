import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/UpdateModel.dart';

void main() {
  group('UpdateModel Tests', () {
    final testTimestamp = DateTime(2026, 5, 14, 10, 0);

    test('should construct correctly with defaults', () {
      final update = UpdateModel(
        id: 'up1',
        driverId: 'drv1',
        content: 'Bus starts in 5 mins',
        timestamp: testTimestamp,
      );

      expect(update.id, 'up1');
      expect(update.role, 'admin'); // default value check
      expect(update.label, 'You'); // default value check
    });

    test('toMap() serialization converts correctly', () {
      final update = UpdateModel(
        id: 'up2',
        driverId: 'drv2',
        content: 'Late by 10 minutes',
        timestamp: testTimestamp,
        role: 'passenger',
        label: 'Kamal Perera',
      );

      final map = update.toMap();

      expect(map['id'], 'up2');
      expect(map['timestamp'], isA<Timestamp>());
      expect(map['role'], 'passenger');
      expect(map['label'], 'Kamal Perera');
    });

    test('fromMap() parses fields and defaults cleanly', () {
      final firestoreData = {
        'driverId': 'drv3',
        'content': 'Reaching terminal',
        'timestamp': Timestamp.fromDate(testTimestamp),
        'role': 'admin',
        'label': 'Driver Amal',
      };

      final model = UpdateModel.fromMap(firestoreData, 'docId_123');

      expect(model.id, 'docId_123');
      expect(model.content, 'Reaching terminal');
      expect(model.timestamp, testTimestamp);
      expect(model.label, 'Driver Amal');
    });
  });
}
