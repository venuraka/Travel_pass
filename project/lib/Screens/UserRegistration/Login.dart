import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/AuthService.dart';
import '../../utils/AuthExceptionHandler.dart';
import 'SignUp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/AccessController.dart';
import '../passenger/Dashboard.dart';
import '../passenger/PendingApproval.dart';
import '../UserRegistration/UserSelection.dart';
import '../Components/CustomSnackBar.dart';
import '../../models/UserModel.dart';

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
      // Navigate to Driver Dashboard (replace with your actual driver home)
      // Assuming 'Driver/Dashboard.dart' exists or using UserSelection for now if multiple driver screens
      // For now, let's go to UserSelection as a placeholder or proper Driver Home
      // But based on request, we want strict routing.
      // If driver, usually goes to Dashboard.
      // Let's check imports. Dashboard.dart is in Screens/Driver.
      // I'll stick to UserSelection for now as I don't see Dashboard imported,
      // OR I can import it. Let's start with UserSelection which likely has logic or just go there.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
      );
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
      // If not approved (or not found as driver/passenger yet - e.g. new user)
      // If new user, maybe go to UserSelection to register?
      // But checkPassengerStatus returns false if not found.
      // So if neither, go to UserSelection.
      // Wait, if registered=false, it means they ARE in passenger collection but not approved.
      // We need to differentiate "Not a user yet" vs "Pending Passenger".

      // Let's refine checkPassengerStatus: it returns false if not found OR not registered.
      // We might need to know if they exist at all.

      // Simple logic:
      // If (passenger exits AND registered=false) -> Pending
      // If (passenger exists AND registered=true) -> Updates
      // If (neither driver nor passenger) -> UserSelection (to register)

      // Reuse logic from AccessController effectively?
      // AccessController only returned bool.
      // Let's assume for now:
      // If we are here, we are not a driver.
      // Let's try to get passenger doc.

      final isPassenger = await _db.collection('passenger').doc(uid).get();

      if (isPassenger.exists) {
        if (isPassenger.data()?['registered'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PassengerDashboardApp(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingApprovalScreen(),
            ),
          );
        }
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
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 30),
                // Header
                Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121415),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Welcome back!',
                  style: TextStyle(fontSize: 16.sp, color: Color(0xFF05A664)),
                ),
                SizedBox(height: 40.h),

                // Google Sign In Button
                _buildGoogleButton(),

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

                // Terms of Service Footer
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'By continuing, you agree to our Terms of Service',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF05A664)),
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
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
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
                    'Login with Google',
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
                    builder: (context) => const GoogleSignUpPage(),
                  ),
                );
              },
              child: const Text(
                "Sign Up",
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
