import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/DriverModel.dart';
import '../services/Database.dart';

class SettingsController {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch current settings for the logged-in driver
  Future<DriverModel?> getSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await _dbService.getDriverData(user.uid);
    } catch (e) {
      debugPrint("SettingsController Error (getSettings): $e");
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

      // 3. Update Passengers based on type
      if (monthlyDelta != 0) {
        await _dbService.adjustPassengerPaymentAmounts(
          user.uid,
          monthlyDelta,
          'Monthly',
        );
      }

      if (dailyDelta != 0) {
        await _dbService.adjustPassengerPaymentAmounts(
          user.uid,
          dailyDelta,
          'Daily',
        );
      }
    } catch (e) {
      debugPrint("SettingsController Error (saveSettings): $e");
      rethrow;
    }
  }
}
