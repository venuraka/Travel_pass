import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Initialize Google Maps (safe to do here — no UI dependency)
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String {
        GMSServices.provideAPIKey(apiKey)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ UIScene migration: register plugins and set up method channels here
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    // 📞 Phone Method Channel
    let phoneChannel = FlutterMethodChannel(
        name: "com.travelpass.app/phone",
        binaryMessenger: messenger
    )
    phoneChannel.setMethodCallHandler { (call, result) in
        if call.method == "makeCall" {
            guard let args = call.arguments as? [String: Any],
                  let phoneNumber = args["phoneNumber"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                    message: "Phone number is required",
                                    details: nil))
                return
            }
            if let url = URL(string: "tel://\(phoneNumber)"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        result(nil)
                    } else {
                        result(FlutterError(code: "OPEN_FAILED",
                                            message: "Failed to open dialer",
                                            details: nil))
                    }
                }
            } else {
                result(FlutterError(code: "CANNOT_OPEN",
                                    message: "Cannot open phone dialer",
                                    details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    // 🔑 Config Method Channel
    let configChannel = FlutterMethodChannel(
        name: "com.travelpass.app/config",
        binaryMessenger: messenger
    )
    configChannel.setMethodCallHandler { (call, result) in
        if call.method == "getGoogleMapsApiKey" {
            let key = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? ""
            result(key)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
  }
}