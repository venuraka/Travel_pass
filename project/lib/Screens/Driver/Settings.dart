import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/SettingsController.dart'; // Import Controller
import '../Components/CustomSnackBar.dart'; // Import CustomSnackBar
import '../UserRegistration/Login.dart';
import 'UpdateRoute.dart';
import '../../controllers/AuthService.dart';
import '../../services/Database.dart';

import '../Components/Header.dart';
import '../Components/Whitecard.dart';
// Assuming Header.dart exists, but I will build the specific header shown in the screenshot inline for accuracy.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Style Constants based on your code
  final Color appGreen = const Color(0xFF05A664);
  final Color darkBg = const Color(0xFF121415);
  final SettingsController _controller = SettingsController();
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  // State Variables
  int _monthlyAmount = 0;
  int _dailyAmount = 0;
  DateTime? _selectedDate;
  String _badgePreference = "Both"; // Current preference
  bool _isLoading = false; // Loading state
  bool _showVoiceAssistant = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _showVoiceAssistant = prefs.getBool('show_ai_assistant') ?? true;

      final driver = await _controller.getSettings();
      if (driver != null) {
        if (mounted) {
          setState(() {
            _selectedDate = driver.paymentDate;
            if (driver.monthlyPaymentAmount != null &&
                driver.monthlyPaymentAmount!.isNotEmpty) {
              _monthlyAmount = int.tryParse(driver.monthlyPaymentAmount!) ?? 0;
            }
            if (driver.dailyPaymentAmount != null &&
                driver.dailyPaymentAmount!.isNotEmpty) {
              _dailyAmount = int.tryParse(driver.dailyPaymentAmount!) ?? 0;
            }
            _badgePreference = driver.badgePreference;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logic to change amounts
  void _updateAmount(bool isMonthly, int change) {
    setState(() {
      if (isMonthly) {
        _monthlyAmount += change;
      } else {
        _dailyAmount += change;
      }
    });
  }

  // Logic for Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: appGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_ai_assistant', _showVoiceAssistant);

      await _controller.saveSettings(
        paymentDate: _selectedDate,
        monthlyAmount: _monthlyAmount.toString(),
        dailyAmount: _dailyAmount.toString(),
        badgePreference: _badgePreference,
      );
      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          "Settings saved & Passengers updated!",
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Failed to save settings: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete your account? This action is permanent and will delete all your profile data, routes, and history.'),
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
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
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
            await _dbService.deleteDriverData(uid);
            
            // 2. Delete Auth Account with Re-auth
            await _authService.deleteAccountWithReauth(password: password);
            
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
            CustomSnackBar.showError(context, "Authentication failed: ${isGoogleUser ? 'Google login failed' : 'Invalid password'}.");
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine height to make the card look like a bottom sheet (approx 50-60% down)
    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardTopPadding = screenHeight * 0.4; // Giving more space

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'Travel',
            subtitle: 'Settings',
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
                  debugPrint("Could not launch $value");
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

          // --- 2. White Card Content ---
          WhiteCard(
            topPadding: cardTopPadding,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF05A664)),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // --- Date Selection Row ---
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null
                                      ? 'Set Payment Date'
                                      : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                                  style: TextStyle(
                                    color: appGreen,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: appGreen,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // --- Monthly Payment Section ---
                          _buildAmountSection(
                            "Monthly Payment",
                            _monthlyAmount,
                            true,
                          ),

                          const SizedBox(height: 20),

                          // --- Daily Payment Section ---
                          _buildAmountSection(
                            "Daily Payment",
                            _dailyAmount,
                            false,
                          ),
                          const SizedBox(height: 30),
                          // --- Badge Preference Section ---
                          _buildBadgePreferenceSection(),
                          const SizedBox(height: 30),

                          // --- AI Assistant Toggle ---
                          _buildToggleSection(
                            "AI Voice Assistant",
                            _showVoiceAssistant,
                            (val) => setState(() => _showVoiceAssistant = val),
                          ),

                          const SizedBox(height: 40),

                          // --- Update Route Button ---
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UpdateRouteScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: appGreen, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              child: Text(
                                'Update Route',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: appGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // --- Done Button ---
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _saveSettings, // Call save method
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          const SizedBox(height: 15),

                          // --- Logout & Delete Section ---
                          const Divider(height: 40),
                          
                          _buildAccountTile(
                            icon: Icons.logout_rounded,
                            title: "Logout",
                            subtitle: "Sign out securely from your session",
                            color: Colors.redAccent,
                            onTap: _logout,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          _buildAccountTile(
                            icon: Icons.delete_forever_rounded,
                            title: "Delete Account",
                            subtitle: "Permanently wipe all your profile data",
                            color: Colors.red,
                            onTap: _deleteAccount,
                            isSolid: true,
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Improved Reusable Widget for Amount Sections
  Widget _buildAmountSection(String title, int amount, bool isMonthly) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: appGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCounterButton(
              icon: Icons.remove,
              onTap: () => _updateAmount(isMonthly, -100),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                'Rs $amount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildCounterButton(
              icon: Icons.add,
              onTap: () => _updateAmount(isMonthly, 100),
            ),
          ],
        ),
      ],
    );
  }

  // Helper widget for the circular Plus/Minus buttons
  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: appGreen, width: 1.2),
        ),
        child: Icon(icon, color: appGreen, size: 20),
      ),
    );
  }

  // New Widget for Badge Preference Selection
  Widget _buildBadgePreferenceSection() {
    return Column(
      children: [
        const Text(
          "Badge Display Preference",
          style: TextStyle(
            color: Color(0xFF05A664),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ["Daily", "Monthly", "Both"].map((option) {
              bool isSelected = _badgePreference == option;
              return GestureDetector(
                onTap: () => setState(() => _badgePreference = option),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? appGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: appGreen),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : appGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Helper widget for toggle sections
  Widget _buildToggleSection(
      String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF05A664),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: appGreen,
            activeTrackColor: appGreen.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isSolid = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSolid ? color : color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(15),
          color: isSolid ? color : color.withOpacity(0.05),
          boxShadow: isSolid ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSolid ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSolid ? Colors.white : color, size: 22),
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
                      color: isSolid ? Colors.white : color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSolid ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: isSolid ? Colors.white.withOpacity(0.8) : color.withOpacity(0.4), size: 14),
          ],
        ),
      ),
    );
  }
}
