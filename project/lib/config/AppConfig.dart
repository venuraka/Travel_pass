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

  /// Must be called once in main() before runApp().
  static Future<void> init() async {
    _googleMapsApiKey =
        await _channel.invokeMethod<String>('getGoogleMapsApiKey') ?? '';
  }

  /// The Google Maps / Places / Directions API key.
  /// Only available after [init()] has been awaited.
  static String get googleMapsApiKey => _googleMapsApiKey;
}
