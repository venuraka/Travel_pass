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
import 'Settings.dart';
import '../../utils/AuthWrapper.dart';


const Color primaryGreen = Color(0xFF05A664);
const Color textDark = Color(0xFF121415);
const Color textGrey = Color(0xFF909090);
const Color bgGreenTint = Color(0xFFF1F8F5);
const Color cardColor = Colors.white;

class PassengerDashboardApp extends StatefulWidget {
  const PassengerDashboardApp({super.key});

  @override
  State<PassengerDashboardApp> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<PassengerDashboardApp> {
  final PassengerDashboardController _controller = PassengerDashboardController();
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
    PushNotificationService().updateTokenForPassenger();
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (!isRefresh) setState(() { _isLoading = true; _errorMessage = null; });
    final data = await _controller.loadDashboardData();
    if (mounted) {
      if (data.containsKey('error')) setState(() { _errorMessage = data['error']; _isLoading = false; });
      else {
        setState(() {
          _passenger = data['passenger'] as PassengerModel;
          _datesToMark = List<Map<String, dynamic>>.from(data['datesToMark']);
          _unreadAlertsCount = data['unreadCount'] as int? ?? 0;
          _driverPhone = data['driverPhone'] as String?;
          _isLoading = false;
        });
        if (_unreadCountSubscription == null && _passenger != null) {
          _unreadCountSubscription = _controller.getUnreadAlertsCountStream(_passenger!.driverId).listen((count) {
            if (mounted) setState(() { _unreadAlertsCount = count; });
          });
        }
        if (_attendanceSubscription == null && _passenger != null) {
          _attendanceSubscription = _controller.getAttendanceDatesStream(_passenger!.uid, _passenger!.driverId).listen((dates) {
            if (mounted) setState(() { _datesToMark = dates; });
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreenTint,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: () => _loadData(isRefresh: true),
          child: _isLoading
              ? const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 500,
                    child: Center(
                        child: CircularProgressIndicator(color: primaryGreen)),
                  ),
                )
              : _errorMessage != null
                  ? (_errorMessage == 'No driver assigned'
                      ? _buildNoDriverView()
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 500,
                            child: Center(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(color: Colors.red))),
                          ),
                        ))
                  : _buildDashboardContent(),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_getGreeting()},',
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: primaryGreen)),
                              SizedBox(height: 4.h),
                              Text(_passenger?.name ?? 'Passenger',
                                  style: TextStyle(
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                      letterSpacing: -0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        _buildCircularIconButton(
                            Icons.settings_outlined, () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PassengerSettingsScreen(),
                            ),
                          );
                          _loadData(isRefresh: true);
                        }),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // --- 2. Today's Status ---
                    if (_passenger?.driverId != null)
                      StreamBuilder<Map<String, dynamic>>(
                        stream: _controller.getTodayStatusCombinedStream(
                            _passenger!.driverId, _passenger!.uid),
                        builder: (context, snapshot) {
                          final data = snapshot.data;
                          if (data == null || !data['hasPollToday'])
                            return const SizedBox.shrink();
                          final bool isStarted = data['isStarted'];
                          final String status = data['status'];
                          final DateTime todayDate = data['date'];
                          return Column(
                            children: [
                              _buildTodayStatusCard(isStarted, status, todayDate),
                              if (isStarted) ...[
                                SizedBox(height: 12.h),
                                _buildFindVehicleButton(context, status == 'Present'),
                              ],
                              SizedBox(height: 24.h),
                            ],
                          );
                        },
                      ),

                    // --- 3. Overview Grid ---
                    Text("Overview",
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                    SizedBox(height: 12.h),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15.w,
                      mainAxisSpacing: 15.h,
                      childAspectRatio: 1.1,
                      children: [
                        _buildActionCard(
                            title: "Call Driver",
                            icon: Icons.call_rounded,
                            color: Colors.green,
                            description: "Voice call",
                            onTap: _handleCallDriver),
                        _buildActionCard(
                            title: "Alerts",
                            icon: Icons.notifications_active_rounded,
                            color: Colors.orangeAccent,
                            description: "Notifications",
                            badgeCount: _unreadAlertsCount,
                            onTap: _handleOpenAlerts),
                        _buildActionCard(
                            title: "Attendance",
                            icon: Icons.history_edu_rounded,
                            color: Colors.blueAccent,
                            description: "View history",
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PassengerAttendaceScreen()))),
                        _buildActionCard(
                            title: "Payments",
                            icon: Icons.account_balance_wallet_rounded,
                            color: Colors.purpleAccent,
                            description: "Transactions",
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PaymentHistoryScreen()))),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // --- 4. Attendance Selection Card ---
                    _buildAttendanceCard(),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          );
        },
      );
  }

  Widget _buildCircularIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: IconButton(icon: Icon(icon, color: textDark), onPressed: onPressed),
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required Color color, required String description, int badgeCount = 0, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.r), border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1.w), boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.04), blurRadius: 15.r, offset: Offset(0, 5.h))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Perfectly centered
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(padding: EdgeInsets.all(10.r), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24.r)),
                if (badgeCount > 0) Positioned(right: -4.w, top: -4.h, child: Container(padding: EdgeInsets.all(5.r), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h), child: Text(badgeCount > 9 ? '9+' : '$badgeCount', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
              ],
            ),
            SizedBox(height: 10.h),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: textDark)),
            Text(description, style: TextStyle(fontSize: 11.sp, color: textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(bool isStarted, String status, DateTime date) {
    bool isPresent = status == 'Present';
    bool isAbsent = status == 'Absent';
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1.w),
          boxShadow: [
            BoxShadow(
                color: primaryGreen.withOpacity(0.05),
                blurRadius: 15.r,
                offset: Offset(0, 5.h))
          ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Today's Attendance",
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textDark)),
                Text("${date.day} ${_getMonthName(date.month)} ${date.year}",
                    style: TextStyle(fontSize: 12.sp, color: textGrey)),
              ]),
              if (isStarted)
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: Row(children: [
                      Icon(Icons.lock_outline_rounded, size: 14.r, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Text("Locked",
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600))
                    ])),
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
                      onTap: () => _updateTodayStatus("Present", date))),
              SizedBox(width: 15.w),
              Expanded(
                  child: _buildStatusToggleButton(
                      label: "Absent",
                      isActive: isAbsent,
                      activeColor: Colors.redAccent,
                      isDisabled: isStarted,
                      onTap: () => _updateTodayStatus("Absent", date))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggleButton({required String label, required bool isActive, required Color activeColor, required bool isDisabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: EdgeInsets.symmetric(vertical: 12.h), decoration: BoxDecoration(color: isActive ? activeColor : Colors.white, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: isActive ? activeColor : Colors.grey.shade300, width: 1.5.w)), child: Center(child: Text(label, style: TextStyle(color: isActive ? Colors.white : (isDisabled ? Colors.grey : textDark), fontWeight: FontWeight.bold, fontSize: 14.sp)))),
    );
  }

  Widget _buildFindVehicleButton(BuildContext context, bool isEnabled) {
    return Container(
      width: double.infinity,
      height: 55.h,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), gradient: LinearGradient(colors: isEnabled ? [primaryGreen, const Color(0xFF048F56)] : [const Color(0xFFB9E4D0), const Color(0xFF90D5B9)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [if (isEnabled) BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 15.r, offset: Offset(0, 8.h))]),
      child: ElevatedButton(
        onPressed: () {
          if (isEnabled) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hold to track vehicle"), behavior: SnackBarBehavior.floating));
          else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mark attendance to enable tracking."), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
        },
        onLongPress: isEnabled ? () { if (_passenger != null) Navigator.push(context, MaterialPageRoute(builder: (_) => TrackVehicle(driverId: _passenger!.driverId, passengerId: _passenger!.uid))); } : null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)), elevation: 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Track Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 8.w), Icon(Icons.location_on_rounded, color: Colors.white, size: 20.r)]),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 20.r,
                offset: Offset(0, 8.h))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Mark Attendance',
              style:
                  TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: textDark)),
          SizedBox(height: 12.h),
          _datesToMark.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Center(
                      child: Text('All caught up! 🎉',
                          style: TextStyle(
                              color: textGrey,
                              fontSize: 14.sp,
                              fontStyle: FontStyle.italic))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _datesToMark.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) =>
                      _buildAttendanceDismissibleRow(_datesToMark[index]),
                ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDismissibleRow(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(color: bgGreenTint, borderRadius: BorderRadius.circular(16.r)),
      child: Dismissible(
        key: ValueKey(item['id']),
        onDismissed: (direction) async {
          String status = direction == DismissDirection.startToEnd ? 'Present' : 'Absent';
          setState(() { _datesToMark.remove(item); });
          try {
            if (_passenger != null) await _controller.markAttendance(passengerId: _passenger!.uid, driverId: _passenger!.driverId, date: item['date'] as DateTime, status: status);
          } catch (e) { _loadData(isRefresh: true); }
        },
        background: _buildDismissBackground(Icons.check_circle_outline, "Present", Colors.green, true),
        secondaryBackground: _buildDismissBackground(Icons.cancel_outlined, "Absent", Colors.redAccent, false),
        child: Padding(padding: EdgeInsets.all(16.r), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)), const Icon(Icons.swipe_outlined, size: 16, color: textGrey)])),
      ),
    );
  }

  Widget _buildDismissBackground(IconData icon, String label, Color color, bool isLeft) {
    return Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16.r)), alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight, padding: EdgeInsets.symmetric(horizontal: 20.w), child: Row(mainAxisSize: MainAxisSize.min, children: [if (isLeft) Icon(icon, color: Colors.white, size: 20.r), SizedBox(width: 8.w), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), if (!isLeft) ...[SizedBox(width: 8.w), Icon(icon, color: Colors.white, size: 20.r)]]));
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning";
    if (hour >= 12 && hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Future<void> _updateTodayStatus(String status, DateTime date) async {
    if (_passenger == null) return;
    try { await _controller.markAttendance(passengerId: _passenger!.uid, driverId: _passenger!.driverId, date: date, status: status); } catch (e) {}
  }

  Future<void> _handleCallDriver() async {
    if (_driverPhone != null && _driverPhone!.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: _driverPhone!);
      if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
    }
  }

  Future<void> _handleOpenAlerts() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdatesScreen(driverId: _passenger?.driverId)));
    _loadData();
  }

  Widget _buildNoDriverView() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_accounts_rounded,
                    size: 80, color: Colors.orangeAccent),
                const SizedBox(height: 24),
                const Text(
                  'No Driver Assigned',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'It looks like you are not currently assigned to any driver. This usually happens if you have unsubscribed or your driver has removed you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textGrey),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        await _controller.resetRegistration();
                        if (mounted) {
                          // Navigate back to AuthWrapper to re-trigger role check
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthWrapper()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                            _errorMessage = "Failed to reset registration: $e";
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Go to Registration',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
