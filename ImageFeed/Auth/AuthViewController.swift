import UIKit

final class AuthViewController: UIViewController {
    weak var delegate: AuthViewControllerDelegate?

    private let oauth2Service = OAuth2Service.shared
    private let tokenStorage = OAuth2TokenStorage.shared

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "practicumLogo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .ypWhite
        return imageView
    }()

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .ypWhite
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.setTitle("Войти", for: .normal)
        button.setTitleColor(.ypBlack, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
        button.addTarget(self, action: #selector(didTouchDownLoginButton), for: .touchDown)
        button.addTarget(self, action: #selector(didTouchUpLoginButton), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupLayout()
        setupNavigationBar()
    }

    @objc
    private func didTapLoginButton() {
        let webViewViewController = WebViewViewController()
        let presenter = WebViewPresenter()
        webViewViewController.presenter = presenter
        webViewViewController.delegate = self
        presenter.view = webViewViewController
        navigationController?.pushViewController(webViewViewController, animated: true)
    }

    @objc
    private func didTouchDownLoginButton() {
        loginButton.backgroundColor = UIColor.ypWhite.withAlphaComponent(0.5)
    }

    @objc
    private func didTouchUpLoginButton() {
        loginButton.backgroundColor = .ypWhite
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }

    private func setupLayout() {
        view.addSubview(logoImageView)
        view.addSubview(loginButton)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 75),
            logoImageView.heightAnchor.constraint(equalToConstant: 78),

            loginButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ viewController: WebViewViewController, didAuthenticateWithCode code: String) {
        navigationController?.popViewController(animated: true)
        UIBlockingProgressHUD.show()

        oauth2Service.fetchAuthToken(code: code) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let token):
                self.tokenStorage.token = token
                UIBlockingProgressHUD.dismiss()
                self.delegate?.authViewControllerDidAuthenticate(self)
            case .failure(let error):
                UIBlockingProgressHUD.dismiss()
                print("[AuthViewController] Failed to fetch auth token: \(error.localizedDescription)")
                self.showAuthErrorAlert()
            }
        }
    }

    func webViewViewControllerDidCancel(_ viewController: WebViewViewController) {
        navigationController?.popViewController(animated: true)
    }
}
