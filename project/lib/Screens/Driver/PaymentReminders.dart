import 'package:flutter/material.dart';
import '../Components/AppBar.dart';

class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({super.key});

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> {
  final Color appGreen = const Color(0xFF05A664);
  final Color bgGreenTint = const Color(0xFFF1F8F5);

  // Sample data for reminders - Convert to state-managed list
  final List<Map<String, String>> _reminders = List.generate(
    10,
    (index) => {
      "id": "rem_$index",
      "name": "Vethum Ranasinghe",
      "location": "Miriswatta",
      "amount": "Rs 1000",
      "status": "2 weeks late",
    },
  );

  /// Handles the removal of a reminder and provides feedback
  void _removeReminder(int index, String action) {
    final removedItem = _reminders[index];
    setState(() {
      _reminders.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${removedItem['name']} marked as $action"),
        backgroundColor: action == "Rejected" ? Colors.redAccent : appGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment Reminders',
      ),
      backgroundColor: bgGreenTint,
      body: _reminders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return Dismissible(
                  key: Key(reminder['id']!),
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      _removeReminder(index, "Paid by Cash");
                    } else {
                      _removeReminder(index, "Rejected");
                    }
                  },
                  // Swipe Right (Accept/Paid by Cash)
                  background: Container(
                    color: appGreen,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 30),
                    child: const Text(
                      "Paid by Cash",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Swipe Left (Reject)
                  secondaryBackground: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 30),
                    child: const Text(
                      "Reject",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildLatePaymentRow(
                      appGreen,
                      reminder['name']!,
                      reminder['location']!,
                      reminder['amount']!,
                      reminder['status']!,
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// UI for when all reminders are cleared
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: appGreen.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            "No pending reminders",
            style: TextStyle(
              fontSize: 18, 
              color: Colors.grey, 
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build each reminder row
  Widget _buildLatePaymentRow(Color color, String name, String location, String amount, String status) {
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
                        amount,
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        status,
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