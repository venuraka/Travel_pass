import 'package:flutter/material.dart';
import '../Components/AppBar.dart';
import '../Components/Cards.dart';
import '../Components/BottomBar.dart';

class PaymentDetailsScreen extends StatelessWidget {
  const PaymentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color appGreen = const Color(0xFF00C853);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment Reminders',
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Late Payment Items (Using custom builder to avoid changing Card.dart)
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Helper Methods ----------------

  // FIXED: Builds a custom card row so we don't need to change InfoCard code
  Widget _buildLatePaymentRow(Color color, String name, String location) {
    return Row(
      children: [
        // Circular Bell Button
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1),
            color: Colors.white,
          ),
          child: Icon(Icons.notifications_none, color: color, size: 22),
        ),

        // Custom Card Layout for Late Payments
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        "Rs 1000",
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "2 weeks late",
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.phone, color: color),
              ],
            ),
          ),
        ),
      ],
    );
  }
}