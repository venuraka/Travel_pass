import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';

class EditPassengerScreen extends StatefulWidget {
  const EditPassengerScreen({super.key});

  @override
  State<EditPassengerScreen> createState() => _EditPassengerScreenState();
}

class _EditPassengerScreenState extends State<EditPassengerScreen> {
  // State variables
  String _paymentFrequency = 'Daily';
  String? _selectedLocation;

  // List for the dropdown
  final List<String> pickupLocations = ['Colombo', 'Gampaha', 'Kandy', 'Galle'];

  final Color appGreen = const Color(0xFF05A664);

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
                    const InputTextField(
                      labelText: 'Name',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 30),

                    // Payment Amount Field
                    const InputTextField(
                      labelText: 'Payment Amount',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),

                    // Phone Number Field
                    const InputTextField(
                      labelText: 'Phone Number',
                      keyboardType: TextInputType.phone,
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
                      initialValue: _selectedLocation,
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
                        onPressed: () {
                          // Handle Registration Logic (e.g., API call)

                          // Then pop back to previous screen
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Edit',
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
