import 'package:flutter/material.dart';
import '../Components/Cards.dart';
import '../Components/Topic.dart';
import 'PaymentHistory.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final Color appGreen = const Color(0xFF05A664);

  List<Map<String, String>> latePayments = [
    {"name": "Vethum Ranasinghe", "place": "Miriswatta"},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta"},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta"},
  ];

  List<Map<String, String>> paidPassengers = [];

  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: appGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // 1. CHANGED: Removed horizontal padding here
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // --- Header (Added Padding) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PageHeader(
                        title: "Payment details",
                        subtitle: Text(
                          "${_selectedDate.toLocal()}".split(' ')[0],
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(Icons.calendar_today_outlined, color: appGreen, size: 28),
                            onPressed: () => _selectDate(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Late Payment Section Title (Added Padding) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
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
                    ),
                    const SizedBox(height: 10),

                    // --- Late Payment Swipers ---
                    for (int i = 0; i < latePayments.length; i++)
                      Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (direction) {
                          setState(() {
                            final person = latePayments.removeAt(i);
                            paidPassengers.add(person);
                          });
                        },
                        // Background stretches full width
                        background: Container(
                          color: appGreen,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        // 2. CHANGED: Wrapped the content in Padding so it stays aligned
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildLatePaymentRow(
                              appGreen, latePayments[i]["name"]!, latePayments[i]["place"]!),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // --- Paid Passengers Section Title (Added Padding) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
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
                    ),
                    const SizedBox(height: 10),

                    // --- Paid Passengers Cards (Added Padding) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InfoCard(
                        title: "Vethum Ranasinghe",
                        subtitle: "Miriswatta",
                        showTag: true,
                        trailing: _buildPaidTrailing(appGreen, "Rs 1000", "2 Days Ago"),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InfoCard(
                        title: "Vethum Ranasinghe",
                        subtitle: "Miriswatta",
                        showTag: false,
                        trailing: _buildPaidTrailing(appGreen, "Rs 1000", "2 Days Ago"),
                      ),
                    ),

                    for (int i = 0; i < paidPassengers.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: InfoCard(
                          title: paidPassengers[i]["name"]!,
                          subtitle: paidPassengers[i]["place"]!,
                          showTag: true,
                          trailing: _buildPaidTrailing(appGreen, "Rs 1000", "Paid Today"),
                        ),
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

  Widget _buildLatePaymentRow(Color color, String name, String location) {
    return Row(
      children: [
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
}