import 'package:flutter/material.dart';
import '../../services/NotificationService.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Components/BottomBar.dart';
import 'Attendance.dart';
import 'AttendanceHistory.dart';
import 'CashHistory.dart';
import 'PaymentDetails.dart';
import 'PaymentHistory.dart';
import 'Passengers.dart';
import 'PaymentReminders.dart';
import 'Poll.dart';
import 'RegisterPassenger.dart';
import 'Settings.dart';
import 'StartJourney.dart';
import 'TodayPassengers.dart';
import 'UpdateRoute.dart';
import 'Updates.dart';
import 'dart:async';
import '../../controllers/DriverDashboardController.dart'; // Added
import '../../controllers/VoiceAssistantController.dart';

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
  String _driverName = 'Loading...';
  StreamSubscription? _nameSubscription;
  late final VoiceAssistantController _voiceController;
  double? _fabTop;
  double? _fabLeft;

  @override // Added initState
  void initState() {
    super.initState();
    _loadDashboardData();
    // Refresh push notification token for this driver
    PushNotificationService().updateTokenForDriver();
    
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

    // Real-time stream for driver name
    _nameSubscription = _controller.getDriverNameStream().listen((name) {
      if (mounted) {
        setState(() {
          _driverName = name;
        });
      }
    });
    _initVoiceController();
  }

  @override
  void dispose() {
    _countSubscription?.cancel();
    _pollSubscription?.cancel();
    _reminderSubscription?.cancel();
    _nameSubscription?.cancel();
    _voiceController.dispose();
    super.dispose();
  }

  void _initVoiceController() {
    _voiceController = VoiceAssistantController(
      onNavigate: (screen) {
        if (!mounted) return;
        if (screen == 'passengers') {
          setState(() { _selectedIndex = 0; });
        } else if (screen == 'payments') {
          setState(() { _selectedIndex = 1; });
        } else if (screen == 'dashboard') {
          setState(() { _selectedIndex = 2; });
        } else if (screen == 'updates') {
          setState(() { _selectedIndex = 3; });
        } else if (screen == 'attendance') {
          setState(() { _selectedIndex = 4; });
        } else if (screen == 'settings') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        } else if (screen == 'poll') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PollScreen()));
        } else if (screen == 'attendance_history') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
        } else if (screen == 'payment_history') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
        } else if (screen == 'cash_history') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CashHistoryScreen()));
        } else if (screen == 'register_passenger') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPassengerScreen()));
        } else if (screen == 'today_passengers') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaypassengersScreen()));
        } else if (screen == 'update_route') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateRouteScreen()));
        }
      },
      onStartJourney: () async {
        if (!mounted) return;
        
        // Final restriction check before starting journey via voice
        final int presentCount = await _controller.getTodayPassengerCount();
        if (presentCount == 0) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot start journey: No passengers are present!"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        await _controller.startJourney();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Startjourney()));
      },
    );
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
      body: Stack(
        children: [
          _getSelectedScreen(),
          _buildVoiceOverlay(),
          _buildDraggableVoiceButton(),
        ],
      ),
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

  Widget _buildDraggableVoiceButton() {
    // Initial position
    _fabTop ??= MediaQuery.of(context).size.height * 0.7;
    _fabLeft ??= MediaQuery.of(context).size.width - 80.w;

    return Positioned(
      top: _fabTop,
      left: _fabLeft,
      child: GestureDetector(
        onPanUpdate: (details) {
          final size = MediaQuery.of(context).size;
          setState(() {
            // Clamp top between status bar and bottom nav bar
            _fabTop = (_fabTop! + details.delta.dy).clamp(50.0, size.height - 180.h);
            // Clamp left between screen edges
            _fabLeft = (_fabLeft! + details.delta.dx).clamp(0.0, size.width - 60.w);
          });
        },
        onPanEnd: (details) {
          // Snap to nearest side (optional, similar to AssistiveTouch)
          setState(() {
            if (_fabLeft! + 30.w < MediaQuery.of(context).size.width / 2) {
              _fabLeft = 20.w;
            } else {
              _fabLeft = MediaQuery.of(context).size.width - 80.w;
            }
          });
        },
        child: FloatingActionButton(
          onPressed: () {
            if (_voiceController.isListening) {
              _voiceController.stopListening();
            } else {
              _voiceController.startListening();
            }
          },
          backgroundColor: primaryGreen,
          heroTag: 'voice_fab',
          child: ListenableBuilder(
            listenable: _voiceController,
            builder: (context, _) {
              return Icon(
                _voiceController.isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOverlay() {
    return ListenableBuilder(
      listenable: _voiceController,
      builder: (context, _) {
        if (!_voiceController.isListening && !_voiceController.isProcessing && _voiceController.aiResponse.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          bottom: 100.h, // Adjusted to be above bottom nav
          left: 20.w,
          right: 20.w,
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.r,
                  offset: Offset(0, 5.h),
                )
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_voiceController.isListening)
                      Row(
                        children: [
                          Icon(Icons.mic, color: Colors.redAccent, size: 20.r),
                          SizedBox(width: 8.w),
                          Text("Listening...", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        ],
                      ),
                    if (_voiceController.recognizedText.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text('"${_voiceController.recognizedText}"', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14.sp)),
                      ),
                    if (_voiceController.aiResponse.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(_voiceController.aiResponse, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 14.sp)),
                      ),
                  ],
                ),
                Positioned(
                  right: -10,
                  top: -10,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 18.r, color: Colors.grey),
                    onPressed: () => _voiceController.clearResponse(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                        _driverName,
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
                    if (_todayPassengerCount == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("At least one passenger must be present to start the journey."),
                          backgroundColor: Colors.redAccent,
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
                  onLongPress: (_hasPollToday && _todayPassengerCount > 0) ? () async {
                    await _controller.startJourney();
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Startjourney()),
                      );
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_hasPollToday && _todayPassengerCount > 0) ? primaryGreen : const Color(0xFFB9E4D0),
                    foregroundColor: (_hasPollToday && _todayPassengerCount > 0) ? Colors.white : primaryGreen.withOpacity(0.8),
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
