import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/Database.dart';
import '../models/PassengerModel.dart';
import '../models/PollModel.dart';
import '../models/AttendanceModel.dart';

class TodayPassengersController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Loads today's active passengers grouped by status (Not Voted, Boarded, Absent).
  /// Returns a map with lists or 'error' key.
  Future<Map<String, dynamic>> loadTodayData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'error': 'Driver not logged in'};
      }

      // 1. Check if there is an active poll for today
      final DateTime now = DateTime.now();
      final DateTime today = DateTime.utc(now.year, now.month, now.day);
      final String dateKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      List<PollModel> polls = await _dbService.getPollsByDriver(user.uid);
      bool isPollActiveToday = false;
      for (var poll in polls) {
        // Check if any date in activeDates matches today (ignoring time)
        if (poll.activeDates.any(
          (d) =>
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day,
        )) {
          isPollActiveToday = true;
          break;
        }
      }

      if (!isPollActiveToday) {
        return {'noPoll': true};
      }

      // 2. Poll is active, fetch passengers
      List<PassengerModel> allPassengers = await _dbService
          .getPassengersByDriver(user.uid);

      List<PassengerModel> boarded = [];
      List<PassengerModel> absent = [];
      List<PassengerModel> notVoted = [];

      // 3. Check attendance for each passenger for today
      for (var passenger in allPassengers) {
        AttendanceModel? attendance = await _dbService.getPassengerAttendance(
          passenger.uid,
        );
        String status = 'Pending'; // Default

        if (attendance != null && attendance.records.containsKey(dateKey)) {
          status = attendance.records[dateKey]!;
        }

        if (status == 'Present') {
          // Assuming 'Present' means Boarded
          boarded.add(passenger);
        } else if (status == 'Absent') {
          absent.add(passenger);
        } else {
          notVoted.add(passenger);
        }
      }

      return {
        'boarded': boarded,
        'absent': absent,
        'notVoted': notVoted,
        'noPoll': false,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Marks attendance for a passenger.
  Future<void> markAttendance(String passengerId, String status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final DateTime now = DateTime.now();
      // Use UTC date stripping time to ensure consistency with load
      final DateTime today = DateTime.utc(now.year, now.month, now.day);

      // Update DB
      // Note: "Boarded" in UI usually maps to 'Present' in DB logic
      String dbStatus = status;
      if (status == 'Boarded') dbStatus = 'Present';

      await _dbService.updateAttendance(passengerId, user.uid, today, dbStatus);
    } catch (e) {
      rethrow;
    }
  }
}
