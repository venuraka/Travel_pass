import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import '../../models/PassengerModel.dart';
import '../../controllers/RegisterPassengerController.dart';

class EditPassengerScreen extends StatefulWidget {
  final PassengerModel passenger;
  final List<String> pickupLocations;

  const EditPassengerScreen({
    super.key,
    required this.passenger,
    this.pickupLocations = const ['Colombo', 'Gampaha', 'Kandy', 'Galle'],
  });

  @override
  State<EditPassengerScreen> createState() => _EditPassengerScreenState();
}

class _EditPassengerScreenState extends State<EditPassengerScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _paymentAmountController;

  // State variables
  late String _paymentFrequency;
  String? _selectedLocation;
  bool _isLoading = false;

  final Color appGreen = const Color(0xFF05A664);
  final RegisterPassengerController _controller = RegisterPassengerController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with passenger data
    _nameController = TextEditingController(text: widget.passenger.name);
    _phoneController = TextEditingController(text: widget.passenger.phone);
    _paymentAmountController = TextEditingController(
      text: widget.passenger.paymentAmount,
    );

    // Initialize state variables
    _paymentFrequency = widget.passenger.paymentType.isNotEmpty
        ? widget.passenger.paymentType
        : 'Daily';

    // Set selected location if it exists in the list, otherwise null or default
    if (widget.pickupLocations.contains(widget.passenger.pickupLocation)) {
      _selectedLocation = widget.passenger.pickupLocation;
    } else if (widget.passenger.pickupLocation.isNotEmpty) {
      // If the location is not in the list, we might want to add it temporarily or handle it
      // For now, let's just default to null if not found to force re-selection or handle custom
      // But typically we should show the existing value.
      // Let's assume the list passed includes the current one or we add it.
      // Check if we need to add it to the dropdown list locally
      _selectedLocation = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  Future<void> _updatePassenger() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _controller.updatePassenger(
        passenger: widget.passenger,
        name: _nameController.text.trim(),
        paymentAmount: _paymentAmountController.text.trim(),
        phone: _phoneController.text.trim(),
        paymentType: _paymentFrequency,
        pickupLocation: _selectedLocation ?? '',
        context: context,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      // Error handled in controller
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine passed locations with current passenger location if unique
    final List<String> dropdownLocations = [...widget.pickupLocations];
    if (widget.passenger.pickupLocation.isNotEmpty &&
        !dropdownLocations.contains(widget.passenger.pickupLocation)) {
      dropdownLocations.insert(0, widget.passenger.pickupLocation);
      _selectedLocation ??= widget.passenger.pickupLocation;
    } else if (_selectedLocation == null &&
        widget.passenger.pickupLocation.isNotEmpty) {
      _selectedLocation = widget.passenger.pickupLocation;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          // Header
          const RegistrationHeader(
            title: 'Edit',
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
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLocation,
                      icon: Icon(Icons.keyboard_arrow_down, color: appGreen),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Pickup Location',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: TextStyle(color: appGreen),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: appGreen, width: 1.0),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: appGreen, width: 2.0),
                        ),
                      ),
                      items: dropdownLocations.map((location) {
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

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePassenger,
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
                                    'Update',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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
