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
  static String _androidCertificateHash = '';
  static String _openWeatherApiKey = '';
  static String _payhereMerchantId = '';
  static String _payhereMerchantSecret = '';

  /// Must be called once in main() before runApp().
  static Future<void> init() async {
    _googleMapsApiKey =
        await _channel.invokeMethod<String>('getGoogleMapsApiKey') ?? '';
    _androidCertificateHash =
        await _channel.invokeMethod<String>('getAndroidCertificateHash') ?? '';
    _openWeatherApiKey =
        await _channel.invokeMethod<String>('getOpenWeatherApiKey') ?? '';
    _payhereMerchantId =
        await _channel.invokeMethod<String>('getPayhereMerchantId') ?? '';
    _payhereMerchantSecret =
        await _channel.invokeMethod<String>('getPayhereMerchantSecret') ?? '';
  }
  
  /// The Google Maps / Places / Directions API key.
  static String get googleMapsApiKey => _googleMapsApiKey;

  /// The OpenWeather API key.
  static String get openWeatherApiKey => _openWeatherApiKey;

  /// The PayHere Merchant ID.
  static String get payhereMerchantId => _payhereMerchantId;

  /// The PayHere Merchant Secret (Hash).
  static String get payhereMerchantSecret => _payhereMerchantSecret;

  /// The Android SHA-1 certificate hash for API restrictions.
  static String get androidCertificateHash => _androidCertificateHash;
}
