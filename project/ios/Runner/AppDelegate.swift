import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
//   Google maps for flutter
  GMSServices.provideAPIKey("AIzaSyCGbN2wCtheM7gjPzgLykngb4lPaPiTR7c")
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for phone calls
    let controller = window?.rootViewController as! FlutterViewController
    let phoneChannel = FlutterMethodChannel(
      name: "com.travelpass.app/phone",
      binaryMessenger: controller.binaryMessenger
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
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
