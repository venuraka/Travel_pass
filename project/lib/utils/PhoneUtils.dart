import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneUtils {
  /// Launches the phone dialer with the given phone number.
  /// Shows a snackbar error if the dialer cannot be opened.
  static Future<void> makeCall(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }

    const platform = MethodChannel('com.travelpass.app/phone');
    try {
      await platform.invokeMethod('makeCall', {'phoneNumber': cleanNumber});
    } on PlatformException catch (e) {
      debugPrint('Error launching dialer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening dialer: ${e.message}')),
        );
      }
    }
  }
}
