import 'package:flutter/material.dart';
import '../../Components/InputTexts.dart';
import '../../Components/Whitecard.dart';

class DriverRegistrationScreen extends StatelessWidget {
  const DriverRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkBackground = Color(0xFF121415);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: <Widget>[
          // Header
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 50),
                const Text(
                  'Driver',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Registration',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green, // 'Registration' in green
                  ),
                ),
              ],
            ),
          ),

          // White Card section
          WhiteCard(
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

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('Register button pressed!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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