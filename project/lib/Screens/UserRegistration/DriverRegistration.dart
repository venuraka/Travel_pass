import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import 'VehicleRegistration.dart';


class DriverRegistrationScreen extends StatelessWidget {
  const DriverRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'Driver',
            subtitle: 'Registration',
            subtitleColor: Color(0xFF05A664),
          ),

          WhiteCard(
            topPadding: 300,
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
                  labelText: 'Phone',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),
                const InputTextField(
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  showTrailingIcon: false,
                ),
                const SizedBox(height: 60),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VehicleRegistrationScreen()),
                      );
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