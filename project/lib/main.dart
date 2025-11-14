import 'package:flutter/material.dart';
import 'Screens/Driver/Dashboard.dart';




void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TravelPass',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
      ),

      // Initial screen when the app starts
        home: const DriverDashboardScreen(),
    );
  }
}