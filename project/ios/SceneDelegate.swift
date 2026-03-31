import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let flutterViewController = FlutterViewController()
        let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).flutterEngine

        flutterViewController.engine = flutterEngine

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = flutterViewController
        window?.makeKeyAndVisible()
    }
}
