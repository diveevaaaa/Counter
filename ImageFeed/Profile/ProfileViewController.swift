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
        avatarImageView.image = UIImage(named: "avatarPlaceholder")
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

        alert.addAction(UIAlertAction(title: "Да", style: .default))
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel))

        present(alert, animated: true)
    }
}
