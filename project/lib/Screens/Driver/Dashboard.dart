import 'package:flutter/material.dart';
import '../../services/NotificationService.dart';
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

import '../../controllers/DriverDashboardController.dart';
import '../../controllers/VoiceAssistantController.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Components/CustomSnackBar.dart';
import 'AttendanceHistory.dart';
import 'PaymentHistory.dart';
import 'CashHistory.dart';
import 'NewPassenger.dart';
import 'TodayPassengers.dart';
import 'UpdateRoute.dart';


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
  final DriverDashboardController _controller = DriverDashboardController();
  int _todayPassengerCount = 0;
  bool _isLoadingCount = true;
  bool _hasPollToday = false;
  int _pendingReminders = 0;
  StreamSubscription? _countSubscription;
  StreamSubscription? _pollSubscription;
  StreamSubscription? _reminderSubscription;
  String _driverName = 'Loading...';
  StreamSubscription? _nameSubscription;

  double? _fabTop;
  double? _fabLeft;
  bool _isStartingJourney = false; // Guard to prevent duplicate StartJourney pushes
  bool _isJourneyActive = false; // Track if journey is already in progress
  bool _showVoiceAssistant = true;
  late VoiceAssistantController _voiceController;


  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    PushNotificationService().updateTokenForDriver();
    
    _countSubscription = _controller.getTodayPassengerCountStream().listen((count) {
      if (mounted) setState(() { _todayPassengerCount = count; _isLoadingCount = false; });
    });

    _pollSubscription = _controller.getTodayPollStatusStream().listen((hasPoll) {
      if (mounted) setState(() { _hasPollToday = hasPoll; });
    });

    _reminderSubscription = _controller.getMissedPaymentCountStream().listen((count) {
      if (mounted) setState(() { _pendingReminders = count; });
    });

    _nameSubscription = _controller.getDriverNameStream().listen((name) {
      if (mounted) setState(() { _driverName = name; });
    });

    _controller.getJourneyStatusStream().listen((isActive) {
      if (mounted) setState(() { _isJourneyActive = isActive; });
    });
    _loadAssistantSetting();
    _initVoiceController();
  }

  Future<void> _loadAssistantSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showVoiceAssistant = prefs.getBool('show_ai_assistant') ?? true;
      });
    }
  }

  void _initVoiceController() {
    _voiceController = VoiceAssistantController(
      onNavigate: (screen) async {
        if (!mounted) return;
        if (screen == 'passengers') setState(() { _selectedIndex = 0; });
        else if (screen == 'payments') setState(() { _selectedIndex = 1; });
        else if (screen == 'dashboard') setState(() { _selectedIndex = 2; });
        else if (screen == 'updates') setState(() { _selectedIndex = 3; });
        else if (screen == 'attendance') setState(() { _selectedIndex = 4; });
        else if (screen == 'settings') {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          _loadAssistantSetting();
        } else if (screen == 'poll') {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PollScreen()));
        } else if (screen == 'attendance_history') {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
        } else if (screen == 'payment_history') {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
        } else if (screen == 'cash_history') {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CashHistoryScreen()));
        } else if (screen == 'register_passenger') {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewPassengerScreen()));
        } else if (screen == 'today_passengers') {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaypassengersScreen()));
        } else if (screen == 'update_route') {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateRouteScreen()));
        }
      },
      onStartJourney: () async {
        if (!mounted || _isStartingJourney) return;
        setState(() => _isStartingJourney = true);
        try {
          final int presentCount = await _controller.getTodayPassengerCount();
          if (presentCount == 0) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot start journey: No passengers are present!"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
             return;
          }
          await _controller.startJourney(isRestart: !_isJourneyActive);
          if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const Startjourney()));
        } finally {
          if (mounted) setState(() => _isStartingJourney = false);
        }
      },
    );
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



  Future<void> _loadDashboardData() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreenTint,
      body: Stack(
        children: [
          _getSelectedScreen(),
          if (_showVoiceAssistant) ...[
            _buildVoiceOverlay(),
            _buildDraggableVoiceButton(),
          ],
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() { _selectedIndex = index; });
        },
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0: return const PassengerScreen();
      case 1: return const PaymentDetailsScreen();
      case 2: return _buildDashboardContent();
      case 3: return const UpdatesScreen();
      case 4: return const AttendanceScreen();
      default: return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          children: [
            // --- 1. Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${_getGreeting()},", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: primaryGreen)),
                      SizedBox(height: 4.h),
                      Text(_driverName, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildCircularIconButton(Icons.settings_outlined, () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  _loadAssistantSetting();
                }),
              ],
            ),
            
            const Spacer(flex: 1),

            // --- 2. Overview Title ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Overview", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textDark)),
            ),
            SizedBox(height: 12.h),

            // --- 3. Hero Card ---
            Expanded(
              flex: 10,
              child: _buildHeroCard(
                title: "Today's Passengers",
                value: _isLoadingCount ? '...' : '$_todayPassengerCount',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaypassengersScreen())),
              ),
            ),
            
            const Spacer(flex: 1),

            // --- 4. Action Grid ---
            Expanded(
              flex: 8,
              child: Row(
                children: [
                  Expanded(child: _buildActionCard(title: "Start Poll", icon: Icons.bar_chart_rounded, color: Colors.blueAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PollScreen())))),
                  const SizedBox(width: 15),
                  Expanded(child: _buildActionCard(title: "Reminders", icon: Icons.notifications_active_rounded, color: Colors.orangeAccent, badgeCount: _pendingReminders, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentRemindersScreen())))),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // --- 5. Main Action Button ---
            _buildStartJourneyButton(),
            
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: IconButton(icon: Icon(icon, color: textDark), onPressed: onPressed),
    );
  }

  Widget _buildHeroCard({required String title, required String value, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [primaryGreen, Color(0xFF048C54)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.25), blurRadius: 15.r, offset: Offset(0, 8.h))],
        ),
        child: Stack(
          children: [
            Positioned(right: -20, bottom: -20, child: Icon(Icons.people_alt_rounded, color: Colors.white.withOpacity(0.15), size: 120.r)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.white70, fontSize: 16.sp, fontWeight: FontWeight.w500)),
                SizedBox(height: 8.h),
                Text(value, style: TextStyle(color: Colors.white, fontSize: 44.sp, fontWeight: FontWeight.bold)),
                const Spacer(),
                Row(
                  children: [
                    Text("View list", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12.sp),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required Color color, int badgeCount = 0, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24.r), 
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15.r, offset: Offset(0, 5.h))]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centered content
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r), 
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), 
                  child: Icon(icon, color: color, size: 28.r)
                ),
                if (badgeCount > 0) 
                  Positioned(
                    right: -4.w, 
                    top: -4.h, 
                    child: Container(
                      padding: EdgeInsets.all(5.r), 
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), 
                      constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h), 
                      child: Text(badgeCount > 9 ? '9+' : '$badgeCount', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                    )
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: textDark)),
            SizedBox(height: 4.h),
            Text("View Details", style: TextStyle(fontSize: 11.sp, color: textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStartJourneyButton() {
    return Container(
      width: double.infinity,
      height: 65.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [BoxShadow(color: _hasPollToday ? primaryGreen.withOpacity(0.3) : const Color(0xFFB9E4D0).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (!_hasPollToday) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please make a poll for today first!"), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating));
          } else if (_todayPassengerCount == 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("At least one passenger must be present to start."), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hold the button to start the journey"), behavior: SnackBarBehavior.floating));
          }
        },
        onLongPress: (_hasPollToday && _todayPassengerCount > 0 && !_isStartingJourney) ? () async {
          if (_isStartingJourney) return;
          setState(() => _isStartingJourney = true);
          try {
            await _controller.startJourney(isRestart: !_isJourneyActive);
            if (mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => const Startjourney()));
          } finally {
            if (mounted) setState(() => _isStartingJourney = false);
          }
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: (_hasPollToday && _todayPassengerCount > 0) ? primaryGreen : const Color(0xFFB9E4D0),
          foregroundColor: (_hasPollToday && _todayPassengerCount > 0) ? Colors.white : primaryGreen.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.r)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isJourneyActive ? 'Resume Journey' : (_hasPollToday ? 'Start Journey' : 'Make a poll to start'), style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700)),
            SizedBox(width: 12.w),
            Icon(_isJourneyActive ? Icons.play_arrow_rounded : (_hasPollToday ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded), size: 24.r),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning";
    if (hour >= 12 && hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Widget _buildDraggableVoiceButton() {
    _fabTop ??= MediaQuery.of(context).size.height * 0.7;
    _fabLeft ??= MediaQuery.of(context).size.width - 80.w;
    return Positioned(
      top: _fabTop,
      left: _fabLeft,
      child: GestureDetector(
        onPanUpdate: (details) {
          final size = MediaQuery.of(context).size;
          setState(() {
            _fabTop = (_fabTop! + details.delta.dy).clamp(50.0, size.height - 180.h);
            _fabLeft = (_fabLeft! + details.delta.dx).clamp(0.0, size.width - 60.w);
          });
        },
        onPanEnd: (details) {
          setState(() {
            if (_fabLeft! + 30.w < MediaQuery.of(context).size.width / 2) _fabLeft = 20.w;
            else _fabLeft = MediaQuery.of(context).size.width - 80.w;
          });
        },
        child: FloatingActionButton(
          onPressed: () => _voiceController.isListening ? _voiceController.stopListening() : _voiceController.startListening(),
          backgroundColor: primaryGreen,
          heroTag: 'voice_fab',
          child: ListenableBuilder(
            listenable: _voiceController,
            builder: (context, _) => Icon(_voiceController.isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOverlay() {
    return ListenableBuilder(
      listenable: _voiceController,
      builder: (context, _) {
        if (!_voiceController.isListening && !_voiceController.isProcessing && _voiceController.aiResponse.isEmpty) return const SizedBox.shrink();
        return Positioned(
          bottom: 100.h,
          left: 20.w,
          right: 20.w,
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10.r, offset: Offset(0, 5.h))]),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_voiceController.isListening) Row(children: [Icon(Icons.mic, color: Colors.redAccent, size: 20.r), SizedBox(width: 8.w), Text("Listening...", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14.sp))]),
                    if (_voiceController.recognizedText.isNotEmpty) Padding(padding: EdgeInsets.only(top: 8.h), child: Text('"${_voiceController.recognizedText}"', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14.sp))),
                    if (_voiceController.aiResponse.isNotEmpty) Padding(padding: EdgeInsets.only(top: 8.h), child: Text(_voiceController.aiResponse, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 14.sp))),
                  ],
                ),
                Positioned(right: -10, top: -10, child: IconButton(icon: Icon(Icons.close, size: 18.r, color: Colors.grey), onPressed: () => _voiceController.clearResponse())),
              ],
            ),
          ),
        );
      },
    );
  }
}
