import UIKit

final class SplashViewController: UIViewController {
    private let tokenStorage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private var didStartFlow = false

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
        guard !didStartFlow else { return }
        didStartFlow = true
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
        guard let token = tokenStorage.token else {
            showAuthFlow()
            return
        }

        fetchProfile(token: token)
    }

    private func showAuthFlow() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }

    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()

        profileService.fetchProfile(token: token) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let profile):
                self.fetchProfileImage(username: profile.username) {
                    UIBlockingProgressHUD.dismiss()
                    self.switchToTabBarController()
                }
            case .failure(let error):
                UIBlockingProgressHUD.dismiss()
                print("[SplashViewController] Failed to fetch profile: \(error.localizedDescription)")
                self.tokenStorage.clearToken()
                self.profileService.clearProfile()
                self.showProfileErrorAlert()
            }
        }
    }

    private func fetchProfileImage(username: String, completion: @escaping () -> Void) {
        profileImageService.fetchProfileImageURL(username: username) { result in
            if case .failure(let error) = result {
                print("[SplashViewController] Failed to fetch profile image: \(error.localizedDescription)")
            }
            completion()
        }
    }

    private func switchToTabBarController() {
        guard let window = view.window else {
            print("[SplashViewController] Failed to get window")
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController")
        window.rootViewController = tabBarController
    }

    private func showProfileErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default) { [weak self] _ in
            self?.showAuthFlow()
        })
        present(alert, animated: true)
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewControllerDidAuthenticate(_ viewController: AuthViewController) {
        guard let token = tokenStorage.token else {
            print("[SplashViewController] Missing token after authentication")
            UIBlockingProgressHUD.dismiss()
            showProfileErrorAlert()
            return
        }

        fetchProfile(token: token)
    }
}
