import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add import
import 'Screens/Driver/Dashboard.dart';
import 'Screens/passenger/Dashboard.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Ensures Flutter widgets are ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with your project options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await dotenv.load(fileName: ".env"); // Load env file

  // Note: GoogleSignIn.instance.initialize() is NOT required on iOS when
  // GoogleService-Info.plist is properly configured. It's only needed on web
  // or when you need to override default configuration.

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

      // Set the initial route to your corrected SignUp Page
      // home: const PassengerDashboardApp(),
      home: const DriverDashboardScreen(),
    );
  }
}
