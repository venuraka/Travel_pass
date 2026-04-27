import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/SettingsController.dart'; // Import Controller
import '../Components/CustomSnackBar.dart'; // Import CustomSnackBar
import '../UserRegistration/Login.dart';
import 'UpdateRoute.dart';

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
  final SettingsController _controller =
      SettingsController(); // Controller Instance

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

                          // --- Logout Button ---
                          TextButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                            label: const Text(
                              'Logout from Account',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
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
}
