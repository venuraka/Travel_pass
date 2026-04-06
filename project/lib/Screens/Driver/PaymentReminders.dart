import 'package:flutter/material.dart';
import '../Components/AppBar.dart';

class PaymentRemindersScreen extends StatelessWidget {
  const PaymentRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color appGreen = const Color(0xFF05A664);
    final Color bgGreenTint = const Color(0xFFF1F8F5);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment Reminders',
      ),
      backgroundColor: bgGreenTint,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // 1. CHANGED: Removed horizontal padding, kept vertical padding
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Late Payment Items
                  // I applied the padding fix to all items below

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    // 2. ADDED: Padding wrapper around the child
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

                  Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) {},
                    background: Container(
                      color: appGreen,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    ),
                  ),

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

  // Unchanged as requested
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