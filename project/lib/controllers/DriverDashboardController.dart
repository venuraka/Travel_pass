import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/Database.dart';
import '../models/PollModel.dart'; // Added

class DriverDashboardController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches the count of passengers who have marked themselves as 'Present' for today.
  Future<int> getTodayPassengerCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 0;
      }

      // 1. Check if there is an active poll for today (Optimization: Check this first)
      final DateTime now = DateTime.now();
      final DateTime today = DateTime.utc(now.year, now.month, now.day);

      List<PollModel> polls = await _dbService.getPollsByDriver(user.uid);
      bool isPollActiveToday = false;
      for (var poll in polls) {
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
        return 0;
      }

      // 2. Fetch passengers
      final passengers = await _dbService.getPassengersByDriver(user.uid);

      // 3. Count only those marked as 'Present' for today
      int presentCount = 0;
      final String dateKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      for (var passenger in passengers) {
        final attendance = await _dbService.getPassengerAttendance(
          passenger.uid,
        );
        if (attendance != null && attendance.records.containsKey(dateKey)) {
          if (attendance.records[dateKey] == 'Present') {
            presentCount++;
          }
        }
      }

      return presentCount;
    } catch (e) {
      debugPrint("Error fetching today's passenger count: $e");
      return 0;
    }
  }
}
