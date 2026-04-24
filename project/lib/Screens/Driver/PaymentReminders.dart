import 'package:flutter/material.dart';
import '../../controllers/DriverDashboardController.dart';
import '../Components/AppBar.dart';

class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({super.key});

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> {
  final Color appGreen = const Color(0xFF05A664);
  final Color bgGreenTint = const Color(0xFFF1F8F5);
  final DriverDashboardController _controller = DriverDashboardController();

  /// Handles the removal of a reminder and provides feedback
  Future<void> _handleAction(Map<String, dynamic> reminder, String action) async {
    if (action == "Paid by Cash") {
      await _controller.markAsPaidByCash(reminder);
    } else if (action == "Rejected") {
      await _controller.markAsRejected(reminder);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                action == "Rejected" ? Icons.close : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text("${reminder['name']} marked as $action"),
            ],
          ),
          backgroundColor: action == "Rejected" ? Colors.redAccent : appGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment Reminders',
      ),
      backgroundColor: bgGreenTint,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _controller.getMissedPaymentPassengersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = snapshot.data ?? [];

          if (reminders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Dismissible(
                key: Key(reminder['id']),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  final action = direction == DismissDirection.startToEnd ? "Paid by Cash" : "Reject";
                  final color = direction == DismissDirection.startToEnd ? appGreen : Colors.redAccent;
                  final name = reminder['name'] ?? 'Passenger';

                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text("Confirm $action", style: TextStyle(color: color)),
                        content: Text("Are you sure you want to mark $name's payment as $action?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.startToEnd) {
                    _handleAction(reminder, "Paid by Cash");
                  } else {
                    _handleAction(reminder, "Rejected");
                  }
                },
                // Swipe Right (Accept/Paid by Cash)
                background: Container(
                  color: appGreen,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 30),
                  child: const Row(
                    children: [
                      Icon(Icons.money, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Paid by Cash",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Swipe Left (Reject)
                secondaryBackground: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 30),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Reject",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.close, color: Colors.white),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildLatePaymentRow(reminder),
                ),
              );
            },
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
            "All payments are up to date",
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
  Widget _buildLatePaymentRow(Map<String, dynamic> reminder) {
    final name = reminder['name'] ?? 'Passenger';
    final location = reminder['pickupLocation'] ?? 'No location';
    final amount = reminder['totalAmount'] ?? 'Rs 0';
    final status = reminder['missedStatus'] ?? 'Pending';
    final phone = reminder['phone'] ?? '';

    return Row(
      children: [
        // Circular Bell Button (Send Reminder)
        GestureDetector(
          onTap: () async {
            final result = await _controller.sendPaymentReminder(reminder, amount);
            
            if (mounted) {
              if (result == "success") {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 10),
                        Text("Reminder sent to $name"),
                      ],
                    ),
                    backgroundColor: appGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (result.startsWith("cooldown")) {
                final hours = result.split("|")[1];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text("You already notified $name. Please wait $hours more hours.")),
                      ],
                    ),
                    backgroundColor: Colors.orangeAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: appGreen, width: 1),
              color: Colors.white,
            ),
            child: Icon(Icons.notifications_none, color: appGreen, size: 22),
          ),
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
                        style: TextStyle(fontSize: 12, color: appGreen, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        status,
                        style: TextStyle(fontSize: 12, color: appGreen, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Call Icon
                IconButton(
                  icon: Icon(Icons.phone, color: appGreen),
                  onPressed: () => _controller.callPassenger(phone),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}