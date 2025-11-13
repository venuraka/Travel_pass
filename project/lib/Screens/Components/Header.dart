import 'package:flutter/material.dart';

class RegistrationHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback? onBackPressed;
  final double topPadding; // ✅ Added variable for top padding

  const RegistrationHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleColor = const Color(0xFF05A664),
    this.onBackPressed,
    this.topPadding = 50.0, // ✅ Default padding value
  });

  @override
  Widget build(BuildContext context) {
    const Color darkBackground = Color(0xFF121415);

    return Container(
      color: darkBackground,
      child: Stack(
        children: [
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                ),
                SizedBox(height: topPadding), // ✅ Dynamic padding here
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}