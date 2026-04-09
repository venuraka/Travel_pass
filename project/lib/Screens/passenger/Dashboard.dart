import 'dart:async';
import '../../services/NotificationService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../passenger/Updates.dart';
import '../passenger/PaymentHistory.dart';
import 'Attendance.dart';
import 'TrackVehicle.dart';
import '../../controllers/PassengerDashboardController.dart';
import '../../models/PassengerModel.dart';


// --- Constants (Unified with Driver Dashboard) ---
const Color primaryGreen = Color(0xFF05A664);
const Color textDark = Color(0xFF121415);
const Color textGrey = Color(0xFF909090);
const Color bgGreenTint = Color(0xFFF1F8F5); // Subtle green background
const Color cardColor = Colors.white;
const Color surfaceGreen = Color(0xFFE8F5EE); // Light green for card surfaces

class PassengerDashboardApp extends StatefulWidget {
  const PassengerDashboardApp({super.key});

  @override
  State<PassengerDashboardApp> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<PassengerDashboardApp> {
  final PassengerDashboardController _controller =
      PassengerDashboardController();

  bool _isLoading = true;
  String? _errorMessage;

  PassengerModel? _passenger;
  List<Map<String, dynamic>> _datesToMark = [];
  int _unreadAlertsCount = 0;
  String? _driverPhone;

  StreamSubscription? _unreadCountSubscription;
  StreamSubscription? _attendanceSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Refresh push notification token for this passenger
    PushNotificationService().updateTokenForPassenger();
  }


  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final data = await _controller.loadDashboardData();

    if (mounted) {
      if (data.containsKey('error')) {
        setState(() {
          _errorMessage = data['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _passenger = data['passenger'] as PassengerModel;
          _datesToMark = List<Map<String, dynamic>>.from(data['datesToMark']);
          _unreadAlertsCount = data['unreadCount'] as int? ?? 0;
          _driverPhone = data['driverPhone'] as String?;
          _isLoading = false;
        });

        // Initialize real-time unread alert count listener
        if (_unreadCountSubscription == null && _passenger != null) {
          _unreadCountSubscription = _controller
              .getUnreadAlertsCountStream(_passenger!.driverId)
              .listen((count) {
            if (mounted) {
              setState(() {
                _unreadAlertsCount = count;
              });
            }
          });
        }

        // Initialize real-time attendance dates listener
        if (_attendanceSubscription == null && _passenger != null) {
          _attendanceSubscription = _controller
              .getAttendanceDatesStream(_passenger!.uid, _passenger!.driverId)
              .listen((dates) {
            if (mounted) {
              setState(() {
                _datesToMark = dates;
              });
            }
          }, onError: (error) {
          });
        }


      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreenTint,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _loadData(isRefresh: true),
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- Modern Header (Simplified - Person icon removed) ---
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
                    _passenger?.name ?? 'Passenger',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // --- Soft Search Bar with Green Border ---
               Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0.r),
                  border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.05),
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

              // --- Today's Status Section ---
              if (_passenger?.driverId != null)
                StreamBuilder<Map<String, dynamic>>(
                  stream: _controller.getTodayStatusCombinedStream(
                    _passenger!.driverId,
                    _passenger!.uid,
                  ),
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    if (data == null || !data['hasPollToday']) {
                      return const SizedBox.shrink();
                    }

                    final bool isStarted = data['isStarted'];
                    final String status = data['status'];
                    final DateTime todayDate = data['date'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTodayStatusCard(isStarted, status, todayDate),
                        const SizedBox(height: 30),
                        if (isStarted) ...[
                          _buildFindVehicleButton(context, status == 'Present'),
                          const SizedBox(height: 35),
                        ],
                      ],
                    );
                  },
                ),


              // --- Overview Section ---
              Row(
                children: [
                   Text(
                    "Overview",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // --- Action Grid (Rows matching Driver style) ---
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: "Call Driver",
                      icon: Icons.call_rounded,
                      color: Colors.green,
                      description: "Voice call",
                      onTap: _handleCallDriver,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionCard(
                      title: "Alerts",
                      icon: Icons.notifications_active_rounded,
                      color: Colors.orangeAccent,
                      description: "Notifications",
                      badgeCount: _unreadAlertsCount,
                      onTap: _handleOpenAlerts,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: "Attendance",
                      icon: Icons.history_edu_rounded,
                      color: Colors.blueAccent,
                      description: "View history",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PassengerAttendaceScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionCard(
                      title: "Payments",
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.purpleAccent,
                      description: "Transactions",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- Attendance Selection Card ---
              _buildAttendanceCard(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Matching Driver Dashboard style action card
  int _selectedIndex = 0;
  final Set<String> _seenNotificationIds = {}; // Prevent duplicate alerts
  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
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
          border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.04),
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
              description,
              style: TextStyle(fontSize: 12.sp, color: textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(bool isStarted, String status, DateTime date) {
    bool isPresent = status == 'Present';
    bool isAbsent = status == 'Absent';
    bool isNotMarked = status == 'Not Marked';

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Attendance",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${date.day} ${_getMonthName(date.month)} ${date.year}",
                    style: TextStyle(fontSize: 12.sp, color: textGrey),
                  ),
                ],
              ),
              if (isStarted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14.r, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Text(
                        "Locked",
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusToggleButton(
                  label: "Present",
                  isActive: isPresent,
                  activeColor: primaryGreen,
                  isDisabled: isStarted,
                  onTap: () => _updateTodayStatus("Present", date),
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: _buildStatusToggleButton(
                  label: "Absent",
                  isActive: isAbsent,
                  activeColor: Colors.redAccent,
                  isDisabled: isStarted,
                  onTap: () => _updateTodayStatus("Absent", date),
                ),
              ),
            ],
          ),
          if (isStarted && isNotMarked)
            Padding(
              padding: EdgeInsets.only(top: 15.h),
              child: Text(
                "You didn't mark your attendance before the journey started.",
                style: TextStyle(fontSize: 12.sp, color: Colors.redAccent, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusToggleButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: 1.5.w,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : (isDisabled ? Colors.grey : textDark),
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  Future<void> _updateTodayStatus(String status, DateTime date) async {
    if (_passenger == null) return;
    
    // Show local feedback immediately if you want, but snapshots will handle it
    try {
      await _controller.markAttendance(
        passengerId: _passenger!.uid,
        driverId: _passenger!.driverId,
        date: date,
        status: status,
      );
    } catch (e) {
    }
  }

  Widget _buildFindVehicleButton(BuildContext context, bool isEnabled) {
    return Container(
      width: double.infinity,
      height: 65.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: isEnabled 
            ? [primaryGreen, const Color(0xFF048F56)]
            : [const Color(0xFFB9E4D0), const Color(0xFF90D5B9)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          if (isEnabled)
            BoxShadow(
              color: primaryGreen.withOpacity(0.3),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (isEnabled) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Hold the button to track vehicle"),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white, size: 18.r),
                    SizedBox(width: 10.w),
                    const Expanded(
                      child: Text("Please mark your attendance to enable tracking."),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onLongPress: isEnabled ? () async {
          if (mounted && _passenger != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrackVehicle(
                  driverId: _passenger!.driverId,
                  passengerId: _passenger!.uid,
                ),
              ),
            );
          }
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0.r),
          ),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Track Vehicle'),
            SizedBox(width: 10.w),
            Icon(Icons.arrow_forward_rounded,
            size: 30.r,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAttendanceCard() {
    return Container(
      padding: EdgeInsets.all(20.0.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mark Attendance',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          SizedBox(height: 15.h),
          ..._datesToMark.map((item) => _buildAttendanceDismissibleRow(item)),
          if (_datesToMark.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0.h),
              child: Center(
                child: Text(
                  'All caught up! 🎉',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 14.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDismissibleRow(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgGreenTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Dismissible(
        key: ValueKey(item['id']),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          String status = direction == DismissDirection.startToEnd ? 'Present' : 'Absent';
          Color statusColor = direction == DismissDirection.startToEnd ? Colors.green : Colors.red;
          bool? proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              title: const Text("Confirm Attendance"),
              content: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: "Are you sure you want to mark your attendance as "),
                    TextSpan(text: status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    TextSpan(text: " for ${item['label']}?"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return proceed ?? false;
        },
        onDismissed: (direction) async {
          String status = direction == DismissDirection.startToEnd ? 'Present' : 'Absent';
          
          setState(() {
            _datesToMark.remove(item);
          });
          
          try {
            if (_passenger != null) {
              await _controller.markAttendance(
                passengerId: _passenger!.uid,
                driverId: _passenger!.driverId,
                date: item['date'] as DateTime,
                status: status,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Attendance successfully marked as $status"),
                    duration: const Duration(seconds: 10), // 10 sec undo as requested
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: "UNDO",
                      textColor: Colors.yellowAccent,
                      onPressed: () async {
                        try {
                          await _controller.removeAttendance(
                            passengerId: _passenger!.uid,
                            date: item['date'] as DateTime,
                          );
                          _loadData(isRefresh: true);
                        } catch(e) {}
                      },
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            _loadData(isRefresh: true); // Revert on error
          }
        },
        background: _buildDismissBackground(Icons.check_circle_outline, "Present", Colors.green, true),
        secondaryBackground: _buildDismissBackground(Icons.cancel_outlined, "Absent", Colors.redAccent, false),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['label'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600, color: textDark),
              ),
              const Icon(Icons.swipe_outlined, size: 16, color: textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(IconData icon, String label, Color color, bool isLeft) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeft) Icon(icon, color: Colors.white),
          if (isLeft) const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (!isLeft) const SizedBox(width: 8),
          if (!isLeft) Icon(icon, color: Colors.white),
        ],
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

  Future<void> _handleCallDriver() async {
    if (_driverPhone != null && _driverPhone!.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: _driverPhone!);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    }
  }

  Future<void> _handleOpenAlerts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdatesScreen(driverId: _passenger?.driverId),
      ),
    );
    _loadData();
  }
}
