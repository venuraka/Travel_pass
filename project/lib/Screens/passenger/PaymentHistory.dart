import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
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
    try {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final pData = await _dbService.getPassengerData(user.uid);
          if (pData != null) {
            DriverModel? dData;
            try {
              dData = await _dbService.getDriverData(pData.driverId);
            } catch (driverError) {
              developer.log('Error loading driver data: $driverError');
              // Continue without driver data
            }

            String attendance = 'Not Marked';
            try {
              attendance = await _dbService.getTodayAttendanceStatus(user.uid);
            } catch (attendanceError) {
              developer.log('Error loading attendance status: $attendanceError');
            }
            
            bool paid = false;
            try {
              if (pData.paymentType == 'Daily') {
                paid = await _dbService.checkIfPaidToday(user.uid);
              } else {
                paid = await _dbService.checkIfPaidThisMonth(user.uid);
              }
            } catch (paymentError) {
              developer.log('Error checking payment status: $paymentError');
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
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        } catch (e) {
          developer.log('Error in _loadData: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      developer.log('Unexpected error in _loadData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      orderId: 'PAY-${_passenger!.uid}-${DateTime.now().millisecondsSinceEpoch}',
      itemsDescription: '${_passenger!.paymentType} Payment - ${_getMonthName()}',
      firstName: _passenger!.name.split(' ').first,
      lastName: _passenger!.name.contains(' ') ? _passenger!.name.split(' ').last : 'Passenger',
      email: _passenger!.email,
      phone: _passenger!.phone,
      address: _passenger!.address,
      city: 'Colombo',
      onCompleted: (paymentId) {
        // Minimal callback - return immediately without any operations
        // This lets PayHere activity finish and free resources
        developer.log('Payment completed with ID: $paymentId');
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment Failed: $error'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            )
          );
        }
      },
      onDismissed: () {
        developer.log('Payment screen dismissed');
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
                payment: p,
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

  Widget _buildPaymentRow({required Map<String, dynamic> payment, required Color color}) {
    final date = payment['date']?.toString().split('T').first.replaceAll('-', '/') ?? 'N/A';
    final amount = payment['amount'] ?? '0';
    final passengerName = payment['passengerName'] ?? 'Unknown';
    final driverName = payment['driverName'] ?? 'Unknown';
    final status = payment['status'] ?? 'success';
    final paymentType = payment['type'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (status == 'collected' || status == 'paid_to_driver' || status == 'distribution_pending' || status == 'distribution_failed' || status == 'success' || status == 'PAID') 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (status == 'collected' || status == 'paid_to_driver' || status == 'distribution_pending' || status == 'distribution_failed' || status == 'success' || status == 'PAID') 
                      ? '✓ Success' 
                      : (status == 'payment_failed' || status == 'FAILED') ? '✗ Failed' : '... Pending',
                  style: TextStyle(
                    color: (status == 'collected' || status == 'paid_to_driver' || status == 'distribution_pending' || status == 'distribution_failed' || status == 'success' || status == 'PAID') 
                        ? Colors.green 
                        : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Passenger and Driver
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passenger',
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      passengerName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver',
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      driverName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Amount and Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs $amount',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                paymentType,
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}