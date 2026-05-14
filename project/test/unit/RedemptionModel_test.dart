import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/RedemptionModel.dart';

void main() {
  group('RedemptionModel Tests', () {
    final requestedDate = DateTime(2026, 5, 10);
    final paidDate = DateTime(2026, 5, 12);

    test('should construct correct details and defaults', () {
      final model = RedemptionModel(
        id: 'redem1',
        driverId: 'drv_id',
        driverName: 'Sunil',
        amount: 5000.0,
        requestedAt: requestedDate,
      );

      expect(model.id, 'redem1');
      expect(model.status, 'pending'); // Default assertion
      expect(model.paidAt, isNull);
    });

    test('toMap() includes conditional properties', () {
      final model = RedemptionModel(
        id: 'redem2',
        driverId: 'drv_id2',
        driverName: 'Nimal',
        amount: 2500.0,
        requestedAt: requestedDate,
        paidAt: paidDate,
        status: 'approved',
      );

      final map = model.toMap();

      expect(map['amount'], 2500.0);
      expect(map['paidAt'], isA<Timestamp>());
      expect(map['status'], 'approved');
    });

    test('fromMap() parses Firestore timestamps accurately', () {
      final firestoreData = {
        'driverId': 'drv_id3',
        'driverName': 'Kamal',
        'amount': 1000,
        'requestedAt': Timestamp.fromDate(requestedDate),
        'paidAt': Timestamp.fromDate(paidDate),
        'status': 'rejected',
      };

      final model = RedemptionModel.fromMap(firestoreData, 'custom_id');

      expect(model.id, 'custom_id');
      expect(model.amount, 1000.0);
      expect(model.requestedAt, requestedDate);
      expect(model.paidAt, paidDate);
      expect(model.status, 'rejected');
    });

    test('Date formatting helpers return expected strings', () {
      final model = RedemptionModel(
        id: 'redem4',
        driverId: 'drv',
        driverName: 'Amal',
        amount: 300.0,
        requestedAt: requestedDate,
        paidAt: paidDate,
      );

      // 2026-05-10 formatted should be 2026/05/10
      expect(model.requestedDateStr, '2026/05/10');
      expect(model.paidDateStr, '2026/05/12');
    });
  });
}
