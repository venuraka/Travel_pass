import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/UpdateModel.dart';
import '../services/Database.dart';

import '../services/NotificationService.dart';

class UpdatesController {
  final DatabaseService _dbService = DatabaseService();
  final PushNotificationService _notificationService = PushNotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// Streams updates for the current driver.
  Stream<List<UpdateModel>> getUpdates() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _dbService.getUpdates(user.uid);
  }

  /// Sends a new update.
  Future<void> sendUpdate(String content, BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final update = UpdateModel(
        id: _uuid.v4(),
        driverId: user.uid,
        content: content,
        timestamp: DateTime.now(),
        role: 'admin',
        label: 'You',
      );

      await _dbService.saveUpdate(update);

      // Trigger Push Notification
      await _notificationService.sendPushNotification(
        driverId: user.uid,
        title: "New Update from Driver",
        body: content,
        data: {"type": "update", "screen": "updates", "driverId": user.uid},
      );
    } catch (e) {
      debugPrint("Error sending update: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow; // Optional depending on if UI needs to handle specific errors
    }
  }
}
