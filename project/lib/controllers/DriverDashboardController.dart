import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/Database.dart';
import '../models/PollModel.dart'; // Added
import '../services/PushNotificationService.dart'; // Added
import 'package:flutter/foundation.dart'; // Added

class DriverDashboardController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initFCM() async {
    final user = _auth.currentUser;
    if (user != null) {
      await PushNotificationService.initialize();
      final token = await PushNotificationService.getToken();
      if (token != null) {
        await _dbService.updateUserFCMToken(user.uid, token, 'driver');
        debugPrint("Driver FCM Token updated: $token");
      }
      PushNotificationService.listenForeground();
    }
  }

  /// Fetches the count of passengers who have marked themselves as 'Present' for today.
  Future<int> getTodayPassengerCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 0;
      }

      // 1. Check if there is an active poll for today (Optimization: Check this first)
      final DateTime now = DateTime.now().toUtc();
      final DateTime today = DateTime.utc(now.year, now.month, now.day);

      List<PollModel> polls = await _dbService.getPollsByDriver(user.uid);
      bool isPollActiveToday = false;
      for (var poll in polls) {
        if (poll.activeDates.any((d) {
          final utcDate = d.toUtc();
          return utcDate.year == today.year &&
                 utcDate.month == today.month &&
                 utcDate.day == today.day;
        })) {
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
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day
          .toString().padLeft(2, '0')}";

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

  /// Returns the current driver's UID.
  String? getDriverId() {
    return _auth.currentUser?.uid;
  }

  /// Sets the journey as started in the database.
  Future<void> startJourney() async {
    final uid = getDriverId();
    if (uid != null) {
      await _dbService.updateJourneyStatus(uid, true);
    }
  }

  /// Resets the journey status (useful for ending it, though not directly asked).
  Future<void> endJourney() async {
    final uid = getDriverId();
    if (uid != null) {
      await _dbService.updateJourneyStatus(uid, false);
    }
  }

  /// Checks if there is an active poll for the current driver today.
  Future<bool> hasActivePollToday() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);

      List<PollModel> polls = await _dbService.getPollsByDriver(user.uid);
      for (var poll in polls) {
        if (poll.activeDates.any((d) {
          final utcDate = d.toUtc();
          return utcDate.year == today.year && utcDate.month == today.month && utcDate.day == today.day;
        })) {
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error checking for today's poll: $e");
    }
    return false;
  }

  /// Returns a stream for today's passenger count.
  Stream<int> getTodayPassengerCountStream() {
    final uid = getDriverId();
    if (uid == null) return Stream.value(0);
    return _dbService.getTodayPassengerCountStream(uid);
  }

  /// Returns a stream for today's poll status. (Real-time)
  Stream<bool> getTodayPollStatusStream() {
    final uid = getDriverId();
    if (uid == null) return Stream.value(false);
    return _dbService.getTodayPollStatusStream(uid);
  }

  /// Returns a stream for pending requests count.
  Stream<int> getPendingRequestsCountStream() {
    final uid = getDriverId();
    if (uid == null) return Stream.value(0);
    return _dbService.getPendingPassengersCountStream(uid);
  }
}
