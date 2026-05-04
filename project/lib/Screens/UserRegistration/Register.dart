import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/AuthService.dart';
import '../../controllers/AccessController.dart';
import '../../utils/AuthExceptionHandler.dart';
import '../passenger/Dashboard.dart';
import '../passenger/PendingApproval.dart';
import '../UserRegistration/UserSelection.dart';
import '../Components/CustomSnackBar.dart';
import '../../models/UserModel.dart';
import '../Driver/Dashboard.dart';
import '../Driver/DriverPendingApproval.dart';
import 'Login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // MVC: Initialize the Service (Model)
  final AuthService _authService = AuthService();
  final AccessController _accessController = AccessController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Controllers for Name/Email/Password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  // 1. Corrected Google Sign-In Logic
  Future<void> _signInWithGoogle() async {
    await _handleAuth(_authService.signInWithGoogle);
  }

  Future<void> _signInWithApple() async {
    await _handleAuth(_authService.signInWithApple);
  }



  // 4. Corrected Email Sign-Up Logic
  Future<void> _handleEmailSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      CustomSnackBar.showError(context, "Please fill all fields");
      return;
    }

    if (password != confirm) {
      CustomSnackBar.showError(context, "Passwords do not match");
      return;
    }

    await _handleAuth(() => _authService.signUpWithEmail(email, password));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        toolbarHeight: 40.h,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // 1. Header Section (Title + Subtitle)
                  Column(
                    children: [
                      SizedBox(height: 10.h),
                      Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF121415),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        'Create an account to get started',
                        style: TextStyle(
                          fontSize: 14.sp, 
                          color: const Color(0xFF05A664),
                        ),
                      ),
                    ],
                  ),

                  // 2. Social Buttons Section
                  Column(
                    children: [
                      _buildGoogleButton(),
                      if (Platform.isIOS) ...[ 
                        SizedBox(height: 12.h),
                        _buildAppleButton(),
                      ],
                    ],
                  ),

                  // 3. Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFF121415))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          "Register with Email",
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFF121415))),
                    ],
                  ),

                  // 4. Email Form Section
                  _buildEmailForm(),

                  // 5. Terms of Service Footer
                  Padding(
                    padding: EdgeInsets.only(bottom: 15.h),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11.sp,
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
            );
          },
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
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF05A664)),
              )
            : Row(
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
                    'Sign up with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          color: Colors.black,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 4.h),
              blurRadius: 10.r,
            ),
          ],
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.apple,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sign up with Apple',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
        const SizedBox(height: 15),
        _buildTextField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          obscureText: true,
        ),
        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05A664),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: const Text(
              'Register',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 15.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Already have an account? "),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ),
              child: const Text(
                "Login",
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
          color: const Color(0xFF121415),
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF05A664), width: 1.0.w),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF05A664), width: 2.0.w),
        ),
      ),
    );
  }
}
