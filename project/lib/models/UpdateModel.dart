import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateModel {
  final String id;
  final String driverId;
  final String content;
  final DateTime timestamp;
  final String role; // 'admin' (driver) or 'passenger'
  final String label; // 'You' or 'Passenger Name'

  UpdateModel({
    required this.id,
    required this.driverId,
    required this.content,
    required this.timestamp,
    this.role = 'admin',
    this.label = 'You',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'role': role,
      'label': label,
    };
  }

  factory UpdateModel.fromMap(Map<String, dynamic> map, String id) {
    return UpdateModel(
      id: id,
      driverId: map['driverId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: map['role'] as String? ?? 'admin',
      label: map['label'] as String? ?? '',
    );
  }
}
