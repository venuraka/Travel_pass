import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../controllers/AuthService.dart';
import '../../utils/AuthExceptionHandler.dart';
import 'Register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/AccessController.dart';
import '../passenger/Dashboard.dart';
import '../passenger/PendingApproval.dart';
import '../UserRegistration/UserSelection.dart';
import '../Components/CustomSnackBar.dart';
import '../../models/UserModel.dart';
import '../Driver/Dashboard.dart';
import '../Driver/DriverPendingApproval.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final AccessController _accessController = AccessController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(Future<MyUserModel?> Function() authFunction) async {
    setState(() => _isLoading = true);
    try {
      final user = await authFunction();
      if (user != null && mounted) {
        _navigateBasedOnRole(user.uid);
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(
        context,
        AuthExceptionHandler.handleException(e),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateBasedOnRole(String uid) async {
    // Check if Driver
    final isDriver = await _accessController.isDriver(uid);
    if (isDriver) {
      if (!mounted) return;
      final isDriverApproved = await _accessController.isDriverApproved(uid);
      if (isDriverApproved) {
        // We need to import DriverDashboardScreen if not imported.
        // Assuming we will add the import at the top if needed. Let's just use it.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverPendingApprovalScreen()),
        );
      }
      return;
    }

    // Check if Passenger
    final isApproved = await _accessController.checkPassengerStatus(uid);
    if (!mounted) return;

    if (isApproved) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PassengerDashboardApp()),
      );
    } else {
      final isPassenger = await _db.collection('passenger').doc(uid).get();

      if (isPassenger.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PendingApprovalScreen(),
          ),
        );
      } else {
        // New user
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    await _handleAuth(_authService.signInWithGoogle);
  }

  Future<void> _signInWithApple() async {
    await _handleAuth(_authService.signInWithApple);
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      CustomSnackBar.showError(context, "Please fill all fields");
      return;
    }

    await _handleAuth(() => _authService.loginWithEmail(email, password));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 30),
                const Text(
                  'LogIn',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121415),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 16, color: Color(0xFF05A664)),
                ),
                SizedBox(height: 40.h),

                // Social Sign In Buttons
                _buildGoogleButton(),
                if (Platform.isIOS) ...[ 
                  SizedBox(height: 20.h),
                  _buildAppleButton(),
                ],

                const SizedBox(height: 30),

                // Divider
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xFF121415))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Or login with Email"),
                    ),
                    Expanded(child: Divider(color: Color(0xFF121415))),
                  ],
                ),

                const SizedBox(height: 30),

                // Email Form
                _buildEmailForm(),

                const SizedBox(height: 20),

                // Terms of Service & Privacy Policy Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(
                            color: Color(0xFF05A664),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final Uri url = Uri.parse('https://venuraka.github.io/TravelPass-Additional-Information/#terms');
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                debugPrint("Could not launch $url");
                              }
                            },
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: Color(0xFF05A664),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final Uri url = Uri.parse('https://venuraka.github.io/TravelPass-Additional-Information/#privacy');
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                debugPrint("Could not launch $url");
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return InkWell(
      onTap: _isLoading ? null : _signInWithGoogle,
      child: Container(
        width: double.infinity,
        height: 55.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: const Color(0xFF121415), width: 1.5.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF121415).withOpacity(0.1),
              offset: Offset(0, 4.h),
              blurRadius: 10.r,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isLoading)
              const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF05A664),
                    ),
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'Assets/Images/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      size: 40,
                      color: Color(0xFF121415),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'SignUp with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF121415),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildAppleButton() {
    return InkWell(
      onTap: _isLoading ? null : _signInWithApple,
      child: Container(
        width: double.infinity,
        height: 55.h,
        decoration: BoxDecoration(
          color: Colors.black, // Apple's standard black style
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 4.h),
              blurRadius: 10.r,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isLoading)
              const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.apple,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sign in with Apple',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      children: [
        _buildTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          label: 'Password',
          controller: _passwordController,
          obscureText: true,
        ),
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05A664),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 24.r,
                    width: 24.r,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.w,
                    ),
                  )
                : Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(color: Color(0xFF121415)),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to Sign Up
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(),
                  ),
                );
              },
              child: const Text(
                "Register",
                style: TextStyle(
                  color: Color(0xFF05A664),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF121415),
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF05A664), width: 1.0.w),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF05A664), width: 2.0.w),
        ),
      ),
    );
  }
}
