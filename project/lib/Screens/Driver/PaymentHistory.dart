import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/Database.dart';
import '../Components/AppBar.dart';
import '../Components/Cards.dart';
import '../Components/Topic.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color appGreen = const Color(0xFF05A664);
  DateTime? _filterDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _filterDate) {
      setState(() {
        _filterDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Payment History',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: PageHeader(
              title: "Payments",
              subtitle: _filterDate == null 
                ? const Text("Showing all history", style: TextStyle(fontSize: 12, color: Colors.grey))
                : Text("Filtered: ${_filterDate!.toLocal()}".split(' ')[0], style: TextStyle(fontSize: 12, color: appGreen, fontWeight: FontWeight.bold)),
              actions: [
                if (_filterDate != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    onPressed: () => setState(() => _filterDate = null),
                  ),
                IconButton(
                  icon: Icon(Icons.calendar_month, color: appGreen),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _dbService.getDriverPaymentHistoryStream(_driverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var payments = snapshot.data ?? [];

                // Apply Filter
                if (_filterDate != null) {
                  final filterStr = "${_filterDate!.year}/${_filterDate!.month.toString().padLeft(2, '0')}/${_filterDate!.day.toString().padLeft(2, '0')}";
                  payments = payments.where((p) => (p['date'] ?? '').toString().startsWith(filterStr)).toList();
                }

                if (payments.isEmpty) {
                  return const Center(child: Text("No payment history found.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: payments.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    final name = p['passengerName'] ?? 'Unknown';
                    final amount = p['amount'] ?? '0';
                    final date = p['date']?.toString().split('T').first.replaceAll('-', '/') ?? 'N/A';
                    final status = p['status'] ?? 'unknown';
                    final type = p['type'] ?? 'Daily';
                    
                    final methodLabel = (status == 'cash') ? "Cash" : "Online";

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InfoCard(
                        title: name,
                        subtitle: "$date",
                        paymentMethod: methodLabel,
                        showTag: true,
                        tagText: type,
                        trailing: Text(
                          "Rs ${double.tryParse(amount.toString())?.toInt() ?? 0}",
                          style: TextStyle(
                            color: appGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}