import 'package:flutter/material.dart';
import '../passenger/Updates.dart';
import '../passenger/PaymentHistory.dart';
import 'Attendance.dart';


// --- Color Palette (Updated and Finalized for Light Theme) ---
// 0xFF05A664 -> Primary Green (Action/Accent)
// 0xFF121415 -> Dark Text (Primary foreground/Text)
// 0xFFF8F9FC -> Very Light Background/Card Color (Unified light mode background)
const Color _primaryGreen = Color(0xFF05A664);
const Color _darkText = Color(0xFF121415);
const Color _secondaryGray = Color(0xFF909090); // Minor/Detail text color (Kept for contrast)
const Color _lightBackground = Color(0xFFF8F9FC); // Main background
const Color _cardColor = Colors.white; // Using pure white for cards/surfaces on the light background

// --- Mock Data for Attendance Marking (Date-based) ---
final List<Map<String, String>> todayDateList = [
  {'id': '2025-11-24', 'label': '2025-11-24', 'status': 'Pending'},
  {'id': '2025-11-23', 'label': '2025-11-23', 'status': 'Pending'},
  {'id': '2025-11-22', 'label': '2025-11-22', 'status': 'Pending'},
];

class PassengerDashboardApp extends StatefulWidget {
  const PassengerDashboardApp({super.key});

  @override
  State<PassengerDashboardApp> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<PassengerDashboardApp> {
  // Use a mutable list of date-based items for state management
  final List<Map<String, String>> _datesToMark = List.from(todayDateList);

  // Helper method to find the correct index for restoration (crucial for UNDO)
  int _findOriginalIndex(Map<String, String> item) {
    return todayDateList.indexWhere((i) => i['id'] == item['id']);
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
      body: SingleChildScrollView(
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PassengerAttendaceScreen()));
                    },
                  ),
                  _buildHistoryTile(
                    title: 'Payment History',
                    icon: Icons.account_balance_wallet_outlined,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentHistoryScreen()));
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
        onPressed: () {},
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
        child: const Text(
          'Track Vehicle',
        ),
      ),
    );
  }

  Widget _buildGreetingAndStatusCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good Morning,',
          style: TextStyle(
            fontSize: 16,
            color: _secondaryGray, // Secondary color for subtle text
            fontWeight: FontWeight.w500,
          ),
        ),
        const Text(
          'Venuraka',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _darkText, // Primary dark text
          ),
        ),
      ],
    );
  }

  Widget _buildQuickContactBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _contactIcon(Icons.call_outlined, 'Call', onPressed: () {
          // TODO: Implement call functionality
        }),
        _contactIcon(Icons.notifications_none, 'Alerts', onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => UpdatesScreen()));
        }),
      ],
    );
  }

  Widget _contactIcon(IconData icon, String label, {VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40), // For a circular ripple effect
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryGreen.withOpacity(0.1), // Very light green background
            ),
            child: Icon(icon, color: _primaryGreen, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: _secondaryGray, fontWeight: FontWeight.w500),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkText),
              ),
            ],
          ),
          // Thinner, lighter divider for separation
          const Divider(height: 25, thickness: 0.5, color: _secondaryGray),

          // Attendance list items (now date-based and dismissible)
          ..._datesToMark.map((item) =>
              _buildAttendanceDismissibleRow(item)
          ).toList(),

          if (_datesToMark.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: Text(
                  'All attendance marked for recent dates! 🎉',
                  style: TextStyle(color: _secondaryGray, fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDismissibleRow(Map<String, String> item) {
    final Key key = ValueKey(item['id']);
    final Color presentColor = _primaryGreen;
    final Color absentColor = Colors.red.shade600;

    // Use a unique index for restoration since the list position changes on removal
    // The original index in the static list is a reliable marker.
    final int originalIndex = _findOriginalIndex(item);
    late Map<String, String> dismissedItem = item; // Store dismissed item details

    return Dismissible(
      key: key,
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        String status = '';
        if (direction == DismissDirection.startToEnd) {
          status = 'Present';
        } else if (direction == DismissDirection.endToStart) {
          status = 'Absent';
        }

        // Remove the item from the state
        setState(() {
          _datesToMark.removeWhere((i) => i['id'] == item['id']);
        });

        // Show SnackBar with undo action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['label']} marked as $status.'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: _primaryGreen,
              onPressed: () {
                // Restore the item at its original position in the static list
                setState(() {
                  // Find the correct insertion point relative to the original static list
                  int insertIndex = 0;
                  for (int i = 0; i < todayDateList.length; i++) {
                    if (i == originalIndex) {
                      insertIndex = i;
                      break;
                    }
                    if (_datesToMark.contains(todayDateList[i])) {
                      insertIndex++;
                    }
                  }

                  // Insert the item at the calculated position
                  _datesToMark.insert(insertIndex, dismissedItem);
                });
              },
            ),
          ),
        );
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
        dateLabel: item['label']!,
        status: item['status']!,
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
                color: _darkText
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
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _darkText),
              ),
            ),
            // Updated color for arrow icon
            const Icon(Icons.arrow_forward_ios, size: 16, color: _secondaryGray),
          ],
        ),
      ),
    );
  }
}