import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/Database.dart';
import '../models/PassengerModel.dart';
import '../models/PollModel.dart';
import '../models/AttendanceModel.dart';
import '../services/NotificationService.dart';

class PassengerDashboardController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PushNotificationService _notificationService = PushNotificationService();

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

      // 1. Check and charge monthly fee if due (Running Balance Logic)
      await _dbService.checkAndChargeMonthlyFees(user.uid);

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
        // Exclude past dates AND today from the "To Mark" list
        // Today will be handled in a separate dedicated section
        if (date.isBefore(today) || date.isAtSameMomentAs(today)) {
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
        // Non-critical, continue
      }

      // 6. Get Driver Phone Number
      String? driverPhone;
      try {
        final driverData = await _dbService.getDriverData(passenger.driverId);
        driverPhone = driverData?.phone;
      } catch (e) {
      }

      return {
        'passenger': passenger,
        'datesToMark': datesToMark,
        'attendanceDoc': attendanceDoc,
        'unreadCount': unreadCount,
        'driverPhone': driverPhone,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> markAttendance({
    required String passengerId,
    required String driverId,
    required DateTime date,
    required String status,
  }) async {
    // 1. Update DB
    await _dbService.updateAttendance(passengerId, driverId, date, status);

    // 2. Notify Driver (Only if Absent)
    if (status == 'Absent') {
      try {
        final passenger = await _dbService.getPassengerData(passengerId);
        if (passenger != null) {
          await _notificationService.sendNotificationToDriver(
            driverId: driverId,
            title: 'Attendance Update',
            body: '${passenger.name} has marked themselves as Absent today.',
            data: {
              'type': 'attendance',
              'passengerId': passengerId,
              'status': status,
            },
          );
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Could not notify driver of attendance: $e');
      }
    }
  }

  Future<void> removeAttendance({
    required String passengerId,
    required DateTime date,
  }) async {
    await _dbService.removeAttendanceRecord(passengerId, date);
  }

  DateTime _normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
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



  /// Combined stream specifically for the "Today's Status" section
  Stream<Map<String, dynamic>> getTodayStatusCombinedStream(String driverId, String passengerId) {
    return Rx.combineLatest3(
      _dbService.getJourneyStatusStream(driverId),
      _dbService.getPassengerAttendanceStream(passengerId),
      _dbService.getTodayPollStatusStream(driverId),
      (bool isStarted, AttendanceModel? attendance, bool hasPollToday) {
        final today = _normalizeDate(DateTime.now());
        final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        
        final status = attendance?.records[dateKey] ?? 'Not Marked';

        return {
          'isStarted': isStarted,
          'hasPollToday': hasPollToday,
          'status': status,
          'date': today,
        };
      },
    );
  }



  /// Returns today's attendance status for the current passenger.
  Future<String> getTodayAttendanceStatus() async {
    final user = _auth.currentUser;
    if (user == null) return 'Error';
    return await _dbService.getTodayAttendanceStatus(user.uid);
  }

  /// Returns a stream of unread alerts count for the passenger.
  Stream<int> getUnreadAlertsCountStream(String driverId) {
    return _dbService.getUpdatesStream(driverId).asyncMap((updates) async {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMillis = prefs.getInt('lastAlertCheckTime') ?? 0;
      final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);
      return updates.where((u) => u.timestamp.isAfter(lastCheckTime)).length;
    });
  }

  /// Returns a real-time stream of dates that need marking.
  Stream<List<Map<String, dynamic>>> getAttendanceDatesStream(String passengerId, String driverId) {
    final pollsStream = _dbService.getPollsByDriverStream(driverId);
    final attendanceStream = _dbService.getPassengerAttendanceStream(passengerId);

    return Rx.combineLatest2<List<PollModel>, AttendanceModel?, List<Map<String, dynamic>>>(
      pollsStream,
      attendanceStream,
      (polls, attendance) {
        List<Map<String, dynamic>> datesToMark = [];
        Map<String, String> markedMap = attendance?.records ?? {};
        
        Set<DateTime> allPollDates = {};
        for (var poll in polls) {
          for (var date in poll.activeDates) {
            allPollDates.add(_normalizeDate(date));
          }
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final List<DateTime> sortedDates = allPollDates.toList()..sort();

        for (var date in sortedDates) {
          // Normalize to ensure comparison works
          final normalizedPollDate = _normalizeDate(date);
          
          final dateKey = "${normalizedPollDate.year}-${normalizedPollDate.month.toString().padLeft(2, '0')}-${normalizedPollDate.day.toString().padLeft(2, '0')}";
          
          // Exclude dates strictly before or equal to today 
          // Today is handled in its own section
          if (normalizedPollDate.isBefore(today) || normalizedPollDate.isAtSameMomentAs(today)) {
            continue;
          }

          if (markedMap.containsKey(dateKey)) {
            continue;
          }
          
          datesToMark.add({
            'id': normalizedPollDate.toIso8601String(),
            'date': normalizedPollDate,
            'label': dateKey,
            'status': 'Pending',
          });
        }
        return datesToMark;
      },
    );
  }
  /// Resets the registration status for the current passenger.
  Future<void> resetRegistration() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance
        .collection('passenger')
        .doc(user.uid)
        .update({
      'registered': false,
      'driverId': '',
      'driverName': '',
    });
  }
}
