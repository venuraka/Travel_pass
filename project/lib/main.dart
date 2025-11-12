import 'package:flutter/material.dart';
import 'Screens/UserSelection.dart';
// import your UserSelectionScreen file here

void main() {
  runApp(const MyApp()); // Runs your main app widget
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // This is the crucial wrapper
      title: 'TravelPass',


      theme: ThemeData(
        fontFamily: 'Poppins',
        // You can define your app-wide theme here

        primaryColor: const Color(0xFF05A664),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF05A664),
          primary: const Color(0xFF05A664),
          secondary: const Color(0xFF121415),
        ),
        scaffoldBackgroundColor: Colors.white,

      ),
      // Set the UserSelectionScreen as the home page
      home: const UserSelectionScreen(),
    );
  }
}

// ... the code for UserSelectionScreen and SelectionTile goes below ...