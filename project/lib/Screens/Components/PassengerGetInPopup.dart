import 'package:flutter/material.dart';
import '../../models/PassengerModel.dart';

class PassengerGetInPopup extends StatefulWidget {
  final List<PassengerModel> passengers;
  final Function(PassengerModel) onCorrect;
  final Function(PassengerModel) onIncorrect;
  final Function(String) onCallPressed;

  const PassengerGetInPopup({
    super.key,
    required this.passengers,
    required this.onCorrect,
    required this.onIncorrect,
    required this.onCallPressed,
  });


  @override
  State<PassengerGetInPopup> createState() => _PassengerGetInPopupState();
}

class _PassengerGetInPopupState extends State<PassengerGetInPopup> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 480,
        decoration: BoxDecoration(
          color: const Color(0xFF121415), // Dark background matching the image
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            // Header with Progress Indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PASSENGER ${(_currentPage + 1)} OF ${widget.passengers.length}",
                    style: const TextStyle(
                      color: Color(0xFF05A664),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (widget.passengers.length > 1)
                    Row(
                      children: List.generate(
                        widget.passengers.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index 
                                ? const Color(0xFF05A664) 
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.passengers.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final passenger = widget.passengers[index];
                  return _buildPassengerCard(passenger);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(PassengerModel passenger) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Question
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "DID ${passenger.name.toUpperCase()} GET IN?",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFFF4D4D),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Hold to mark as absent"),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onLongPress: () => _showConfirmationDialog(passenger),
                ),
              ),
              const SizedBox(width: 20),
              // Correct Button (Green Check)
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_rounded,
                  color: const Color(0xFF05A664),
                  onTap: () => widget.onCorrect(passenger),
                  onLongPress: null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),

        // Bottom Component: Hold to call
        _buildHoldToCall(passenger),
      ],
    );
  }


  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Icon(icon, color: color, size: 50),
      ),
    );
  }

  void _showConfirmationDialog(PassengerModel passenger) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Mark as Absent?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure to mark ${passenger.name} as absent? This will update their attendance and remove them from the tracking list.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onIncorrect(passenger);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D4D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("CONFIRM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHoldToCall(PassengerModel passenger) {
    return GestureDetector(
      onLongPress: () => widget.onCallPressed(passenger.phone),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(40),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call_rounded, color: Colors.white60, size: 20),
            SizedBox(width: 12),
            Text(
              "HOLD TO GET A CALL",
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
