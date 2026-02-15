import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id; // This will likely be the passengerId
  final String driverId;
  // Key: Date String (YYYY-MM-DD), Value: Status ('Present' or 'Absent')
  final Map<String, String> records;
  final Timestamp lastUpdated;

  AttendanceModel({
    required this.id,
    required this.driverId,
    required this.records,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'records': records,
      'lastUpdated': lastUpdated,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      driverId: map['driverId'] ?? '',
      records: Map<String, String>.from(map['records'] ?? {}),
      lastUpdated: map['lastUpdated'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
