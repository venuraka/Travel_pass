import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/RedemptionModel.dart';
import '../../services/Database.dart';
import '../Components/AppBar.dart';
import '../Components/Topic.dart';

class PaymentCollectionScreen extends StatefulWidget {
  const PaymentCollectionScreen({super.key});

  @override
  State<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color appGreen = const Color(0xFF05A664);
  DateTime? _filterDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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

  /// Returns the status label and color for a given redemption status.
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {'label': 'Pending', 'color': Colors.orange, 'icon': Icons.hourglass_top_rounded};
      case 'approved':
        return {'label': 'Paid', 'color': appGreen, 'icon': Icons.check_circle_rounded};
      case 'rejected':
        return {'label': 'Rejected', 'color': Colors.redAccent, 'icon': Icons.cancel_rounded};
      default:
        return {'label': 'Unknown', 'color': Colors.grey, 'icon': Icons.help_outline};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: const CustomAppBar(title: 'Redemption History'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: PageHeader(
                title: "Payouts",
                subtitle: _filterDate == null
                    ? const Text("Showing all requests",
                        style: TextStyle(fontSize: 12, color: Colors.grey))
                    : Text(
                        "Filtered: ${_filterDate!.year}/${_filterDate!.month.toString().padLeft(2, '0')}/${_filterDate!.day.toString().padLeft(2, '0')}",
                        style: TextStyle(
                            fontSize: 12,
                            color: appGreen,
                            fontWeight: FontWeight.bold),
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

            /// Redemption List
            Expanded(
              child: StreamBuilder<List<RedemptionModel>>(
                stream: _dbService.getRedemptionsStream(_driverId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var redemptions = snapshot.data ?? [];

                  // Apply date filter (filter by requested date)
                  if (_filterDate != null) {
                    redemptions = redemptions.where((item) {
                      // Use local components for comparison to match the local date picker
                      final req = item.requestedAt.toLocal();
                      return req.year == _filterDate!.year &&
                          req.month == _filterDate!.month &&
                          req.day == _filterDate!.day;
                    }).toList();
                  }

                  if (redemptions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text("No redemptions found",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: redemptions.length,
                    itemBuilder: (context, index) {
                      return _buildRedemptionCard(redemptions[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Redemption Card — shows requested date, paid date, amount, and status badge
  Widget _buildRedemptionCard(RedemptionModel item) {
    final statusInfo = _getStatusInfo(item.status);
    final Color statusColor = statusInfo['color'];
    final String statusLabel = statusInfo['label'];
    final IconData statusIcon = statusInfo['icon'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top Row: Amount + Status Badge ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Amount
                Text(
                  "Rs ${item.amount.toInt()}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: appGreen,
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 14),

            // ─── Date Details ───
            Row(
              children: [
                // Requested Date
                Expanded(
                  child: _buildDateColumn(
                    icon: Icons.upload_rounded,
                    label: "Requested",
                    date: item.requestedDateStr,
                    color: Colors.blueGrey,
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade200,
                ),

                // Paid Date
                Expanded(
                  child: _buildDateColumn(
                    icon: Icons.download_rounded,
                    label: "Received",
                    date: item.paidDateStr ?? "—",
                    color: item.paidAt != null ? appGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for the date column
  Widget _buildDateColumn({
    required IconData icon,
    required String label,
    required String date,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: date == "—" ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
      ],
    );
  }
}