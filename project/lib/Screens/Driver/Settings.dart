import 'package:flutter/material.dart';
import '../Components/Whitecard.dart';
// Assuming Header.dart exists, but I will build the specific header shown in the screenshot inline for accuracy.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Style Constants based on your code
  final Color appGreen = const Color(0xFF05A664);
  final Color darkBg = const Color(0xFF121415);

  // State Variables
  int _amount = 1000;
  DateTime? _selectedDate;

  // Logic to change amount
  void _incrementAmount() {
    setState(() {
      _amount += 100; // Adjust increment step as needed
    });
  }

  void _decrementAmount() {
    setState(() {
      if (_amount > 0) _amount -= 100;
    });
  }

  // Logic for Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine height to make the card look like a bottom sheet (approx 50-60% down)
    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardTopPadding = screenHeight * 0.5;

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // --- 1. Custom Header (Matches Screenshot) ---
          Positioned(
            top: 60, // Adjust for SafeArea
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Back Button Area
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: appGreen, width: 1.5),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: appGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 150), // Push "Settings" text down to center
                Text(
                  'Settings',
                  style: TextStyle(
                    color: appGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // --- 2. White Card Content ---
          WhiteCard(
            topPadding: cardTopPadding,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // --- Date Selection Row ---
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'Set Payment Date'
                                : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                              color: appGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.calendar_today_outlined, color: appGreen, size: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- Payment Label ---
                    Text(
                      'Change Payment Amount For All Passengers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: appGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Counter Row (Minus / Value / Plus) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus Button
                        _buildCounterButton(
                          icon: Icons.remove,
                          onTap: _decrementAmount,
                        ),

                        // Amount Text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          child: Text(
                            'Rs $_amount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Plus Button
                        _buildCounterButton(
                          icon: Icons.add,
                          onTap: _incrementAmount,
                        ),
                      ],
                    ),

                    const SizedBox(height: 50),

                    // --- Done Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save settings logic here
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the circular Plus/Minus buttons
  Widget _buildCounterButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: appGreen, width: 1.2),
        ),
        child: Icon(
          icon,
          color: appGreen,
          size: 20,
        ),
      ),
    );
  }
}