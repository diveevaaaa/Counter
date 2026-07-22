import UIKit

final class TabBarController: UITabBarController {
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViewControllers()
        setupAppearance()
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypBlack
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.3)

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func setupViewControllers() {
        let feedInactiveIcon = UIImage(named: "tab_editorial_no_active")?.withRenderingMode(.alwaysOriginal)
        let feedActiveIcon = UIImage(named: "tab_editorial_active")?.withRenderingMode(.alwaysOriginal)
        let profileInactiveIcon = UIImage(named: "tab_profile_no_active")?.withRenderingMode(.alwaysOriginal)
        let profileActiveIcon = UIImage(named: "tab_profile_active")?.withRenderingMode(.alwaysOriginal)

        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: feedInactiveIcon,
            selectedImage: feedActiveIcon
        )
        imagesListViewController.tabBarItem.accessibilityIdentifier = "ImagesListTab"

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let profileViewController = storyboard.instantiateViewController(
            withIdentifier: "ProfileViewController"
        )
        profileViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: profileInactiveIcon,
            selectedImage: profileActiveIcon
        )
        profileViewController.tabBarItem.accessibilityIdentifier = "ProfileTab"

        viewControllers = [imagesListViewController, profileViewController]
    }
}
