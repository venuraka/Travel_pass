import 'package:cloud_firestore/cloud_firestore.dart';

class RedemptionModel {
  final String id;
  final String driverId;
  final String driverName;
  final double amount;
  final DateTime requestedAt;
  final DateTime? paidAt;
  final String status; // 'pending', 'approved', 'rejected'

  RedemptionModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.amount,
    required this.requestedAt,
    this.paidAt,
    this.status = 'pending',
  });

  factory RedemptionModel.fromMap(Map<String, dynamic> map, String id) {
    return RedemptionModel(
      id: id,
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? 'Driver',
      amount: (map['amount'] ?? 0.0).toDouble(),
      requestedAt: map['requestedAt'] != null
          ? (map['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] as Timestamp).toDate()
          : null,
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'amount': amount,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      'status': status,
    };
  }

  /// Helper to get a formatted date string.
  String get requestedDateStr =>
      "${requestedAt.year}/${requestedAt.month.toString().padLeft(2, '0')}/${requestedAt.day.toString().padLeft(2, '0')}";

  String? get paidDateStr => paidAt != null
      ? "${paidAt!.year}/${paidAt!.month.toString().padLeft(2, '0')}/${paidAt!.day.toString().padLeft(2, '0')}"
      : null;
}
