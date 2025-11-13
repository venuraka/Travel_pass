import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import 'VehicleRegistration.dart';


class PassengerRegistrationScreen extends StatefulWidget {
  const PassengerRegistrationScreen({super.key});

  @override
  State<PassengerRegistrationScreen> createState() => _PassengerRegistrationScreenState();
}

class _PassengerRegistrationScreenState extends State<PassengerRegistrationScreen> {
  String paymentType = 'Daily Payment';
  String? selectedLocation;

  final List<String> pickupLocations = [
    'Colombo',
    'Gampaha',
    'Kandy',
    'Negombo',
    'Matara',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'passenger',
            subtitle: 'Registration',
            subtitleColor: Color(0xFF05A664),
            topPadding: 30,
          ),

          WhiteCard(
            topPadding: 250,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const InputTextField(
                    labelText: 'Name',
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 30),
                  const InputTextField(
                    labelText: 'Vehicle Number Plate',
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 30),
                  const InputTextField(
                    labelText: 'Address',
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 30),
                  const InputTextField(
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 30),
                  const InputTextField(
                    labelText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 30),
                  const InputTextField(
                    labelText: 'Other Phone Number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 30),

                  // ===== Payment Type Radio Buttons =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Payment Type',
                      style: TextStyle(
                        color: Color(0xFF121415),
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
                          value: 'Daily Payment',
                          groupValue: paymentType,
                          activeColor: const Color(0xFF05A664),
                          onChanged: (value) {
                            setState(() => paymentType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Monthly'),
                          value: 'Monthly Payment',
                          groupValue: paymentType,
                          activeColor: const Color(0xFF05A664),
                          onChanged: (value) {
                            setState(() => paymentType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ===== Pickup Location Dropdown =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pickup Location',
                      style: TextStyle(
                        color: Color(0xFF121415),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF05A664), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLocation,
                        hint: const Text('Select Pickup Location'),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF05A664)),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black),
                        items: pickupLocations.map((location) {
                          return DropdownMenuItem<String>(
                            value: location,
                            child: Text(location),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLocation = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // ===== Register Button =====
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VehicleRegistrationScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05A664),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}