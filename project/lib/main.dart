import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add import
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:project/Screens/Driver/Dashboard.dart';
import 'Screens/passenger/Dashboard.dart';
import 'firebase_options.dart';
import 'utils/AuthWrapper.dart';

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
    // Standard design size for mobile apps (e.g., iPhone 13)
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TravelPass',
          theme: ThemeData(
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: Colors.white,
          ),

          // Set the initial route to AuthWrapper
          // home: const AuthWrapper(),
          home: const DriverDashboardScreen(),
          // home: const  PassengerDashboardApp(),
        );
      },
    );
  }
}
