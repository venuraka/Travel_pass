import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// AppConfig manages application-level configuration.
/// Most sensitive keys have been moved to the backend for security.
class AppConfig {
  static const MethodChannel _channel = MethodChannel('com.travelpass.app/config');

  static String _googleMapsApiKey = '';
  static String _openWeatherApiKey = '';
  static String _androidCertificateHash = '';

  /// Must be called once in main() before runApp().
  static Future<void> init() async {
    try {
      // Common keys: These fetch the platform-specific value from the native side.
      // (e.g. gets Android key on Android, iOS key on iOS)
      _googleMapsApiKey =
          await _channel.invokeMethod<String>('getGoogleMapsApiKey') ?? '';
      _openWeatherApiKey =
          await _channel.invokeMethod<String>('getOpenWeatherApiKey') ?? '';


      // Android-specific configuration
      if (Platform.isAndroid) {
        _androidCertificateHash =
            await _channel.invokeMethod<String>('getAndroidCertificateHash') ?? '';
      }

      // iOS-specific configuration (Add any iOS-only native methods here)
      if (Platform.isIOS) {
        // Currently, all iOS keys are handled via the common methods above.
        // Add specific iOS-only calls here if you implement them in AppDelegate.swift.
      }
    } catch (e) {
      debugPrint('AppConfig init error: $e');
    }
  }

  /// Returns the Google Maps API key for the current platform.
  static String get googleMapsApiKey => _googleMapsApiKey;

  /// The OpenWeather API key.
  static String get openWeatherApiKey => _openWeatherApiKey;



  /// The Android SHA-1 certificate hash (only populated on Android).
  static String get androidCertificateHash => _androidCertificateHash;
}
