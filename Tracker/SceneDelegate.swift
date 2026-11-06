import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let onboardingCompleted = UserDefaults.standard.bool(forKey: OnboardingViewController.completedKey)
        if onboardingCompleted {
            window.rootViewController = TabBarController()
            window.backgroundColor = .ypWhite
        } else {
            window.rootViewController = OnboardingViewController()
            window.backgroundColor = UIColor(hex: 0x3772E7)
        }
        window.makeKeyAndVisible()
        self.window = window
    }
}
