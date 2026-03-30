import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  private func getEnvValue(key: String) -> String? {
    guard let path = Bundle.main.path(forResource: "flutter_assets/.env", ofType: nil) else {
      return nil
    }
    
    do {
      let content = try String(contentsOfFile: path, encoding: .utf8)
      let lines = content.components(separatedBy: .newlines)
      for line in lines {
        let parts = line.components(separatedBy: "=")
        if parts.count >= 2 && parts[0].trimmingCharacters(in: .whitespaces) == key {
          return parts[1].trimmingCharacters(in: .whitespaces)
        }
      }
    } catch {
      print("Error reading .env file: \(error)")
    }
    return nil
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Initialize Google Maps from .env
    if let apiKey = getEnvValue(key: "GOOGLE_MAPS_API_KEY") {
      GMSServices.provideAPIKey(apiKey)
    } else {
      // Fallback
      GMSServices.provideAPIKey("AIzaSyCGbN2wCtheM7gjPzgLykngb4lPaPiTR7c")
    }
    
    // 2. Register plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // 3. Call super.application to ensure window is properly initialized
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // 4. Set up method channel (check if window and controller are available)
    if let controller = window?.rootViewController as? FlutterViewController {
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
    }
    
    return result
  }
}
