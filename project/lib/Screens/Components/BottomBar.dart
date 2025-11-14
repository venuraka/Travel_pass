import 'package:flutter/material.dart';

// You can move these constants to a separate colors file later if you prefer
const Color primaryGreen = Color(0xFF05A664);
const Color textMuted = Color(0xFF121415);

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  // Helper function to create navigation items
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = index == selectedIndex;
    final Color color = isSelected ? primaryGreen : textMuted;
    final FontWeight fontWeight = isSelected ? FontWeight.bold : FontWeight.normal;

    return Expanded(
      child: InkWell(
        onTap: () {
          // Handle navigation logic here
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: fontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double contentHeight = 56.0;
    final double safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      height: contentHeight + safeAreaBottom,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.person_outline,
              label: 'Passenger',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.monetization_on_outlined,
              label: 'Money',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.home,
              label: 'Dashboard',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.campaign_outlined,
              label: 'Updates',
              index: 3,
            ),
            _buildNavItem(
              icon: Icons.how_to_reg_outlined,
              label: 'Attendance',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }
}