import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool showTag; // To toggle the "Daily" ribbon
  final String tagText;
  final Widget trailing;
  final String overallPreference; // 'Daily', 'Monthly', or 'Both'
  final String? paymentMethod; // 'Cash' or 'Online'
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.trailing,
    this.showTag = false,
    this.tagText = "Monthly",
    this.overallPreference = "Both",
    this.paymentMethod,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2.r,
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        // Use a Stack to overlay the "Daily" tag on top of the content
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // Main Content Layer
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Text Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: showTag ? 12.h : 0,
                          ), // Spacing if tag exists
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          subtitleWidget ??
                              Text(
                                subtitle ?? '',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        ],
                      ),
                    ),
                    // The Dynamic Trailing Widget (Price or Phone Icon) — constrained
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 100.w),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: trailing,
                      ),
                    ),
                  ],
                ),
              ),

              // The Dynamic Tag Layer (Top-Left)
              if (showTag && _shouldShowBadge())
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getBadgeBgColor(),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      tagText,
                      style: TextStyle(
                        color: _getBadgeTextColor(),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // The Payment Method Tag (Top-Right)
              if (paymentMethod != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: (paymentMethod?.toUpperCase() == 'CASH') 
                          ? Colors.orange.shade100 
                          : (paymentMethod?.toUpperCase() == 'REJECTED')
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      paymentMethod!.toUpperCase(),
                      style: TextStyle(
                        color: (paymentMethod?.toUpperCase() == 'CASH') 
                            ? Colors.orange.shade800 
                            : (paymentMethod?.toUpperCase() == 'REJECTED')
                                ? Colors.red.shade800
                                : Colors.blue.shade800,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowBadge() {
    if (overallPreference == "Both") return true;
    return tagText.toLowerCase() == overallPreference.toLowerCase();
  }

  Color _getBadgeBgColor() {
    if (overallPreference != "Both") return Colors.black;
    // Specific styles for "Both"
    if (tagText == "Monthly") {
      return const Color(0xFF05A664); // Dark Green
    } else {
      return Colors.black; // Default style for Daily when "Both" is selected
    }
  }

  Color _getBadgeTextColor() {
    if (overallPreference != "Both") return const Color(0xFF00C853); // Matrix Green
    // Specific styles for "Both"
    if (tagText == "Monthly") {
      return const Color(0xFFE8F5E9); // Light Green text
    } else {
      return const Color(0xFF00C853); // Default style for Daily when "Both" is selected
    }
  }
}
