import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:project/services/Database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:project/main.dart'; // Added
import 'package:project/Screens/passenger/PaymentHistory.dart'; // Added
import 'package:project/Screens/Driver/NewPassenger.dart'; // Added
import 'package:project/Screens/passenger/Updates.dart'; // Added
import 'package:project/Screens/passenger/TrackVehicle.dart'; // Added
import 'package:flutter/material.dart'; // Added
import 'package:project/utils/AuthWrapper.dart'; // Added


class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // ✅ High Importance Channel for Android (Must match Cloud Function)
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', 
    'High Importance Notifications',
    description: 'This channel is used for essential passenger alerts.',
    importance: Importance.max,
  );

  // ✅ Set to us-central1 as confirmed in your Firebase Console
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  final DatabaseService _dbService = DatabaseService();

  static final PushNotificationService _instance =
  PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  /// 🔹 Initialize FCM
  Future<void> initialize() async {
    // 1️⃣ Request permission (iOS + Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2️⃣ Initialize Local Notifications (For Foreground Popups)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initializationSettings);

    // 3️⃣ Create Android Channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('✅ Notification permission granted');
      }

      // 4️⃣ Foreground messages listener — only shows a popup, does NOT auto-navigate
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (kDebugMode) {
          print('📩 Foreground notification: ${notification?.title}');
        }

        // Show local notification popup only — user must TAP to navigate
        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android.smallIcon,
                priority: Priority.high,
                importance: Importance.max,
              ),
            ),
          );
          // NOTE: No auto-redirect here. Navigation only happens when the user taps
          // the notification (handled by onMessageOpenedApp and local notification tap).
        }
      });

      // 5️⃣ Handle Background Notification Taps (Tapped when app is in background but open)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) print('📩 Notification tapped in background: ${message.data}');
        handleNotificationRedirect(message.data);
      });

      // 6️⃣ Handle Cold Start Notification Taps (Tapped when app was totally closed)
      _fcm.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          if (kDebugMode) print('📩 Notification tapped (Cold Start): ${message.data}');
          handleNotificationRedirect(message.data);
        }
      });
    } else {
      if (kDebugMode) {
        print('❌ Notification permission denied');
      }
    }

    // 7️⃣ Background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
  }

  /// 🔹 Handle Redirection Logic
  void handleNotificationRedirect(Map<String, dynamic> data) {
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      if (data['screen'] == 'payment') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
        );
      } else if (data['screen'] == 'new_passenger') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NewPassengerScreen()),
        );
      } else if (data['screen'] == 'updates') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UpdatesScreen(driverId: data['driverId']),
          ),
        );
      } else if (data['screen'] == 'track') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TrackVehicle(
              driverId: data['driverId'] ?? '',
              passengerId: _auth.currentUser?.uid ?? '',
            ),
          ),
        );
      } else if (data['type'] == 'registration_approved') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  /// 🔹 Update token specifically for a Driver (called from Driver Dashboard)
  Future<void> updateTokenForDriver() async {
    await _saveTokenToDatabase(collection: 'driver');
  }

  /// 🔹 Update token specifically for a Passenger (called from Passenger Dashboard)
  Future<void> updateTokenForPassenger() async {
    await _saveTokenToDatabase(collection: 'passenger');
  }

  /// 🔹 Save token to Firestore
  Future<void> _saveTokenToDatabase({required String collection, String? newToken}) async {
    final user = _auth.currentUser;

    if (user != null) {
      if (kDebugMode) print('👤 User detected: ${user.uid}. Fetching token...');
      
      String? token = newToken;
      
      // Retry up to 3 times if token is null (common on first boot)
      for (int i = 0; i < 3; i++) {
        token ??= await _fcm.getToken();
        if (token != null) break;
        
        if (kDebugMode) print('⏳ Token is null, retrying in 2s... ($i/3)');
        await Future.delayed(const Duration(seconds: 2));
      }

      if (token != null) {
        try {
          await _dbService.updateFcmToken(collection, user.uid, token);
          if (kDebugMode) {
            print('✅ FCM Token successfully saved to $collection collection: $token');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to save FCM token to $collection: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to retrieve FCM token after retries. Check Google Play Services.');
        }
      }
    } else {
      if (kDebugMode) print('ℹ️ No user logged in. Skipping token save.');
    }
  }

  /// 🔹 Send push notification via Cloud Function
  Future<void> sendPushNotification({
    required String driverId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1️⃣ Get tokens from DB
      final tokens = await _dbService.getPassengerTokensByDriver(driverId);

      if (tokens.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No tokens found for driver: $driverId');
        }
        return;
      }

      // 2️⃣ Call Firebase Cloud Function
      final HttpsCallable callable =
      _functions.httpsCallable('sendNotification');

      final response = await callable.call({
        'tokens': tokens,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      if (kDebugMode) {
        print('✅ Cloud Function Result: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending notification: $e');
      }
    }
  }

  /// 🔹 Send notification specifically to a Driver
  Future<void> sendNotificationToDriver({
    required String driverId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1️⃣ Get driver token from DB
      final token = await _dbService.getDriverToken(driverId);

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No FCM token found for driver: $driverId');
        }
        return;
      }

      // 2️⃣ Call Firebase Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('sendNotification');

      await callable.call({
        'tokens': [token], // Send as a list with one token
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      if (kDebugMode) {
        print('✅ Notification sent to driver: $driverId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending notification to driver: $e');
      }
    }
  }

  /// 🔹 Send notification to a specific group of Passengers
  Future<bool> sendNotificationToPassengers({
    required List<String> passengerIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (passengerIds.isEmpty) return false;

    try {
      // 1️⃣ Get tokens for these passengers
      final tokens = await _dbService.getTokensForPassengers(passengerIds);

      if (tokens.isEmpty) {
        if (kDebugMode) print('⚠️ No FCM tokens found for requested passengers.');
        return false;
      }

      // 2️⃣ Call Firebase Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('sendNotification');

      final response = await callable.call({
        'tokens': tokens,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      if (kDebugMode) {
        print('✅ Notifications sent to ${tokens.length} passengers.');
        print('✅ Cloud Function Result: ${response.data}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending group notification: $e');
      }
      return false;
    }
  }
}

/// 🔥 REQUIRED: Background handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  if (kDebugMode) {
    print('📩 Background message: ${message.messageId}');
  }
}