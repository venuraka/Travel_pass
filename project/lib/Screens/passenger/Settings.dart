import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/Database.dart';
import '../Components/CustomSnackBar.dart';
import '../UserRegistration/Login.dart';
import '../Components/Header.dart';
import '../../controllers/AuthService.dart';

class PassengerSettingsScreen extends StatefulWidget {
  const PassengerSettingsScreen({super.key});

  @override
  State<PassengerSettingsScreen> createState() => _PassengerSettingsScreenState();
}

class _PassengerSettingsScreenState extends State<PassengerSettingsScreen> {
  final Color appGreen = const Color(0xFF05A664);
  final Color darkBg = const Color(0xFF121415);
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;



Future<void> _unsubscribe() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: const Text('Are you sure you want to unsubscribe from your current driver? This will remove your association with them.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Unsubscribe', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _dbService.unsubscribePassengerFromDriver(user.uid);
          if (mounted) {
            CustomSnackBar.showSuccess(context, "Successfully unsubscribed.");
            // After unsubscribing, they probably need to re-login or be redirected to a "Find Driver" state.
            // For now, let's just go back to dashboard which should handle the null driverId state.
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(context, "Unsubscribe failed: $e");
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(context, "Logout failed: $e");
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete your account? This action is permanent and will delete all your data including your balance and history.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');
      bool reauthSuccess = false;
      String? password;

      if (isGoogleUser) {
        // For Google users, we just call reauthenticate directly
        reauthSuccess = true; 
      } else {
        final TextEditingController passwordController = TextEditingController();
        final bool? dialogResult = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Identity'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please enter your password to confirm account deletion.'),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        reauthSuccess = dialogResult ?? false;
        password = passwordController.text;
      }

      if (reauthSuccess && (isGoogleUser || (password != null && password.isNotEmpty))) {
        setState(() => _isLoading = true);
        try {
          if (user != null) {
            final uid = user.uid;

            // 1. Delete Firestore Data
            await _dbService.deletePassengerData(uid);

            // 2. Delete Auth Account with Re-auth
            final AuthService authService = AuthService();
            await authService.deleteAccountWithReauth(password: password);

            if (mounted) {
              CustomSnackBar.showSuccess(context, "Account deleted successfully.");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          }
        } catch (e) {
          if (mounted) {
            CustomSnackBar.showError(context, "Authentication failed: Invalid password.");
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardTopPadding = screenHeight * 0.6; // Start lower for a smaller card

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'Account',
            subtitle: 'Management',
            subtitleColor: Color(0xFF05A664),
            topPadding: 50,
          ),

          // --- Info Icon Button ---
          Positioned(
            top: 50,
            right: 20,
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
              onSelected: (value) async {
                final Uri url = Uri.parse(value);
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  if (mounted) {
                    CustomSnackBar.showError(context, "Could not launch $value");
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: "https://venuraka.github.io/TravelPass-Additional-Information/",
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                      SizedBox(width: 10),
                      Text("Privacy Policy"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "https://venuraka.github.io/TravelPass-Additional-Information/contactus.html",
                  child: Row(
                    children: [
                      Icon(Icons.contact_support_outlined, color: Colors.green),
                      SizedBox(width: 10),
                      Text("Contact Us"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- Custom Non-Scrollable Card ---
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: screenHeight * 0.35, // Balanced position to avoid large empty gaps
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12, // Softer shadow for premium feel
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Profile Info Section ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF05A664).withOpacity(0.3),
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                const Color(0xFF05A664).withOpacity(0.1),
                            child: const Icon(Icons.person_rounded,
                                size: 36, color: Color(0xFF05A664)),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Profile",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: darkBg,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Manage your account & preferences",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 45), // Breathing room

                    // --- Section Title ---
                    Text(
                      "Security & Account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkBg.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Unsubscribe Button (Moved to Top) ---
                    _buildSettingTile(
                      icon: Icons.person_remove_rounded,
                      title: "Unsubscribe Driver",
                      subtitle: "Remove your current driver association",
                      color: Colors.orangeAccent,
                      onTap: _unsubscribe,
                    ),

                    const SizedBox(height: 16),

                    // --- Logout Button ---
                    _buildSettingTile(
                      icon: Icons.logout_rounded,
                      title: "Logout from Account",
                      subtitle: "Sign out securely from this device",
                      color: Colors.redAccent,
                      onTap: _logout,
                    ),

                    const SizedBox(height: 16),

                    // --- Delete Account Button ---
                    _buildSettingTile(
                      icon: Icons.delete_forever_rounded,
                      title: "Delete Account",
                      subtitle: "Permanently remove your account and data",
                      color: Colors.red,
                      onTap: _deleteAccount,
                    ),
                    const SizedBox(height: 40), // Extra space at bottom
                  ],
                ),
              ),
            ),
          ),
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF05A664)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(15),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }
}
