import 'package:flutter/services.dart';

/// Reads sensitive configuration from the native platform at runtime.
///
/// On iOS, the value is read from Info.plist (never compiled into Dart bytecode).
/// On Android, the value is read from AndroidManifest.xml meta-data.
///
/// Call [AppConfig.init()] once in main() before runApp().
/// After that, [AppConfig.googleMapsApiKey] is available synchronously.
class AppConfig {
  static const MethodChannel _channel = MethodChannel('com.travelpass.app/config');

  static String _googleMapsApiKey = '';
  static String _androidCertificateHash = ''; // Added

  /// Must be called once in main() before runApp().
  static Future<void> init() async {
    _googleMapsApiKey =
        await _channel.invokeMethod<String>('getGoogleMapsApiKey') ?? '';
    _androidCertificateHash =
        await _channel.invokeMethod<String>('getAndroidCertificateHash') ?? '';
    
    // ignore: avoid_print
    print("[AppConfig] API Key loaded: ${_googleMapsApiKey.isNotEmpty}");
    // ignore: avoid_print
    print("[AppConfig] Android Hash loaded: $_androidCertificateHash");
  }
  
  /// The Google Maps / Places / Directions API key.
  static String get googleMapsApiKey => _googleMapsApiKey;

  /// The Android SHA-1 certificate hash for API restrictions.
  static String get androidCertificateHash => _androidCertificateHash;
}
