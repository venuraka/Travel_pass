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
import 'package:project/services/NotificationService.dart';
import 'package:project/config/AppConfig.dart';
import 'package:project/Screens/passenger/PaymentHistory.dart';

void main() async {
  // 1. Ensures Flutter widgets are ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Lock orientation to Portrait Only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 3. Initialize Firebase with your project options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 4. Initialize FCM
  await PushNotificationService().initialize();

  // 5. Load API keys securely from native platform (Info.plist / AndroidManifest)
  await AppConfig.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Standard design size for mobile apps (e.g., iPhone 13)
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'TravelPass',
          theme: ThemeData(
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: Colors.white,
          ),
          // home: const PassengerDashboardApp(),
          // home: const DriverDashboardScreen(),
          // this should be default button,dont change this 
          // home: const AuthWrapper(),
          home: GoogleSignUpPage(),
        );
      },
    );
  }
}
