import UIKit

final class AuthViewController: UIViewController {
    weak var delegate: AuthViewControllerDelegate?

    private let oauth2Service = OAuth2Service.shared
    private let tokenStorage = OAuth2TokenStorage.shared

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Logo_of_Unsplash"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .custom)
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    @objc
    private func didTapLoginButton() {
        guard !UIBlockingProgressHUD.isBlocking else { return }

        let webViewViewController = WebViewViewController()
        let presenter = WebViewPresenter()
        webViewViewController.presenter = presenter
        webViewViewController.delegate = self
        presenter.view = webViewViewController
        webViewViewController.modalPresentationStyle = .fullScreen
        present(webViewViewController, animated: true)
    }

    @objc
    private func didTouchDownLoginButton() {
        loginButton.backgroundColor = UIColor.ypWhite.withAlphaComponent(0.5)
    }

    @objc
    private func didTouchUpLoginButton() {
        loginButton.backgroundColor = .ypWhite
    }

    private func setupLayout() {
        view.addSubview(logoImageView)
        view.addSubview(loginButton)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),

            loginButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            loginButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func showAuthErrorAlert() {
        AlertPresenter.showLoginError(on: self)
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ viewController: WebViewViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }

            UIBlockingProgressHUD.show()
            self.oauth2Service.fetchOAuthToken(code: code) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let token):
                    self.tokenStorage.token = token
                    UIBlockingProgressHUD.dismiss()
                    self.delegate?.authViewControllerDidAuthenticate(self)
                case .failure(let error):
                    UIBlockingProgressHUD.dismiss()
                    print("[AuthViewController] Failed to fetch OAuth token: \(error.localizedDescription)")
                    self.showAuthErrorAlert()
                }
            }
        }
    }

    func webViewViewControllerDidCancel(_ viewController: WebViewViewController) {
        dismiss(animated: true)
    }
}
