import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import '../../models/PassengerModel.dart';
import '../../controllers/RegisterPassengerController.dart';

class RegisterPassengerScreen extends StatefulWidget {
  final PassengerModel passenger;
  final List<String>? pickupLocations; // Added parameter

  const RegisterPassengerScreen({
    super.key,
    required this.passenger,
    this.pickupLocations,
  });

  @override
  State<RegisterPassengerScreen> createState() =>
      _RegisterPassengerScreenState();
}

class _RegisterPassengerScreenState extends State<RegisterPassengerScreen> {
  // State variables
  String _paymentFrequency = 'Daily';
  String? _selectedLocation;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _paymentAmountController;
  late TextEditingController _phoneController;

  final RegisterPassengerController _controller = RegisterPassengerController();
  bool _isLoading = false;

  // List for the dropdown
  late List<String> pickupLocations;

  final Color appGreen = const Color(0xFF05A664);

  @override
  void initState() {
    super.initState();

    // Initialize pickup locations
    if (widget.pickupLocations != null && widget.pickupLocations!.isNotEmpty) {
      pickupLocations = widget.pickupLocations!;
    } else {
      // Default fallback if no route data
      pickupLocations = ['Colombo', 'Gampaha', 'Kandy', 'Galle'];
    }

    // Initialize controllers with passenger data
    _nameController = TextEditingController(text: widget.passenger.name);
    _paymentAmountController = TextEditingController(
      text: widget.passenger.paymentAmount,
    );
    _phoneController = TextEditingController(text: widget.passenger.phone);

    // Set selected location
    _selectedLocation =
        widget.passenger.pickupLocation.isNotEmpty &&
            pickupLocations.contains(widget.passenger.pickupLocation)
        ? widget.passenger.pickupLocation
        : null;

    // Set payment frequency if it matches (or keep default Daily)
    if (widget.passenger.paymentType == 'Monthly') {
      _paymentFrequency = 'Monthly';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _paymentAmountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    try {
      await _controller.registerPassenger(
        context: context,
        passenger: widget.passenger,
        name: _nameController.text.trim(),
        paymentAmount: _paymentAmountController.text.trim(),
        phone: _phoneController.text.trim(),
        paymentType: _paymentFrequency,
        pickupLocation: _selectedLocation ?? widget.passenger.pickupLocation,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      // Error is handled in controller
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // You can use this to constrain height if needed,
    // but SingleChildScrollView usually handles overflow better without fixed heights.
    // final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          // Header
          const RegistrationHeader(
            title: 'Register',
            subtitle: 'Passenger',
            subtitleColor: Color(0xFF05A664),
            topPadding: 30,
          ),

          // White Card
          WhiteCard(
            topPadding: 250,
            child: SizedBox(
              // height: screenHeight - 250 - 30,
              child: SingleChildScrollView(
                // Changed to standard scrolling to prevent overflow on small screens
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Name Field
                    InputTextField(
                      labelText: 'Name',
                      keyboardType: TextInputType.name,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 30),

                    // Payment Amount Field
                    InputTextField(
                      labelText: 'Payment Amount',
                      keyboardType: TextInputType.number,
                      controller: _paymentAmountController,
                    ),
                    const SizedBox(height: 30),

                    // Phone Number Field
                    InputTextField(
                      labelText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 30),

                    // Payment Frequency
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Payment Frequency',
                        style: TextStyle(
                          color: const Color(0xFF121415),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Daily'),
                            value: 'Daily',
                            groupValue: _paymentFrequency,
                            activeColor: appGreen,
                            onChanged: (value) {
                              setState(() => _paymentFrequency = value!);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Monthly'),
                            value: 'Monthly',
                            groupValue: _paymentFrequency,
                            activeColor: appGreen,
                            onChanged: (value) {
                              setState(() => _paymentFrequency = value!);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- UPDATED DROPDOWN SECTION ---
                    // Replaced Container with DropdownButtonFormField to match InputTextField style
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      icon: Icon(Icons.keyboard_arrow_down, color: appGreen),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText:
                            'Pickup Location', // Matches InputTextField label style
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: TextStyle(color: appGreen),
                        // Mimics standard InputTextField underline style
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: appGreen, width: 1.0),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: appGreen, width: 2.0),
                        ),
                      ),
                      items: pickupLocations.map((location) {
                        return DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                    ),

                    // --------------------------------
                    const SizedBox(height: 50),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
