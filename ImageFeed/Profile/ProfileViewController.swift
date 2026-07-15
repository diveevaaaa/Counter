import UIKit

final class ProfileViewController: UIViewController {
    @IBOutlet private var avatarImageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var loginNameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var logoutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .ypBlack
        avatarImageView.image = UIImage(named: "avatarPhoto")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 35
        avatarImageView.clipsToBounds = true

        nameLabel.font = .systemFont(ofSize: 23, weight: .bold)
        nameLabel.textColor = .ypWhite

        loginNameLabel.font = .systemFont(ofSize: 13, weight: .regular)
        loginNameLabel.textColor = .ypGray

        descriptionLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = .ypWhite
        descriptionLabel.numberOfLines = 0
    }

    @IBAction
    private func didTapLogoutButton(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Да", style: .default) { [weak self] _ in
            self?.performLogout()
        })
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel))

        present(alert, animated: true)
    }

    private func performLogout() {
        OAuth2TokenStorage.shared.clearToken()

        guard let window = view.window else {
            print("[ProfileViewController] Failed to get window for logout")
            return
        }

        let splashViewController = SplashViewController()
        window.rootViewController = splashViewController
    }
}
