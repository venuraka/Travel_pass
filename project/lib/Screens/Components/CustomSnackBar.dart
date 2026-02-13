import 'package:flutter/material.dart';

class CustomSnackBar {
  static const Color successColor = Color(0xFF05A664);
  static const Color errorColor = Color(0xFF121415);

  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor ?? errorColor,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, backgroundColor: successColor);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, backgroundColor: errorColor);
  }
}
