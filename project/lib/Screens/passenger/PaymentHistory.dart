import 'package:flutter/material.dart';
import '../Components/AppBar.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  // Temporary demo list for payments
  final List<Map<String, dynamic>> payments = const [
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
    {"date": "2024/12/1", "amount": "Rs 1000"},
  ];

  @override
  Widget build(BuildContext context) {
    final Color appGreen = const Color(0xFF05A664);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Payments',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // --- Section 1: Arias Payment Card (Outstanding Payment) ---
              _buildSectionHeader("Arias Outstanding Payments", appGreen), // Changed header slightly
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                // Using the restyled card with new wordings
                child: _buildAriasPaymentCardRestyled(appGreen),
              ),

              const SizedBox(height: 30),

              // --- Section 2: Payments List Header ---
              _buildSectionHeader("Payments", appGreen),
              const SizedBox(height: 10),

              // --- Section 3: Payments List ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: payments.map((payment) {
                    return _buildPaymentRow(
                      date: payment["date"]!,
                      amount: payment["amount"]!,
                      color: appGreen,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- RESTYLED WIDGET: Wordings Updated for 'Yet to Pay' ---
  Widget _buildAriasPaymentCardRestyled(Color color) {
    const Color textColor = Colors.white;
    // Using a distinct color for outstanding payments, like Red,
    // but sticking to the green theme for consistency, just using the solid green.
    // If you prefer red for 'due', you can change the color: color to Colors.red in this widget.

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: color, // Retaining the green color theme
      child: Container(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount and Date (Highlighted Info)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Amount Due",
                      style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rs 1000",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Payment Due Date",
                      style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "2024/12/1",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for section titles (reused from your code)
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper widget for each payment row in the list
  Widget _buildPaymentRow({
    required String date,
    required String amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date (Slightly less prominent)
          Text(
            date,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          // Amount (Highlighted Green)
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}