import 'package:flutter/material.dart';


class DriverRegistrationScreen extends StatelessWidget {
  const DriverRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the dark background color
    const Color darkBackground = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: <Widget>[
          // Header Content (Back Button and Title)
          const Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button (using IconButton for the circle effect)
                Icon(
                  Icons.arrow_back,
                  color: Colors.white, // Back button icon color
                  size: 30,
                ),
                SizedBox(height: 50),
                // Title
                Text(
                  'Driver',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // 'Driver' in white
                  ),
                ),
                Text(
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

          // The large, rounded white card container
          Positioned.fill(
            top: 250, // Starts below the header text
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
              ),
              child: SingleChildScrollView( // Use SingleChildScrollView for scrollability
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[

                    // 2. Input Fields
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
                      showTrailingIcon: false, // The image has a trailing circle only on the first field
                    ),

                    const SizedBox(height: 60),

                    // 3. Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          print('Register button pressed!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Green background
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          elevation: 0, // No shadow
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
                    const SizedBox(height: 50), // Extra space at the bottom
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

// ------------------------------------------
// 2. CUSTOM TEXT FIELD WIDGET
// ------------------------------------------

class InputTextField extends StatelessWidget {
  final String labelText;
  final TextInputType keyboardType;
  final bool showTrailingIcon;

  const InputTextField({
    super.key,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.black54, // Label in dark gray/black
          fontWeight: FontWeight.w500,
        ),
        // Use an underline border
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 1.0), // Green underline when enabled
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2.0), // Slightly thicker green when focused
        ),

        // Trailing icon (the small pink circle shown in the image)
        suffixIcon: showTrailingIcon
            ? Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.pink.shade200, // Pink border
                width: 2,
              ),
            ),
          ),
        )
            : null,
      ),
    );
  }
}