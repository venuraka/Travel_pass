import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Uncomment when dependency is added
// import 'package:google_sign_in/google_sign_in.dart'; // Uncomment when dependency is added
import 'GoogleSignUp.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Placeholder logic matching GoogleSignUpPage
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Login Logic needs google_sign_in package')),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF121415)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 30),
                // Header
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121415),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF05A664),
                  ),
                ),
                const SizedBox(height: 40),

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
                      style: TextStyle(
                        fontSize: 14,
                          color: Color(0xFF05A664),
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
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF121415), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF121415).withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 10,
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
                     valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05A664)),
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
        _buildTextField(label: 'Email', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 15),
        _buildTextField(label: 'Password', obscureText: true),
        const SizedBox(height: 30),
        
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
               // Placeholder for Email Login
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email Login Logic Placeholder')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05A664),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                fontSize: 18,
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
             const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF121415))),
             GestureDetector(
               onTap: () {
                 // Navigate to Sign Up
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const GoogleSignUpPage()),
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
         )
      ],
    );
  }

  Widget _buildTextField({required String label, bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF121415),
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF05A664), width: 1.0),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF05A664), width: 2.0),
        ),
      ),
    );
  }
}
