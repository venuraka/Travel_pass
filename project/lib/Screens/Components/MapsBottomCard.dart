import 'package:flutter/material.dart';
import '../../models/PassengerModel.dart';

// --- Color Definitions (Approximated from image) ---
const Color kCardBackgroundColor = Color(0xFF121415);
const Color kPrimaryTextColor = Color(0xFF05A664);
const Color kSecondaryTextColor = Color(0xFFF8F9FC);

class NextPassengerCard extends StatefulWidget {
  final List<PassengerModel> passengers;
  final int currentIndex;
  final String status;
  final VoidCallback? onCallPressed;
  final Function(int) onPageChanged;

  const NextPassengerCard({
    super.key,
    required this.passengers,
    required this.currentIndex,
    required this.status,
    this.onCallPressed,
    required this.onPageChanged,
  });

  @override
  State<NextPassengerCard> createState() => _NextPassengerCardState();
}

class _NextPassengerCardState extends State<NextPassengerCard> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex);
  }

  @override
  void didUpdateWidget(NextPassengerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _pageController.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onCallPressed,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: kCardBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // --- Title: Next Passenger ---
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Next Passenger',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),

            // --- Passenger Info Row with Swipeable PageView ---
            SizedBox(
              height: 120, // Height for the info area
              child: Row(
                children: [
                  // Left Arrow
                  IconButton(
                    onPressed: widget.currentIndex > 0
                        ? () => widget.onPageChanged(widget.currentIndex - 1)
                        : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: widget.currentIndex > 0 ? kPrimaryTextColor : Colors.grey,
                      size: 20,
                    ),
                  ),

                  // Swipeable Content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: widget.onPageChanged,
                      itemCount: widget.passengers.length,
                      itemBuilder: (context, index) {
                        final p = widget.passengers[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              p.name,
                              style: const TextStyle(
                                color: kPrimaryTextColor,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              p.pickupLocation,
                              style: const TextStyle(
                                color: kPrimaryTextColor,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (index == widget.currentIndex) ...[
                              const SizedBox(height: 8.0),
                              Text(
                                widget.status,
                                style: const TextStyle(
                                  color: kPrimaryTextColor,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]
                          ],
                        );
                      },
                    ),
                  ),

                  // Right Arrow
                  IconButton(
                    onPressed: widget.currentIndex < widget.passengers.length - 1
                        ? () => widget.onPageChanged(widget.currentIndex + 1)
                        : null,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: widget.currentIndex < widget.passengers.length - 1
                          ? kPrimaryTextColor
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30.0),

            // --- Bottom Action Indicator ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.call, color: kPrimaryTextColor, size: 18),
                SizedBox(width: 8.0),
                Text(
                  'Hold To Get a Call...',
                  style: TextStyle(
                    color: kSecondaryTextColor,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Journey Info Card (No changes needed for this card) ---
class JourneyInfoCard extends StatelessWidget {
  final String busArrivalTime;
  final String nextStop;
  final int attendanceCount;
  final VoidCallback? onCallPressed;

  const JourneyInfoCard({
    super.key,
    required this.busArrivalTime,
    required this.nextStop,
    required this.attendanceCount,
    this.onCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // --- Swipe Up Instruction ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Text(
                'Swipe up if you have arrived at the pickup spot',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // --- Bus Will Come on ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Bus Will Come on',
                style: TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                busArrivalTime,
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // --- Next Stop ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Next Stop',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                nextStop,
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // --- Attendance Count ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Attendance Count',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                '$attendanceCount',
                style: const TextStyle(
                  color: kSecondaryTextColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24.0),

          // --- Hold To Get a Call ---
          GestureDetector(
            onTap: onCallPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(
                  Icons.phone_callback,
                  color: kPrimaryTextColor,
                  size: 18,
                ),
                SizedBox(width: 8.0),
                Text(
                  'Hold To Get a Call...',
                  style: TextStyle(
                    color: kPrimaryTextColor,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}