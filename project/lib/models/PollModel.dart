import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String id;
  final String driverId;
  final String vehiclePlate;
  final List<DateTime> activeDates;
  final Timestamp createdAt;

  PollModel({
    required this.id,
    required this.driverId,
    required this.vehiclePlate,
    required this.activeDates,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'vehiclePlate': vehiclePlate,
      'activeDates': activeDates.map((d) => Timestamp.fromDate(d)).toList(),
      'createdAt': createdAt,
    };
  }

  factory PollModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PollModel(
      id: documentId,
      driverId: map['driverId'] ?? '',
      vehiclePlate: map['vehiclePlate'] ?? '',
      activeDates:
          (map['activeDates'] as List<dynamic>?)
              ?.map((t) => (t as Timestamp).toDate())
              .toList() ??
          [],
      createdAt: map['createdAt'] as Timestamp,
    );
  }
}
