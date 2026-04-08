import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'Screens/Driver/Dashboard.dart';
import 'Screens/UserRegistration/Login.dart';
import 'Screens/UserRegistration/SignUp.dart';
import 'Screens/passenger/Dashboard.dart';
import 'firebase_options.dart';
import 'utils/AuthWrapper.dart';
import 'config/AppConfig.dart';

void main() async {
  // 1. Ensures Flutter widgets are ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Lock orientation to Portrait Only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 3. Initialize Firebase with your project options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 4. Set up FCM Background handler removed

  // 5. Load API keys securely from native platform (Info.plist / AndroidManifest)
  await AppConfig.init();

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
          // home: const PassengerDashboardApp(),
          home: const DriverDashboardScreen(),
          // home: const GoogleSignUpPage(),

        );
      },
    );
  }
}
