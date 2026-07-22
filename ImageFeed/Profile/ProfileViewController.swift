import UIKit
import Kingfisher

protocol ProfileServiceProtocol: AnyObject {
    var profile: Profile? { get }
    func clearProfile()
}

protocol ProfileImageServiceProtocol: AnyObject {
    var avatarURL: String? { get }
    func clearProfileImage()
}

extension ProfileService: ProfileServiceProtocol {}
extension ProfileImageService: ProfileImageServiceProtocol {}

final class ProfileViewController: UIViewController {
    private enum Text {
        static let defaultDescription = "Hello, World!"
    }

    @IBOutlet private var avatarImageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var loginNameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var logoutButton: UIButton!

    var profileService: ProfileServiceProtocol = ProfileService.shared
    var profileImageService: ProfileImageServiceProtocol = ProfileImageService.shared
    private var profileImageServiceObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "ProfileView"
        view.backgroundColor = .ypBlack
        avatarImageView.accessibilityIdentifier = "ProfileAvatarImageView"
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 35
        avatarImageView.clipsToBounds = true

        nameLabel.accessibilityIdentifier = "ProfileNameLabel"
        nameLabel.font = .systemFont(ofSize: 23, weight: .bold)
        nameLabel.textColor = .ypWhite

        loginNameLabel.accessibilityIdentifier = "ProfileLoginNameLabel"
        loginNameLabel.font = .systemFont(ofSize: 13, weight: .regular)
        loginNameLabel.textColor = .ypGray

        descriptionLabel.accessibilityIdentifier = "ProfileDescriptionLabel"
        descriptionLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = .ypWhite
        descriptionLabel.numberOfLines = 0

        logoutButton.accessibilityIdentifier = "ProfileLogoutButton"

        updateProfileDetails()
        setupObservers()
        updateAvatar()
    }

    deinit {
        if let profileImageServiceObserver {
            NotificationCenter.default.removeObserver(profileImageServiceObserver)
        }
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

    private func setupObservers() {
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
    }

    private func updateProfileDetails() {
        guard let profile = profileService.profile else { return }

        nameLabel.text = profile.name
        loginNameLabel.text = profile.loginName

        if let bio = profile.bio, !bio.isEmpty {
            descriptionLabel.text = bio
        } else {
            descriptionLabel.text = Text.defaultDescription
        }
    }

    private func updateAvatar() {
        guard let urlString = profileImageService.avatarURL,
              let url = URL(string: urlString) else {
            avatarImageView.image = UIImage(named: "avatarPlaceholder")
            return
        }

        let placeholder = UIImage(named: "avatarPlaceholder")
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [.processor(processor), .scaleFactor(UIScreen.main.scale)]
        )
    }

    private func performLogout() {
        OAuth2TokenStorage.shared.clearToken()
        profileService.clearProfile()
        profileImageService.clearProfileImage()

        guard let window = view.window else {
            print("[ProfileViewController] Failed to get window for logout")
            return
        }

        let splashViewController = SplashViewController()
        window.rootViewController = splashViewController
    }
}
