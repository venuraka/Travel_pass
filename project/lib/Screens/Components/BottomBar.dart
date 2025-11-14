import 'package:flutter/material.dart';

const Color primaryGreen = Color(0xFF05A664);
const Color textMuted = Color(0xFF121415);

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = index == selectedIndex;
    final Color color = isSelected ? primaryGreen : textMuted;
    final FontWeight weight = isSelected ? FontWeight.bold : FontWeight.normal;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Padding(
          // reduced top padding and kept a small bottom padding
          padding: const EdgeInsets.only(top: 0, bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: weight,
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
    final double height = 70 + MediaQuery.of(context).padding.bottom;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(icon: Icons.person_outline, label: 'Passenger', index: 0),
          _buildNavItem(icon: Icons.monetization_on_outlined, label: 'Money', index: 1),
          _buildNavItem(icon: Icons.home, label: 'Dashboard', index: 2),
          _buildNavItem(icon: Icons.campaign_outlined, label: 'Updates', index: 3),
          _buildNavItem(icon: Icons.how_to_reg_outlined, label: 'Attendance', index: 4),
        ],
      ),
    );
  }
}