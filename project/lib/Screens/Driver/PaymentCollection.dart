import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/RedemptionModel.dart';
import '../../services/Database.dart';
import '../Components/AppBar.dart';

class PaymentCollectionScreen extends StatefulWidget {
  const PaymentCollectionScreen({super.key});

  @override
  State<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color appGreen = const Color(0xFF05A664);
  final Color bgGreenTint = const Color(0xFFF1F8F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreenTint,
      appBar: const CustomAppBar(title: "Redemption History"),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<RedemptionModel>>(
                stream: _dbService.getRedemptionsStream(_driverId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 64.r, color: Colors.grey.shade400),
                          SizedBox(height: 16.h),
                          Text(
                            "No redemptions yet",
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final redemptions = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemCount: redemptions.length,
                    itemBuilder: (context, index) {
                      final item = redemptions[index];
                      return _buildRedemptionCard(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildRedemptionCard(RedemptionModel item) {
    final dateStr = "${item.date.year}/${item.date.month}/${item.date.day}";
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Redeemed on",
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              SizedBox(height: 4.h),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Amount",
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              SizedBox(height: 4.h),
              Text(
                "Rs ${item.amount.toInt()}",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: appGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
