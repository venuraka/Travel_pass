import 'package:flutter/material.dart';
import 'AuthService.dart';


class AuthController {
  final AuthService _authService = AuthService();

  // Controllers for text fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future<void> handleSignUp(BuildContext context) async {
    if (passwordController.text != confirmPasswordController.text) {
      // Show error: Passwords don't match
      return;
    }

    try {
      await _authService.signUpWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      // Navigate to home on success
    } catch (e) {
      // Show error dialog
    }
  }
}