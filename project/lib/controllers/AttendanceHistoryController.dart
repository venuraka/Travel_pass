import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/Database.dart';
import '../models/PassengerModel.dart';
import '../models/PollModel.dart';
import '../models/AttendanceModel.dart';

class AttendanceHistoryController {
  final DatabaseService _dbService;
  final FirebaseAuth _auth;

  AttendanceHistoryController({DatabaseService? dbService, FirebaseAuth? auth})
      : _dbService = dbService ?? DatabaseService(),
        _auth = auth ?? FirebaseAuth.instance;

  Future<Map<DateTime, String>> loadAttendanceHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // 1. Get Passenger Details (to get driverId)
      DocumentSnapshot passengerDoc = await FirebaseFirestore.instance
          .collection('passenger')
          .doc(user.uid)
          .get();

      if (!passengerDoc.exists) {
        throw Exception('Passenger profile not found');
      }

      PassengerModel passenger = PassengerModel.fromMap(
        passengerDoc.data() as Map<String, dynamic>,
      );

      if (passenger.driverId.isEmpty) {
        throw Exception('No driver assigned');
      }

      // 2. Get Driver's Polls (All valid dates)
      List<PollModel> polls = await _dbService.getPollsByDriver(
        passenger.driverId,
      );

      // 3. Get Existing Attendance (Single Document)
      AttendanceModel? attendanceDoc = await _dbService.getPassengerAttendance(
        user.uid,
      );

      // 4. Merge Data to create History Map
      Map<DateTime, String> historyMap = {};

      // Helper for date normalization
      DateTime normalize(DateTime dt) =>
          DateTime.utc(dt.year, dt.month, dt.day);

      // A. Add Poll Dates as 'Not Marked' initially
      for (var poll in polls) {
        for (var date in poll.activeDates) {
          historyMap[normalize(date)] = 'Not Marked';
        }
      }

      // B. Overlay Recorded Attendance
      if (attendanceDoc != null) {
        for (var entry in attendanceDoc.records.entries) {
          // Parse date key 'YYYY-MM-DD'
          try {
            List<String> parts = entry.key.split('-');
            if (parts.length == 3) {
              DateTime date = DateTime.utc(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
              historyMap[date] = entry.value; // 'Present', 'Absent'
            }
          } catch (e) {
            debugPrint("Error parsing date key ${entry.key}: $e");
          }
        }
      }

      return historyMap;
    } catch (e) {
      debugPrint("Error loading attendance history: $e");
      rethrow;
    }
  }
}
