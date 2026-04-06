import 'package:cloud_firestore/cloud_firestore.dart';

class RedemptionModel {
  final String id;
  final String driverId;
  final double amount;
  final DateTime date;
  final String status; // 'Completed', 'Processing'

  RedemptionModel({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.date,
    this.status = 'Completed',
  });

  factory RedemptionModel.fromMap(Map<String, dynamic> map, String id) {
    return RedemptionModel(
      id: id,
      driverId: map['driverId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? 'Completed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
    };
  }
}
