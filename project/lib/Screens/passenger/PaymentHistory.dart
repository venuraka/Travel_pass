import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/PaymentService.dart';
import '../Components/AppBar.dart';
import '../../services/Database.dart';

import '../../models/PassengerModel.dart';
import '../../models/DriverModel.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  PassengerModel? _passenger;
  DriverModel? _driver;
  String _attendanceStatus = 'Not Marked';
  bool _isPaid = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final pData = await _dbService.getPassengerData(user.uid);
      if (pData != null) {
        final dData = await _dbService.getDriverData(pData.driverId);
        final attendance = await _dbService.getTodayAttendanceStatus(user.uid);
        
        bool paid = false;
        if (pData.paymentType == 'Daily') {
          paid = await _dbService.checkIfPaidToday(user.uid);
        } else {
          paid = await _dbService.checkIfPaidThisMonth(user.uid);
        }

        if (mounted) {
          setState(() {
            _passenger = pData;
            _driver = dData;
            _attendanceStatus = attendance;
            _isPaid = paid;
            _isLoading = false;
          });
        }
      }
    }
  }

  bool get _isButtonEnabled {
    if (_passenger == null || _driver == null || _isPaid) return false;

    if (_passenger!.paymentType == 'Daily') {
      return _attendanceStatus == 'Present';
    } else {
      // Monthly logic
      final now = DateTime.now();
      final dueDay = (_driver!.paymentDate?.day) ?? 1;
      return now.day >= dueDay;
    }
  }

  String _getMonthName() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[now.month - 1];
  }

  void _handlePayment() {
    if (!_isButtonEnabled) return;

    final amountStr = _passenger!.paymentAmount.isNotEmpty 
        ? _passenger!.paymentAmount 
        : (_passenger!.paymentType == 'Monthly' 
            ? (_driver!.monthlyPaymentAmount ?? '0') 
            : (_driver!.dailyPaymentAmount ?? '0'));

    PaymentService.startOneTimePayment(
      amount: amountStr,
      orderId: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      itemsDescription: '${_passenger!.paymentType} Payment - ${_getMonthName()}',
      firstName: _passenger!.name.split(' ').first,
      lastName: _passenger!.name.contains(' ') ? _passenger!.name.split(' ').last : 'Passenger',
      email: _passenger!.email,
      phone: _passenger!.phone,
      address: _passenger!.address,
      city: 'Colombo',
      onCompleted: (paymentId) async {
        await _dbService.recordPayment(
          passengerId: _passenger!.uid,
          driverId: _passenger!.driverId,
          amount: amountStr,
          type: _passenger!.paymentType,
          paymentId: paymentId,
        );
        
        // Reload to update button state
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Successful!'))
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment Failed: $error'))
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color appGreen = const Color(0xFF05A664);
    final Color bgGreenTint = const Color(0xFFF1F8F5);

    if (_isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bgGreenTint,
      appBar: const CustomAppBar(
        title: 'Payments',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildSectionHeader("Outstanding Payments", appGreen),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildOutstandingCard(appGreen),
              ),
              const SizedBox(height: 30),
              _buildSectionHeader("Recent Payments", appGreen),
              const SizedBox(height: 10),
              _buildPaymentHistoryList(appGreen),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutstandingCard(Color color) {
    const Color textColor = Colors.white;
    final isMonthly = _passenger?.paymentType == 'Monthly';
    
    final amountDue = _passenger?.paymentAmount.isNotEmpty == true 
        ? _passenger!.paymentAmount 
        : (isMonthly ? (_driver?.monthlyPaymentAmount ?? '0') : (_driver?.dailyPaymentAmount ?? '0'));

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: _isPaid ? Colors.grey : color,
      child: Container(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Amount Due", style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8))),
                    const SizedBox(height: 4),
                    Text("Rs $amountDue", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 28, color: textColor)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(isMonthly ? "Due Month" : "Due Date", style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8))),
                    const SizedBox(height: 4),
                    Text(
                      isMonthly ? _getMonthName() : DateTime.now().toString().split(' ').first.replaceAll('-', '/'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled ? _handlePayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  disabledBackgroundColor: Colors.white.withOpacity(0.5),
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  _isPaid ? "Paid" : "Pay Now", 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
            if (!_isButtonEnabled && !_isPaid)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  isMonthly 
                    ? "Available from ${(_driver?.paymentDate?.day) ?? 1} ${_getMonthName()}"
                    : (_attendanceStatus == 'Present' ? "Ready to Pay" : "You haven't joind the journey today!"),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryList(Color color) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _dbService.getPaymentHistory(_passenger!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final payments = snapshot.data!;
        if (payments.isEmpty) return const Center(child: Text("No payment history found."));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: payments.map((p) {
              return _buildPaymentRow(
                date: p['date']?.toString().split('T').first.replaceAll('-', '/') ?? 'N/A',
                amount: "Rs ${p['amount']}",
                color: color,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPaymentRow({required String date, required String amount, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(amount, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}