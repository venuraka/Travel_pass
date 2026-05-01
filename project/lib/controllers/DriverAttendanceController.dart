import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/Database.dart';
import '../models/PassengerModel.dart';
import '../models/AttendanceModel.dart';
import '../models/PollModel.dart';

class DriverAttendanceController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> loadAttendanceData(
    DateTime? selectedDate,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'error': 'Driver not logged in'};
      }

      // 1. Fetch Polls to find active dates and nearest date
      List<PollModel> polls = await _dbService.getPollsByDriver(user.uid);

      // Collect all active dates
      Set<DateTime> allDates = {};
      for (var poll in polls) {
        for (var date in poll.activeDates) {
          allDates.add(DateTime.utc(date.year, date.month, date.day));
        }
      }

      List<DateTime> sortedDates = allDates.toList()..sort();
      final today = DateTime.utc(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      // Determine the target date to show
      DateTime targetDate;
      if (selectedDate != null) {
        targetDate = DateTime.utc(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
      } else if (sortedDates.isNotEmpty) {
        // Find nearest future date (including today)
        try {
          targetDate = sortedDates.firstWhere((d) => !d.isBefore(today));
        } catch (e) {
          // No future dates, default to last available or today
          targetDate = sortedDates.last;
        }
      } else {
        targetDate = today;
      }

      final dateKey =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      // 2. Fetch all passengers for this driver
      List<PassengerModel> allPassengers = await _dbService
          .getPassengersByDriver(user.uid);

      // 3. Group Passengers by Status
      List<PassengerModel> boarded = [];
      List<PassengerModel> absent = [];
      List<PassengerModel> notVoted = []; // Pending

      for (var passenger in allPassengers) {
        // Fetch attendance record for this passenger
        AttendanceModel? attendance = await _dbService.getPassengerAttendance(
          passenger.uid,
        );

        String status = 'Pending';
        if (attendance != null && attendance.records.containsKey(dateKey)) {
          status = attendance.records[dateKey]!;
        }

        if (status == 'Present') {
          boarded.add(passenger);
        } else if (status == 'Absent') {
          absent.add(passenger);
        } else {
          notVoted.add(passenger);
        }
      }

      return {
        'targetDate': targetDate,
        'boarded': boarded,
        'absent': absent,
        'notVoted': notVoted,
        'allDates': sortedDates,
        'isPollActive': sortedDates.contains(targetDate),
      };
    } catch (e) {
      debugPrint("Error loading driver attendance data: $e");
      return {'error': e.toString()};
    }
  }
}
