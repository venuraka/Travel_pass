import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/Database.dart';
import '../models/PollModel.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/WeatherService.dart';
import '../services/NotificationService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class DriverDashboardController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeatherService _weatherService = WeatherService();
  final PushNotificationService _notificationService = PushNotificationService();



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
      return 0;
    }
  }

  /// Returns the current driver's UID.
  String? getDriverId() {
    return _auth.currentUser?.uid;
  }

  /// Sets the journey as started in the database and sends weather alerts.
  Future<void> startJourney() async {
    final uid = getDriverId();
    if (uid != null) {
      // 1. Mark journey as started in DB
      await _dbService.updateJourneyStatus(uid, true);

      // 2. TRIGGER WEATHER-BASED NOTIFICATIONS (Scanning Whole Route)
      try {
        // 1. Get Driver's saved route to scan multiple points
        final driver = await _dbService.getDriverData(uid);
        final route = driver?.route;
        
        List<Map<String, double>> pointsToCheck = [];

        if (route != null && route.isNotEmpty) {
          // Add the Start Point
          pointsToCheck.add({
            "lat": (route.first["lat"] as num).toDouble(),
            "lng": (route.first["lng"] as num).toDouble(),
          });

          // Add the Middle Point (if route is long enough)
          if (route.length >= 3) {
            final midIndex = (route.length / 2).floor();
            pointsToCheck.add({
              "lat": (route[midIndex]["lat"] as num).toDouble(),
              "lng": (route[midIndex]["lng"] as num).toDouble(),
            });
          }

          // Add the Final Destination
          if (route.length >= 2) {
            pointsToCheck.add({
              "lat": (route.last["lat"] as num).toDouble(),
              "lng": (route.last["lng"] as num).toDouble(),
            });
          }
        } else {
          // Fallback to current position if no route is defined
          Position position = await Geolocator.getCurrentPosition();
          pointsToCheck.add({
            "lat": position.latitude,
            "lng": position.longitude,
          });
        }
        
        // 2. Aggregate the weather recommendation (Priority: Rain > Hot > Sunny)
        Map<String, String> finalRec = {
          "title": "Journey Started!",
          "body": "The weather looks clear across the entire route today.",
          "type": "sunny",
        };

        for (final point in pointsToCheck) {
          final rec = await _weatherService.getDestinationForecast(
            point["lat"]!, 
            point["lng"]!
          );
          
          if (rec["type"] == "rain") {
            // Rain is highest priority - if it's raining anywhere, notify!
            finalRec = rec;
            finalRec["body"] = "Rain is expected along your route today. " +
                               "Don't forget your umbrella!";
            break; 
          } else if (rec["type"] == "hot" && finalRec["type"] != "rain") {
            finalRec = rec;
          }
        }

        // 3. Get UIDs of all "Present" passengers
        final presentIds = await _dbService.getPresentPassengerIds(uid);

        if (presentIds.isNotEmpty) {
          await _notificationService.sendNotificationToPassengers(
            passengerIds: presentIds,
            title: finalRec["title"] ?? "Journey Started!",
            body: finalRec["body"] ?? "Your bus is on the way.",
            data: {
              "type": "weather_alert",
              "weather_type": finalRec["type"]
            },
          );
          
          if (kDebugMode) {
            print("✅ Route-wide weather alert sent: ${finalRec["title"]}");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error in weather notification: $e');
        }
      }
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
  /// Returns a stream for the current driver's name.
  Stream<String> getDriverNameStream() {
    final uid = getDriverId();
    if (uid == null) return Stream.value('Driver');
    return _dbService.getDriverNameStream(uid);
  }

  /// 🔹 PAYMENT REMINDERS ACTIONS 🔹

  /// Returns a stream of passengers who have missed payments.
  Stream<List<Map<String, dynamic>>> getMissedPaymentPassengersStream() {
    final uid = getDriverId();
    if (uid == null) return Stream.value([]);
    return _dbService.getMissedPaymentPassengersStream(uid);
  }

  /// Initiates a phone call to the passenger.
  Future<void> callPassenger(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  /// Sends a push notification reminder to the passenger.
  Future<void> sendPaymentReminder(String passengerId, String name, String amount) async {
    final driverId = getDriverId();
    if (driverId == null) return;

    await _notificationService.sendNotificationToPassengers(
      passengerIds: [passengerId],
      title: "Payment Reminder 💳",
      body: "Hi $name, you have a pending payment of $amount. Please settle it at your earliest convenience.",
      data: {
        "type": "payment_reminder",
        "screen": "payment"
      },
    );
  }

  /// Marks a payment as paid by cash.
  Future<void> markAsPaidByCash(Map<String, dynamic> passenger) async {
    final driverId = getDriverId();
    if (driverId == null) return;

    final driverData = await _dbService.getDriverData(driverId);
    
    await _dbService.recordManualPayment(
      passengerId: passenger['id'],
      passengerName: passenger['name'],
      driverId: driverId,
      driverName: driverData?.name ?? 'Driver',
      amount: passenger['paymentAmount'] ?? '0',
      type: passenger['paymentType'] ?? 'Daily',
    );
  }
}
