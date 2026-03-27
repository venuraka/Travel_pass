import 'package:flutter/material.dart';

class PassengerGetInPopup extends StatelessWidget {
  final String passengerName;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;

  const PassengerGetInPopup({
    super.key,
    required this.passengerName,
    required this.onCorrect,
    required this.onIncorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF121415),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Did $passengerName Get In to the\nvehicle",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.check_circle,
                  color: Colors.white,
                  onTap: onCorrect,
                ),
                _buildActionButton(
                  icon: Icons.cancel,
                  color: Colors.redAccent,
                  onTap: onIncorrect,
                ),
              ],
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onLongPress: () {
                // Implement call logic if needed
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.call, color: Color(0xFF05A664), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Hold To Get a Call...",
                    style: TextStyle(color: Color(0xFF05A664), fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        color: color,
        size: 70,
      ),
    );
  }
}
