import 'package:flutter/material.dart';
import '../../models/PassengerModel.dart';
import './MarqueeText.dart';

// --- Color Definitions (Approximated from image) ---
const Color kCardBackgroundColor = Color(0xFF121415);
const Color kPrimaryTextColor = Color(0xFF05A664);
const Color kSecondaryTextColor = Color(0xFFF8F9FC);

class NextPassengerCard extends StatefulWidget {
  final List<PassengerModel> passengers;
  final int currentIndex;
  final String status;
  final Color statusColor; // Added
  final Function(String)? onCallPressed;
  final Function(int) onPageChanged;
  final VoidCallback? onFinishJourney; // Added

  final bool isAtFinalDestination; // Added
  final bool allOnboarded; // Added

  const NextPassengerCard({
    super.key,
    required this.passengers,
    required this.currentIndex,
    required this.status,
    this.statusColor = kPrimaryTextColor, // Added default
    this.onCallPressed,
    required this.onPageChanged,
    this.onFinishJourney, // Added
    this.isAtFinalDestination = false, // Added
    this.allOnboarded = false, // Added
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildStatusBlock(String status, Color statusColor) {
    if (!status.contains('|')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: MarqueeText(
          text: status.toLowerCase(),
          style: TextStyle(
            color: statusColor,
            fontSize: 18.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    final parts = status.split('|');
    if (parts.length != 2) {
      return Column(
        children: parts.map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: MarqueeText(
            text: p.trim(),
            style: TextStyle(
              color: statusColor,
              fontSize: 18.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        )).toList(),
      );
    }

    final leftRaw = parts[0].trim();
    final rightRaw = parts[1].trim();

    String leftLabel = "";
    String leftVal = "";
    if (leftRaw.contains(':')) {
      final sub = leftRaw.split(':');
      leftLabel = sub[0].trim();
      leftVal = sub[1].trim();
    } else {
      leftVal = leftRaw;
    }

    String rightLabel = "";
    String rightVal = "";
    if (rightRaw.contains(':')) {
      final sub = rightRaw.split(':');
      rightLabel = sub[0].trim();
      rightVal = sub[1].trim();
    } else {
      rightVal = rightRaw;
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left Column (Passenger)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leftLabel.isNotEmpty)
                  Text(
                    leftLabel.toLowerCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  leftVal.toLowerCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          
          // Vertical Divider
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withOpacity(0.1),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // Right Column (Bus)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rightLabel.isNotEmpty)
                  Text(
                    rightLabel.toLowerCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  rightVal.toLowerCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kPrimaryTextColor,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-calculating allReached to include the destination phase
    final bool allPassengersPicked = widget.allOnboarded || widget.passengers.isEmpty || 
        (widget.currentIndex >= widget.passengers.length && widget.passengers.isNotEmpty);
    
    final currentPassenger = !allPassengersPicked && widget.passengers.isNotEmpty
        ? widget.passengers[widget.currentIndex] 
        : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: kCardBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      padding: const EdgeInsets.only(top: 24.0, bottom: 30.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // --- Title ---
          Text(
            widget.isAtFinalDestination 
                ? 'Destination Reached' 
                : (allPassengersPicked ? 'Heading To Destination' : 'Next Passenger'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22.0,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
          const SizedBox(height: 30),

          if (!allPassengersPicked) ...[
            // --- Passenger Info Row with Swipeable PageView ---
            SizedBox(
              height: 165,
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.currentIndex > 0
                        ? () => widget.onPageChanged(widget.currentIndex - 1)
                        : null,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: widget.currentIndex > 0 ? Colors.white60 : Colors.white10,
                      size: 24,
                    ),
                  ),
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
                            MarqueeText(
                              text: p.name.toLowerCase(),
                              style: const TextStyle(
                                color: kPrimaryTextColor,
                                fontSize: 22.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            MarqueeText(
                              text: p.pickupLocation.toLowerCase(),
                              style: const TextStyle(
                                color: kPrimaryTextColor,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            _buildStatusBlock(widget.status, widget.statusColor),
                          ],
                        );
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: widget.currentIndex < widget.passengers.length - 1
                        ? () => widget.onPageChanged(widget.currentIndex + 1)
                        : null,
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: widget.currentIndex < widget.passengers.length - 1
                          ? Colors.white60
                          : Colors.white10,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30.0),
            // HOLD TO CALL
            GestureDetector(
              onLongPress: () {
                if (currentPassenger != null && widget.onCallPressed != null) {
                  widget.onCallPressed!(currentPassenger.phone);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.call_rounded, color: kPrimaryTextColor, size: 20),
                    SizedBox(width: 12.0),
                    Text(
                      'Hold To Get a Call...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // --- Destination View ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    widget.isAtFinalDestination 
                        ? 'You have arrived at the final destination.'
                        : 'All passengers are onboard. Driving to destination...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  // Split the status (e.g. "23km | 36min") into two lines and center them
                  if (widget.status.contains('|')) 
                    Column(
                      children: widget.status.split('|').map((part) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          part.trim(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: kPrimaryTextColor,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )).toList(),
                    )
                  else
                    Text(
                      widget.status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kPrimaryTextColor,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Only show button if actually at destination
            if (widget.isAtFinalDestination)
              GestureDetector(
                onTap: widget.onFinishJourney,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ]
                  ),
                  child: const Text(
                    'FINISH JOURNEY',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}


// --- Journey Info Card (For generic info, not used in Next Passenger flow) ---
class JourneyInfoCard extends StatelessWidget {
  final int vehicleETA; // Minutes
  final int passengerETA; // Minutes
  final String nextStop;
  final int attendanceCount;
  final bool isOnboarded;
  final int progressIndex;
  final bool hasNextPickup; // Added
  final VoidCallback? onCallPressed;

  const JourneyInfoCard({
    super.key,
    required this.vehicleETA,
    required this.passengerETA,
    required this.nextStop,
    required this.attendanceCount,
    this.isOnboarded = false,
    this.progressIndex = 0,
    this.hasNextPickup = true,
    this.onCallPressed,
  });

  Color _getWalkingColor() {
    if (passengerETA > vehicleETA) return Colors.redAccent;
    if (passengerETA < vehicleETA) return Colors.greenAccent;
    return Colors.orangeAccent;
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // --- Main ETA Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Vehicle ETA Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnboarded ? 'Drop-off ETA' : 'Vehicle Arrival',
                      style: const TextStyle(
                        color: kPrimaryTextColor,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$vehicleETA mins',
                      style: const TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Separator or Icon
              Container(
                height: 40,
                width: 1,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),

              // Passenger/NextStop Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isOnboarded) ...[
                      const Text(
                        'Your Walking Time',
                        style: TextStyle(
                          color: kPrimaryTextColor,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$passengerETA mins',
                        style: TextStyle(
                          color: _getWalkingColor(),
                          fontSize: 22.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Next Destination',
                        style: TextStyle(
                          color: kPrimaryTextColor,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      hasNextPickup 
                        ? MarqueeText(
                            text: nextStop,
                            style: const TextStyle(
                              color: kSecondaryTextColor,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text(
                            'Final Destination',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          
          // --- Quick Info Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isOnboarded)
               Expanded(
                 child: Row(
                   children: [
                     const Icon(Icons.location_on_rounded, color: Colors.white38, size: 16),
                     const SizedBox(width: 8),
                     Expanded(
                       child: MarqueeText(
                         text: 'Next: $nextStop',
                         style: const TextStyle(color: Colors.white60, fontSize: 13),
                       ),
                     ),
                   ],
                 ),
               ),
              
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Onboarded: $attendanceCount',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Action Button ---
          GestureDetector(
            onLongPress: onCallPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.phone_callback_rounded, color: kPrimaryTextColor, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Hold To Get a Call...',
                    style: TextStyle(
                      color: kPrimaryTextColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}