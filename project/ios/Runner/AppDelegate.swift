import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

    // ✅ Required for UIScene
    lazy var flutterEngine = FlutterEngine(name: "my flutter engine")

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ✅ Start Flutter engine (VERY IMPORTANT for UIScene)
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)

        // ✅ Initialize Google Maps from Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String {
            GMSServices.provideAPIKey(apiKey)
        } else {
            fatalError("GoogleMapsAPIKey not found in Info.plist")
        }

        // ✅ Setup Method Channel using FlutterEngine
        let controller = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)

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