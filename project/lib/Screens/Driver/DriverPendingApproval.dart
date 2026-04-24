import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../UserRegistration/Login.dart';
import '../../controllers/AccessController.dart';
import 'Dashboard.dart';

class DriverPendingApprovalScreen extends StatefulWidget {
  const DriverPendingApprovalScreen({super.key});

  @override
  State<DriverPendingApprovalScreen> createState() => _DriverPendingApprovalScreenState();
}

class _DriverPendingApprovalScreenState extends State<DriverPendingApprovalScreen> {
  final AccessController _accessController = AccessController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final user = _auth.currentUser;
    if (user != null) {
      final isApproved = await _accessController.isDriverApproved(user.uid);
      
      if (isApproved) {
        if (mounted) {
          // Navigate to Driver Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverDashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Still pending admin approval. Please wait.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 80,
                color: Color(0xFF05A664),
              ),
              const SizedBox(height: 30),
              const Text(
                'Verification Pending',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF121415),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Your account is awaiting administrator approval. We are currently verifying your bank details and documents. You will be notified once you can access the dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF121415),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isChecking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Refresh Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _logout,
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
