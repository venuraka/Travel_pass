import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import '../../models/PassengerModel.dart';
import '../../controllers/RegisterPassengerController.dart';
import '../../services/Database.dart';

class EditPassengerScreen extends StatefulWidget {
  final PassengerModel passenger;

  const EditPassengerScreen({super.key, required this.passenger});

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
  List<String> _availableLocations = [];
  bool _isLoadingRoute = true;

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

    _fetchRouteStops();
  }

  Future<void> _fetchRouteStops() async {
    try {
      final driverData = await DatabaseService().getDriverData(
        widget.passenger.driverId,
      );
      if (driverData != null && driverData.route != null) {
        final locations = driverData.route!
            .where((point) => point['role'] != 'end')
            .map((point) => point['name'] as String)
            .toList();

        if (mounted) {
          setState(() {
            _availableLocations = locations;
            _isLoadingRoute = false;

            // Handle initial selection
            if (widget.passenger.pickupLocation.isNotEmpty) {
              if (_availableLocations.contains(
                widget.passenger.pickupLocation,
              )) {
                _selectedLocation = widget.passenger.pickupLocation;
              } else {
                // If current location is not in the fetched route, add it temporarily
                _availableLocations.insert(0, widget.passenger.pickupLocation);
                _selectedLocation = widget.passenger.pickupLocation;
              }
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingRoute = false);
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
      if (mounted) setState(() => _isLoadingRoute = false);
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
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final paymentAmount = _paymentAmountController.text.trim();

    if (name.isEmpty || paymentAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(paymentAmount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment mount must contain only numbers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _controller.updatePassenger(
        passenger: widget.passenger,
        name: name,
        paymentAmount: paymentAmount,
        phone: phone,
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
                      labelText: 'Phone Number (Optional)',
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
                    _isLoadingRoute
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(color: appGreen),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedLocation,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: appGreen,
                            ),
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Pickup Location',
                              labelStyle: const TextStyle(color: Colors.grey),
                              floatingLabelStyle: TextStyle(color: appGreen),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: appGreen,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: appGreen,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            items: _availableLocations.map((location) {
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
