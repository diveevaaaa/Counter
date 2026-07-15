import UIKit

final class SplashViewController: UIViewController {
    private let tokenStorage = OAuth2TokenStorage.shared

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "practicumLogo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .ypWhite
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switchToAppropriateFlow()
    }

    private func setupLayout() {
        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 75),
            logoImageView.heightAnchor.constraint(equalToConstant: 78)
        ])
    }

    private func switchToAppropriateFlow() {
        if tokenStorage.token != nil {
            switchToTabBarController()
        } else {
            showAuthFlow()
        }
    }

    private func showAuthFlow() {
        let authViewController = AuthViewController()
        authViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: authViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    private func switchToTabBarController() {
        guard let window = view.window else {
            print("[SplashViewController] Failed to get window")
            return
        }

        let tabBarController = TabBarController()
        window.rootViewController = tabBarController
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewControllerDidAuthenticate(_ viewController: AuthViewController) {
        viewController.dismiss(animated: true) { [weak self] in
            self?.switchToTabBarController()
        }
    }
}
