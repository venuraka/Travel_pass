import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _DriverRegistration2ScreenState();
}

class _DriverRegistration2ScreenState
    extends State<VehicleRegistrationScreen> {
  String? selectedVehicle;
  final List<String> vehicleTypes = ['Car', 'Mini Van', 'Mini Bus','Bus'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'Vehicle',
            subtitle: 'Registration',
            subtitleColor: Color(0xFF05A664),
            topPadding: 100,
          ),

          WhiteCard(
            topPadding: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const InputTextField(
                  labelText: 'Add Route Stop',
                  keyboardType: TextInputType.text,
                  showTrailingIcon: true,
                ),
                const SizedBox(height: 30),

                const InputTextField(
                  labelText: 'Seat Count',
                  keyboardType: TextInputType.number,
                  showTrailingIcon: false,
                ),
                const SizedBox(height: 30),

                // ✅ Vehicle Type Dropdown with Green Border
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF05A664), // green border
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedVehicle,
                      hint: const Text(
                        'Vehicle Type',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF05A664)), // green dropdown arrow
                      isExpanded: true,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      items: vehicleTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVehicle = value;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('Register button pressed!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05A664),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
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
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}