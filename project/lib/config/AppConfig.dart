import 'package:flutter/services.dart';

/// AppConfig manages application-level configuration.
/// Most sensitive keys have been moved to the backend for security.
class AppConfig {
  static const MethodChannel _channel = MethodChannel('com.travelpass.app/config');

  static String _googleMapsApiKey = '';
  static String _androidCertificateHash = '';

  /// Must be called once in main() before runApp().
  static Future<void> init() async {
    _googleMapsApiKey =
        await _channel.invokeMethod<String>('getGoogleMapsApiKey') ?? '';
    _androidCertificateHash =
        await _channel.invokeMethod<String>('getAndroidCertificateHash') ?? '';
  }
  
  /// The Google Maps / Places / Directions API key.
  static String get googleMapsApiKey => _googleMapsApiKey;

  /// The Android SHA-1 certificate hash for API restrictions.
  static String get androidCertificateHash => _androidCertificateHash;
}
