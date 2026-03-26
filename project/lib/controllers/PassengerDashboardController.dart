import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/Database.dart';
import '../models/PassengerModel.dart';
import '../models/PollModel.dart';
import '../models/AttendanceModel.dart';

class PassengerDashboardController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable state (simplified for this architecture)
  // In a full GetX/Provider setup, these would be reactive.
  // Here, the View will call methods and setState based on Future results.

  Future<Map<String, dynamic>> loadDashboardData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'error': 'User not logged in'};
      }

      // 1. Get Passenger Details
      DocumentSnapshot passengerDoc = await FirebaseFirestore.instance
          .collection('passenger')
          .doc(user.uid)
          .get();

      if (!passengerDoc.exists) {
        return {'error': 'Passenger profile not found'};
      }

      PassengerModel passenger = PassengerModel.fromMap(
        passengerDoc.data() as Map<String, dynamic>,
      );

      if (passenger.driverId.isEmpty) {
        return {'error': 'No driver assigned'};
      }

      // 2. Get Driver's Polls
      List<PollModel> polls = await _dbService.getPollsByDriver(
        passenger.driverId,
      );

      // 3. Get Existing Attendance (Single Document)
      AttendanceModel? attendanceDoc = await _dbService.getPassengerAttendance(
        user.uid,
      );

      // 4. Calculate "Dates to Mark"
      List<Map<String, dynamic>> datesToMark = [];

      // Get the map of marked dates: Key='YYYY-MM-DD', Value=Status
      Map<String, String> markedMap = attendanceDoc?.records ?? {};

      // Flatten all poll active dates
      Set<DateTime> allPollDates = {};
      for (var poll in polls) {
        for (var date in poll.activeDates) {
          allPollDates.add(_normalizeDate(date));
        }
      }

      // Filter and Sort
      List<DateTime> sortedDates = allPollDates.toList()..sort();

      // Current UTC date for comparison
      final today = _normalizeDate(DateTime.now());

      for (var date in sortedDates) {
        // Exclude past dates from the "To Mark" list
        if (date.isBefore(today)) {
          continue;
        }

        final dateKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        // If NOT in the marked map
        if (!markedMap.containsKey(dateKey)) {
          datesToMark.add({
            'id': date.toIso8601String(), // unique key
            'date': date,
            'label': dateKey,
            'status': 'Pending',
          });
        }
      }

      // For history, we just pass the map or convert it if needed.
      // The View expects a list for history? The previous view code for 'Attendance History' screen likely needs this.
      // But for Dashboard, we just return the attendanceDoc.

      // 5. Get Alert Unread Count
      int unreadCount = 0;
      try {
        // Fetch updates (taking the latest ones from the stream snapshot)
        final updatesStream = _dbService.getUpdates(passenger.driverId);
        final updates = await updatesStream.first; // Get first batch

        final prefs = await SharedPreferences.getInstance();
        final lastCheckMillis = prefs.getInt('lastAlertCheckTime') ?? 0;
        final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(
          lastCheckMillis,
        );

        unreadCount = updates
            .where((u) => u.timestamp.isAfter(lastCheckTime))
            .length;
      } catch (e) {
        debugPrint("Error fetching unread count: $e");
        // Non-critical, continue
      }

      // 6. Get Driver Phone Number
      String? driverPhone;
      try {
        final driverData = await _dbService.getDriverData(passenger.driverId);
        driverPhone = driverData?.phone;
      } catch (e) {
        debugPrint("Error fetching driver phone: $e");
      }

      return {
        'passenger': passenger,
        'datesToMark': datesToMark,
        'attendanceDoc': attendanceDoc,
        'unreadCount': unreadCount,
        'driverPhone': driverPhone,
      };
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      return {'error': e.toString()};
    }
  }

  Future<void> markAttendance({
    required String passengerId,
    required String driverId,
    required DateTime date,
    required String status,
  }) async {
    await _dbService.updateAttendance(passengerId, driverId, date, status);
  }

  DateTime _normalizeDate(DateTime dt) {
    return DateTime.utc(dt.year, dt.month, dt.day);
  }

  Future<void> markAlertsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'lastAlertCheckTime',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Streams the journey starting status for a specific driver.
  Stream<bool> getJourneyStatusStream(String driverId) {
    return _dbService.getJourneyStatusStream(driverId);
  }

  /// Combined stream that returns true only if both a poll is active and journey is started.
  Stream<bool> getTrackingEligibilityStream(String driverId) {
    return Rx.combineLatest2(
      _dbService.getTodayPollStatusStream(driverId),
      _dbService.getJourneyStatusStream(driverId),
      (bool hasPoll, bool isStarted) => hasPoll && isStarted,
    );
  }

  /// Returns today's attendance status for the current passenger.
  Future<String> getTodayAttendanceStatus() async {
    final user = _auth.currentUser;
    if (user == null) return 'Error';
    return await _dbService.getTodayAttendanceStatus(user.uid);
  }
}
