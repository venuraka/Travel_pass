import 'package:flutter/material.dart';
import '../Components/Cards.dart';


class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color appGreen = const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    // --- Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Payment details",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Icon(Icons.calendar_today_outlined, color: appGreen, size: 28),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- Late Payment Section ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Late Payment",
                        style: TextStyle(
                          color: appGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Late Payment Items (Using custom builder to avoid changing Card.dart)
                    _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),

                    const SizedBox(height: 20),

                    // --- Paid Passengers Section ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Paid Passengers",
                        style: TextStyle(
                          color: appGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Paid Passenger 1 (Standard InfoCard works here)
                    InfoCard(
                      title: "Vethum Ranasinghe",
                      subtitle: "Miriswatta",
                      showTag: true,
                      trailing: _buildPaidTrailing(appGreen, "Rs 1000", "2 Days Ago"),
                    ),

                    // Paid Passenger 2
                    InfoCard(
                      title: "Vethum Ranasinghe",
                      subtitle: "Miriswatta",
                      showTag: false,
                      trailing: _buildPaidTrailing(appGreen, "Rs 1000", "2 Days Ago"),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

          ],
        ),
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

  // Builds the Trailing widget for Paid Passengers (Price + Date)
  Widget _buildPaidTrailing(Color color, String price, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          price,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? color : Colors.grey.withOpacity(0.6),
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive ? color : Colors.grey.withOpacity(0.6),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        )
      ],
    );
  }
}