import 'package:flutter/material.dart';

// --- Color Palette (Reassigned for Light Theme) ---
const Color _primaryGreen = Color(0xFF05A664); // Primary action/accent color
const Color _darkText = Color(0xFF121415); // Primary text/button foreground
const Color _secondaryGray = Color(0xFF909090); // Minor/Detail text color
const Color _lightBackground = Color(0xFFF7F9FB); // Very light gray background
const Color _cardColor = Colors.white;

class PassengerDashboardApp extends StatelessWidget {
  const PassengerDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the attendance list
    final List<Map<String, dynamic>> attendanceData = [
      {'date': '2025/11/24', 'status': 'present'},
      {'date': '2025/11/23', 'status': 'present'},
      {'date': '2025/11/22', 'status': 'absent'},
    ];

    return Scaffold(
      // 1. MODIFICATION: Simple AppBar without title or actions for a cleaner look.
      appBar: AppBar(
        // The app bar is kept to manage status bar color, but made minimal.
        backgroundColor: _lightBackground, // Match the background
        elevation: 0,
        toolbarHeight: 0, // Make it invisible (only for status bar management)
      ),
      body: SingleChildScrollView(
        // Padding is moved inside the Column children to handle the top element flush
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 2. MODIFICATION: Greeting Card is now the first, primary element.
            // Padding added here to match the old body padding
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
                  // 3. Primary Action Button
                  _buildFindVehicleButton(context),
                  const SizedBox(height: 30),

                  // 4. Quick Contact Bar
                  _buildQuickContactBar(),
                  const SizedBox(height: 30),

                  // 5. Attendance Tracker Card
                  _buildAttendanceCard(attendanceData),
                  const SizedBox(height: 30),

                  // 6. History Action Tiles
                  _buildHistoryTile(
                    title: 'Attendance History',
                    icon: Icons.history_edu_outlined,
                    onPressed: () {},
                  ),
                  _buildHistoryTile(
                    title: 'Payment History',
                    icon: Icons.account_balance_wallet_outlined,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders (Light Theme) ---

  // PRIMARY ACTION: Uses the Near-Black for the background to create high contrast.
  Widget _buildFindVehicleButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            // Subtle, professional shadow
            color: _darkText.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          foregroundColor: _cardColor, // White text on dark button
          backgroundColor: _darkText, // Near-black for maximum impact
          padding: const EdgeInsets.symmetric(vertical: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Track Vehicle',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // GREETING/STATUS CARD: Clean white surface with high-contrast text.
  Widget _buildGreetingAndStatusCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New menu icon for a cleaner look without the full AppBar
        const Text(
          'Welcome Back,',
          style: TextStyle(
            fontSize: 16,
            color: _secondaryGray, // Gray for secondary text
            fontWeight: FontWeight.w500,
          ),
        ),
        const Text(
          'Venuraka',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _darkText, // Near-black for high contrast
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Lightest tint of the accent color
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  // QUICK CONTACT: Uses the Green for the icons to draw attention.
  Widget _buildQuickContactBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _contactIcon(Icons.call_outlined, 'Call'),
        _contactIcon(Icons.notifications_none, 'Alerts'),
      ],
    );
  }

  Widget _contactIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryGreen.withOpacity(0.1), // Subtle green background
          ),
          child: Icon(icon, color: _primaryGreen, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: _secondaryGray, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ATTENDANCE CARD: Clean, structured list on a white card.
  Widget _buildAttendanceCard(List<Map<String, dynamic>> attendanceData) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _secondaryGray.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with subtle Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mark Attendance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkText),
              ),
            ],
          ),
          const Divider(height: 25, color: _secondaryGray),

          // Attendance list items (Max 3 shown for dashboard)
          ...attendanceData.take(3).map((data) => _buildAttendanceRow(data['date'] as String, data['status'] == 'present')).toList(),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(String date, bool isPresent) {
    final Color statusColor = isPresent ? _primaryGreen : Colors.red.shade700;
    final String statusText = isPresent ? 'Present' : 'Absent';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _darkText),
          ),
          Row(
            children: [
              Icon(
                isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // HISTORY TILES: Minimalist list with subtle separators.
  Widget _buildHistoryTile({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _secondaryGray.withOpacity(0.2), // Light gray separator
              width: 0.5,
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
            const Icon(Icons.arrow_forward_ios, size: 16, color: _secondaryGray),
          ],
        ),
      ),
    );
  }
}