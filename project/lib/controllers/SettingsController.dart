import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/DriverModel.dart';
import '../services/Database.dart';
import '../services/NotificationService.dart';

class SettingsController {
  final DatabaseService _dbService;
  final FirebaseAuth _auth;

  SettingsController({DatabaseService? dbService, FirebaseAuth? auth})
      : _dbService = dbService ?? DatabaseService(),
        _auth = auth ?? FirebaseAuth.instance;

  // Fetch current settings for the logged-in driver
  Future<DriverModel?> getSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await _dbService.getDriverData(user.uid);
    } catch (e) {
      rethrow;
    }
  }

  // Save settings: Update driver doc AND update passengers based on payment type
  Future<void> saveSettings({
    required DateTime? paymentDate,
    required String monthlyAmount,
    required String dailyAmount,
    required String badgePreference,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // 1. Get current driver settings to calculate deltas
      final currentDriver = await _dbService.getDriverData(user.uid);

      // Calculate Monthly Delta
      final oldMonthlyStr = currentDriver?.monthlyPaymentAmount ?? '0';
      final oldMonthly = int.tryParse(oldMonthlyStr) ?? 0;
      final newMonthly = int.tryParse(monthlyAmount) ?? 0;
      final monthlyDelta = newMonthly - oldMonthly;

      // Calculate Daily Delta
      final oldDailyStr = currentDriver?.dailyPaymentAmount ?? '0';
      final oldDaily = int.tryParse(oldDailyStr) ?? 0;
      final newDaily = int.tryParse(dailyAmount) ?? 0;
      final dailyDelta = newDaily - oldDaily;

      // 2. Update Driver Settings
      await _dbService.updateDriverSettings(
        user.uid,
        paymentDate,
        monthlyAmount,
        dailyAmount,
        badgePreference,
      );

      final notificationService = PushNotificationService();

      // 3. Update Passengers based on type and Notify
      if (monthlyDelta != 0) {
        await _dbService.adjustPassengerPaymentAmounts(
          user.uid,
          monthlyDelta,
          'Monthly',
        );

        // Notify Monthly Passengers
        try {
          final passengers = await _dbService.getPassengersByDriver(user.uid);
          final monthlyIds = passengers
              .where((p) => p.paymentType == 'Monthly' || p.paymentType == 'Monthly Payment')
              .map((p) => p.uid)
              .toList();

          if (monthlyIds.isNotEmpty) {
            await notificationService.sendNotificationToPassengers(
              passengerIds: monthlyIds,
              title: 'Monthly Fare Updated 💳',
              body: 'The driver has updated the monthly travel fee to Rs $monthlyAmount.',
              data: {'type': 'fare_update', 'newAmount': monthlyAmount},
            );
          }
        } catch (e) {
          debugPrint('⚠️ Could not notify monthly passengers of fare change: $e');
        }
      }

      if (dailyDelta != 0) {
        await _dbService.adjustPassengerPaymentAmounts(
          user.uid,
          dailyDelta,
          'Daily',
        );

        // Notify Daily Passengers
        try {
          final passengers = await _dbService.getPassengersByDriver(user.uid);
          final dailyIds = passengers
              .where((p) => p.paymentType == 'Daily' || p.paymentType == 'Daily Payment')
              .map((p) => p.uid)
              .toList();

          if (dailyIds.isNotEmpty) {
            await notificationService.sendNotificationToPassengers(
              passengerIds: dailyIds,
              title: 'Daily Fare Updated 💳',
              body: 'The driver has updated the daily travel fee to Rs $dailyAmount.',
              data: {'type': 'fare_update', 'newAmount': dailyAmount},
            );
          }
        } catch (e) {
          debugPrint('⚠️ Could not notify daily passengers of fare change: $e');
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
