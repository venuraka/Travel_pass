import 'package:flutter/material.dart';
import '../Components/BottomBar.dart';
import 'Attendance.dart';
import 'Money.dart';
import 'Passengers.dart';
import 'Updates.dart';

const Color primaryGreen = Color(0xFF05A664);
const Color textMuted = Color(0xFF121415);

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 2; // default Dashboard

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedScreen(),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  /// Returns the widget for the currently selected tab
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const PassengerScreen();
      case 1:
        return const MoneyScreen();
      case 2:
        return _buildDashboardContent();
      case 3:
        return const UpdatesScreen();
      case 4:
        return const AttendanceScreen();
      default:
        return _buildDashboardContent();
    }
  }

  /// Dashboard content (your original widgets)
  Widget _buildDashboardContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- Header ---
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hi Venuraka',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF121415),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: primaryGreen,
                        size: 24,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // --- Search Bar ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: primaryGreen, width: 1.5),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.black54),
                    prefixIcon: Icon(Icons.search, color: primaryGreen),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.0),
                  ),
                ),
              ),

              const SizedBox(height: 70),

              // --- Metric Cards ---
              _buildMetricCard(title: "Today's Passengers", value: '27', hasBorder: true, isPrimaryColor: true),
              const SizedBox(height: 25),
              _buildMetricCard(title: "Start a Poll", icon: Icons.bar_chart, hasBorder: true, isPrimaryColor: false),
              const SizedBox(height: 25),
              _buildPaymentReminderCard(),
              const SizedBox(height: 100),

              // --- Start Journey Button ---
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: SizedBox(
                    width: 300,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                        shadowColor: primaryGreen.withOpacity(0.5),
                      ),
                      child: const Text(
                        'Start Journey',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    String? value,
    IconData? icon,
    required bool hasBorder,
    required bool isPrimaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: hasBorder ? Border.all(color: primaryGreen, width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              )),
          if (value != null)
            Text(value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isPrimaryColor ? primaryGreen : Colors.black87,
                ))
          else if (icon != null)
            Icon(icon, color: primaryGreen, size: 30),
        ],
      ),
    );
  }

  Widget _buildPaymentReminderCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: primaryGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Reminders',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black54),
              children: [
                TextSpan(
                  text: 'Venuraka ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen),
                ),
                TextSpan(text: 'has to pay ', style: TextStyle(color: Colors.black54)),
                TextSpan(
                  text: 'LKR 1000/=',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}