import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String get _dateString {
    final now = DateTime.now();
    return DateFormat.yMMMd().format(now);
  }

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
              subtitle: Text(
                _filterDate == null 
                  ? "All History"
                  : DateFormat.yMMMd().format(_filterDate!), 
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
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
            child: _filterDate == null
                ? StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _dbService.getDriverPaymentHistoryStream(_driverId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var payments = snapshot.data ?? [];

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
                          final location = p['pickupLocation'] ?? 'No location';
                          final status = p['status'] ?? 'unknown';
                          final type = p['type'] ?? 'Daily';
                          
                          final methodLabel = (status == 'cash') ? "Cash" : "Online";

                          bool showDateHeader = false;
                          if (index == 0) {
                            showDateHeader = true;
                          } else {
                            final prevDate = payments[index - 1]['date']?.toString().split('T').first.replaceAll('-', '/') ?? 'N/A';
                            if (date != prevDate) {
                              showDateHeader = true;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  child: Text(
                                    date,
                                    style: TextStyle(
                                      color: appGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InfoCard(
                                  title: name,
                                  subtitle: location,
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
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // --- SECTION 1: PAID ON THIS DAY ---
                        _buildSectionHeader("Paid Today", appGreen),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _dbService.getDriverPaymentHistoryStream(_driverId),
                          builder: (context, snapshot) {
                            final filterStr = "${_filterDate!.year}/${_filterDate!.month.toString().padLeft(2, '0')}/${_filterDate!.day.toString().padLeft(2, '0')}";
                            // Filter for successful payments only (not rejected)
                            final payments = (snapshot.data ?? []).where((p) => 
                              (p['date'] ?? '').toString().startsWith(filterStr) && 
                              p['status'] != 'rejected'
                            ).toList();

                            if (payments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("No successful payments on this day.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: payments.length,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemBuilder: (context, index) {
                                final p = payments[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InfoCard(
                                    title: p['passengerName'] ?? 'Unknown',
                                    subtitle: p['pickupLocation'] ?? 'No location',
                                    paymentMethod: (p['status'] == 'cash') ? "Cash" : "Online",
                                    showTag: true,
                                    tagText: p['type'] ?? 'Daily',
                                    trailing: Text(
                                      "Rs ${double.tryParse(p['amount'].toString())?.toInt() ?? 0}",
                                      style: TextStyle(color: appGreen, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // --- SECTION 2: ARREARS ON THIS DAY (TIME TRAVEL LOGIC) ---
                        const SizedBox(height: 20),
                        _buildSectionHeader("Outstanding Arrears", Colors.redAccent),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _dbService.getHistoricalArrearsStream(_driverId, _filterDate!),
                          builder: (context, snapshot) {
                            final arrears = snapshot.data ?? [];

                            if (arrears.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("No arrears for this day! 🎉", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: arrears.length,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemBuilder: (context, index) {
                                final a = arrears[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InfoCard(
                                    title: a['name'],
                                    subtitle: a['pickupLocation'],
                                    showTag: true,
                                    tagText: a['type'],
                                    trailing: Text(
                                      "Rs ${a['balance'].toInt()}",
                                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // --- SECTION 3: REJECTED / FORGIVEN PAYMENTS ---
                        const SizedBox(height: 20),
                        _buildSectionHeader("Rejected / Forgiven", Colors.grey.shade700),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _dbService.getDriverPaymentHistoryStream(_driverId),
                          builder: (context, snapshot) {
                            final filterStr = "${_filterDate!.year}/${_filterDate!.month.toString().padLeft(2, '0')}/${_filterDate!.day.toString().padLeft(2, '0')}";
                            // Filter for rejected payments only
                            final rejected = (snapshot.data ?? []).where((p) => 
                              (p['date'] ?? '').toString().startsWith(filterStr) && 
                              p['status'] == 'rejected'
                            ).toList();

                            if (rejected.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("No rejected payments on this day.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rejected.length,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemBuilder: (context, index) {
                                final p = rejected[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InfoCard(
                                    title: p['passengerName'] ?? 'Unknown',
                                    subtitle: p['pickupLocation'] ?? 'No location',
                                    paymentMethod: "Rejected",
                                    showTag: true,
                                    tagText: p['type'] ?? 'Daily',
                                    trailing: Text(
                                      "Rs ${double.tryParse(p['amount'].toString())?.toInt() ?? 0}",
                                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Helper widget for section titles
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}