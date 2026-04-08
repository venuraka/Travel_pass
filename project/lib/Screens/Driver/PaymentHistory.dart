import 'package:flutter/material.dart';
import '../Components/AppBar.dart';
import '../Components/Cards.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  // Temporary demo lists
  List<Map<String, dynamic>> PaidPassenger = [
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": false},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
  ];

  List<Map<String, dynamic>> AriasPayment = [
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": false},
    {"name": "Vethum Ranasinghe", "place": "Miriswatta", "tag": true},
  ];



  @override
  Widget build(BuildContext context) {
    final Color appGreen = const Color(0xFF05A664);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Payment History',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const SizedBox(height: 20),

            // --- Section 2: Today’s Passengers ---
            _buildSectionHeader("Aireas Payments", appGreen),

            for (int i = 0; i < PaidPassenger.length; i++)
              Dismissible(
                key: Key("payment_$i"),
                direction: DismissDirection.startToEnd, // RIGHT ONLY
                onDismissed: (direction) {
                  setState(() {
                    final person = PaidPassenger.removeAt(i);
                    AriasPayment.add(person);
                  });
                },
                background: Container(
                  color: const Color(0xFF05A664),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                child: InfoCard(
                  title: PaidPassenger[i]["name"],
                  subtitle: PaidPassenger[i]["place"],
                  showTag: PaidPassenger[i]["tag"],
                  trailing: _buildPhoneIcon(appGreen),
                ),
              ),
            const SizedBox(height: 30),
            // --- Section 1: Not Voted ---
            if (AriasPayment.isNotEmpty) ...[
              _buildSectionHeader("Paid Passengers", appGreen),

              for (int i = 0; i < AriasPayment.length; i++)
                InfoCard(
                  title: AriasPayment[i]["name"],
                  subtitle: AriasPayment[i]["place"],
                  showTag: AriasPayment[i]["tag"],
                  trailing: _buildPhoneIcon(appGreen),
                ),
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Helper widget for section titles
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper widget for the phone icon
  Widget _buildPhoneIcon(Color color) {
    return InkWell(
      onTap: () {
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.phone,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}