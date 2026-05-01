import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Screens/UserRegistration/Login.dart';
import '../Screens/UserRegistration/UserSelection.dart';
import '../Screens/passenger/Dashboard.dart';
import '../Screens/passenger/PendingApproval.dart';
import '../Screens/Driver/DriverPendingApproval.dart';
import '../Screens/Driver/Dashboard.dart';
import '../controllers/AccessController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AccessController _accessController = AccessController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Loading Auth State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF05A664)),
            ),
          );
        }

        // 2. User Not Logged In
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // 3. User Logged In - Check Role & Status
        final User user = snapshot.data!;
        return FutureBuilder<Map<String, dynamic>>(
          future: _checkUserRoleAndStatus(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF05A664)),
                ),
              );
            }

            final data = roleSnapshot.data;
            if (data == null) {
              // Fallback/Error -> Login
              return const LoginPage();
            }

            final String role = data['role'];
            final bool isApproved = data['isApproved'];

            if (role == 'driver') {
              if (isApproved) {
                return const DriverDashboardScreen();
              } else {
                return const DriverPendingApprovalScreen();
              }
            } else if (role == 'passenger') {
              if (isApproved) {
                return const PassengerDashboardApp();
              } else {
                return const PendingApprovalScreen();
              }
            } else {
              // New user or unknown -> UserSelection to register
              return const UserSelectionScreen();
            }
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _checkUserRoleAndStatus(String uid) async {
    // Check Driver
    if (await _accessController.isDriver(uid)) {
      final bool isApproved = await _accessController.isDriverApproved(uid);
      return {'role': 'driver', 'isApproved': isApproved};
    }

    // Check Passenger
    // We need to know if they exist AND if they are approved
    try {
      final doc = await _db.collection('passenger').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final bool registered = data['registered'] == true;
        final String driverId = data['driverId'] ?? '';

        if (driverId.isEmpty) {
          return {'role': 'unknown', 'isApproved': false};
        }
        
        return {'role': 'passenger', 'isApproved': registered};
      }
    } catch (e) {
      // Handle error internally
    }

    // Not found
    return {'role': 'unknown', 'isApproved': false};
  }
}
