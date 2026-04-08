import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Components/BottomBar.dart';
import 'Attendance.dart';
import 'PaymentDetails.dart';
import 'Passengers.dart';
import 'PaymentReminders.dart';
import 'Poll.dart';
import 'Settings.dart';
import 'StartJourney.dart';
import 'TodayPassengers.dart';
import 'Updates.dart';
import 'dart:async';
import '../../controllers/DriverDashboardController.dart'; // Added

const Color primaryGreen = Color(0xFF05A664);
const Color textDark = Color(0xFF121415);
const Color textGrey = Color(0xFF909090);
const Color bgGreenTint = Color(0xFFF1F8F5);

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 2;
  final DriverDashboardController _controller =
      DriverDashboardController(); // Added
  int _todayPassengerCount = 0; // Added state variable
  bool _isLoadingCount = true;
  bool _hasPollToday = false;
  int _pendingReminders = 0; // Notification count
  StreamSubscription? _countSubscription;
  StreamSubscription? _pollSubscription;
  StreamSubscription? _reminderSubscription;

  @override // Added initState
  void initState() {
    super.initState();
    _loadDashboardData();
    
    // Real-time stream for passenger count
    _countSubscription = _controller.getTodayPassengerCountStream().listen((count) {
      if (mounted) {
        setState(() {
          _todayPassengerCount = count;
          _isLoadingCount = false;
        });
      }
    });

    // Real-time stream for today's poll status
    _pollSubscription = _controller.getTodayPollStatusStream().listen((hasPoll) {
      if (mounted) {
        setState(() {
          _hasPollToday = hasPoll;
        });
      }
    });

    // Real-time stream for pending requests (reminders)
    _reminderSubscription = _controller.getPendingRequestsCountStream().listen((count) {
      if (mounted) {
        setState(() {
          _pendingReminders = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _countSubscription?.cancel();
    _pollSubscription?.cancel();
    _reminderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool isRefresh = false}) async {
    // Initial load for non-streaming data if any
    if (mounted) {
      setState(() {
        // _isLoadingCount = false; // Handled by stream now
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreenTint,
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

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const PassengerScreen();
      case 1:
        return const PaymentDetailsScreen();
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

  Widget _buildDashboardContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- Modern Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen, // Using green for greeting text
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Venuraka',
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: textDark,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // --- Soft Search Bar ---
               Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15.r,
                      offset: Offset(0, 5.h),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(Icons.search, color: primaryGreen, size: 24.r),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0.h),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- Section Title ---
               Text(
                "Overview",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 15),

              // --- Hero Card (Today's Passengers) ---
               _buildHeroCard(
                title: "Today's Passengers",
                value: _isLoadingCount
                    ? '...'
                    : '$_todayPassengerCount', // Updated
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TodaypassengersScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // --- Action Grid ---
              // Grouping actions together creates better visual organization
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: "Start Poll",
                      icon: Icons.bar_chart_rounded,
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PollScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionCard(
                      title: "Reminders",
                      icon: Icons.notifications_active_rounded,
                      color: Colors.orangeAccent,
                      badgeCount: _pendingReminders,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentRemindersScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // --- Start Journey Button (Poll-conditional) ---
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _hasPollToday ? primaryGreen.withOpacity(0.3) : const Color(0xFFB9E4D0).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (!_hasPollToday) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please make a poll for today first!"),
                          backgroundColor: Colors.orangeAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Hold the button to start the journey"),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onLongPress: _hasPollToday ? () async {
                    await _controller.startJourney();
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Startjourney()),
                      );
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasPollToday ? primaryGreen : const Color(0xFFB9E4D0),
                    foregroundColor: _hasPollToday ? Colors.white : primaryGreen.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _hasPollToday ? 'Start Journey' : 'Make a poll to start journey',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Icon(
                        _hasPollToday ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
                        size: 24.r,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }

  /// A special card for the most important metric
  Widget _buildHeroCard({
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryGreen, Color(0xFF048C54)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
           borderRadius: BorderRadius.circular(20.0.r),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.25),
              blurRadius: 15.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
                size: 28.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Smaller square cards for secondary actions
   Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color, // Pass a color to distinguish the icon
    int badgeCount = 0,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(20.0.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24.r),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -5.w,
                    top: -5.h,
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20.w,
                        minHeight: 20.h,
                      ),
                      child: Text(
                         badgeCount > 9 ? '9+' : '$badgeCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "Tap to view",
              style: TextStyle(fontSize: 12.sp, color: textGrey),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }
}
