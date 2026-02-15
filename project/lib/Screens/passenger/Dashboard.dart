import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../passenger/Updates.dart';
import '../passenger/PaymentHistory.dart';
import 'Attendance.dart';
import 'TrackVehicle.dart';
import '../../controllers/PassengerDashboardController.dart';
import '../../models/PassengerModel.dart';

// --- Color Palette (Updated and Finalized for Light Theme) ---
// 0xFF05A664 -> Primary Green (Action/Accent)
// 0xFF121415 -> Dark Text (Primary foreground/Text)
// 0xFFF8F9FC -> Very Light Background/Card Color (Unified light mode background)
// const Color _primaryGreen = Color(0xFF05A664);
const Color _primaryGreen = Color(0xFF05A664);
const Color _darkText = Color(0xFF121415);
const Color _secondaryGray = Color(
  0xFF909090,
); // Minor/Detail text color (Kept for contrast)
const Color _lightBackground = Color(0xFFF8F9FC); // Main background
const Color _cardColor =
    Colors.white; // Using pure white for cards/surfaces on the light background

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
          // We can also store the attendanceDoc if needed for history view
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Unified light background color
      backgroundColor: _lightBackground,
      appBar: AppBar(
        backgroundColor: _lightBackground,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Greeting Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildGreetingAndStatusCard(),
                  ),
                  const SizedBox(height: 30),

                  // All subsequent elements are wrapped in padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Primary Action Button
                        _buildFindVehicleButton(context),
                        const SizedBox(height: 30),

                        // Quick Contact Bar
                        _buildQuickContactBar(),
                        const SizedBox(height: 30),

                        // ATTENDANCE CARD - NOW DATE-BASED
                        _buildAttendanceCard(),
                        const SizedBox(height: 30),

                        // History Action Tiles
                        _buildHistoryTile(
                          title: 'Attendance History',
                          icon: Icons.history_edu_outlined,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PassengerAttendaceScreen(),
                              ),
                            );
                          },
                        ),
                        _buildHistoryTile(
                          title: 'Payment History',
                          icon: Icons.account_balance_wallet_outlined,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- Widget Builders ---

  Widget _buildFindVehicleButton(BuildContext context) {
    return Container(
      // Modern, subtle shadow for primary actions
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrackVehicle()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: _cardColor, // White text on green button
          padding: const EdgeInsets.symmetric(vertical: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        child: const Text('Track Vehicle'),
      ),
    );
  }

  Widget _buildGreetingAndStatusCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: TextStyle(
                fontSize: 16,
                color: _secondaryGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _passenger?.name ?? 'Passenger',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: _darkText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickContactBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _contactIcon(
          Icons.call_outlined,
          'Call',
          onPressed: () async {
            if (_driverPhone != null && _driverPhone!.isNotEmpty) {
              final Uri launchUri = Uri(scheme: 'tel', path: _driverPhone!);
              try {
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Could not launch dialer.")),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error launching call: $e")),
                  );
                }
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Driver phone number not available."),
                ),
              );
            }
          },
        ),
        _contactIcon(
          Icons.notifications_none,
          'Alerts',
          badgeCount: _unreadAlertsCount,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UpdatesScreen(driverId: _passenger?.driverId),
              ),
            );
            // Refresh data when returning to update badge
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _contactIcon(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40), // For a circular ripple effect
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryGreen.withOpacity(
                    0.1,
                  ), // Very light green background
                ),
                child: Icon(icon, color: _primaryGreen, size: 30),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: _secondaryGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _cardColor, // Pure white surface
        borderRadius: BorderRadius.circular(16),
        // Subtle, high-quality shadow for card separation
        boxShadow: [
          BoxShadow(
            color: _darkText.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mark Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ],
          ),
          // Thinner, lighter divider for separation
          const Divider(height: 25, thickness: 0.5, color: _secondaryGray),

          // Attendance list items (now date-based and dismissible)
          ..._datesToMark.map((item) => _buildAttendanceDismissibleRow(item)),

          if (_datesToMark.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: Text(
                  'All attendance marked for recent dates! 🎉',
                  style: TextStyle(
                    color: _secondaryGray,
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
    final Key key = ValueKey(item['id']);
    final Color presentColor = _primaryGreen;
    final Color absentColor = Colors.red.shade600;

    return Dismissible(
      key: key,
      direction: DismissDirection.horizontal,
      onDismissed: (direction) async {
        String status = '';
        if (direction == DismissDirection.startToEnd) {
          status = 'Present';
        } else if (direction == DismissDirection.endToStart) {
          status = 'Absent';
        }

        // Optimistically remove from UI
        final removedItem = item;
        final removedIndex = _datesToMark.indexOf(item);

        setState(() {
          _datesToMark.remove(item);
        });

        // Call Controller to save
        try {
          if (_passenger != null) {
            await _controller.markAttendance(
              passengerId: _passenger!.uid,
              driverId: _passenger!.driverId,
              date: item['date'] as DateTime,
              status: status,
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item['label']} marked as $status.')),
            );
          }
        } catch (e) {
          // Revert on error (optional, but good UX)
          if (mounted) {
            setState(() {
              _datesToMark.insert(removedIndex, removedItem);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error marking attendance: $e")),
            );
          }
        }
      },

      // Swipe RIGHT (Mark Present)
      background: Container(
        decoration: BoxDecoration(
          color: presentColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: _cardColor),
            SizedBox(width: 10),
            Text(
              'Mark Present',
              style: TextStyle(color: _cardColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),

      // Swipe LEFT (Mark Absent)
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: absentColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Mark Absent',
              style: TextStyle(color: _cardColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 10),
            Icon(Icons.cancel_outlined, color: _cardColor),
          ],
        ),
      ),

      // The main content of the row
      child: _buildAttendanceRowContent(
        dateLabel: item['label']! as String,
        status: item['status']! as String,
      ),
    );
  }

  Widget _buildAttendanceRowContent({
    required String dateLabel,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor, // Pure white for the content row
        borderRadius: BorderRadius.circular(12),
        // Finer border for a cleaner look
        border: Border.all(color: _secondaryGray.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Display the date/label in YYYY-MM-DD format
          Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              // Slightly brighter badge color
              color: _secondaryGray.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _secondaryGray, // Subtle text color for status badge
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      // Change background color on tap for feedback
      splashColor: _primaryGreen.withOpacity(0.05),
      highlightColor: _primaryGreen.withOpacity(0.02),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          border: Border(
            // Cleaner, thinner bottom border
            bottom: BorderSide(
              color: _secondaryGray.withOpacity(0.15),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primaryGreen, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ),
            // Updated color for arrow icon
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: _secondaryGray,
            ),
          ],
        ),
      ),
    );
  }
}
