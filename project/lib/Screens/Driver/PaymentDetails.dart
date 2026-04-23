import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/Database.dart';
import '../Components/Cards.dart';
import '../Components/Topic.dart';
import 'PaymentHistory.dart';
import 'PaymentCollection.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final Color appGreen = const Color(0xFF05A664);
  final Color bgGreenTint = const Color(0xFFF1F8F5);
  final DatabaseService _dbService = DatabaseService();
  final String _driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _badgePreference = "Both";
  bool _isRequesting = false;


  @override
  void initState() {
    super.initState();
    _loadDriverSettings();
  }

  Future<void> _loadDriverSettings() async {
    final driver = await _dbService.getDriverData(_driverId);
    if (driver != null && mounted) {
      setState(() {
        _badgePreference = driver.badgePreference;
      });
    }
  }

  // Removed hardcoded lists as we now use StreamBuilders

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
      backgroundColor: bgGreenTint,
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
                    // --- Driver Balance Card ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: StreamBuilder<double>(
                        stream: _dbService.getDriverBalanceStream(_driverId),
                        builder: (context, snapshot) {
                          final balance = snapshot.data ?? 0.0;
                          return _buildBalanceCard(balance);
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    // --- Paid Passengers Section Title ---
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

                    // --- Paid Passengers Cards (Real-time Stream) ---
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _dbService.getRecentPaymentsStream(_driverId),
                      builder: (context, snapshot) {
                        final payments = snapshot.data ?? [];
                        if (payments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: Text("No recent payments found.", style: TextStyle(color: Colors.grey))),
                          );
                        }

                        return Column(
                          children: payments.map((p) {
                            final date = p['date']?.toString().split('T').first.replaceAll('-', '/') ?? 'Today';
                            final amount = p['amount'] ?? '0';
                            final name = p['passengerName'] ?? 'Passenger';
                            final place = p['pickupLocation'] ?? 'No location';
                            final type = p['type'] ?? 'Daily';

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              child: InfoCard(
                                title: name,
                                subtitle: place,
                                showTag: true,
                                tagText: type,
                                overallPreference: _badgePreference,
                                trailing: _buildPaidTrailing(appGreen, "Rs $amount", date),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    ),

                    const SizedBox(height: 30),

                    // --- Arrears (Late Payment) Section Title ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Arrears",
                          style: TextStyle(
                            color: appGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- Late Payment Swipers (Real-time Stream) ---
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _dbService.getMissedPaymentPassengersStream(_driverId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        
                        final payments = snapshot.data ?? [];
                        if (payments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: Text("No late payments! 🎉", style: TextStyle(color: Colors.grey))),
                          );
                        }

                        return Column(
                          children: payments.map((reminder) {
                            final name = reminder['name'] ?? 'Passenger';
                            final place = reminder['pickupLocation'] ?? 'No location';
                            final type = reminder['paymentType'] ?? 'Daily';
                            final amount = reminder['totalAmount'] ?? 'Rs 0';
                            final status = reminder['missedStatus'] ?? 'Late';

                            return Dismissible(
                              key: ValueKey(reminder['id']),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (direction) async {
                                // Record manual payment when swiped
                                await _dbService.recordManualPayment(
                                  passengerId: reminder['id'],
                                  passengerName: name,
                                  driverId: _driverId,
                                  driverName: "Driver", 
                                  amount: amount.replaceAll('Rs ', ''),
                                  type: type,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Recorded cash payment for $name")),
                                  );
                                }
                              },
                              background: Container(
                                color: appGreen,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Icon(Icons.check, color: Colors.white),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildLatePaymentRow(
                                    appGreen, 
                                    name, 
                                    place, 
                                    type, 
                                    _badgePreference,
                                    amount,
                                    status
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
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

  Widget _buildLatePaymentRow(Color color, String name, String location, String tag, String overallPreference, String amount, String status) {
    // Visibility logic
    bool shouldShowBadge = (overallPreference == "Both") || (tag.toLowerCase() == overallPreference.toLowerCase());

    // Styling logic
    Color badgeBgColor = Colors.black;
    Color badgeTextColor = const Color(0xFF00C853); // Matrix Green

    if (overallPreference == "Both") {
      if (tag == "Monthly") {
        badgeBgColor = const Color(0xFF05A664); // Dark Green
        badgeTextColor = const Color(0xFFE8F5E9); // Light Green
      } else {
        // Daily stays default style: Black BG, Matrix Green Text
        badgeBgColor = Colors.black;
        badgeTextColor = const Color(0xFF00C853);
      }
    }

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                   Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: shouldShowBadge ? 12 : 0),
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

                  // The Dynamic Tag Layer
                  if (shouldShowBadge)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- NEW: Balance Card Widget ---
  Widget _buildBalanceCard(double balance) {
    const Color textColor = Colors.white;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentCollectionScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 6,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: appGreen,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Accumulated Balance",
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Rs ${balance.toInt()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),

              Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ready to redeem?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  _isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : TextButton(
                          onPressed: () => _showRequestPayoutDialog(balance),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Request Payout",
                            style: TextStyle(
                              color: appGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: Request Payout Dialog ---
  void _showRequestPayoutDialog(double balance) {
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No balance to redeem.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Request Payout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to request a payout of Rs ${balance.toInt()} to your registered account?",
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handlePaymentRequest(balance);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePaymentRequest(double balance) async {
    setState(() => _isRequesting = true);
    try {
      await _dbService.requestPayment(_driverId, balance);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Request submitted! We will process it shortly."),
            backgroundColor: appGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to submit request. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
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